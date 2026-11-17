pub mod bump;
pub mod stack;
pub mod free_list;
pub mod buddy;
pub mod slab;

use std::alloc::Layout;
use std::ptr::NonNull;
use std::sync::Mutex;

/// Common error type for allocation failures.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AllocError {
    OutOfMemory,
    InvalidLayout,
}

/// The core allocator trait that all our custom allocators will implement.
/// 
/// # Safety
/// The implementor must ensure that returned pointers are valid, correctly aligned,
/// and that deallocation correctly releases memory without violating safety guarantees.
pub unsafe trait CustomAllocator {
    /// Attempt to allocate a block of memory with the given layout.
    unsafe fn alloc(&mut self, layout: Layout) -> Result<NonNull<u8>, AllocError>;

    /// Deallocate the memory block at `ptr` with the given layout.
    unsafe fn dealloc(&mut self, ptr: NonNull<u8>, layout: Layout);

    /// Returns whether the allocator has been initialized with backing memory.
    fn is_initialized(&self) -> bool;

    /// Returns whether a given address is within the bounds managed by this allocator.
    fn contains_addr(&self, addr: usize) -> bool;
}

use std::sync::atomic::{AtomicUsize, Ordering};

/// A wrapper around a `CustomAllocator` that synchronizes access via a `Mutex`.
/// This wrapper allows the allocator to be used in static contexts and implements
/// `std::alloc::GlobalAlloc`.
pub struct Locked<A> {
    inner: Mutex<A>,
    start: AtomicUsize,
    end: AtomicUsize,
}

impl<A> Locked<A> {
    /// Creates a new `Locked` allocator wrapping the given inner allocator.
    pub const fn new(inner: A) -> Self {
        Self {
            inner: Mutex::new(inner),
            start: AtomicUsize::new(0),
            end: AtomicUsize::new(0),
        }
    }

    /// Access the underlying allocator lock.
    pub fn lock(&self) -> std::sync::MutexGuard<'_, A> {
        self.inner.lock().expect("Failed to lock allocator mutex")
    }

    /// Registers the memory bounds of the allocator.
    /// This is used for lock-free checks before delegating to the System allocator.
    pub fn register_bounds(&self, start: usize, size: usize) {
        self.start.store(start, Ordering::Release);
        self.end.store(start + size, Ordering::Release);
    }
}

unsafe impl<A> std::alloc::GlobalAlloc for Locked<A>
where
    A: CustomAllocator,
{
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        let start = self.start.load(Ordering::Acquire);
        
        if start != 0 {
            // Once initialized, lock the mutex and allocate
            let mut allocator = self.lock();
            match allocator.alloc(layout) {
                Ok(ptr) => ptr.as_ptr(),
                Err(_) => std::ptr::null_mut(),
            }
        } else {
            // Fallback to System allocator if not yet initialized
            std::alloc::System.alloc(layout)
        }
    }

    unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
        if let Some(non_null) = NonNull::new(ptr) {
            let addr = ptr as usize;
            let start = self.start.load(Ordering::Acquire);
            let end = self.end.load(Ordering::Acquire);

            if start != 0 && addr >= start && addr < end {
                // If the pointer belongs to our heap, lock and deallocate
                let mut allocator = self.lock();
                allocator.dealloc(non_null, layout);
            } else {
                // Fallback to System allocator for unmanaged blocks
                std::alloc::System.dealloc(ptr, layout)
            }
        }
    }
}

/// Align the given address upwards to the next multiple of the alignment.
/// 
/// `align` must be a power of two.
pub fn align_up(addr: usize, align: usize) -> usize {
    debug_assert!(align.is_power_of_two(), "Alignment must be a power of two");
    (addr + align - 1) & !(align - 1)
}

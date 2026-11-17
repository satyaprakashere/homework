use crate::{AllocError, CustomAllocator};
use std::alloc::Layout;
use std::ptr::NonNull;

/// A simple Bump (Arena) Allocator.
/// 
/// Allocation bumps a pointer forward. Deallocation is a no-op.
/// All memory is reclaimed at once when `reset` is called.
pub struct BumpAllocator {
    start: usize,
    end: usize,
    next: usize,
    allocations: usize,
}

impl BumpAllocator {
    /// Creates a new, uninitialized `BumpAllocator`.
    /// 
    /// Must be initialized with `init` before use.
    pub const fn new() -> Self {
        Self {
            start: 0,
            end: 0,
            next: 0,
            allocations: 0,
        }
    }

    /// Initializes the allocator with a raw memory region.
    /// 
    /// # Safety
    /// The caller must ensure the memory region `[start, start + size)` is valid and
    /// exclusive to this allocator.
    pub unsafe fn init(&mut self, start: usize, size: usize) {
        self.start = start;
        self.end = start + size;
        self.next = start;
        self.allocations = 0;
    }

    /// Resets the bump allocator, reclaiming all memory.
    /// 
    /// # Safety
    /// The caller must ensure that all previously allocated memory from this allocator
    /// is no longer in use.
    pub unsafe fn reset(&mut self) {
        self.next = self.start;
        self.allocations = 0;
    }

    /// Returns the number of active allocations.
    pub fn allocations_count(&self) -> usize {
        self.allocations
    }
}

unsafe impl CustomAllocator for BumpAllocator {
    unsafe fn alloc(&mut self, layout: Layout) -> Result<NonNull<u8>, AllocError> {
        let align = layout.align();
        let size = layout.size();

        // Calculate aligned address for the start of allocation
        let aligned_next = crate::align_up(self.next, align);
        
        // Ensure no overflow occurs when adding size
        let next_limit = aligned_next.checked_add(size).ok_or(AllocError::OutOfMemory)?;

        if next_limit <= self.end {
            self.next = next_limit;
            self.allocations += 1;
            Ok(NonNull::new_unchecked(aligned_next as *mut u8))
        } else {
            Err(AllocError::OutOfMemory)
        }
    }

    unsafe fn dealloc(&mut self, _ptr: NonNull<u8>, _layout: Layout) {
        // Deallocation is a no-op. Memory is only reclaimed upon calling `reset()`.
    }

    fn is_initialized(&self) -> bool {
        self.start != 0
    }

    fn contains_addr(&self, addr: usize) -> bool {
        addr >= self.start && addr < self.end
    }
}

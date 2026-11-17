use crate::{AllocError, CustomAllocator};
use std::alloc::Layout;
use std::ptr::NonNull;

/// Header prepended to every stack allocation to maintain structure and enforce LIFO.
struct StackHeader {
    prev_next: usize,
    #[allow(dead_code)]
    padding: usize,
}

/// A Stack (LIFO) Allocator.
/// 
/// Memory is allocated like a stack. Deallocations must occur in strict LIFO order.
pub struct StackAllocator {
    start: usize,
    end: usize,
    next: usize,
    allocations: usize,
}

impl StackAllocator {
    /// Creates a new, uninitialized `StackAllocator`.
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

    /// Resets the stack allocator, reclaiming all memory.
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

unsafe impl CustomAllocator for StackAllocator {
    unsafe fn alloc(&mut self, layout: Layout) -> Result<NonNull<u8>, AllocError> {
        let align = std::cmp::max(layout.align(), std::mem::align_of::<StackHeader>());
        let header_size = std::mem::size_of::<StackHeader>();

        // Align the payload to its required alignment, making room for the header
        let payload_addr = crate::align_up(self.next + header_size, align);
        let next_limit = payload_addr.checked_add(layout.size()).ok_or(AllocError::OutOfMemory)?;

        if next_limit <= self.end {
            let header_addr = payload_addr - header_size;
            let header = StackHeader {
                prev_next: self.next,
                padding: payload_addr - self.next,
            };

            // Write the header metadata right before the payload
            std::ptr::write(header_addr as *mut StackHeader, header);

            self.next = next_limit;
            self.allocations += 1;
            Ok(NonNull::new_unchecked(payload_addr as *mut u8))
        } else {
            Err(AllocError::OutOfMemory)
        }
    }

    unsafe fn dealloc(&mut self, ptr: NonNull<u8>, layout: Layout) {
        let header_size = std::mem::size_of::<StackHeader>();
        let payload_addr = ptr.as_ptr() as usize;

        // Enforce LIFO: The deallocated block must be the one at the top of the stack.
        assert_eq!(
            payload_addr + layout.size(),
            self.next,
            "Stack allocator deallocation out of LIFO order!"
        );

        let header_addr = payload_addr - header_size;
        let header = std::ptr::read(header_addr as *const StackHeader);

        // Reset the bump pointer back to the state before this allocation
        self.next = header.prev_next;

        if self.allocations > 0 {
            self.allocations -= 1;
        }
    }

    fn is_initialized(&self) -> bool {
        self.start != 0
    }

    fn contains_addr(&self, addr: usize) -> bool {
        addr >= self.start && addr < self.end
    }
}

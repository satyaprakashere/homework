use crate::{AllocError, CustomAllocator};
use std::alloc::Layout;
use std::ptr::NonNull;

/// A node in a buddy free list. Stored inside the free blocks.
struct FreeBlock {
    next: Option<NonNull<FreeBlock>>,
}

/// A Binary Buddy Allocator.
/// 
/// Divides memory into power-of-two sized blocks.
/// Provides zero-overhead allocations (no headers) because layout is provided on deallocation.
pub struct BuddyAllocator {
    start: usize,
    size: usize,
    free_lists: [Option<NonNull<FreeBlock>>; 32],
    min_order: usize,
    max_order: usize,
}

impl BuddyAllocator {
    /// Creates a new, uninitialized `BuddyAllocator`.
    /// 
    /// Must be initialized with `init` before use.
    pub const fn new() -> Self {
        Self {
            start: 0,
            size: 0,
            free_lists: [None; 32],
            min_order: 4, // 16 bytes minimum
            max_order: 0,
        }
    }

    /// Initializes the allocator with a raw memory region.
    /// 
    /// # Safety
    /// The caller must ensure the memory region `[start, start + size)` is valid,
    /// exclusive to this allocator, and that `size` is a power of two.
    /// The `start` address must also be aligned to `size`.
    pub unsafe fn init(&mut self, start: usize, size: usize) {
        assert!(size.is_power_of_two(), "Buddy allocator size must be a power of two");
        assert_eq!(start % size, 0, "Buddy allocator start address must be aligned to its size");

        self.start = start;
        self.size = size;
        self.free_lists = [None; 32];
        
        let max_order = size.trailing_zeros() as usize;
        self.max_order = max_order;

        // The entire buffer starts as a single free block at max_order
        let block_ptr = NonNull::new_unchecked(start as *mut FreeBlock);
        std::ptr::write(block_ptr.as_ptr(), FreeBlock { next: None });
        self.free_lists[max_order] = Some(block_ptr);
    }

    /// Get the order (power of two exponent) required for a layout.
    fn get_order(&self, layout: Layout) -> usize {
        let req_size = std::cmp::max(layout.size(), layout.align());
        let req_size = std::cmp::max(req_size, 1 << self.min_order);
        req_size.next_power_of_two().trailing_zeros() as usize
    }
}

unsafe impl CustomAllocator for BuddyAllocator {
    unsafe fn alloc(&mut self, layout: Layout) -> Result<NonNull<u8>, AllocError> {
        if self.size == 0 {
            return Err(AllocError::OutOfMemory);
        }

        let order = self.get_order(layout);
        if order > self.max_order {
            return Err(AllocError::OutOfMemory);
        }

        // Find the smallest order block available
        let mut current_order = order;
        while current_order <= self.max_order {
            if self.free_lists[current_order].is_some() {
                break;
            }
            current_order += 1;
        }

        if current_order > self.max_order {
            return Err(AllocError::OutOfMemory);
        }

        // Remove block from free list
        let block_ptr = self.free_lists[current_order].unwrap();
        let block = block_ptr.as_ref();
        self.free_lists[current_order] = block.next;

        // Split block down to requested order
        while current_order > order {
            current_order -= 1;
            let block_size = 1 << current_order;
            let right_buddy_addr = (block_ptr.as_ptr() as usize) + block_size;
            let right_buddy_ptr = NonNull::new_unchecked(right_buddy_addr as *mut FreeBlock);

            // Write and insert right buddy
            std::ptr::write(right_buddy_ptr.as_ptr(), FreeBlock {
                next: self.free_lists[current_order],
            });
            self.free_lists[current_order] = Some(right_buddy_ptr);
        }

        Ok(NonNull::new_unchecked(block_ptr.as_ptr() as *mut u8))
    }

    unsafe fn dealloc(&mut self, ptr: NonNull<u8>, layout: Layout) {
        if self.size == 0 {
            return;
        }

        let order = self.get_order(layout);
        let mut current_ptr = ptr.cast::<FreeBlock>();
        let mut current_order = order;

        // Coalesce buddies up to max_order
        while current_order < self.max_order {
            let rel_addr = current_ptr.as_ptr() as usize - self.start;
            let buddy_rel_addr = rel_addr ^ (1 << current_order);
            let buddy_addr = self.start + buddy_rel_addr;

            // Search for buddy in current_order free list
            let mut prev: Option<NonNull<FreeBlock>> = None;
            let mut curr = self.free_lists[current_order];
            let mut buddy_found = false;

            while let Some(node_ptr) = curr {
                if node_ptr.as_ptr() as usize == buddy_addr {
                    buddy_found = true;
                    // Remove buddy from free list
                    if let Some(mut p) = prev {
                        p.as_mut().next = node_ptr.as_ref().next;
                    } else {
                        self.free_lists[current_order] = node_ptr.as_ref().next;
                    }
                    break;
                }
                prev = Some(node_ptr);
                curr = node_ptr.as_ref().next;
            }

            if buddy_found {
                // Merge buddy blocks
                let merged_rel_addr = rel_addr & !(1 << current_order);
                current_ptr = NonNull::new_unchecked((self.start + merged_rel_addr) as *mut FreeBlock);
                current_order += 1;
            } else {
                break;
            }
        }

        // Add final coalesced block back to free list
        std::ptr::write(current_ptr.as_ptr(), FreeBlock {
            next: self.free_lists[current_order],
        });
        self.free_lists[current_order] = Some(current_ptr);
    }

    fn is_initialized(&self) -> bool {
        self.size != 0
    }

    fn contains_addr(&self, addr: usize) -> bool {
        addr >= self.start && addr < self.start + self.size
    }
}

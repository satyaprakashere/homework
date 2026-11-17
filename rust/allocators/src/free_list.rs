use crate::{AllocError, CustomAllocator};
use std::alloc::Layout;
use std::ptr::NonNull;

/// A node in the free list. Stored inside the free memory blocks themselves.
struct FreeNode {
    size: usize,
    next: Option<NonNull<FreeNode>>,
}

/// Header prepended to every active allocation.
struct AllocHeader {
    size: usize,
    padding: usize,
}

/// A general-purpose Free List Allocator.
/// 
/// Manages free blocks of memory using a singly linked list.
/// Implements first-fit allocation and coalesces adjacent free blocks on deallocation.
pub struct FreeListAllocator {
    start: usize,
    size: usize,
    head: Option<NonNull<FreeNode>>,
}

impl FreeListAllocator {
    /// Creates a new, uninitialized `FreeListAllocator`.
    /// 
    /// Must be initialized with `init` before use.
    pub const fn new() -> Self {
        Self {
            start: 0,
            size: 0,
            head: None,
        }
    }

    /// Initializes the allocator with a raw memory region.
    /// 
    /// # Safety
    /// The caller must ensure the memory region `[start, start + size)` is valid and
    /// exclusive to this allocator.
    pub unsafe fn init(&mut self, start: usize, size: usize) {
        let align = std::mem::align_of::<FreeNode>();
        let aligned_start = crate::align_up(start, align);
        let padding = aligned_start - start;

        if size > padding {
            let aligned_size = size - padding;
            self.start = aligned_start;
            self.size = aligned_size;

            if aligned_size >= std::mem::size_of::<FreeNode>() {
                let node = FreeNode {
                    size: aligned_size,
                    next: None,
                };
                let ptr = NonNull::new_unchecked(aligned_start as *mut FreeNode);
                std::ptr::write(ptr.as_ptr(), node);
                self.head = Some(ptr);
            } else {
                self.head = None;
            }
        } else {
            self.start = 0;
            self.size = 0;
            self.head = None;
        }
    }
}

unsafe impl CustomAllocator for FreeListAllocator {
    unsafe fn alloc(&mut self, layout: Layout) -> Result<NonNull<u8>, AllocError> {
        let mut prev: Option<NonNull<FreeNode>> = None;
        let mut curr = self.head;
        let mut found: Option<(Option<NonNull<FreeNode>>, NonNull<FreeNode>, usize)> = None;

        let align = std::cmp::max(layout.align(), std::mem::align_of::<AllocHeader>());
        let header_size = std::mem::size_of::<AllocHeader>();

        // First-fit search
        while let Some(node_ptr) = curr {
            let node = node_ptr.as_ref();
            let node_addr = node_ptr.as_ptr() as usize;
            let node_size = node.size;

            // Compute payload address aligned to requirements
            let payload_addr = crate::align_up(node_addr + header_size, align);
            
            if let Some(required_size) = (payload_addr - node_addr).checked_add(layout.size()) {
                if required_size <= node_size {
                    found = Some((prev, node_ptr, payload_addr - node_addr));
                    break;
                }
            }

            prev = Some(node_ptr);
            curr = node.next;
        }

        let (prev_node, mut node_ptr, padding) = found.ok_or(AllocError::OutOfMemory)?;
        let node = node_ptr.as_mut();
        let node_addr = node_ptr.as_ptr() as usize;
        let node_size = node.size;

        let required_size = padding + layout.size();
        let remaining_size = node_size - required_size;

        // If leftover memory is large enough for a FreeNode, split the block.
        if remaining_size >= std::mem::size_of::<FreeNode>() {
            let new_node_addr = node_addr + required_size;
            let new_node = FreeNode {
                size: remaining_size,
                next: node.next,
            };
            let new_node_ptr = NonNull::new_unchecked(new_node_addr as *mut FreeNode);
            std::ptr::write(new_node_ptr.as_ptr(), new_node);

            if let Some(mut p) = prev_node {
                p.as_mut().next = Some(new_node_ptr);
            } else {
                self.head = Some(new_node_ptr);
            }
        } else {
            // Otherwise, allocate the entire block (no split)
            if let Some(mut p) = prev_node {
                p.as_mut().next = node.next;
            } else {
                self.head = node.next;
            }
        }

        // Write AllocHeader right before payload
        let payload_addr = node_addr + padding;
        let header_addr = payload_addr - header_size;
        let header = AllocHeader {
            size: required_size - padding, // actual payload size allocated
            padding,
        };
        std::ptr::write(header_addr as *mut AllocHeader, header);

        Ok(NonNull::new_unchecked(payload_addr as *mut u8))
    }

    unsafe fn dealloc(&mut self, ptr: NonNull<u8>, _layout: Layout) {
        let header_size = std::mem::size_of::<AllocHeader>();
        let payload_addr = ptr.as_ptr() as usize;
        
        let header_addr = payload_addr - header_size;
        let header = std::ptr::read(header_addr as *const AllocHeader);

        let block_start = payload_addr - header.padding;
        let block_size = header.size + header.padding;

        // Find insertion position to keep free list sorted by address
        let mut prev: Option<NonNull<FreeNode>> = None;
        let mut curr = self.head;

        while let Some(node_ptr) = curr {
            if (node_ptr.as_ptr() as usize) > block_start {
                break;
            }
            prev = Some(node_ptr);
            curr = node_ptr.as_ref().next;
        }

        let mut new_node_ptr = NonNull::new_unchecked(block_start as *mut FreeNode);
        let new_node = FreeNode {
            size: block_size,
            next: curr,
        };
        std::ptr::write(new_node_ptr.as_ptr(), new_node);

        if let Some(mut p) = prev {
            p.as_mut().next = Some(new_node_ptr);
        } else {
            self.head = Some(new_node_ptr);
        }

        // Coalesce: Merge with current next if they are contiguous
        if let Some(curr_ptr) = curr {
            let curr_addr = curr_ptr.as_ptr() as usize;
            if block_start + block_size == curr_addr {
                let curr_ref = curr_ptr.as_ref();
                new_node_ptr.as_mut().size += curr_ref.size;
                new_node_ptr.as_mut().next = curr_ref.next;
            }
        }

        // Coalesce: Merge with previous if they are contiguous
        if let Some(mut prev_ptr) = prev {
            let prev_ref = prev_ptr.as_ref();
            let prev_addr = prev_ptr.as_ptr() as usize;
            if prev_addr + prev_ref.size == block_start {
                prev_ptr.as_mut().size += new_node_ptr.as_ref().size;
                prev_ptr.as_mut().next = new_node_ptr.as_ref().next;
            }
        }
    }

    fn is_initialized(&self) -> bool {
        self.start != 0
    }

    fn contains_addr(&self, addr: usize) -> bool {
        addr >= self.start && addr < self.start + self.size
    }
}

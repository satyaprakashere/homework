use crate::{AllocError, CustomAllocator, free_list::FreeListAllocator};
use std::alloc::Layout;
use std::ptr::NonNull;

/// A node in a slab's free list. Stored inside the free slots themselves.
struct FreeSlot {
    next: Option<NonNull<FreeSlot>>,
}

/// A cache for a specific slot size.
struct SlabCache {
    slot_size: usize,
    free_list: Option<NonNull<FreeSlot>>,
}

impl SlabCache {
    const fn new(slot_size: usize) -> Self {
        Self {
            slot_size,
            free_list: None,
        }
    }
}

/// Header prepended to every allocation.
/// Padded to 32 bytes to ensure aligned payloads up to 32-byte alignment.
#[repr(align(32))]
struct SlabHeader {
    slot_size: usize,
    fallback_size: usize,
    fallback_padding: usize,
    _padding: usize,
}

/// A Slab Allocator.
/// 
/// Composed of multiple SlabCaches for small fixed sizes (64, 128, 256, 512 bytes)
/// and a fallback FreeListAllocator for large allocations and allocating slab pages.
pub struct SlabAllocator {
    fallback: FreeListAllocator,
    caches: [SlabCache; 4],
}

impl SlabAllocator {
    /// Creates a new, uninitialized `SlabAllocator`.
    /// 
    /// Must be initialized with `init` before use.
    pub const fn new() -> Self {
        Self {
            fallback: FreeListAllocator::new(),
            caches: [
                SlabCache::new(64),
                SlabCache::new(128),
                SlabCache::new(256),
                SlabCache::new(512),
            ],
        }
    }

    /// Initializes the allocator with a raw memory region.
    /// 
    /// # Safety
    /// The caller must ensure the memory region `[start, start + size)` is valid and
    /// exclusive to this allocator.
    pub unsafe fn init(&mut self, start: usize, size: usize) {
        self.fallback.init(start, size);
        for cache in &mut self.caches {
            cache.free_list = None;
        }
    }

    /// Maps a request size to the cache index and its slot size.
    fn select_cache(&self, size: usize) -> Option<(usize, usize)> {
        for (idx, cache) in self.caches.iter().enumerate() {
            if cache.slot_size >= size {
                return Some((idx, cache.slot_size));
            }
        }
        None
    }
}

unsafe impl CustomAllocator for SlabAllocator {
    unsafe fn alloc(&mut self, layout: Layout) -> Result<NonNull<u8>, AllocError> {
        let header_size = std::mem::size_of::<SlabHeader>(); // 32 bytes
        let total_size = layout.size() + header_size;

        // We can use the slab allocator if:
        // 1. The total size fits within our largest slab (512 bytes)
        // 2. The layout alignment is <= 32 (since the header is 32 bytes aligned and sized,
        //    payloads starting at slot_start + 32 are aligned up to 32 bytes).
        if layout.align() <= 32 && total_size <= 512 {
            if let Some((cache_idx, slot_size)) = self.select_cache(total_size) {
                // If cache is empty, allocate a new page (4096 bytes) from fallback
                if self.caches[cache_idx].free_list.is_none() {
                    let page_size = 4096;
                    let page_layout = Layout::from_size_align(page_size, 64)
                        .map_err(|_| AllocError::InvalidLayout)?;
                    
                    let page_ptr = self.fallback.alloc(page_layout)?;
                    
                    // Divide page into slots and link them
                    let num_slots = page_size / slot_size;
                    let mut prev_slot: Option<NonNull<FreeSlot>> = None;
                    
                    for i in (0..num_slots).rev() {
                        let slot_addr = page_ptr.as_ptr() as usize + i * slot_size;
                        let slot_ptr = NonNull::new_unchecked(slot_addr as *mut FreeSlot);
                        std::ptr::write(slot_ptr.as_ptr(), FreeSlot { next: prev_slot });
                        prev_slot = Some(slot_ptr);
                    }
                    self.caches[cache_idx].free_list = prev_slot;
                }

                // Take slot from free list
                let slot_ptr = self.caches[cache_idx].free_list.unwrap();
                self.caches[cache_idx].free_list = slot_ptr.as_ref().next;

                // Write header at start of slot
                let slot_addr = slot_ptr.as_ptr() as usize;
                let header = SlabHeader {
                    slot_size,
                    fallback_size: 0,
                    fallback_padding: 0,
                    _padding: 0,
                };
                std::ptr::write(slot_addr as *mut SlabHeader, header);

                let payload_addr = slot_addr + header_size;
                return Ok(NonNull::new_unchecked(payload_addr as *mut u8));
            }
        }

        // Fallback allocation for large size/alignment
        let align = std::cmp::max(layout.align(), 32);
        let fallback_size = layout.size() + header_size + layout.align();
        let fallback_layout = Layout::from_size_align(fallback_size, align)
            .map_err(|_| AllocError::InvalidLayout)?;

        let block_ptr = self.fallback.alloc(fallback_layout)?;
        let block_addr = block_ptr.as_ptr() as usize;

        // Align payload
        let payload_addr = crate::align_up(block_addr + header_size, layout.align());
        let header_addr = payload_addr - header_size;

        let header = SlabHeader {
            slot_size: 0,
            fallback_size,
            fallback_padding: payload_addr - block_addr,
            _padding: 0,
        };
        std::ptr::write(header_addr as *mut SlabHeader, header);

        Ok(NonNull::new_unchecked(payload_addr as *mut u8))
    }

    unsafe fn dealloc(&mut self, ptr: NonNull<u8>, layout: Layout) {
        let header_size = std::mem::size_of::<SlabHeader>();
        let payload_addr = ptr.as_ptr() as usize;
        let header_addr = payload_addr - header_size;
        
        let header = std::ptr::read(header_addr as *const SlabHeader);

        if header.slot_size > 0 {
            // Return to slab cache
            let slot_size = header.slot_size;
            let slot_ptr = NonNull::new_unchecked(header_addr as *mut FreeSlot);
            
            // Find cache index
            let cache_idx = match slot_size {
                64 => 0,
                128 => 1,
                256 => 2,
                512 => 3,
                _ => unreachable!("Invalid slot size in SlabHeader"),
            };

            std::ptr::write(slot_ptr.as_ptr(), FreeSlot {
                next: self.caches[cache_idx].free_list,
            });
            self.caches[cache_idx].free_list = Some(slot_ptr);
        } else {
            // Return to fallback
            let block_addr = payload_addr - header.fallback_padding;
            let block_ptr = NonNull::new_unchecked(block_addr as *mut u8);
            
            let align = std::cmp::max(layout.align(), 32);
            let fallback_layout = Layout::from_size_align(header.fallback_size, align)
                .expect("Failed to reconstruct fallback layout");

            self.fallback.dealloc(block_ptr, fallback_layout);
        }
    }

    fn is_initialized(&self) -> bool {
        self.fallback.is_initialized()
    }

    fn contains_addr(&self, addr: usize) -> bool {
        self.fallback.contains_addr(addr)
    }
}

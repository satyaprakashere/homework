use allocators::{
    AllocError, CustomAllocator,
    bump::BumpAllocator,
    stack::StackAllocator,
    free_list::FreeListAllocator,
    buddy::BuddyAllocator,
    slab::SlabAllocator,
};
use std::alloc::Layout;

// Align buffers properly using repr(align)
#[repr(align(1024))]
struct Buffer1024([u8; 1024]);

#[repr(align(16384))]
struct Buffer16384([u8; 16384]);

#[test]
fn test_bump_allocator() {
    let mut buffer = Buffer1024([0; 1024]);
    let mut bump = BumpAllocator::new();
    
    unsafe {
        bump.init(buffer.0.as_mut_ptr() as usize, buffer.0.len());
        
        // Basic allocation
        let layout1 = Layout::from_size_align(8, 8).unwrap();
        let ptr1 = bump.alloc(layout1).unwrap();
        assert_eq!(ptr1.as_ptr() as usize % 8, 0);
        
        let layout2 = Layout::from_size_align(15, 4).unwrap();
        let ptr2 = bump.alloc(layout2).unwrap();
        assert_eq!(ptr2.as_ptr() as usize % 4, 0);
        assert!(ptr2.as_ptr() as usize >= ptr1.as_ptr() as usize + 8);

        // Deallocate (no-op)
        bump.dealloc(ptr1, layout1);
        bump.dealloc(ptr2, layout2);
        
        // Assert we still have 2 "active" allocations because dealloc is a no-op
        assert_eq!(bump.allocations_count(), 2);

        // Allocate until out of memory
        let big_layout = Layout::from_size_align(1001, 8).unwrap();
        let res = bump.alloc(big_layout);
        assert_eq!(res.unwrap_err(), AllocError::OutOfMemory);

        // Reset
        bump.reset();
        assert_eq!(bump.allocations_count(), 0);

        // Can allocate again
        let ptr3 = bump.alloc(layout1).unwrap();
        assert_eq!(ptr3.as_ptr() as usize, buffer.0.as_ptr() as usize);
    }
}

#[test]
fn test_stack_allocator() {
    let mut buffer = Buffer1024([0; 1024]);
    let mut stack = StackAllocator::new();

    unsafe {
        stack.init(buffer.0.as_mut_ptr() as usize, buffer.0.len());

        let l1 = Layout::from_size_align(16, 8).unwrap();
        let l2 = Layout::from_size_align(32, 16).unwrap();
        let l3 = Layout::from_size_align(8, 4).unwrap();

        // LIFO allocations
        let p1 = stack.alloc(l1).unwrap();
        let p2 = stack.alloc(l2).unwrap();
        let p3 = stack.alloc(l3).unwrap();

        assert_eq!(stack.allocations_count(), 3);

        // Correct LIFO deallocations
        stack.dealloc(p3, l3);
        stack.dealloc(p2, l2);
        stack.dealloc(p1, l1);

        assert_eq!(stack.allocations_count(), 0);

        // Allocate again and reset
        let _ = stack.alloc(l1).unwrap();
        stack.reset();
        assert_eq!(stack.allocations_count(), 0);
    }
}

#[test]
#[should_panic(expected = "Stack allocator deallocation out of LIFO order!")]
fn test_stack_allocator_out_of_order_panic() {
    let mut buffer = Buffer1024([0; 1024]);
    let mut stack = StackAllocator::new();

    unsafe {
        stack.init(buffer.0.as_mut_ptr() as usize, buffer.0.len());

        let l1 = Layout::from_size_align(16, 8).unwrap();
        let l2 = Layout::from_size_align(32, 16).unwrap();

        let p1 = stack.alloc(l1).unwrap();
        let _p2 = stack.alloc(l2).unwrap();

        // Deallocating p1 before p2 violates LIFO
        stack.dealloc(p1, l1);
    }
}

#[test]
fn test_free_list_allocator() {
    let mut buffer = Buffer1024([0; 1024]);
    let mut free_list = FreeListAllocator::new();

    unsafe {
        free_list.init(buffer.0.as_mut_ptr() as usize, buffer.0.len());

        let l1 = Layout::from_size_align(32, 8).unwrap();
        let l2 = Layout::from_size_align(64, 16).unwrap();
        let l3 = Layout::from_size_align(32, 8).unwrap();

        // Allocations
        let p1 = free_list.alloc(l1).unwrap();
        let p2 = free_list.alloc(l2).unwrap();
        let p3 = free_list.alloc(l3).unwrap();

        // Deallocate middle block (creates a hole)
        free_list.dealloc(p2, l2);

        // Allocate in the hole
        let l4 = Layout::from_size_align(16, 8).unwrap();
        let p4 = free_list.alloc(l4).unwrap();
        assert!((p4.as_ptr() as usize) >= (p1.as_ptr() as usize) + 32);
        assert!((p4.as_ptr() as usize) < (p3.as_ptr() as usize));

        // Deallocate remainder and others to test coalescing
        free_list.dealloc(p4, l4);
        free_list.dealloc(p1, l1);
        free_list.dealloc(p3, l3);

        // Now, we should have a fully coalesced single block.
        // Let's verify by allocating a very large block (close to 1024).
        // Since AllocHeader is 16 bytes, we need to leave room for it.
        let large_layout = Layout::from_size_align(960, 8).unwrap();
        let p_large = free_list.alloc(large_layout).unwrap();
        
        // Cleanup
        free_list.dealloc(p_large, large_layout);
    }
}

#[test]
fn test_buddy_allocator() {
    let mut buffer = Buffer1024([0; 1024]);
    let mut buddy = BuddyAllocator::new();

    unsafe {
        // Base address of Buffer1024 is aligned to 1024 because of repr(align(1024))
        buddy.init(buffer.0.as_mut_ptr() as usize, buffer.0.len());

        let l1 = Layout::from_size_align(16, 8).unwrap();   // 16 bytes order 4
        let l2 = Layout::from_size_align(32, 16).unwrap();  // 32 bytes order 5
        let l3 = Layout::from_size_align(64, 32).unwrap();  // 64 bytes order 6

        let p1 = buddy.alloc(l1).unwrap();
        let p2 = buddy.alloc(l2).unwrap();
        let p3 = buddy.alloc(l3).unwrap();

        assert_eq!(p1.as_ptr() as usize % 16, 0);
        assert_eq!(p2.as_ptr() as usize % 32, 0);
        assert_eq!(p3.as_ptr() as usize % 64, 0);

        // Free buddy blocks and let them coalesce
        buddy.dealloc(p1, l1);
        buddy.dealloc(p2, l2);
        buddy.dealloc(p3, l3);

        // Reallocate the full size of buddy allocator (1024 bytes)
        let full_layout = Layout::from_size_align(1024, 1024).unwrap();
        let p_full = buddy.alloc(full_layout).unwrap();
        
        buddy.dealloc(p_full, full_layout);
    }
}

#[test]
fn test_slab_allocator() {
    let mut buffer = Buffer16384([0; 16384]);
    let mut slab = SlabAllocator::new();

    unsafe {
        slab.init(buffer.0.as_mut_ptr() as usize, buffer.0.len());

        // Allocate small items that should fit in Slab caches
        // Sizes: 16 (fits in slot 64), 60 (fits in slot 128 - wait, 60 + 32 header = 92, fits in slot 128)
        let l1 = Layout::from_size_align(16, 8).unwrap();   // slots size 64
        let l2 = Layout::from_size_align(64, 16).unwrap();  // 64 + 32 = 96 fits in slot 128
        let l3 = Layout::from_size_align(200, 32).unwrap(); // 200 + 32 = 232 fits in slot 256

        let p1 = slab.alloc(l1).unwrap();
        let p2 = slab.alloc(l2).unwrap();
        let p3 = slab.alloc(l3).unwrap();

        assert_eq!(p1.as_ptr() as usize % 8, 0);
        assert_eq!(p2.as_ptr() as usize % 16, 0);
        assert_eq!(p3.as_ptr() as usize % 32, 0);

        // Large allocation bypassing Slab (slot sizes only go up to 512, payload max 480)
        let l_large = Layout::from_size_align(1000, 8).unwrap();
        let p_large = slab.alloc(l_large).unwrap();

        // Deallocate all
        slab.dealloc(p1, l1);
        slab.dealloc(p2, l2);
        slab.dealloc(p3, l3);
        slab.dealloc(p_large, l_large);
    }
}

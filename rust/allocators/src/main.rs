use allocators::{Locked, bump::BumpAllocator};

// Register our custom BumpAllocator as the global allocator
#[global_allocator]
static GLOBAL: Locked<BumpAllocator> = Locked::new(BumpAllocator::new());

fn main() {
    // Allocate a static buffer to use as the heap for our allocator
    static mut HEAP_BUFFER: [u8; 1024 * 1024] = [0; 1024 * 1024];
    
    // Initialize the global allocator with our static heap buffer
    unsafe {
        GLOBAL.lock().init(HEAP_BUFFER.as_mut_ptr() as usize, HEAP_BUFFER.len());
        GLOBAL.register_bounds(HEAP_BUFFER.as_mut_ptr() as usize, HEAP_BUFFER.len());
    }

    println!("Allocating a vector using our custom global BumpAllocator...");
    
    // Create a vector and push elements to trigger allocations
    let mut v = Vec::new();
    for i in 1..=5 {
        v.push(i * 10);
    }
    
    println!("Vector contents: {:?}", v);
    
    // Check how many active allocations are currently tracked
    let alloc_count = GLOBAL.lock().allocations_count();
    println!("Active allocations in our BumpAllocator: {}", alloc_count);

    println!("All allocations completed successfully using our custom allocator!");
}

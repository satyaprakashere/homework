package main

import "core:fmt"
import "core:mem"

/*
    04_POOL: THE DYNAMIC POOL (DYNAMIC ARENA)
    
    A dynamic pool is an arena that can grow. Instead of one fixed buffer, 
    it allocates blocks as needed.
    
    Real-world use case: 
    When you need arena-like behavior (free all at once) but you don't know 
    the total size beforehand (e.g., loading a level with an unknown number 
    of assets).
*/

Entity :: struct {
	id: int,
	pos: [3]f32,
	active: bool,
}

main :: proc() {
	// 1. Initialize a dynamic pool. 
	// It will use the provided allocator to fetch new blocks.
	pool: mem.Dynamic_Pool
	mem.dynamic_pool_init(&pool, context.allocator)
	defer mem.dynamic_pool_destroy(&pool)

	// 2. Get the allocator.
	allocator := mem.dynamic_pool_allocator(&pool)

	fmt.println("--- Starting Dynamic Pool Example ---")

	// 3. Allocate many objects.
	// The pool will automatically allocate more memory blocks if needed.
	entities := make([]^Entity, 1000, allocator)
	
	for i in 0..<1000 {
		entities[i] = new(Entity, allocator)
		entities[i].id = i
	}

	fmt.println("Allocated 1000 entities in the dynamic pool.")
	fmt.printf("First entity ID: %d\n", entities[0].id)
	fmt.printf("Last entity ID: %d\n", entities[999].id)

	// 4. Free all at once.
	// This frees all the blocks allocated by the pool.
	mem.dynamic_pool_free_all(&pool)
	
	fmt.println("Pool cleared.")
	fmt.println("--- Dynamic Pool Example Finished ---\n")
}

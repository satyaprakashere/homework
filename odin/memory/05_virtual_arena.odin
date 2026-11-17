package main

import "core:fmt"
import "core:mem/virtual"

/*
    05_VIRTUAL_ARENA: THE VIRTUAL MEMORY ARENA
    
    Virtual arenas use operating system features to reserve a huge range of 
    address space without actually using physical memory (RAM) until 
    the memory is accessed.
    
    Real-world use case: 
    A large data structure or cache that might grow significantly, but you 
    don't want to over-commit memory or handle complex reallocations.
*/

main :: proc() {
	// 1. Initialize a virtual arena.
	// We'll reserve 1 Gigabyte of address space!
	arena: virtual.Arena
	err := virtual.arena_init_static(&arena, 1 * 1024 * 1024 * 1024)
	if err != nil {
		fmt.println("Failed to initialize virtual arena:", err)
		return
	}
	defer virtual.arena_destroy(&arena)

	allocator := virtual.arena_allocator(&arena)

	fmt.println("--- Starting Virtual Arena Example ---")
	fmt.println("Reserved 1GB of virtual address space.")

	// 2. Allocate some data. 
	// The OS will map physical pages only when we actually use them.
	data := make([]int, 1000, allocator)
	for i in 0..<1000 {
		data[i] = i * 10
	}

	fmt.printf("Allocated 1000 integers. Current used: %d bytes\n", arena.total_used)
	fmt.printf("Data[500] = %d\n", data[500])

	// 3. Clear the arena.
	// This "frees" the memory back to the arena (it can still keep the physical pages 
	// or release them depending on implementation/config).
	virtual.arena_free_all(&arena)
	
	fmt.println("Virtual arena cleared.")
	fmt.println("--- Virtual Arena Example Finished ---\n")
}

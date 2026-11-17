package main

import "core:fmt"
import "core:mem"
import "core:strings"

/*
	01_ARENA: THE ARENA ALLOCATOR
	
	Arenas (also known as region allocators or scratchpads) are one of the most 
	powerful memory management patterns in Odin.
	
	Real-world use case:
	Processing a large batch of temporary data (e.g., parsing a JSON file, 
	building a scene graph, or string manipulation) where you want to 
	allocate many things and then discard them all at once.
*/

main :: proc() {
	// 1. Create a backing buffer for the arena.
	// In a real-world app, this could be a large chunk of memory allocated once.
	backing_buffer := make([]byte, 1024 * 64) // 64KB
	defer delete(backing_buffer)

	// 2. Initialize the arena with the buffer.
	arena: mem.Arena
	mem.arena_init(&arena, backing_buffer)
	
	// 3. Create an allocator from the arena.
	arena_allocator := mem.arena_allocator(&arena)

	fmt.println("--- Starting Arena Example ---")

	// 4. Use the arena to perform some work.
	// We'll simulate a process that generates many temporary strings.
	process_data(arena_allocator)

	fmt.printf("Arena usage: %d/%d bytes\n", arena.offset, len(backing_buffer))
	
	// 5. Free everything in the arena at once!
	// This is O(1) and very fast. No need to track individual allocations.
	mem.arena_free_all(&arena)
	
	fmt.println("Arena cleared.")
	fmt.println("--- Arena Example Finished ---\n")
}

process_data :: proc(allocator: mem.Allocator) {
	// We pass the allocator to this function. Any allocations here will 
	// come from the arena.
	
	// Switch the context allocator so 'new' and dynamic arrays use it automatically.
	context.allocator = allocator

	// Simulate building a complex data structure with many strings.
	names := [dynamic]string{}
	defer delete(names) // This deletes the array header, but the strings are in the arena.

	for i in 0..<10 {
		name := strings.concatenate({"User_", fmt.tprintf("%d", i)})
		append(&names, name)
	}

	fmt.println("Generated names in arena:")
	for name in names {
		fmt.printf("  %s\n", name)
	}
}

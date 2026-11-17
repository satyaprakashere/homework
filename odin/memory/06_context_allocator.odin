package main

import "core:fmt"
import "core:mem"

/*
    06_CONTEXT_ALLOCATOR: THE ODIN WAY
    
    Odin provides a 'context' which is a hidden pointer passed to every function.
    One of its most important fields is 'context.allocator'.
    
    Real-world use case: 
    Writing library code that doesn't care WHERE memory comes from, it just 
    calls 'new' or 'make' and uses whatever allocator the caller provided.
*/

main :: proc() {
	fmt.println("--- Starting Context Example ---")

	// 1. By default, context.allocator is the general-purpose heap allocator.
	fmt.println("Using Default Allocator:")
	use_library_code()

	// 2. We can locally override the context.allocator for a scope.
	{
		backing := make([]byte, 1024)
		defer delete(backing)

		arena: mem.Arena
		mem.arena_init(&arena, backing)
		
		// Swap the context allocator!
		context.allocator = mem.arena_allocator(&arena)

		fmt.println("\nUsing Arena Allocator (via Context):")
		use_library_code()
		
		fmt.printf("Arena used: %d bytes\n", arena.offset)
		// No need to free 'p' or 'arr' from use_library_code individually!
	}

	fmt.println("\n--- Context Example Finished ---\n")
}

// This function represents a library or a deep subsystem.
// It doesn't take an allocator as a parameter; it just uses context.allocator.
use_library_code :: proc() {
	// 'new' uses context.allocator by default
	p := new(int)
	p^ = 42
	
	// 'make' for dynamic arrays also uses context.allocator
	arr := make([dynamic]f32, 5)
	
	fmt.printf("  Library allocated an int: %d\n", p^)
	fmt.printf("  Library allocated an array of length: %d\n", len(arr))
	
	// Note: In a real app, if using the heap, we should free these.
	// If using an arena, we don't have to!
}

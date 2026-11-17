package main

import "core:fmt"
import "core:mem"

/*
    03_STACK: THE STACK ALLOCATOR
    
    A stack allocator allows for fast, LIFO (Last-In First-Out) allocations. 
    It's similar to the system stack but more flexible.
    
    Real-world use case: 
    Local temporary buffers in a loop or a high-frequency function where 
    the size isn't known at compile-time but we know the lifetime is short.
*/

main :: proc() {
	// 1. Create a buffer on the system stack for our Stack Allocator.
	buffer: [1024]byte
	
	// 2. Initialize the stack allocator.
	s: mem.Stack
	mem.stack_init(&s, buffer[:])
	
	allocator := mem.stack_allocator(&s)

	fmt.println("--- Starting Stack Example ---")

	// 3. Perform LIFO allocations.
	for i in 0..<5 {
		// Allocate a slice of bytes
		size := (i + 1) * 64
		ptr, err := mem.alloc(size, mem.DEFAULT_ALIGNMENT, allocator)
		if err != nil {
			fmt.println("Allocation failed!", err)
			break
		}
		
		fmt.printf("Allocated %d bytes at %p\n", size, ptr)
		
		// In a stack allocator, you MUST free in reverse order (LIFO).
		// Or you can just free all at the end.
		// Here we just use it and don't free individually for the loop.
	}

	fmt.printf("Stack used: %d/%d bytes\n", s.curr_offset, len(buffer))

	// 4. Free everything.
	// In a stack allocator, we can "pop" or just clear everything.
	mem.stack_free_all(&s)
	
	fmt.println("--- Stack Example Finished ---\n")
}

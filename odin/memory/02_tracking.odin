package main

import "core:fmt"
import "core:mem"

/*
    02_TRACKING: THE TRACKING ALLOCATOR
    
    The Tracking Allocator is a wrapper that records every allocation and free.
    It's an essential tool for debugging and ensuring your application doesn't leak.
    
    Real-world use case: 
    Using it as your main allocator during development to catch leaks immediately.
*/

main :: proc() {
	// 1. Initialize the tracking allocator.
	// It needs a "backing" allocator to actually perform the memory operations.
	// We'll use the default heap allocator.
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)

	// 2. Set the tracking allocator as our current allocator.
	context.allocator = mem.tracking_allocator(&track)

	fmt.println("--- Starting Tracking Example ---")

	// 3. Perform some allocations.
	do_work()

	// 4. Check for leaks at the end.
	if len(track.allocation_map) > 0 {
		fmt.printf("!!! LEAK DETECTED: %d allocations still active !!!\n", len(track.allocation_map))
		for _, entry in track.allocation_map {
			fmt.printf("  - Leaked %v bytes at %v\n", entry.size, entry.location)
		}
	} else {
		fmt.println("No leaks detected. Great job!")
	}

	if len(track.bad_free_array) > 0 {
		fmt.printf("!!! %d BAD FREES DETECTED !!!\n", len(track.bad_free_array))
		for entry in track.bad_free_array {
			fmt.printf("  - Bad free at %v\n", entry.location)
		}
	}

	fmt.println("--- Tracking Example Finished ---\n")
}

do_work :: proc() {
	// A correct allocation and free
	p1 := new(int)
	free(p1)

	// A LEAK! We forgot to free this.
	p2 := new(f32)
	_ = p2 // Suppress unused warning

	// A DOUBLE FREE! (This would normally crash, but tracking can catch it)
	/*
	p3 := new(int)
	free(p3)
	free(p3)
	*/
}

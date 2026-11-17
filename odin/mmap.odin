package main

import "core:fmt"
import "core:mem"
import unix "core:sys/posix"

// Our Arena structure
Arena :: struct {
	data:   []byte,
	offset: int,
}

// Initialize the Arena by reserving memory via mmap
arena_init :: proc(a: ^Arena, size: int) {
	// We use MAP_ANONYMOUS because we don't want a file, just RAM.
	// We use MAP_PRIVATE so other processes can't see our memory.
	// PROT_READ | PROT_WRITE allows us to actually use the memory.

	// Note: unix.mmap returns a byte slice []byte
	data := unix.mmap(
		nil,
		uint(size),
		{.READ} 	| {.WRITE},
		{.PRIVATE} 	| {.ANONYMOUS},
		-1,
		0,
	)

	if data == unix.MAP_FAILED {
		fmt.panicf("Failed to mmap memory\n")
	}

	a.data = mem.slice_ptr(cast(^byte)data, size)
	a.offset = 0
}

// A simple bump-allocator function
arena_alloc :: proc(a: ^Arena, size: int, alignment: int) -> []byte {
	// Align the current offset
	aligned_offset := mem.align_forward_int(a.offset, alignment)

	if aligned_offset + size > len(a.data) {
		return nil // Out of memory!
	}

	res := a.data[aligned_offset:aligned_offset + size]
	a.offset = aligned_offset + size
	return res
}

arena_destroy :: proc(a: ^Arena) {
	unix.munmap(raw_data(a.data), uint(len(a.data)))
	a.data = nil
	a.offset = 0
}

main :: proc() {
	my_arena: Arena
	// Reserve 1 Gigabyte of virtual address space instantly
	GB :: 1024 * 1024 * 1024
	arena_init(&my_arena, 1 * GB)
	defer arena_destroy(&my_arena)

	// Allocate a small chunk from our 1GB pool
	// This is essentially just "offset += size" — extremely fast!
	buf := arena_alloc(&my_arena, 1024, 8)

	fmt.printf("Arena pointer: %p\n", &my_arena.data[0])
	fmt.printf("Buffer pointer: %p\n", &buf[0])
	fmt.printf("Current Arena Usage: %d bytes\n", my_arena.offset)
}

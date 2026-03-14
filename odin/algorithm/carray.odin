package algorithm

import "core:fmt"

CArray :: struct {
	data:     []u8,
	size:     u8,
	capacity: u8,
}

init :: proc(arr: ^CArray, capacity: u8, allocator: mem.Allocator = context.allocator) {
	arr.data = make([]u8, capacity, allocator)
	arr.size = 0
	arr.capacity = capacity
}

main :: proc() {
	arr: CArray
	init(&arr, 10)
	fmt.println(arr.data)
}

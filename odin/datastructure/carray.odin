package algorithm

import "core:fmt"
import "core:mem"

CArray :: struct($T: typeid) {
	data:     []T,
	size:     u16,
	capacity: u16,
}

init :: proc(arr: ^CArray($T), capacity: u16, allocator: mem.Allocator = context.allocator) {
	arr.data = make([]T, capacity, allocator)
	arr.size = 0
	arr.capacity = capacity
}

main :: proc() {
	arr: CArray(int)
	init(&arr, 10)
	fmt.println(arr.data)
}

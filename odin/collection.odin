package main

import "core:fmt"
//import "core:container/set"

main :: proc() {
	test_array()
	test_set()
	test_quueue()
}

test_array :: proc() {
	arr := make([dynamic]int)
	defer delete(arr)
	
	append(&arr, 100)
	fmt.println(arr)
}

test_set :: proc() {
// Initialize a set of strings
	my_set:= make(map[string]struct{})
	defer delete(my_set)

	// Add elements
	my_set["Odin"] = {}
	my_set["Go"] = {}
	my_set["Rust"] = {}

	// Check for existence
	if "Odin" in my_set {
		fmt.println("Odin is in the set!")
	}

	// Iterate
	for entry, _ in my_set {
		fmt.println(entry)
	}
}

test_quueue :: proc() {
	q: [dynamic]int
	defer delete(q)
	
	// Push (Enqueue)
	append(&q, 10)
	append(&q, 20)
	
	// Pop (Dequeue)
	if len(q) > 0 {
		val := q[0]
		ordered_remove(&q, 0) // Shifting elements!
		fmt.println("Popped:", val)
	}
}
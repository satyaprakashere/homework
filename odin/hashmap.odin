package main

import "core:fmt"
//import "core:container/set"

main :: proc() {
	test_array()
	test_set()
}

test_array :: proc() {
	arr := make([dynamic]int)
	defer delete(arr)
	
	append(&arr, 100)
	fmt.println(arr)
}

test_set :: proc() {
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

package main

import "core:fmt"

main :: proc() {
	test_array()
	test_set()
	test_map()
	test_queue()
	test_dynamic_array()
}

test_array :: proc() {
	arr := [?]int {1, 2, 4}

	arr[2] = 3
	fmt.println(arr)
}

test_set :: proc() {
	my_set := make(map[string]struct{})
	defer delete(my_set)

	// Add elements
	my_set["Odin"] = {}
	my_set["Go"] = {}
	my_set["Rust"] = {}

	// Check for existence
	if "Odin" in my_set {
		fmt.println("Odin is in the set!")
	}

	fmt.println(my_set)
}

test_map :: proc() {
	my_map := make(map[string]^string)
	defer delete(my_map)

	a := "C successor"
	b := "Lightweight Java"
	c := "Evil"

	// Add elements
	my_map["Odin"] = &a
	my_map["Go"] = &b
	my_map["Rust"] = &c

	fmt.println(my_map)
}

test_queue :: proc() {
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

test_dynamic_array :: proc() {
	darr := make_dynamic_array_len_cap([dynamic]int, 10, 20)
	defer delete_dynamic_array(darr)
	fmt.println(darr)
}

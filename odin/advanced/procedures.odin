package main

import "core:fmt"

get_coordinates :: proc() -> (x, y: int) {
	x, y = 10, 20
	return
}

main :: proc() {
	fmt.println("\n--- 1. Odin Procedures Demo ---")
	x, y := get_coordinates()
	fmt.printf("X: %v, Y: %v\n", x, y)
}

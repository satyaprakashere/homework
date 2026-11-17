//go:build ignore

package main

import (
	"arena"
	"slices"
)

func main() {
	data := unsafeUse()
	println(data[12345]) // Accessing invalid memory

	data = safeUse()
	println(data[12345]) // Accessing invalid memory
}

func unsafeUse() []int {
	a := arena.NewArena()
	defer a.Free()

	// Slice becomes invalid once Free is called
	slice := arena.MakeSlice[int](a, 200000, 300000)

	// Populate and use the slice normally
	for i := 0; i < len(slice); i++ {
		slice[i] = (i + 1) * 10
	}

	return slice
}

func safeUse() []int {
	a := arena.NewArena()
	defer a.Free()

	// Slice becomes invalid once Free is called
	slice := slices.Clone(arena.MakeSlice[int](a, 100000, 200000))

	// Populate and use the slice normally
	for i := 0; i < len(slice); i++ {
		slice[i] = (i + 1) * 10
	}

	return slice
}

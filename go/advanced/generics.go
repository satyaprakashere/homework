package main

import "fmt"

// Filter is a generic function that works for any slice type.
func Filter[T any](slice []T, predicate func(T) bool) []T {
	var result []T
	for _, v := range slice {
		if predicate(v) {
			result = append(result, v)
		}
	}
	return result
}

func RunGenericsDemo() {
	fmt.Println("\n--- 1. Generics Demo ---")
	nums := []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
	even := Filter(nums, func(n int) bool { return n%2 == 0 })
	fmt.Printf("Generics Filter (Even): %v\n", even)

	strings := []string{"apple", "banana", "cherry", "date"}
	longWords := Filter(strings, func(s string) bool { return len(s) > 5 })
	fmt.Printf("Generics Filter (Long words): %v\n", longWords)
}

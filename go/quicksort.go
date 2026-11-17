//go:build ignore

package main

import (
	"fmt"
	"math/rand" // Using the global generator
)

func main() {
	data := CreateRandomSlice(10000, 987654)
	fmt.Println("Sorted:", QuickSort(data))
}

func QuickSort(arr []int) []int {
	if len(arr) < 2 {
		return arr
	}

	left, right := 0, len(arr)-1
	pivot := arr[len(arr)/2] // Choosing the middle element as pivot

	for left <= right {
		for arr[left] < pivot {
			left++
		}
		for arr[right] > pivot {
			right--
		}
		if left <= right {
			arr[left], arr[right] = arr[right], arr[left]
			left++
			right--
		}
	}

	if right > 0 {
		QuickSort(arr[:right+1])
	}
	if left < len(arr) {
		QuickSort(arr[left:])
	}

	return arr
}

func CreateRandomSlice(n int, max int) []int {
	res := make([]int, n)
	for i := 0; i < n; i++ {
		res[i] = rand.Intn(max)
	}
	return res
}

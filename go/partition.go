//go:build ignore

package main

import "fmt"

// Helper recursive function to find partitions
// n: the remaining sum to partition,
// max: maximum number allowed in the partition (to maintain order),
// prefix: current partition being constructed,
// results: pointer to slice of partitions
func partitionHelper(n, max int, prefix []int, results *[][]int) {
	if n == 0 {
		// Found a valid partition, add a copy to results
		partition := make([]int, len(prefix))
		copy(partition, prefix)
		*results = append(*results, partition)
		return
	}

	for i := max; i >= 1; i-- {
		if i <= n {
			partitionHelper(n-i, i, append(prefix, i), results)
		}
	}
}

// partition generates all partitions of n
func partition(n int) [][]int {
	var results [][]int
	partitionHelper(n, n, []int{}, &results)
	return results
}

func main() {
	n := 10
	partitions := partition(n)
	fmt.Printf("Partitions of %d:\n", n)
	
	for _, p := range partitions {
		fmt.Println(p)
	}
	
	fmt.Printf("total Partitions of %d: %d\n", n, len(partitions))
	
}

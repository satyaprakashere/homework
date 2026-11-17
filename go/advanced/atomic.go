package main

import (
	"fmt"
	"sync"
	"sync/atomic"
)

func RunAtomicDemo() {
	fmt.Println("\n--- 6. Atomic Operations Demo ---")

	var counter atomic.Uint64
	var wg sync.WaitGroup

	const numGoroutines = 50
	const incrementsPerRoutine = 1000

	for range numGoroutines {
		wg.Go(func() {
			for range incrementsPerRoutine {
				// Atomically increment the counter without using a Mutex
				counter.Add(1)
			}
		})
	}

	wg.Wait()
	fmt.Printf("Total increments: %d (Expected: %d)\n", counter.Load(), numGoroutines*incrementsPerRoutine)
}

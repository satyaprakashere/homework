//go:build ignore

package main

import (
	"fmt"
	"sync"
)

type process struct {
	Id int
	Wg *sync.WaitGroup
}

func worker(in chan int, p process) {
	defer p.Wg.Done()
	x := <-in
	fmt.Printf("Worker %d: Hello from goroutine with Value : %d\n", p.Id, x)
}

func main() {
	var wg sync.WaitGroup
	input := make(chan int, 10)

	for i := 1; i <= 1000; i++ {
		wg.Add(1) // Increment wait group counter
		go worker(input, process{i, &wg})
		input <- (i + 40)
	}

	wg.Wait() // Wait for all goroutines to finish
	fmt.Println("All go-routines finished.")
}

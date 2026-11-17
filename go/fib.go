//go:build ignore

package main

import (
	"fmt"
	"math"
	"sync"
	"time"
	"math/rand/v2"
)

func main() {
	fmt.Println("hello world")
	fmt.Println(fibI(9876543))
	
	input := make(chan uint64, 20)
	res	  := make(chan uint64, 20)
	
	wg := sync.WaitGroup{}

	wg.Go(func() { fib_process(input, res)})
	wg.Go(func() { generate_input(input)  })
	
	for range(res) {
		fmt.Println(<-res)
	}
	
}

func generate_input(input chan uint64) {
	for {
		time.Sleep(100 * time.Millisecond)
		input <- rand.Uint64N(100000)
	}
}

func fib_process(n chan uint64, res chan uint64) {
	for range(n) {
		res <- fibI(<-n)
	}
}

func fibI(n uint64) uint64 {
	if n < 2 {
		return n
	}

	var a, b uint64 = 0, 1
	for i := 2; i <= int(n); i++ {
		a, b = b, a+b
	}
	return b
}

func fibII(n int) int {
	if n < 2 {
		return n
	}

	var a, b int = 0, 1
	for i := 2; i <= int(n); i++ {
		a, b = b, (a+b)%(math.MaxInt32)
	}
	return b
}

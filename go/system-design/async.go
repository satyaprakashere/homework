//go:build ignore

package main

import "fmt"

func main() {
	c := make(chan uint)
	go func() {
		c <- fibonacci(9876543210)
	}()

	fmt.Println("Hello There!@")

	fibx := <-c
	fmt.Println(fibx)
}

func fibonacci(n uint) uint {
	return fibonacciH(0, 1, n)
}

func fibonacciH(a, b, n uint) uint {
base:
	if n < 1 {
		return a
	}
	a, b, n = b, a+b, n-1
	goto base
}

func send_req() {
	fmt.Println("Sending request")
}

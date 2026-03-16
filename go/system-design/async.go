//go:build ignore

package main

import "fmt"

func main() {
	c := make(chan uint)
	go fib(c)

	fmt.Println("Hello There!@")
	send_req()
	fmt.Println(<-c)
}

func fib(c chan uint) {
	c <- fibonacci(987654321)
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
	fmt.Println("Sending request...")
}

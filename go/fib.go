package main

import "fmt"

func main() {
	fmt.Println("hello world")
	fmt.Println(fib(98))
}

func fib(n uint64) uint64 {
	return fibH(0, 1, n)
}

func fibH(a, b, n uint64) uint64 {
	if n == 0 {
		return a
	} else if n == 1 {
		return b
	} else {
		return fibH(b, a+b, n-1)
	}
}

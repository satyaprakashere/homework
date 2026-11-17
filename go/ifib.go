//go:build ignore

package main

import "fmt"

func main() {
	fmt.Println("hello world")
	fmt.Println(fibI(98765432))
}

func fib(n int64) int64 {
	return fibH(0, 1, n)
}

func fibH(a, b, n int64) int64 {
	if n == 0 {
		return a
	}
	return fibH(b, a+b, n-1)
}

func fibI(n int64) int64 {
	if n < 2 {
		return n
	}

	var a, b int64 = 0, 1
	for i := 2; i <= int(n); i++ {
		a, b = b, a+b
	}
	return b
}

//go:build ignore

package main

import "fmt"

func main() {
  fmt.Println("Hello world")
  fmt.Println(fib(98765432))
}

func fib(n uint64) uint64 {
  return fibH(0, 1, n)
}

func fibH(a, b, n uint64) uint64 {
Base:
  if n == 0 {
    return a
  }

  a, b, n = b, a+b, n-1
  goto Base
}

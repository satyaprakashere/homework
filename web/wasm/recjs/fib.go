//go:build ignore
package main

import "syscall/js"

func add(this js.Value, args []js.Value) interface{} {
  a := args[0].Int()
  b := args[1].Int()
  return a + b
}

func main() {
  js.Global().Set("addFromGo", js.FuncOf(add))
  select {} // keep Go runtime alive
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

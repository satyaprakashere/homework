//go:build ignore
package main

import "fmt"

func main() {
  fmt.Println(fib(fibState {1, 0, 10}))
}

type fibState struct {
  A int
  B int
  Position int
}

func fib(state fibState) int {
  switch state.Position {
  case 0:
    state.A, state.B = 1,2
    for ;state.A<100; {
      state.B, state.A = state.A, state.A + state.B
      // switching the context
      state.Position = 1;
      return state.A
    }
  case 1:
    state.Position = 2;
    return state.A-1
  case 2:
    state.Position = -1;
  }
  return -1
}
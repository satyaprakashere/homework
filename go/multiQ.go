//go:build ignore

package main

import "fmt"

type multiQ struct {
  list [][]int
}

func main() {
  fmt.Println("Hello There@")

  mQueue := multiQ{}
  fmt.Println(mQueue)
}

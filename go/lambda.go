//go:build ignore

package main

import "fmt"

func main() {
	chans := make([]chan int, 10)
	for i := range chans {
		chans[i] = make(chan int, 10)
	}

	f := func(x int) int { return x }

	g := f
	h := hello

	fmt.Println(g(5))
	fmt.Println(h)
}

func hello() {

}

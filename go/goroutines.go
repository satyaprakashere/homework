//go:build ignore
package main

import "fmt"

func main() {
	simplegc()
	gcwithbuffer()
}

func simplegc() {
	for i:= 0; i < 10; i++ {
		go func() {
			fmt.Println("Hello There! from ", i)
		} ()
	}
}

func gcwithbuffer() {
	for i:= 0; i < 100; i++ {
		go function(i)
	}
}

func function(i int) {
	fmt.Println("Hello There! from ", i)
}

func helper1(y chan int) {
	x := <- y
	fmt.Println(x)
}
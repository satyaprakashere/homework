package main

import "fmt"

func main() {
	fmt.Println("Hello World!")
	c := make(chan int, 1)
	c <- 123
	x := 6
	x = <- c
	fmt.Println(x)
}

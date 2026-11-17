//go:build ignore

package main

import "fmt"

type Int int

func (i Int) Add(b Int) Int {
	return i + b
}

func (i Int) Days() Int {
	return i
}

func main() {
	var a Int = 31
	result := a.Days() // result is MyInt(15)
	fmt.Println(result)
}

//go:build ignore

package main

import "fmt"

func main() {
	testString()
	testArray()
	testVector()
	testMap()
}

func testString() {
	str := "Hello"
	for _, c := range str {
		fmt.Printf("%c ", c)
	}
	fmt.Println()
}

func testArray() {
	arr := [2]int{1, 2}
	fmt.Println(arr)
}

func testVector() {
	vec := []int{1, 2, 3}
	vec = append(vec, 5)
	fmt.Println(vec)

	fmt.Println(vec[len(vec)-1])
}

func testMap() {
	tostr := make(map[int32]string, 10)
	tostr[3] = "Hello There! Map here"
	str, ok := tostr[3]
	fmt.Println(str)
	if ok {
		fmt.Println(str)
	} else {
		fmt.Println("Wrong key!")
	}
}

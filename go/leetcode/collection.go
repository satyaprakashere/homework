package main

import "fmt"

func main() {
    testString()
    testArray()
    testVector()
}

func testString() {
    str := "Hello"
    for _, c := range str {
        fmt.Printf("%c ", c);
    }
    fmt.Println()
}

func testArray() {
    arr := [2]int{1,2}
    fmt.Println(arr)
}

func testVector() {
    vec := []int{1, 2, 3}
    fmt.Println(vec)
}

//go:build ignore

package main

import (
	"fmt"
	"sync"
)

func main() {
	c1 := make(chan int)
	c2 := make(chan int)
	// defer close(c)

	wg := sync.WaitGroup{}
	wg.Add(2)

	wg.Go(func() {testArray(c2)})
	go testVector()
	
	wg.Go(func() {
		testMap()
	})
	
	go func() {
		defer wg.Done()
		testString()
		c1 <- 2
	}()
	x := <-c1
	fmt.Println(x)

	select {
	case msg := <-c1:
		fmt.Println("c1: ", msg)
	case msg := <-c2:
		fmt.Println("c2: ", msg)
	}

	wg.Done()
	
	wg.Wait()
}

func testString() {
	fmt.Println("testing string in go")
	str := "Hello"
	for _, c := range str {
		fmt.Printf("%c ", c)
	}
	fmt.Println()
}

func testArray(c chan int) {
	fmt.Println("testing array in go")
	arr := [2]int{1, 2}
	fmt.Println(arr)
	c <- 1
}

func testVector() {
	fmt.Println("testing dynamic array in go")
	vec := []int{1, 2, 3}
	vec = append(vec, 5)
	fmt.Println(vec)

	fmt.Println(vec[len(vec)-1])
}

func testMap() {
	fmt.Println("testing map in go")
	tostr := make(map[int32]string, 10)

	tostr[3] = "Hello There! Map here"
	str, ok := tostr[3]; if ok {
		fmt.Println(str)
	} else {
		fmt.Println("Wrong key!")
	}
}

//go:build ignore
package main

import _ "fmt"

func fib_array(k int) func(int) {
    _ := make([int]struct{}, 100)
    
    return func(n int) {}
}

func main() {
    
}
//go:build ignore
package main

import "fmt"

func main() {
    hello := func() {
        fmt.Print("hello ")
    }
    
    type funcH = func()
    
    var world funcH
    world = func () {
        fmt.Print(" world!")
    }

    hello()
    
    fmt.Print(world)
    world()
}
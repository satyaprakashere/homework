//go:build ignore
package main

import "fmt"

func main() {
    var done bool
    var msg string
    
    go func() {
        msg = "hello from memory!"
        done = true
    }()
    
    for !done {}

    fmt.Println(msg)
}
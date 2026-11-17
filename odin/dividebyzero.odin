package main

import "core:fmt"

main :: proc() {
    x := 0
    fmt.printf("987/0 is %v\n", 987/x)
}

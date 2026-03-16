package main

import "core:fmt"

fib_recursive :: proc(n: uint) -> uint {
    if n <= 1 do return n
    return fib_recursive(n - 1) + fib_recursive(n - 2)
}

fib_tail_recursive :: proc(a, b, n: uint) -> uint {
    if n < 1 do return a
    return fib_tail_recursive(b, a+b, n-1)
}

main :: proc() {
    n:uint = 10
    result := fib_recursive(n)
    fmt.printf("Fibonacci of %v is %v\n", n, result)

    n = 55
    result = fib_tail_recursive(0, 1, n)
    fmt.printf("Fibonacci of %v is %v\n", n, result)
}
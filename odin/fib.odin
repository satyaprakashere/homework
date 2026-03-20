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

fib_iterative :: proc(n: uint) -> uint {
    if n < 2 {
        return n
    }

    a, b: uint = 0, 1
    for i := 2; i <= int(n); i+=1 {
        a, b = b, a+b
    }

    return b
}

main :: proc() {
    n:uint = 5
    result := fib_recursive(n)
    fmt.printf("Fibonacci of %v is %v\n", n, result)

    n = 98765432
    result = fib_iterative(n)
    fmt.printf("Fibonacci of %v is %v\n", n, result)
}

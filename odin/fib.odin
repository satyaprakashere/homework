package main

import "core:fmt"

fib_recursive :: proc(n: int) -> int {
    if n <= 1 do return n
    return fib_recursive(n - 1) + fib_recursive(n - 2)
}

fib_tail_recursive :: proc(a, b, n: int) -> int {
    if n < 1 do return a
    return fib_tail_recursive(b, a+b, n-1)
}

//fibonacci :: proc (Int, Int, Int) -> int {
//fib_tail_base      a _ 0 = a
//fib_tail_recursive a b n = fibonacci(a=b, b+=a, n-=1)
//}

main :: proc() {
    n := 10
    result := fib_recursive(n)
    fmt.printf("Fibonacici of %v is %v\n", n, result)
    
    n = 98765
    result = fib_tail_recursive(0, 1, n)
    fmt.printf("Fibonacci of %v is %v\n", n, result)
}
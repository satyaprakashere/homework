package main

import "core:fmt"
import "core:time"

fib_recursive :: proc(n: uint) -> uint {
	if n <= 1 do return n
	return fib_recursive(n - 1) + fib_recursive(n - 2)
}

// same result with or without "preserve/none"
fib_tail_recursive :: proc "preserve/none" (a, b, n: uint) -> uint {
	if n == 0 do return a

	return #must_tail fib_tail_recursive(b, a + b, n - 1)
}

fib_iterative :: proc(n: uint) -> uint {
	if n < 2 {
		return n
	}

	a, b: uint = 0, 1
	for i := n-1; i != 0; i -= 1 {
		a, b = b, a + b
	}

	return b
}

main :: proc() {
	n: uint 	 = 12
	result 		:= fib_recursive(n)
	fmt.printf("Fibonacci of %v is %v\n", n, result)

	n = 98765432

	start 		:= time.tick_now()
	result 		 = fib_iterative(n)
	duration 	:= time.tick_since(start)

	fmt.printf("Fibonacci of %v is %v\n", n, result)
	fmt.printf("iterative operation took: %v\n", duration)

	start 		= time.tick_now()
	result 		= fib_tail_recursive(0, 1, n)
	duration 	= time.tick_since(start)

	fmt.printf("Fibonacci of %v is %v\n", n, result)
	fmt.printf("tail recursive operation took: %v\n", duration)
}


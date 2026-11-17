package main

import "core:fmt"
import "core:os"

main :: proc() {
	loop(function)
}

function :: proc() {
	fibn := fib_iterative(9876543)
	fmt.printf("Fibonacci of %v is %v\n", 9876543, fibn)
}

loop :: proc(f: proc()) {
	f()
	
	buf : [8]byte
	for {
		n, err := os.read(os.stdin, buf[:]); if err != nil {
			return
		}

		input := buf[0]
		
		if input != 'n' {
			f()
		} else {
			return
		}
	}
}

fib_iterative :: proc(n: uint) -> uint {
	if n < 2 {
		return n
	}
	
	a, b: uint = 0, 1
	for i := 2; i <= int(n); i += 1 {
		a, b = b, a + b
	}
	
	return b
}
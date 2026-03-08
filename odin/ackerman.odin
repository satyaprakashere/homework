package main

import "core:fmt"

// ackermann computes the Ackermann-Péter function
ackermann :: proc(m, n: u64) -> u64 {
	fmt.println("m: ", m, ", n: ", n)
	
	if m == 0 {
		return n + 1
	} else if m > 0 && n == 0 {
		return ackermann(m - 1, 1)
	} else {
		return ackermann(m - 1, ackermann(m, n - 1))
	}
}

ackermann_fast :: proc(m, n: u64) -> u64 {
	fmt.println("m: ", m, ", n: ", n)
	if m == 0 {
		return n + 1
	} else if m > 0 && n == 0 {
		return ackermann(m - 1, 1)
	} else {
		return ackermann(m - 1, ackermann(m, n - 1))
	}
}


main :: proc() {
	// Values grow extremely fast. 
	// A(4, 2) is already an astronomical number.
	m, n: u64 = 3, 4
	result := ackermann(m, n)
	
	fmt.printf("Ackermann(%v, %v) = %v\n", m, n, result)
}
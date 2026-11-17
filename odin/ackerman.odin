package main

import "core:fmt"

main :: proc() {
	// Values grow extremely fast.
	// A(4, 2) is already an astronomical number.
	m, n: u64 = 4, 1
	result := ackermann_goto(m, n)
	
	fmt.printf("Ackermann(%v, %v) = %v\n", m, n, result)
}

// ackermann computes the Ackermann-Péter function
ackermann :: proc(m, n: u64) -> u64 {
//	fmt.println("m: ", m, ", n: ", n)
	
	if m == 0 {
		return n + 1
	} else if m > 0 && n == 0 {
		return ackermann(m - 1, 1)
	} else {
		return ackermann(m - 1, ackermann(m, n - 1))
	}
}

ackermann_fast :: proc(m, n: u64) -> u64 {
//	fmt.println("m: ", m, ", n: ", n)
	if m == 0 {
		return n + 1
	} else if m > 0 && n == 0 {
		return ackermann(m - 1, 1)
	} else {
		return ackermann(m - 1, ackermann(m, n - 1))
	}
}

ackermann_goto :: proc "preserve/none" (m, n: u64) -> u64 {
//	fmt.println("m: ", m, ", n: ", n)
	if m == 0 do return n + 1
	if n == 0 do return #must_tail ackermann_goto(m - 1, 1)
	
	ns := ackermann_goto(m, n - 1)
	return #must_tail ackermann_goto(m - 1, ns)
}

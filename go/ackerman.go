//go:build ignore

package main

import "fmt"

func main() {
	fmt.Println(ackermannWithStack(4, 1))
}

func ackermann(m, n int) int {
	if m == 0 {
		return n + 1
	}
	if n == 0 {
		return ackermann(m-1, 1)
	}

	ns := ackermann(m, n-1)
	return ackermann(m-1, ns)
}

func ackermannWithGoto(m, n int) int {
base:
	if m == 0 {
		return n + 1
	}

	if n == 0 {
		m, n = m-1, 1
		goto base
	}

	// Call the goto version instead of the standard one
	ns := ackermannWithGoto(m, n-1)
	m, n = m-1, ns
	goto base // Tail-call optimization applied to the final return
}

func ackermannWithStack(m, n int) int {
	// Use a slice as an explicit stack for the 'm' parameters
	stack := make([]int, 0, 100000)
	stack = append(stack, m)

	for len(stack) > 0 {
		// Pop the top 'm' value from the stack
		m = stack[len(stack)-1]
		stack = stack[:len(stack)-1]

		if m == 0 {
			n = n + 1
		} else if n == 0 {
			stack = append(stack, m-1)
			n = 1
		} else {
			// Push the outer call's 'm-1', then the inner call's 'm'
			stack = append(stack, m-1)
			stack = append(stack, m)
			n = n - 1
		}
	}

	return n
}

func ackermannWithGoroutine(m, n int) int {
	if m == 0 {
		return n + 1
	}

	if n == 0 {
		return ackermann(m-1, 1)
	}

	ns := ackermann(m, n-1)

	return ackermann(m-1, ns)
}

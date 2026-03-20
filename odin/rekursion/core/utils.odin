package rekursion

import "core:fmt"
import "core:strings"

pop :: proc(stack: ^[dynamic]$T) -> T {
	if len(stack) == 0 {
		fmt.eprintln("Error: Stack underflow")
		return T{}
	}
	val := stack[len(stack) - 1]
	resize(stack, len(stack) - 1)
	return val
}

// Low-level stack helper for dynamic arrays to avoid ambiguity
vm_stack_push_dynamic :: proc(stack: ^[dynamic]$T, val: T) {
	n := len(stack)
	resize(stack, n + 1)
	stack[n] = val
}

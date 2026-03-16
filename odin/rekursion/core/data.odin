package rekursion

import "core:fmt"
import "core:strings"

Op_Code :: enum u8 {
	NOP,
	PUSH_CONST,
	POP,
	LOAD_VAR,
	STORE_VAR,
	DEF_VAR,
	CALL,
	RET,
	JUMP,
	JUMP_IF_FALSE,
	CLOSE_PROC,
}

Instruction :: struct {
	op:  Op_Code,
	arg: i32,
}

Bytecode :: struct {
	instructions: [dynamic]Instruction,
	constants:    [dynamic]Value,
}

Value :: union {
	Nil,
	bool,
	i32,
	i64,
	f32,
	f64,
	string,
	Symbol,
	Array,
	Builtin,
	^Pair,
	^Table,
	^Macro,
	^Procedure,
	^Continuation,
}

Nil :: struct {}

Symbol :: distinct string

Pair :: struct {
	first: Value,
	rest:  Value,
}

Procedure :: struct {
	params:      []Symbol,
	body:        Value,
	env:         ^Env,
	is_variadic: bool,
}

Builtin :: proc(vm: ^VM, args: []Value)

Macro :: struct {
	params:      []Symbol,
	body:        Value,
	env:         ^Env,
	is_variadic: bool,
}

Env :: struct {
	parent: ^Env,
	values: map[Symbol]Value,
}

Continuation :: struct {
	stack:  [dynamic]Value,
	frames: [dynamic]CallFrame,
	ip:     int,
}

Array :: struct {
	data: [dynamic]Value,
}

Table :: struct {
	parent: ^Table,
	data:   map[string]Value,
}

CallFrame :: struct {
	return_ip: int,
	env:       ^Env,
	is_reset:  bool,
	sp:        int,
}

VM :: struct {
	stack:  [dynamic]Value,
	frames: [dynamic]CallFrame,
	env:    ^Env,
	ip:     int,
}

// destroy_env :: proc(e: ^Env) {
// 	if e == nil {return}
// 	delete(e.values)
// 	free(e)
// }

is_false :: proc(v: Value) -> bool {
	#partial switch val in v {
	case bool:
		return !val
	case Nil:
		return true
	}

	return false
}

pop :: proc(stack: ^[dynamic]$T) -> T {
	if len(stack) == 0 {
		fmt.eprintln("Error: Stack underflow")
		return T{}
	}
	val := stack[len(stack) - 1]
	resize(stack, len(stack) - 1)
	return val
}

vm_stack_push :: proc(vm: ^VM, val: Value) {
	n := len(vm.stack)
	resize(&vm.stack, n + 1)
	vm.stack[n] = val
}

// Low-level stack helper for dynamic arrays to avoid ambiguity
vm_stack_push_dynamic :: proc(stack: ^[dynamic]$T, val: T) {
	n := len(stack)
	resize(stack, n + 1)
	stack[n] = val
}

value_to_string :: proc(v: Value) -> string {
	if s, ok := simple_value_to_string(v); ok {return s}
	return complex_value_to_string(v)
}

simple_value_to_string :: proc(v: Value) -> (string, bool) {
	#partial switch val in v {
	case Nil:
		return "nil", true
	case bool:
		return val ? "true" : "false", true
	case i64:
		return fmt.tprintf("%v", val), true
	case f64:
		return fmt.tprintf("%v", val), true
	case string:
		return fmt.tprintf("\"%v\"", val), true
	case Symbol:
		return string(val), true
	}
	return "||unknown simple value|", false
}

complex_value_to_string :: proc(v: Value) -> string {
	#partial switch val in v {
	case ^Pair:
		return pair_to_string(val)
	case ^Procedure:
		return "|procedure|"
	case Builtin:
		return "|builtin|"
	case ^Continuation:
		return "|continuation|"
	case Array:
		return array_to_string(val)
	case ^Table:
		return "|table|"
	case ^Macro:
		return "|macro|"
	}
	return "||unknown complex value||"
}

pair_to_string :: proc(p: ^Pair) -> string {
	sb: strings.Builder
	strings.builder_init(&sb, context.temp_allocator)
	strings.write_string(&sb, "(")
	curr := p
	for {
		strings.write_string(&sb, value_to_string(curr.first))
		next, done := format_pair_rest(&sb, curr)
		if done {break}
		curr = next
	}
	return strings.to_string(sb)
}

format_pair_rest :: proc(sb: ^strings.Builder, curr: ^Pair) -> (^Pair, bool) {
	#partial switch next in curr.rest {
	case ^Pair:
		strings.write_string(sb, " ")
		return next, false
	case Nil:
		strings.write_string(sb, ")")
		return nil, true
	case:
		strings.write_string(sb, " . ")
		strings.write_string(sb, value_to_string(curr.rest))
		strings.write_string(sb, ")")
		return nil, true
	}
}

array_to_string :: proc(v: Array) -> string {
	sb: strings.Builder
	strings.builder_init(&sb, context.temp_allocator)
	strings.write_string(&sb, "[")
	for val, i in v.data {
		strings.write_string(&sb, value_to_string(val))
		if i < len(v.data) - 1 {
			strings.write_string(&sb, " ")
		}
	}
	strings.write_string(&sb, "]")
	return strings.to_string(sb)
}

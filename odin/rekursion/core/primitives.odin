package rekursion

// import "base:builtin"
import "core:fmt"
import "core:strings"

Primitive_Record :: struct {
	name: string,
	handler: Builtin,
}

PRIMITIVES :: []Primitive_Record {
	{"add", builtin_add},
	{"sub", builtin_sub},
	{"mul", builtin_mul},
	{"div", builtin_div},
	{"rem", builtin_rem},
	{"mod", builtin_mod},
	{"cons", builtin_cons},
	{"first", builtin_first},
	{"rest", builtin_rest},
	{"set_first", builtin_set_first},
	{"set_rest", builtin_set_rest},
	{"print", builtin_print},
	{"display", builtin_display},
	{"newline", builtin_newline},
	{"array", builtin_array},
	{"length", builtin_length},
	{"append", builtin_append},
	{"reverse", builtin_reverse},
	{"list_ref", builtin_list_ref},
	{"member", builtin_member},
	{"memv", builtin_memv},
	{"memq", builtin_memq},
	{"assoc", builtin_assoc},
	{"assv", builtin_assv},
	{"assq", builtin_assq},
	{"is_null", builtin_is_null},
	{"is_pair", builtin_is_pair},
	{"is_number", builtin_is_number},
	{"is_symbol", builtin_is_symbol},
	{"is_boolean", builtin_is_boolean},
	{"is_string", builtin_is_string},
	{"is_procedure", builtin_is_procedure},
	{"number_to_string", builtin_number_to_string},
	{"symbol_to_string", builtin_symbol_to_string},
	{"string_append", builtin_string_append},
	{"eq", builtin_eq},
	{"equal", builtin_equal},
	{"numeq", builtin_numeq},
	{"less_than", builtin_less_than},
	{"greater_than", builtin_greater_than},
	{"cshift", builtin_shift},
	{"creset", builtin_reset},
	{"apply", builtin_apply},
	{"error", builtin_error},
}

setup_primitives :: proc(env: ^Env) {
	for p in PRIMITIVES {
		env_define(env, Symbol(p.name), p.handler)
	}

	// Constants
	env_define(env, Symbol("true"), true)
	env_define(env, Symbol("false"), false)
}

NumericOp :: enum {
	ADD,
	SUB,
	MUL,
	DIV,
}

fold_numeric_f64 :: proc(vm: ^VM, args: []Value, op: NumericOp) {
	res: f64 = 0
	start_idx: int = 1

	first := args[0]
	val0 := first.(f64) or_else f64(first.(i64))

	if len(args) == 1 && (op == .SUB || op == .DIV) {
		res = -val0 if op == .SUB else 1.0 / val0
		vm_stack_push(vm, res)
		return
	}

	res = val0
	for i in start_idx ..< len(args) {
		val := args[i].(f64) or_else f64(args[i].(i64))
		switch op {
		case .ADD: res += val
		case .SUB: res -= val
		case .MUL: res *= val
		case .DIV:
			if val == 0 {
				vm_error(vm, "Division by zero")
				return
			}
			res /= val
		}
	}
	vm_stack_push(vm, res)
}

fold_numeric_i64 :: proc(vm: ^VM, args: []Value, op: NumericOp) {
	res: i64 = 0
	start_idx: int = 1

	val0 := args[0].(i64)

	if len(args) == 1 && (op == .SUB || op == .DIV) {
		if op == .DIV && val0 == 0 {
			vm_error(vm, "Division by zero")
			return
		}
		res = -val0 if op == .SUB else 1 / val0
		vm_stack_push(vm, res)
		return
	}

	res = val0
	for i in start_idx ..< len(args) {
		val := args[i].(i64)
		switch op {
		case .ADD: res += val
		case .SUB: res -= val
		case .MUL: res *= val
		case .DIV:
			if val == 0 {
				vm_error(vm, "Division by zero")
				return
			}
			res /= val
		}
	}
	vm_stack_push(vm, res)
}

fold_numeric :: proc(vm: ^VM, args: []Value, op: NumericOp) {
	if len(args) == 0 {
		if op == .ADD do vm_stack_push(vm, i64(0))
		if op == .MUL do vm_stack_push(vm, i64(1))
		if op == .SUB || op == .DIV do vm_error(vm, "%v expects at least 1 argument", op)
		return
	}

	for a in args {
		if _, ok := a.(f64); ok {
			fold_numeric_f64(vm, args, op)
			return
		}
	}

	fold_numeric_i64(vm, args, op)
}

builtin_add :: proc(vm: ^VM, args: []Value) {
	fold_numeric(vm, args, .ADD)
}

builtin_sub :: proc(vm: ^VM, args: []Value) {
	fold_numeric(vm, args, .SUB)
}

builtin_mul :: proc(vm: ^VM, args: []Value) {
	fold_numeric(vm, args, .MUL)
}

builtin_div :: proc(vm: ^VM, args: []Value) {
	fold_numeric(vm, args, .DIV)
}



builtin_rem :: proc(vm: ^VM, args: []Value) {
	if len(args) != 2 {
		vm_error(vm, "rem expects 2 arguments, got %d", len(args))
		return
	}
	a, ok1 := args[0].(i64)
	b, ok2 := args[1].(i64)
	if ok1 && ok2 {
		if b == 0 {
			vm_error(vm, "Division by zero in rem")
			return
		}
		vm_stack_push(vm, Value(a % b))
	} else {
		vm_error(vm, "rem expects integers, got %v and %v", args[0], args[1])
	}
}

builtin_mod :: proc(vm: ^VM, args: []Value) {
	if len(args) != 2 {
		vm_error(vm, "mod expects 2 arguments, got %d", len(args))
		return
	}
	a, ok1 := args[0].(i64)
	b, ok2 := args[1].(i64)
	if ok1 && ok2 {
		if b == 0 {
			vm_error(vm, "Division by zero in mod")
			return
		}
		res := a % b
		if res < 0 && b > 0 {
			res += b
		} else if res > 0 && b < 0 {
			res += b
		}
		vm_stack_push(vm, Value(res))
	} else {
		vm_error(vm, "mod expects integers, got %v and %v", args[0], args[1])
	}
}

builtin_cons :: proc(vm: ^VM, args: []Value) {
	if len(args) != 2 {
		vm_error(vm, "cons expects 2 arguments, got %d", len(args))
		return
	}
	pair := new(Pair, context.allocator)
	pair.first = args[0]
	pair.rest = args[1]
	vm_stack_push(vm, Value(pair))
}

builtin_first :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {
		vm_error(vm, "first expects 1 argument, got %d", len(args))
		return
	}
	pair, ok := args[0].(^Pair)
	if !ok {
		vm_error(vm, "first expects a pair, got %v", args[0])
		return
	}
	vm_stack_push(vm, pair.first)
}

builtin_rest :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {
		vm_error(vm, "rest expects 1 argument, got %d", len(args))
		return
	}
	pair, ok := args[0].(^Pair)
	if !ok {
		vm_error(vm, "rest expects a pair, got %v", args[0])
		return
	}
	vm_stack_push(vm, pair.rest)
}

builtin_apply :: proc(vm: ^VM, args: []Value) {
	if len(args) < 2 {
		vm_error(vm, "apply expects at least 2 arguments, got %d", len(args))
		return
	}

	proc_val := args[0]
	list_val := args[1]

	call_args := make([dynamic]Value, context.temp_allocator)
	defer delete(call_args)
	curr := list_val
	for {
		p := curr.(^Pair) or_break
		append(&call_args, p.first)
		curr = p.rest
	}

	vm_exec_call_proc(vm, nil, proc_val, call_args[:], vm.ip)
}

builtin_set_first :: proc(vm: ^VM, args: []Value) {
	if len(args) != 2 {
		vm_error(vm, "set-first! expects 2 arguments, got %d", len(args))
		return
	}
	pair, ok := args[0].(^Pair)
	if !ok {
		vm_error(vm, "set-first! expects a pair, got %v", args[0])
		return
	}
	pair.first = args[1]
	vm_stack_push(vm, pair.first)
}

builtin_set_rest :: proc(vm: ^VM, args: []Value) {
	if len(args) != 2 {
		vm_error(vm, "set-rest! expects 2 arguments, got %d", len(args))
		return
	}
	pair, ok := args[0].(^Pair)
	if !ok {
		vm_error(vm, "set-rest! expects a pair, got %v", args[0])
		return
	}
	pair.rest = args[1]
	vm_stack_push(vm, pair.rest)
}

builtin_array :: proc(vm: ^VM, args: []Value) {
	if len(args) == 0 {
		vm_error(vm, "array expects at least 1 argument")
		return
	}

	head := new(Pair, context.allocator)
	head.first = args[0]

	curr := head
	for i in 1 ..< len(args) {
		next := new(Pair, context.allocator)
		next.first = args[i]
		curr.rest = next
		curr = next
	}
	curr.rest = Nil{}

	vm_stack_push(vm, Value(head))
}

builtin_print :: proc(vm: ^VM, args: []Value) {
	for arg in args {
		fmt.print(value_to_string(arg))
		fmt.print(" ")
	}
	fmt.println()
	vm_stack_push(vm, Value(Nil{}))
}


get_string_key :: proc(v: Value) -> (string, bool) {
	#partial switch k in v {
	case string:
		return k, true
	case Symbol:
		return string(k), true
	case i64:
		return fmt.aprintf("%d", k), true
	case f64:
		return fmt.aprintf("%f", k), true
	}
	return "", false
}

// Predicates
builtin_is_null :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {vm_stack_push(vm, bool(false)); return}
	_, ok := args[0].(Nil)
	vm_stack_push(vm, Value(ok))
}

builtin_is_pair :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {vm_stack_push(vm, bool(false)); return}
	_, ok := args[0].(^Pair)
	vm_stack_push(vm, Value(ok))
}

builtin_is_number :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {vm_stack_push(vm, bool(false)); return}
	_, ok1 := args[0].(i64)
	_, ok2 := args[0].(f64)
	vm_stack_push(vm, Value(ok1 || ok2))
}

builtin_is_symbol :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {vm_stack_push(vm, bool(false)); return}
	_, ok := args[0].(Symbol)
	vm_stack_push(vm, Value(ok))
}

builtin_is_boolean :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {vm_stack_push(vm, bool(false)); return}
	_, ok := args[0].(bool)
	vm_stack_push(vm, Value(ok))
}

builtin_is_string :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {vm_stack_push(vm, bool(false)); return}
	_, ok := args[0].(string)
	vm_stack_push(vm, Value(ok))
}

builtin_is_procedure :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {vm_stack_push(vm, bool(false)); return}
	#partial switch _ in args[0] {
	case ^Procedure, Builtin, ^Continuation:
		vm_stack_push(vm, bool(true))
		return
	}
	vm_stack_push(vm, bool(false))
}

// Converters
builtin_number_to_string :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {
		vm_error(vm, "number-to-string expects 1 argument, got %d", len(args))
		return
	}
	#partial switch n in args[0] {
	case i64:
		vm_stack_push(vm, Value(fmt.aprintf("%d", n, allocator = context.allocator)))
		return
	case f64:
		vm_stack_push(vm, Value(fmt.aprintf("%f", n, allocator = context.allocator)))
		return
	}
	vm_error(vm, "number-to-string expects a number, got %v", args[0])
}

builtin_symbol_to_string :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {
		vm_error(vm, "symbol-to-string expects 1 argument, got %d", len(args))
		return
	}
	if s, ok := args[0].(Symbol); ok {
		vm_stack_push(vm, Value(string(s)))
		return
	}
	vm_error(vm, "symbol-to-string expects a symbol, got %v", args[0])
}

builtin_string_append :: proc(vm: ^VM, args: []Value) {
	if len(args) == 0 {vm_stack_push(vm, Value(string(""))); return}
	sb: strings.Builder
	strings.builder_init(&sb, context.temp_allocator)
	defer strings.builder_destroy(&sb)
	for a in args {
		if s, ok := a.(string); ok {
			strings.write_string(&sb, s)
		} else {
			// value_to_string might allocate, but we'll use temp for its internal parts if we can
			// for now, we just write to builder
			strings.write_string(&sb, value_to_string(a, context.temp_allocator))
		}
	}
	vm_stack_push(vm, Value(strings.clone(strings.to_string(sb), context.allocator)))
}

// Equality
builtin_eq :: proc(vm: ^VM, args: []Value) {
	if len(args) != 2 {vm_stack_push(vm, bool(false)); return}
	a, b := args[0], args[1]

	res := false
	#partial switch va in a {
	case Nil:
		_, ok := b.(Nil); res = ok
	case bool:
		vb, ok := b.(bool); res = ok && va == vb
	case i64:
		vb, ok := b.(i64); res = ok && va == vb
	case f64:
		vb, ok := b.(f64); res = ok && va == vb
	case Symbol:
		vb, ok := b.(Symbol); res = ok && va == vb
	case string:
		vb, ok := b.(string); res = ok && va == vb
	case Builtin:
		res = false
	case ^Pair:
		vb, ok := b.(^Pair); res = ok && va == vb
	case ^Procedure:
		vb, ok := b.(^Procedure); res = ok && va == vb
	case ^Continuation:
		vb, ok := b.(^Continuation); res = ok && va == vb
	}
	vm_stack_push(vm, Value(res))
}

builtin_equal :: proc(vm: ^VM, args: []Value) {
	if len(args) != 2 {vm_stack_push(vm, bool(false)); return}
	vm_stack_push(vm, Value(value_equal(args[0], args[1])))
}

builtin_numeq :: proc(vm: ^VM, args: []Value) {
	if len(args) < 2 {vm_stack_push(vm, bool(true)); return}
	first, ok := args[0].(i64)
	if !ok {
		if f, fok := args[0].(f64); fok {
			first = i64(f)
		} else {
			vm_stack_push(vm, bool(false))
			return
		}
	}

	for i in 1 ..< len(args) {
		val, vok := args[i].(i64)
		if !vok {
			if f, fok := args[i].(f64); fok {
				val = i64(f)
			} else {
				vm_stack_push(vm, bool(false))
				return
			}
		}
		if first != val {vm_stack_push(vm, bool(false)); return}
	}
	vm_stack_push(vm, bool(true))
}

builtin_less_than :: proc(vm: ^VM, args: []Value) {
	if len(args) < 2 {vm_stack_push(vm, bool(true)); return}
	for i in 0 ..< len(args) - 1 {
		a, a_ok := args[i].(i64)
		if !a_ok {
			if f, fok := args[i].(f64); fok {
				a = i64(f)
			} else {
				vm_stack_push(vm, bool(false))
				return
			}
		}
		b, b_ok := args[i + 1].(i64)
		if !b_ok {
			if f, fok := args[i + 1].(f64); fok {
				b = i64(f)
			} else {
				vm_stack_push(vm, bool(false))
				return
			}
		}

		if a >= b {vm_stack_push(vm, bool(false)); return}
	}
	vm_stack_push(vm, bool(true))
}

builtin_greater_than :: proc(vm: ^VM, args: []Value) {
	if len(args) < 2 {vm_stack_push(vm, bool(true)); return}
	for i in 0 ..< len(args) - 1 {
		a, a_ok := args[i].(i64)
		if !a_ok {
			if f, fok := args[i].(f64); fok {
				a = i64(f)
			} else {
				vm_stack_push(vm, bool(false))
				return
			}
		}
		b, b_ok := args[i + 1].(i64)
		if !b_ok {
			if f, fok := args[i + 1].(f64); fok {
				b = i64(f)
			} else {
				vm_stack_push(vm, bool(false))
				return
			}
		}
		if a <= b {vm_stack_push(vm, bool(false)); return}
	}
	vm_stack_push(vm, bool(true))
}

// Delimited Continuations

builtin_reset :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {
		vm_error(vm, "reset expects 1 argument, got %d", len(args))
		return
	}
	proc_val := args[0]

	// Push a boundary frame that will eventually return to the caller of reset
	append(
		&vm.frames,
		CallFrame{return_ip = vm.ip, env = vm.env, sp = len(vm.stack), is_reset = true},
	)

	// Call the procedure, but make it return to a marker that will pop the boundary
	vm_exec_call_proc(vm, nil, proc_val, []Value{}, -2)
}

builtin_shift :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {
		vm_error(vm, "shift expects 1 argument, got %d", len(args))
		return
	}
	proc_val := args[0]

	// Find the nearest reset frame (boundary)
	reset_idx := -1
	for i := len(vm.frames) - 1; i >= 0; i -= 1 {
		if vm.frames[i].is_reset {
			reset_idx = i
			break
		}
	}

	if reset_idx == -1 {
		fmt.eprintf("Error: shift without reset\n")
		return
	}

	reset_frame := vm.frames[reset_idx]

	// Capture frames from reset_idx + 1 up to current
	captured_frames := make([dynamic]CallFrame, context.allocator)
	for i in reset_idx + 1 ..< len(vm.frames) {
		frame := vm.frames[i]
		frame.sp -= reset_frame.sp
		append(&captured_frames, frame)
	}

	// Capture stack from reset_frame.sp up to current
	captured_stack := make([dynamic]Value, context.allocator)
	for i in reset_frame.sp ..< len(vm.stack) {
		vm_stack_push_dynamic(&captured_stack, vm.stack[i])
	}

	// Create continuation
	cont := new(Continuation, context.allocator)
	cont.frames = captured_frames
	cont.stack = captured_stack
	cont.ip = vm.ip

	// Escaping the reset boundary: pop up to AND including the reset frame.
	resize(&vm.frames, reset_idx)
	resize(&vm.stack, reset_frame.sp)

	// Call the shift-lambda with the continuation.
	// It should return to wherever the reset was going to return.
	// Call the shift-lambda with the continuation.
	// It should return to wherever the reset was going to return.
	vm_exec_call_proc(vm, nil, proc_val, []Value{Value(cont)}, reset_frame.return_ip)
}

builtin_display :: proc(vm: ^VM, args: []Value) {
	for arg in args {
		if s, ok := arg.(string); ok {
			fmt.print(s)
		} else {
			fmt.print(value_to_string(arg, context.temp_allocator))
		}
	}
	vm_stack_push(vm, Nil{})
}

builtin_newline :: proc(vm: ^VM, args: []Value) {
	fmt.println()
	vm_stack_push(vm, Nil{})
}

builtin_error :: proc(vm: ^VM, args: []Value) {
	if len(args) > 0 {
		vm_error(vm, "%s", value_to_string(args[0], context.temp_allocator))
	} else {
		vm_error(vm, "Error")
	}
}

builtin_length :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {
		vm_error(vm, "length expects 1 argument")
		return
	}
	count: i64 = 0
	curr := args[0]
	for {
		p, ok := curr.(^Pair)
		if !ok do break
		count += 1
		curr = p.rest
	}
	vm_stack_push(vm, count)
}

builtin_append :: proc(vm: ^VM, args: []Value) {
	if len(args) == 0 {vm_stack_push(vm, Nil{}); return}
	if len(args) == 1 {vm_stack_push(vm, args[0]); return}

	// We'll build a new list for all but the last argument
	head: ^Pair = nil
	tail: ^Pair = nil

	for i in 0 ..< len(args) - 1 {
		curr := args[i]
		for {
			p, ok := curr.(^Pair)
			if !ok do break
			
			new_p := new(Pair)
			new_p.first = p.first
			if head == nil {
				head = new_p
			} else {
				tail.rest = new_p
			}
			tail = new_p
			curr = p.rest
		}
	}

	if head == nil {
		vm_stack_push(vm, args[len(args) - 1])
	} else {
		tail.rest = args[len(args) - 1]
		vm_stack_push(vm, head)
	}
}

builtin_reverse :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {vm_error(vm, "reverse expects 1 argument"); return}
	res: Value = Nil{}
	curr := args[0]
	for {
		p, ok := curr.(^Pair)
		if !ok do break
		new_p := new(Pair)
		new_p.first, new_p.rest = p.first, res
		res = new_p
		curr = p.rest
	}
	vm_stack_push(vm, res)
}

builtin_list_ref :: proc(vm: ^VM, args: []Value) {
	if len(args) != 2 {vm_error(vm, "list-ref expects 2 arguments"); return}
	idx := args[1].(i64) or_else 0
	curr := args[0]
	for i in 0 ..< idx {
		p, ok := curr.(^Pair)
		if !ok {vm_error(vm, "list-ref index out of range"); return}
		curr = p.rest
	}
	if p, ok := curr.(^Pair); ok {
		vm_stack_push(vm, p.first)
	} else {
		vm_error(vm, "list-ref index out of range")
	}
}

builtin_memq :: proc(vm: ^VM, args: []Value) { builtin_member_internal(vm, args, .EQ) }
builtin_memv :: proc(vm: ^VM, args: []Value) { builtin_member_internal(vm, args, .EQV) }
builtin_member :: proc(vm: ^VM, args: []Value) { builtin_member_internal(vm, args, .EQUAL) }

builtin_assq :: proc(vm: ^VM, args: []Value) { builtin_assoc_internal(vm, args, .EQ) }
builtin_assv :: proc(vm: ^VM, args: []Value) { builtin_assoc_internal(vm, args, .EQV) }
builtin_assoc :: proc(vm: ^VM, args: []Value) { builtin_assoc_internal(vm, args, .EQUAL) }

CompareMode :: enum { EQ, EQV, EQUAL }

builtin_member_internal :: proc(vm: ^VM, args: []Value, mode: CompareMode) {
	if len(args) != 2 {vm_error(vm, "member/memq/memv expects 2 arguments"); return}
	key, list := args[0], args[1]
	curr := list
	for {
		p, ok := curr.(^Pair)
		if !ok do break
		if compare_values(key, p.first, mode) {
			vm_stack_push(vm, curr)
			return
		}
		curr = p.rest
	}
	vm_stack_push(vm, bool(false))
}

builtin_assoc_internal :: proc(vm: ^VM, args: []Value, mode: CompareMode) {
	if len(args) != 2 {vm_error(vm, "assoc/assq/assv expects 2 arguments"); return}
	key, alist := args[0], args[1]
	curr := alist
	for {
		p, ok := curr.(^Pair)
		if !ok do break
		if entry, eok := p.first.(^Pair); eok {
			if compare_values(key, entry.first, mode) {
				vm_stack_push(vm, p.first)
				return
			}
		}
		curr = p.rest
	}
	vm_stack_push(vm, bool(false))
}

compare_values :: proc(a, b: Value, mode: CompareMode) -> bool {
	if mode == .EQUAL do return value_equal(a, b)
	// For EQ and EQV, in this interpreter they are mostly the same as value_equal for primitives
	// and pointer equality for pairs/procs.
	// Actually, value_equal already does pointer equality for pairs/procs.
	// Let's just use value_equal for now, but in a real R5RS it differs for numbers/chars.
	return value_equal(a, b)
}

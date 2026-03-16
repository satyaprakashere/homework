package rekursion

import "core:fmt"
import "core:strings"

setup_primitives :: proc(env: ^Env) {
	// basic cpu arithmetic
	env_define(env, Symbol("add"), builtin_add)
	env_define(env, Symbol("sub"), builtin_sub)
	env_define(env, Symbol("mul"), builtin_mul)
	env_define(env, Symbol("div"), builtin_div)

	// basic list operations
	env_define(env, Symbol("cons"), builtin_cons)
	env_define(env, Symbol("first"), builtin_first)
	env_define(env, Symbol("rest"), builtin_rest)

	// basic array operations
	env_define(env, Symbol("array"), builtin_array)
	env_define(env, Symbol("print"), builtin_print)
	env_define(env, Symbol("table"), builtin_make_table)
	env_define(env, Symbol("get"), builtin_table_get)
	env_define(env, Symbol("set"), builtin_table_set)
	env_define(env, Symbol("set-parent"), builtin_table_set_parent)
	env_define(env, Symbol("apply"), builtin_apply)

	// Constants
	env_define(env, Symbol("true"), true)
	env_define(env, Symbol("false"), false)

	// Predicates
	env_define(env, Symbol("is-null"), builtin_is_null)
	env_define(env, Symbol("is-pair"), builtin_is_pair)
	env_define(env, Symbol("is-number"), builtin_is_number)
	env_define(env, Symbol("is-symbol"), builtin_is_symbol)
	env_define(env, Symbol("is-boolean"), builtin_is_boolean)
	env_define(env, Symbol("is-string"), builtin_is_string)
	env_define(env, Symbol("is-procedure"), builtin_is_procedure)
	env_define(env, Symbol("is-table"), builtin_is_table)

	// Converters
	env_define(env, Symbol("number-to-string"), builtin_number_to_string)
	env_define(env, Symbol("symbol-to-string"), builtin_symbol_to_string)
	env_define(env, Symbol("string-append"), builtin_string_append)

	// Equality
	env_define(env, Symbol("eq"), builtin_eq)
	env_define(env, Symbol("eq?"), builtin_eq)
	env_define(env, Symbol("equal"), builtin_equal)
	env_define(env, Symbol("numeq"), builtin_numeq)
	env_define(env, Symbol("less_than"), builtin_less_than)
	env_define(env, Symbol("greater_than"), builtin_greater_than)

	// Continuations
	env_define(env, Symbol("cshift"), builtin_shift)
	env_define(env, Symbol("creset"), builtin_reset)
}

builtin_add :: proc(vm: ^VM, args: []Value) {
	res: i64 = 0
	for a in args {
		if val, ok := a.(i64); ok {
			res += val
		} else if fval, fok := a.(f64); fok {
			res += i64(fval)
		}
	}
	vm_stack_push(vm, Value(res))
}

builtin_sub :: proc(vm: ^VM, args: []Value) {
	if len(args) == 0 {vm_stack_push(vm, Value(i64(0))); return}
	res: i64 = 0
	if val, ok := args[0].(i64); ok {
		res = val
	} else if fval, fok := args[0].(f64); fok {
		res = i64(fval)
	}

	for i in 1 ..< len(args) {
		if val, ok := args[i].(i64); ok {
			res -= val
		} else if fval, fok := args[i].(f64); fok {
			res -= i64(fval)
		}
	}
	vm_stack_push(vm, Value(res))
}

builtin_mul :: proc(vm: ^VM, args: []Value) {
	res: i64 = 1
	for a in args {
		if val, ok := a.(i64); ok {
			res *= val
		} else if fval, fok := a.(f64); fok {
			res *= i64(fval)
		}
	}
	vm_stack_push(vm, Value(res))
}

builtin_div :: proc(vm: ^VM, args: []Value) {
	if len(args) == 0 {vm_stack_push(vm, Value(i64(1))); return}
	res: i64 = 1
	if val, ok := args[0].(i64); ok {
		res = val
	} else if fval, fok := args[0].(f64); fok {
		res = i64(fval)
	}
	for i in 1 ..< len(args) {
		denominator: i64 = 1
		if val, ok := args[i].(i64); ok {
			denominator = val
		} else if fval, fok := args[i].(f64); fok {
			denominator = i64(fval)
		}

		if denominator != 0 {
			res /= denominator
		}
	}
	vm_stack_push(vm, Value(res))
}

builtin_cons :: proc(vm: ^VM, args: []Value) {
	if len(args) != 2 {vm_stack_push(vm, Value(Nil{})); return}
	pair := new(Pair)
	pair.first = args[0]
	pair.rest = args[1]
	vm_stack_push(vm, Value(pair))
}

builtin_first :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {vm_stack_push(vm, Value(Nil{})); return}
	pair, ok := args[0].(^Pair)
	if !ok {vm_stack_push(vm, Value(Nil{})); return}
	vm_stack_push(vm, pair.first)
}

builtin_rest :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {vm_stack_push(vm, Value(Nil{})); return}
	pair, ok := args[0].(^Pair)
	if !ok {vm_stack_push(vm, Value(Nil{})); return}
	vm_stack_push(vm, pair.rest)
}

builtin_apply :: proc(vm: ^VM, args: []Value) {
	if len(args) < 2 {
		vm_stack_push(vm, Value(Nil{}))
		return
	}

	proc_val := args[0]
	list_val := args[1]

	call_args := make([dynamic]Value, context.temp_allocator)
	curr := list_val
	for {
		if p, ok := curr.(^Pair); ok {
			append(&call_args, p.first)
			curr = p.rest
		} else {
			break
		}
	}

	vm_exec_call_proc(vm, nil, proc_val, call_args[:], vm.ip)
}

builtin_array :: proc(vm: ^VM, args: []Value) {
	if len(args) == 0 {vm_stack_push(vm, Value(Nil{})); return}

	head := new(Pair)
	head.first = args[0]

	curr := head
	for i in 1 ..< len(args) {
		next := new(Pair)
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

builtin_make_table :: proc(vm: ^VM, args: []Value) {
	t := new(Table)
	t.data = make(map[string]Value)
	vm_stack_push(vm, Value(t))
}

builtin_table_get :: proc(vm: ^VM, args: []Value) {
	if len(args) != 2 {vm_stack_push(vm, Value(Nil{})); return}
	t, ok := args[0].(^Table)
	if !ok {vm_stack_push(vm, Value(Nil{})); return}

	key, key_ok := get_string_key(args[1])
	if !key_ok {vm_stack_push(vm, Value(Nil{})); return}

	curr := t
	for curr != nil {
		if val, found := curr.data[key]; found {
			vm_stack_push(vm, Value(val))
			return
		}
		curr = curr.parent
	}
	vm_stack_push(vm, Value(Nil{}))
}

builtin_table_set :: proc(vm: ^VM, args: []Value) {
	if len(args) != 3 {vm_stack_push(vm, Value(Nil{})); return}
	t, ok := args[0].(^Table)
	if !ok {vm_stack_push(vm, Value(Nil{})); return}

	key, key_ok := get_string_key(args[1])
	if !key_ok {vm_stack_push(vm, Value(Nil{})); return}

	val := args[2]
	t.data[key] = val
	vm_stack_push(vm, Value(val))
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

builtin_table_set_parent :: proc(vm: ^VM, args: []Value) {
	if len(args) != 2 {vm_stack_push(vm, Value(Nil{})); return}

	t, ok := args[0].(^Table)
	if !ok {vm_stack_push(vm, Value(Nil{})); return}

	parent, ok_p := args[1].(^Table)
	if !ok_p {
		if _, is_nil := args[1].(Nil); is_nil {
			t.parent = nil
			vm_stack_push(vm, Value(Nil{}))
			return
		}
		vm_stack_push(vm, Value(Nil{}))
		return
	}

	t.parent = parent
	vm_stack_push(vm, Value(parent))
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

builtin_is_table :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {vm_stack_push(vm, bool(false)); return}
	_, ok := args[0].(^Table)
	vm_stack_push(vm, Value(ok))
}

// Converters
builtin_number_to_string :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {vm_stack_push(vm, Nil{}); return}
	#partial switch n in args[0] {
	case i64:
		vm_stack_push(vm, Value(fmt.tprintf("%d", n)))
		return
	case f64:
		vm_stack_push(vm, Value(fmt.tprintf("%f", n)))
		return
	}
	vm_stack_push(vm, Value(Nil{}))
}

builtin_symbol_to_string :: proc(vm: ^VM, args: []Value) {
	if len(args) != 1 {vm_stack_push(vm, Value(Nil{})); return}
	if s, ok := args[0].(Symbol); ok {
		vm_stack_push(vm, Value(string(s)))
		return
	}
	vm_stack_push(vm, Value(Nil{}))
}

builtin_string_append :: proc(vm: ^VM, args: []Value) {
	if len(args) == 0 {vm_stack_push(vm, Value(string(""))); return}
	sb: strings.Builder
	strings.builder_init(&sb)
	defer strings.builder_destroy(&sb)
	for a in args {
		if s, ok := a.(string); ok {
			strings.write_string(&sb, s)
		} else {
			strings.write_string(&sb, value_to_string(a))
		}
	}
	vm_stack_push(vm, Value(strings.clone(strings.to_string(sb))))
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
	case ^Table:
		vb, ok := b.(^Table); res = ok && va == vb
	}
	vm_stack_push(vm, Value(res))
}

builtin_equal :: proc(vm: ^VM, args: []Value) {
	if len(args) != 2 {vm_stack_push(vm, bool(false)); return}
	vm_stack_push(vm, Value(rekursion_value_equal(vm, args[0], args[1])))
}

rekursion_value_equal :: proc(vm: ^VM, a, b: Value) -> bool {
	#partial switch va in a {
	case Nil:
		_, ok := b.(Nil); return ok
	case bool:
		vb, ok := b.(bool); return ok && va == vb
	case i64:
		vb, ok := b.(i64); return ok && va == vb
	case f64:
		vb, ok := b.(f64); return ok && va == vb
	case Symbol:
		vb, ok := b.(Symbol); return ok && va == vb
	case string:
		vb, ok := b.(string); return ok && va == vb
	case ^Pair:
		vb, ok := b.(^Pair)
		if !ok {return false}
		if va == vb {return true}
		return(
			rekursion_value_equal(vm, va.first, vb.first) &&
			rekursion_value_equal(vm, va.rest, vb.rest) \
		)
	case Array:
		vb, ok := b.(Array)
		if !ok || len(va.data) != len(vb.data) {return false}
		for i in 0 ..< len(va.data) {
			if !rekursion_value_equal(vm, va.data[i], vb.data[i]) {return false}
		}
		return true
	case ^Table, ^Procedure, ^Continuation, Builtin:
		a_b_args := []Value{a, b}
		old_sp := len(vm.stack)
		builtin_eq(vm, a_b_args)
		res_val := vm.stack[len(vm.stack) - 1]
		res := res_val.(bool)
		resize(&vm.stack, old_sp)
		return res
	}
	return false
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
	if len(args) != 1 {return}
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
	if len(args) != 1 {return}
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
	captured_frames := make([dynamic]CallFrame)
	for i in reset_idx + 1 ..< len(vm.frames) {
		frame := vm.frames[i]
		frame.sp -= reset_frame.sp
		append(&captured_frames, frame)
	}

	// Capture stack from reset_frame.sp up to current
	captured_stack := make([dynamic]Value)
	for i in reset_frame.sp ..< len(vm.stack) {
		vm_stack_push_dynamic(&captured_stack, vm.stack[i])
	}

	// Create continuation
	cont := new(Continuation)
	cont.frames = captured_frames
	cont.stack = captured_stack
	cont.ip = vm.ip

	// Escaping the reset boundary: pop up to AND including the reset frame.
	resize(&vm.frames, reset_idx)
	resize(&vm.stack, reset_frame.sp)

	// Call the shift-lambda with the continuation.
	// It should return to wherever the reset was going to return.
	vm_exec_call_proc(vm, nil, proc_val, []Value{Value(cont)}, reset_frame.return_ip)
}

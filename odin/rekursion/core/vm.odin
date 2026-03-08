package rekursion

import "core:fmt"
import "core:mem"
import "core:reflect"

STACK_LIMIT :: 108

Op_Code :: enum u8 {
	NOP,
	PUSH_CONST,
	PUSH_NIL,
	PUSH_TRUE,
	PUSH_FALSE,
	POP,
	LOAD_VAR,
	STORE_VAR,
	DEF_VAR,
	CALL,
	RET,
	JUMP,
	JUMP_IF_FALSE,
	ADD,
	SUB,
	MUL,
	DIV,
	EQ,
	LT,
	GT,
	RESET,
	SHIFT,
	FINISH_RESET,
	CLOSE_PROC,
	MAKE_ARRAY,
	CALL_CONS,
	CALL_APPEND,
	SHIFT_YIELD,
}

Instruction :: struct {
	op:  Op_Code,
	arg: i32,
}

Bytecode :: struct {
	instructions: [dynamic]Instruction,
	constants:    [dynamic]Value,
}

VM :: struct {
	stack:  [dynamic]Value,
	frames: [dynamic]CallFrame,
	env:    ^Env,
	ip:     int,
}

vm_init :: proc(env: ^Env) -> VM {
	return VM{stack = make([dynamic]Value), frames = make([dynamic]CallFrame), env = env, ip = 0}
}

vm_run :: proc(vm: ^VM, bytecode: ^Bytecode) -> Value {
	steps := 0
	for vm.ip < len(bytecode.instructions) {
		steps += 1
		if steps > 100 {
			fmt.println("VM reached max steps limit! Possible infinite loop. steps: %v", steps)
			if vm.ip < len(bytecode.instructions) {
				fmt.printf("debug: IP: %d, Op: %v\n", vm.ip, bytecode.instructions[vm.ip].op)
			}
			break
		}
		inst := bytecode.instructions[vm.ip]
		vm.ip += 1
		if val, quit := vm_exec_inst(vm, bytecode, inst); quit {
			return val
		}
	}
	if len(vm.stack) > 0 {return pop(&vm.stack)}
	return Nil{}
}

vm_exec_inst :: proc(vm: ^VM, bytecode: ^Bytecode, inst: Instruction) -> (Value, bool) {
	switch inst.op {
	// vm_exec_inst to vm_exec_stack
	// with same arguments
	// and one extra result-flag
	//
	// I should be able to reuse this callframe/stackframe, how?
	case .NOP, .PUSH_CONST, .PUSH_NIL, .PUSH_TRUE, .PUSH_FALSE, .POP, .MAKE_ARRAY:
		return vm_exec_stack(vm, bytecode, inst), false
	case .LOAD_VAR, .STORE_VAR, .DEF_VAR:
		return vm_exec_env(vm, bytecode, inst), false
	case .CALL_CONS:
		return vm_exec_call_cons(vm), false
	case .CALL_APPEND:
		return vm_exec_call_append(vm), false
	case .JUMP, .JUMP_IF_FALSE:
		return vm_exec_control(vm, inst), false
	case .RET:
		return vm_exec_ret(vm)
	case .ADD, .SUB, .MUL, .DIV, .EQ, .LT, .GT:
		return vm_exec_math(vm, inst), false
	case .CLOSE_PROC:
		return vm_exec_close_proc(vm), false
	case .CALL:
		return vm_exec_call(vm, bytecode, inst)
	case .RESET, .FINISH_RESET, .SHIFT, .SHIFT_YIELD:
		return vm_exec_shift_reset(vm, inst), false
	case:
		return Nil{}, false
	}
}

vm_exec_stack :: proc(vm: ^VM, bytecode: ^Bytecode, inst: Instruction) -> Value {
	#partial switch inst.op {
	case .NOP:
	case .PUSH_CONST:
		// TODO: add multiple type of constants
		append(&vm.stack, bytecode.constants[inst.arg])
	case .PUSH_NIL:
		append(&vm.stack, Nil{})
	case .PUSH_TRUE:
		v: Value = true
		append(&vm.stack, v)
	case .PUSH_FALSE:
		v: Value = false
		append(&vm.stack, v)
	case .POP:
		// TODO: why not return this value?
		pop(&vm.stack)
	case .MAKE_ARRAY:
		size := int(inst.arg)
		vec := make([dynamic]Value, size)
		// TODO: optimize in layer 2
		for i in 0 ..< size {
			vec[size - 1 - i] = pop(&vm.stack)
		}
		append(&vm.stack, Array{data = vec})
	}

	return Nil{}
}

vm_exec_env :: proc(vm: ^VM, bytecode: ^Bytecode, inst: Instruction) -> Value {
	symbol := bytecode.constants[inst.arg].(Symbol)
	#partial switch inst.op {
	case .LOAD_VAR:
		if val, ok := env_lookup(vm.env, symbol); ok {
			append(&vm.stack, val)
		} else {
			fmt.printf("Unbound variable: %s\n", symbol)
			append(&vm.stack, Nil{})
		}
	case .STORE_VAR:
		env_set(vm.env, symbol, pop(&vm.stack))
	case .DEF_VAR:
		val := pop(&vm.stack)
		if vm.env.parent == nil {
			// Global environment: copy out of the current arena
			// TODO: ??
			val = clone_value(val)
		}
		env_define(vm.env, symbol, val)
		append(&vm.stack, symbol)
	}
	return Nil{}
}

vm_exec_control :: proc(vm: ^VM, inst: Instruction) -> Value {
	#partial switch inst.op {
	case .JUMP:
		vm.ip = int(inst.arg)
	case .JUMP_IF_FALSE:
		if is_false(pop(&vm.stack)) {vm.ip = int(inst.arg)}
	case:
	}
	return Nil{}
}

vm_exec_ret :: proc(vm: ^VM) -> (Value, bool) {
	val := pop(&vm.stack)
	if len(vm.frames) == 0 {return val, true}
	frame := pop(&vm.frames)
	vm.env = frame.env
	if frame.is_reset {
		if frame.return_ip > 0 {
			vm.ip = frame.return_ip
		} else if frame.return_ip == -2 {
			if len(vm.frames) > 0 {
				caller_frame := pop(&vm.frames)
				vm.env = caller_frame.env
				vm.ip = caller_frame.return_ip
			}
		}
		append(&vm.stack, val)
		return Nil{}, false
	}
	append(&vm.stack, val)
	vm.ip = frame.return_ip
	return Nil{}, false
}

vm_exec_math :: proc(vm: ^VM, inst: Instruction) -> Value {
	b_val, a_val := pop(&vm.stack), pop(&vm.stack)
	if _, ok_b := b_val.(Nil); ok_b {fmt.println("ERROR: Math pop got Nil for b")}
	if _, ok_a := a_val.(Nil); ok_a {fmt.println("ERROR: Math pop got Nil for a")}
	b, a := b_val.(i64), a_val.(i64)
	#partial switch inst.op {
	case .ADD:
		append(&vm.stack, a + b)
	case .SUB:
		append(&vm.stack, a - b)
	case .MUL:
		append(&vm.stack, a * b)
	case .DIV:
		append(&vm.stack, a / b)
	case .EQ:
		append(&vm.stack, a == b)
	case .LT:
		append(&vm.stack, a < b)
	case .GT:
		append(&vm.stack, a > b)
	case:
	}
	return Nil{}
}

vm_exec_close_proc :: proc(vm: ^VM) -> Value {
	proc_val := pop(&vm.stack)
	#partial switch p in proc_val {
	case ^Procedure:
		new_proc := new(Procedure)
		new_proc^ = p^
		new_proc.env = vm.env
		append(&vm.stack, new_proc)
	case:
		fmt.println("Error: expected procedure for CLOSE_PROC")
	}
	return Nil{}
}

vm_exec_call :: proc(vm: ^VM, bytecode: ^Bytecode, inst: Instruction) -> (Value, bool) {
	proc_val := pop(&vm.stack)
	num_args := int(inst.arg)
	if len(vm.stack) < num_args {
		fmt.println(
			"Error: Stack underflow in CALL. Expected args:",
			num_args,
			"stack has:",
			len(vm.stack),
		)
		// fmt.printf("TRACE CALL DUMP: func type=%%T\n", proc_val)
		for i in 0 ..< len(vm.stack) {
			fmt.printf("  stack[%%d] type=%%T\n", i, vm.stack[i])
		}
		return Nil{}, true
	}
	args := make([]Value, num_args)
	defer destroy_values(args)
	for i in 0 ..< num_args {
		args[num_args - 1 - i] = pop(&vm.stack)
	}
	vm_exec_call_proc(vm, bytecode, proc_val, args)
	return Nil{}, false
}

vm_exec_call_proc :: proc(vm: ^VM, bytecode: ^Bytecode, proc_val: Value, args: []Value) {
	#partial switch p in proc_val {
	case Builtin:
		append(&vm.stack, p(args))
	case ^Procedure:
		append(
			&vm.frames,
			CallFrame{return_ip = vm.ip, env = vm.env, is_reset = false, sp = len(vm.stack)},
		)
		vm.env = vm_setup_proc_env(p, args)
		vm.ip = int(p.body.(i64))
	case ^Continuation:
		append(
			&vm.frames,
			CallFrame{return_ip = vm.ip, env = vm.env, is_reset = false, sp = len(vm.stack)},
		)
		append(
			&vm.frames,
			CallFrame{return_ip = -2, env = vm.env, is_reset = true, sp = len(vm.stack)},
		)
		for frame in p.frames {
			new_frame := frame
			new_frame.sp += len(vm.stack)
			append(&vm.frames, new_frame)
		}
		for v in p.stack {append(&vm.stack, v)}
		append(&vm.stack, args[0])
		vm.ip = p.ip
	case:
		fmt.println("Error: expected procedure")
		append(&vm.stack, Nil{})
	}
}

vm_setup_proc_env :: proc(p: ^Procedure, args: []Value) -> ^Env {
	new_env := new(Env)
	new_env.parent = p.env
	new_env.values = make(map[Symbol]Value)
	if p.is_variadic {
		req_args := len(p.params) - 1
		for i in 0 ..< req_args {new_env.values[p.params[i]] = args[i]}
		rest_args: Value = Nil{}
		for i := len(args) - 1; i >= req_args; i -= 1 {
			pair := new(Pair)
			pair.first, pair.rest = args[i], rest_args
			rest_args = pair
		}
		new_env.values[p.params[req_args]] = rest_args
	} else {
		for sym, i in p.params {
			if i < len(args) {new_env.values[sym] = args[i]}
		}
	}
	return new_env
}

vm_exec_shift_reset :: proc(vm: ^VM, inst: Instruction) -> Value {
	#partial switch inst.op {
	case .RESET:
		append(
			&vm.frames,
			CallFrame {
				return_ip = int(inst.arg),
				env = vm.env,
				is_reset = true,
				sp = len(vm.stack),
			},
		)
	case .FINISH_RESET:
		if len(vm.frames) > 0 {
			frame := pop(&vm.frames)
			if !frame.is_reset {
				fmt.println("Error: FINISH_RESET expected reset frame")
			} else {
				val := pop(&vm.stack)
				resize(&vm.stack, frame.sp)
				if frame.return_ip == -2 {
					// Continuation return!
					caller_frame := pop(&vm.frames)
					vm.env = caller_frame.env
					vm.ip = caller_frame.return_ip
				}
				append(&vm.stack, val)
			}
		}
	case .SHIFT:
		k_sym := pop(&vm.stack).(Symbol)
		jump_offset := inst.arg
		reset_idx := -1
		for i := len(vm.frames) - 1; i >= 0; i -= 1 {
			if vm.frames[i].is_reset {reset_idx = i; break}
		}
		if reset_idx == -1 {fmt.println("Error: shift without reset"); return Nil{}}
		reset_frame := vm.frames[reset_idx]
		captured_frames := make([dynamic]CallFrame)
		for i in reset_idx + 1 ..< len(vm.frames) {
			new_frame := vm.frames[i]
			new_frame.sp -= reset_frame.sp
			append(&captured_frames, new_frame)
		}
		captured_stack := make([dynamic]Value)
		for i in reset_frame.sp ..< len(vm.stack) {append(&captured_stack, vm.stack[i])}
		cont := new(Continuation)
		cont.stack, cont.frames, cont.ip =
			captured_stack, captured_frames, vm.ip + int(jump_offset)
		resize(&vm.frames, reset_idx + 1)
		resize(&vm.stack, reset_frame.sp)
		env_define(vm.env, k_sym, cont)
	case .SHIFT_YIELD:
		yield_val := pop(&vm.stack)

		reset_idx := -1
		for i := len(vm.frames) - 1; i >= 0; i -= 1 {
			if vm.frames[i].is_reset {reset_idx = i; break}
		}
		if reset_idx == -1 {fmt.println("Error: shift yield without reset block"); return Nil{}}
		reset_frame := vm.frames[reset_idx]

		resize(&vm.frames, reset_idx)

		// This shrinks the stack down to where the reset block originally started
		resize(&vm.stack, reset_frame.sp)

		vm.env = reset_frame.env
		if reset_frame.return_ip > 0 {
			vm.ip = reset_frame.return_ip
		} else if reset_frame.return_ip == -2 {
			if len(vm.frames) > 0 {
				caller_frame := pop(&vm.frames)
				vm.ip = caller_frame.return_ip
				vm.env = caller_frame.env
			}
		}
		append(&vm.stack, yield_val)
	case:
	}
	return Nil{}
}

is_false :: proc(v: Value) -> bool {
	#partial switch val in v {
	case bool:
		return !val
	case Nil:
		return true
	}
	return false
}

env_lookup :: proc(env: ^Env, sym: Symbol) -> (Value, bool) {
	curr := env
	for curr != nil {
		if val, ok := curr.values[sym]; ok {
			return val, true
		}
		curr = curr.parent
	}
	return Nil{}, false
}

env_define :: proc(env: ^Env, sym: Symbol, val: Value) {
	env.values[sym] = val
}

env_set :: proc(env: ^Env, sym: Symbol, val: Value) {
	curr := env
	for curr != nil {
		if _, ok := curr.values[sym]; ok {
			curr.values[sym] = val
			return
		}
		curr = curr.parent
	}
	// Error if not found
}

vm_exec_call_cons :: proc(vm: ^VM) -> Value {
	if len(vm.stack) < 2 {
		fmt.println("Error: Stack underflow in CALL_CONS")
		return Nil{}
	}
	b := pop(&vm.stack)
	a := pop(&vm.stack)
	pair := new(Pair)
	pair.first = a
	pair.rest = b
	append(&vm.stack, pair)
	return Nil{}
}

vm_exec_call_append :: proc(vm: ^VM) -> Value {
	if len(vm.stack) < 2 {return Nil{}}
	lst_to_append := pop(&vm.stack)
	lst_base := pop(&vm.stack)

	if _, ok := lst_to_append.(Nil); ok {
		append(&vm.stack, lst_base)
		return Nil{}
	}

	if _, ok := lst_base.(Nil); ok {
		append(&vm.stack, lst_to_append)
		return Nil{}
	}

	b_pair, b_ok := lst_to_append.(^Pair)
	if !b_ok {
		// Improper list append? Fallback to cons-like behavior
		pair := new(Pair)
		pair.first = lst_base
		pair.rest = lst_to_append
		append(&vm.stack, pair)
		return Nil{}
	}

	// We need to copy lst_base and make its tail point to lst_to_append to avoid mutating shared structures
	a_pair, a_ok := lst_base.(^Pair)
	if !a_ok {
		// appending atom to list
		pair := new(Pair)
		pair.first = lst_base
		pair.rest = b_pair
		append(&vm.stack, pair)
		return Nil{}
	}

	// Deep copy a_pair spine
	head := new(Pair)
	head.first = a_pair.first
	curr := head
	a_curr := a_pair.rest

	for {
		if _, is_nil := a_curr.(Nil); is_nil {
			curr.rest = b_pair
			break
		}
		if p, is_pair := a_curr.(^Pair); is_pair {
			next := new(Pair)
			next.first = p.first
			curr.rest = next
			curr = next
			a_curr = p.rest
		} else {
			// Improper list in A
			curr.rest = b_pair
			break
		}
	}

	append(&vm.stack, head)
	return Nil{}
}

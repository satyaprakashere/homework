package rekursion

import "core:fmt"
import "core:mem"

MAX_STEPS :: 1_000_000

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
	TAIL_CALL,
	PUSH_ENV,
	POP_ENV,
}

vm_init :: proc(env: ^Env, allocator: mem.Allocator = context.allocator) -> VM {
	return VM {
		stack = make([dynamic]Value, 0, 1024, allocator = allocator),
		frames = make([dynamic]CallFrame, 0, 1024, allocator = allocator),
		env = env,
		ip = 0,
	}
}

vm_run :: proc(vm: ^VM, bytecode: ^Bytecode) -> Value {
	// fmt.println("DEBUG: vm_run starting with", len(bytecode.instructions), "instructions")
	steps := 0
	for vm.ip >= 0 && vm.ip < len(bytecode.instructions) {
		steps += 1
		if steps > MAX_STEPS {
			fmt.eprintf(
				"VM reached max steps limit! Possible infinite loop. steps: %d, limit: %d\n",
				steps,
				MAX_STEPS,
			)
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
	case .NOP, .PUSH_CONST, .POP:
		return vm_exec_stack(vm, bytecode, inst), false
	case .LOAD_VAR, .STORE_VAR, .DEF_VAR, .PUSH_ENV, .POP_ENV:
		return vm_exec_env(vm, bytecode, inst), false
	case .JUMP, .JUMP_IF_FALSE:
		return vm_exec_control(vm, inst), false
	case .RET:
		return vm_exec_ret(vm)
	case .CLOSE_PROC:
		return vm_exec_close_proc(vm), false
	case .CALL, .TAIL_CALL:
		return vm_exec_call(vm, bytecode, inst)
	case:
		return Nil{}, false
	}
}

vm_exec_stack :: proc(vm: ^VM, bytecode: ^Bytecode, inst: Instruction) -> Value {
	#partial switch inst.op {
	case .NOP:
	case .PUSH_CONST:
		vm_stack_push(vm, bytecode.constants[inst.arg])
	case .POP:
		pop(&vm.stack)
	}

	return Nil{}
}

vm_exec_env :: proc(vm: ^VM, bytecode: ^Bytecode, inst: Instruction) -> Value {
	#partial switch inst.op {
	case .LOAD_VAR:
		symbol := bytecode.constants[inst.arg].(Symbol)
		if val, ok := env_lookup(vm.env, symbol); ok {
			vm_stack_push(vm, val)
		} else {
			fmt.eprintf("Unbound variable: %s\n", symbol)
			vm_stack_push(vm, Nil{})
		}
	case .STORE_VAR:
		symbol := bytecode.constants[inst.arg].(Symbol)
		env_set(vm.env, symbol, pop(&vm.stack))
	case .DEF_VAR:
		symbol := bytecode.constants[inst.arg].(Symbol)
		val := pop(&vm.stack)
		if vm.env.parent == nil {
			// Global environment: copy out of the current arena
			// TODO: ??
			val = clone_value(val)
		}
		env_define(vm.env, symbol, val)
		vm_stack_push(vm, symbol)
	case .PUSH_ENV:
		new_env := new(Env)
		new_env.parent = vm.env
		new_env.values = make(map[Symbol]Value, 8)
		vm.env = new_env
	case .POP_ENV:
		if vm.env.parent != nil {
			vm.env = vm.env.parent
		}
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
	vm_stack_push(vm, val)

	if frame.return_ip == -2 {
		if len(vm.frames) == 0 {return val, true}
		return vm_exec_ret(vm)
	}

	vm.ip = frame.return_ip
	return Nil{}, false
}


vm_exec_close_proc :: proc(vm: ^VM) -> Value {
	proc_val := pop(&vm.stack)
	#partial switch p in proc_val {
	case ^Procedure:
		new_proc := new(Procedure)
		new_proc^ = p^
		new_proc.env = vm.env
		vm_stack_push(vm, new_proc)
	case:
		fmt.println("Error: expected procedure for CLOSE_PROC")
	}
	return Nil{}
}

vm_exec_call :: proc(vm: ^VM, bytecode: ^Bytecode, inst: Instruction) -> (Value, bool) {
	// check stack underflow
	// this should not happen, so it should panic instead of returning Nil{}
	// TODO: panic instead of returning Nil{}
	// TODO: logs should be in a different layer of code, it should clutter the main code
	num_args := int(inst.arg)
	assert(len(vm.stack) >= num_args)
	// if len(vm.stack) < num_args {
	// 	log_stack_underflow(vm, num_args)
	// 	return Nil{}, true
	// }

	args := make([]Value, num_args, context.temp_allocator)

	if inst.op == .TAIL_CALL {
		if len(vm.frames) == 0 {
			fmt.eprintf("Error: 'recur' outside of a function\n")
			return Nil{}, true
		}
		procedure := vm.frames[len(vm.frames) - 1].procedure
		for i in 0 ..< num_args {
			args[num_args - 1 - i] = pop(&vm.stack)
		}
		// Tail call optimization: reuse the current frame's return address
		last_frame := pop(&vm.frames)
		vm.env = last_frame.env // Restore parent environment BEFORE the new call
		vm_exec_call_proc(vm, bytecode, procedure, args, last_frame.return_ip)
		return Nil{}, false
	}

	// Normal CALL
	procedure := pop(&vm.stack)
	for i in 0 ..< num_args {
		args[num_args - 1 - i] = pop(&vm.stack)
	}

	if len(vm.frames) > 0 {
		current_proc := vm.frames[len(vm.frames) - 1].procedure
		if p, ok := procedure.(^Procedure); ok && p == current_proc {
			fmt.eprintf("Error: Recursion requires 'recur' keyword\n")
			vm_stack_push(vm, Nil{})
			return Nil{}, true
		}
	}

	vm_exec_call_proc(vm, bytecode, procedure, args, vm.ip)
	return Nil{}, false
}

vm_exec_call_proc :: proc(
	vm: ^VM,
	bytecode: ^Bytecode,
	proc_val: Value,
	args: []Value,
	return_ip: int,
) {
	#partial switch p in proc_val {
	case Builtin:
		p(vm, args)
	case ^Procedure:
		append(
			&vm.frames,
			CallFrame{return_ip = return_ip, env = vm.env, sp = len(vm.stack), procedure = p},
		)
		vm.env = vm_setup_proc_env(p, args)
		vm.ip = int(p.body.(i64))
	case ^Continuation:
		// A continuation call is also delimited
		append(&vm.frames, CallFrame{return_ip = return_ip, env = vm.env, sp = len(vm.stack)})
		append(
			&vm.frames,
			CallFrame{return_ip = -2, env = vm.env, sp = len(vm.stack), is_reset = true},
		)
		for frame in p.frames {
			new_frame := frame
			new_frame.sp += len(vm.stack)
			append(&vm.frames, new_frame)
		}
		for v in p.stack {vm_stack_push(vm, v)}
		vm_stack_push(vm, args[0])
		vm.ip = p.ip
	case:
		fmt.println("Error: expected procedure")
		vm_stack_push(vm, Nil{})
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
			if i < len(args) {
				new_env.values[sym] = args[i]
			}
		}
	}
	return new_env
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
	fmt.eprintf("Unbound variable: %s\n", sym)
}

log_stack_underflow :: proc(vm: ^VM, num_args: int) {
	fmt.eprintln(
		"Error: Stack underflow in CALL. Expected args:",
		num_args,
		"stack has:",
		len(vm.stack),
	)
	// fmt.printf("TRACE CALL DUMP: func type=%T\n", procedure)
	for i in 0 ..< len(vm.stack) {
		fmt.eprintf("  stack[%d] type=%T\n", i, vm.stack[i])
	}
}

package rekursion

import "core:fmt"

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
		if steps > 1000 {
			fmt.println("VM reached max steps limit! Possible infinite loop.")
			if vm.ip < len(bytecode.instructions) {
<<<<<<< HEAD
				fmt.printf("IP: %d, Op: %v\n", vm.ip, bytecode.instructions[vm.ip].op)
			}
			break
		}
		// fmt.printf("Call Stack: %v\n", vm.stack[:])

		inst := bytecode.instructions[vm.ip]
		vm.ip += 1

=======
				fmt.printf("debug: IP: %d, Op: %v\n", vm.ip, bytecode.instructions[vm.ip].op)
			}
			break
		}
		fmt.printf("info: Call Stack: %v\n", vm.stack[:])

		inst := bytecode.instructions[vm.ip]
		vm.ip += 1
		fmt.printf("info: IP: %d, Op: %v\n\n", vm.ip, inst.op)
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)
		switch inst.op {
		case .NOP:
		// do nothing
		case .PUSH_CONST:
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
			pop(&vm.stack)
		case .LOAD_VAR:
			symbol := bytecode.constants[inst.arg].(Symbol)
			val, ok := env_lookup(vm.env, symbol)
			if ok {
				append(&vm.stack, val)
			} else {
				fmt.printf("Unbound variable: %s\n", symbol)
				append(&vm.stack, Nil{})
			}
		case .STORE_VAR:
			symbol := bytecode.constants[inst.arg].(Symbol)
			val := pop(&vm.stack)
			env_set(vm.env, symbol, val)
		case .DEF_VAR:
			symbol := bytecode.constants[inst.arg].(Symbol)
			val := pop(&vm.stack)
			env_define(vm.env, symbol, val)
			append(&vm.stack, symbol)

		case .CLOSE_PROC:
			// Pop Procedure prototype, create closure by attaching env
			proc_val := pop(&vm.stack)
			#partial switch p in proc_val {
			case ^Procedure:
				new_proc := new(Procedure)
				new_proc^ = p^ // Copy
				new_proc.env = vm.env // Capture current env
				append(&vm.stack, new_proc)
			case:
				fmt.println("Error: expected procedure for CLOSE_PROC")
			}
		case .MAKE_ARRAY:
			size := int(inst.arg)
			vec := make([dynamic]Value, size)
			for i in 0 ..< size {
				// Stack has elements in order?
				// If we pushed e1, e2, e3. Stack: ..., e1, e2, e3.
				// pop -> e3.
				// So we need to fill from end?
				val := pop(&vm.stack)
				vec[size - 1 - i] = val
			}
			append(&vm.stack, Array{data = vec})
		case .RESET:
			// Push a reset frame
			append(
				&vm.frames,
				CallFrame {
					return_ip = -1, // Not a return frame in normal sense
					env       = vm.env,
					is_reset  = true,
					sp        = len(vm.stack),
				},
			)

		case .FINISH_RESET:
			// When we finish a reset block normally, we pop the reset frame
			// and return the value on top of stack
			if len(vm.frames) > 0 {
				frame := pop(&vm.frames)
				if !frame.is_reset {
					fmt.println("Error: FINISH_RESET expected reset frame")
				}
				// The result is already on stack
			}
		case .SHIFT:
			// (shift k expr) -> k is bound to continuation
			k_sym := pop(&vm.stack).(Symbol)
			jump_offset := inst.arg

			// 1. Find nearest reset frame
			reset_idx := -1
			for i := len(vm.frames) - 1; i >= 0; i -= 1 {
				if vm.frames[i].is_reset {
					reset_idx = i
					break
				}
			}

			if reset_idx == -1 {
				fmt.println("Error: shift without reset")
				return Nil{}
			}

			reset_frame := vm.frames[reset_idx]

			// 2. Capture continuation
			// Capture frames above reset
			captured_frames := make([dynamic]CallFrame)
			for i in reset_idx + 1 ..< len(vm.frames) {
				append(&captured_frames, vm.frames[i])
			}

			// Capture stack above reset.sp
			captured_stack := make([dynamic]Value)
			for i in reset_frame.sp ..< len(vm.stack) {
				append(&captured_stack, vm.stack[i])
			}

			// 3. Create Continuation
			cont := new(Continuation)
			cont.stack = captured_stack
			cont.frames = captured_frames
			cont.ip = vm.ip + int(jump_offset)

			// 4. Abort to reset
			// Restore frames (keep reset frame)
			resize(&vm.frames, reset_idx + 1)
			// Restore stack (clear down to sp)
			resize(&vm.stack, reset_frame.sp)

			// 5. Bind k
			env_define(vm.env, k_sym, cont)

		// 6. Continue execution (fall through to body)
		// The body of shift follows immediately.


		case .CALL:
			// For now, simplify calls to builtins or fixed num args
			proc_val := pop(&vm.stack)
			num_args := int(inst.arg)
<<<<<<< HEAD
=======
			fmt.printf("info: CALL. Expected %d args, stack has %d\n", num_args, len(vm.stack))
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)
			if len(vm.stack) < num_args {
				fmt.printf(
					"Error: Stack underflow in CALL. Expected %d args, stack has %d\n",
					num_args,
					len(vm.stack),
				)
				return Nil{}
			}

			args := make([]Value, num_args)
<<<<<<< HEAD
			for i in 0 ..< num_args {
				args[num_args - 1 - i] = pop(&vm.stack)
			}
=======
			defer destroy_values(args)
			for i in 0 ..< num_args {
				args[num_args - 1 - i] = pop(&vm.stack)
			}
			fmt.printf("info: CALL. Args: %v\n", args)
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)

			#partial switch p in proc_val {
			case Builtin:
				res := p(args)
				append(&vm.stack, res)
			case ^Procedure:
<<<<<<< HEAD
=======
				fmt.printf("info: CALL. Procedure: %v\n", p)
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)
				// Push CallFrame
				append(
					&vm.frames,
					CallFrame {
						return_ip = vm.ip,
						env = vm.env,
						is_reset = false,
						sp = len(vm.stack),
					},
				)

				// Bind arguments
				// Create new env
				new_env := new(Env)
				new_env.parent = p.env
				new_env.values = make(map[Symbol]Value)

				if p.is_variadic {
					// (lambda (a b . c) ...) -> params = [a, b, c]
					// args must be at least 2.
					req_args := len(p.params) - 1
					if len(args) < req_args {
						fmt.println("Error: not enough arguments")
						// TODO: Handle error better
					}

					// Bind required args
					for i in 0 ..< req_args {
						new_env.values[p.params[i]] = args[i]
					}

					// Bind rest args
					rest_args: Value = Nil{}
					// We need to build list from remaining args.
					// args[req_args:]
					// List construction is from end to start.
					for i := len(args) - 1; i >= req_args; i -= 1 {
						pair := new(Pair)
						pair.first = args[i]
						pair.rest = rest_args
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

				vm.env = new_env
				// Jump to body. `p.body` is holding the IP as i64 (HACK from compiler).
<<<<<<< HEAD
=======
				fmt.printf("info: BytecodeInstructions: %v\n", bytecode.instructions)
				fmt.printf("info: p.body: %v\n", p.body)
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)
				vm.ip = int(p.body.(i64))

			case ^Continuation:
				// Restore continuation
				// 1. Push CallFrame (return point)
				append(
					&vm.frames,
					CallFrame {
						return_ip = vm.ip,
						env = vm.env,
						is_reset = false,
						sp = len(vm.stack),
					},
				)

				// 2. Push Reset Frame (delimiter)
				append(
					&vm.frames,
					CallFrame {
						return_ip = -1,
						env       = vm.env, // Or should it be nil env?
						is_reset  = true,
						sp        = len(vm.stack),
					},
				)

				// 3. Restore captured frames
				// We need to Deep Copy or just append? CallFrames are structs (values).
				// We need to shift current stack.
				// The captured stack assumes `sp` starts at 0 relative to reset.
				// We are appending.

				for frame in p.frames {
					// We need to adjust return_ip? No, they are absolute.
					// We need to adjust sp? NO, sp in CallFrame is absolute index.
					// This is a problem! `sp` in CallFrame is absolute index into stack.
					// If we restore frames, their `sp` values will be wrong because we are at a higher stack level.
					// We MUST offset their sp.

					new_frame := frame
					new_frame.sp += len(vm.stack) // Offset by current stack height
					append(&vm.frames, new_frame)
				}

				// 4. Restore captured stack
				for v in p.stack {
					append(&vm.stack, v)
				}

				// 5. Push argument
				arg := args[0]
				append(&vm.stack, arg)

				// 6. Resume
				vm.ip = p.ip

			case:
				fmt.println("Error: expected procedure")
				append(&vm.stack, Nil{})
			}
		case .RET:
			val := pop(&vm.stack)

			if len(vm.frames) == 0 {
				// Top level return?
				return val
			}

			frame := pop(&vm.frames)
			// Restore
			vm.env = frame.env

			if frame.is_reset {
				// We popped a reset frame via RET.
				// This implies we finished a computation inside a reset block (e.g. at end of continuation).
				// We just proceed, the value is on stack.
				// We do NOT restore IP because it is -1.
				append(&vm.stack, val)
				continue
			}

			// Push return value back
			append(&vm.stack, val)
			vm.ip = frame.return_ip
		case .JUMP:
			vm.ip = int(inst.arg)
		case .JUMP_IF_FALSE:
			val := pop(&vm.stack)
			if is_false(val) {
				vm.ip = int(inst.arg)
			}
		case .ADD:
			b := pop(&vm.stack).(i64)
			a := pop(&vm.stack).(i64)
			append(&vm.stack, a + b)
		case .SUB:
			b := pop(&vm.stack).(i64)
			a := pop(&vm.stack).(i64)
			append(&vm.stack, a - b)
		case .MUL:
			b := pop(&vm.stack).(i64)
			a := pop(&vm.stack).(i64)
			append(&vm.stack, a * b)
		case .DIV:
			b := pop(&vm.stack).(i64)
			a := pop(&vm.stack).(i64)
			append(&vm.stack, a / b)
		case .EQ:
			b := pop(&vm.stack).(i64)
			a := pop(&vm.stack).(i64)
			append(&vm.stack, a == b)
		case .LT:
			b := pop(&vm.stack).(i64)
			a := pop(&vm.stack).(i64)
			append(&vm.stack, a < b)
		case .GT:
			b := pop(&vm.stack).(i64)
			a := pop(&vm.stack).(i64)
			append(&vm.stack, a > b)
		}
	}

	if len(vm.stack) > 0 {
		return pop(&vm.stack)
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
<<<<<<< HEAD
=======
	fmt.printf("info: env_lookup: %v\n", env.values)
	fmt.printf("info: symbol: %v\n\n", sym)
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)
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
<<<<<<< HEAD
=======

destroy_bytecode :: proc(bytecode: ^Bytecode) {
	destroy_values(bytecode.constants[:])

	delete(bytecode.instructions)
	delete(bytecode.constants)
}

destroy_vm :: proc(vm: ^VM) {
	defer delete(vm.stack)
	defer delete(vm.frames)

	destroy_values(vm.stack[:])
	destroy_call_frames(vm.frames[:])
}
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)

package rekursion

import "core:fmt"

Compiler :: struct {
	bytecode: Bytecode,
}

<<<<<<< HEAD
=======
destroy_compiler :: proc(compiler: ^Compiler) {
	destroy_bytecode(&compiler.bytecode)
}

>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)
compiler_init :: proc() -> Compiler {
	return Compiler {
		bytecode = Bytecode {
			instructions = make([dynamic]Instruction),
			constants = make([dynamic]Value),
		},
	}
}

compile_expression :: proc(compiler: ^Compiler, expr: Value) {
	#partial switch e in expr {
	case Nil:
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_NIL})
	case bool:
		op := e ? Op_Code.PUSH_TRUE : Op_Code.PUSH_FALSE
		append(&compiler.bytecode.instructions, Instruction{op = op})
	case i64, f64, string:
		idx := add_constant(compiler, e)
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
	case Symbol:
		idx := add_constant(compiler, e)
		append(&compiler.bytecode.instructions, Instruction{op = .LOAD_VAR, arg = i32(idx)})
	case ^Pair:
		compile_list(compiler, e)
	case Array:
		for val in e.data {
			compile_expression(compiler, val)
		}
		append(
			&compiler.bytecode.instructions,
			Instruction{op = .MAKE_ARRAY, arg = i32(len(e.data))},
		)
	}
}

add_constant :: proc(compiler: ^Compiler, val: Value) -> int {
	for v, i in compiler.bytecode.constants {
		if value_equals(v, val) {
			return i
		}
	}
	append(&compiler.bytecode.constants, val)
	return len(compiler.bytecode.constants) - 1
}

value_equals :: proc(a, b: Value) -> bool {
	res := false
	// Simple equality for atoms
	#partial switch va in a {
	case Nil:
		_, ok := b.(Nil); res = ok
	case bool:
		vb, ok := b.(bool); res = ok && va == vb
	case i64:
		vb, ok := b.(i64); res = ok && va == vb
	case f64:
		vb, ok := b.(f64); res = ok && va == vb
	case string:
		vb, ok := b.(string); res = ok && va == vb
	case Symbol:
		vb, ok := b.(Symbol); res = ok && va == vb
	}
	return res
}

compile_list :: proc(compiler: ^Compiler, p: ^Pair) {
	head := p.first

	#partial switch h in head {
	case Symbol:
		if h == "define" {
			// (define sym expr) or (define (sym args...) body)
			args := p.rest.(^Pair)

			#partial switch def_head in args.first {
			case Symbol:
				sym := def_head
				val_expr := args.rest.(^Pair).first
				compile_expression(compiler, val_expr)
				idx := add_constant(compiler, sym)
				append(&compiler.bytecode.instructions, Instruction{op = .DEF_VAR, arg = i32(idx)})
				return
			case ^Pair:
				// (define (name params...) body)
				// def_head is (name params...)
				name := def_head.first.(Symbol)
				params := def_head.rest // (params...)

				body := args.rest // (body...)

				// Construct (lambda params body...)
				lambda_sym := Symbol("lambda")

				// Arguments to lambda: (params body...)
				// We create a new Pair for the lambda args list
				lambda_args := new(Pair)
				lambda_args.first = params
				lambda_args.rest = body

				// The lambda expression itself: (lambda params body...)
				lambda_expr := new(Pair)
				lambda_expr.first = lambda_sym
				lambda_expr.rest = lambda_args

				// Compile the lambda
				compile_expression(compiler, lambda_expr)

				// Define the variable
				idx := add_constant(compiler, name)
				append(&compiler.bytecode.instructions, Instruction{op = .DEF_VAR, arg = i32(idx)})
				return
			}
		} else if h == "if" {
			// (if test then else)
			args := p.rest.(^Pair)
			test_expr := args.first

			then_args := args.rest.(^Pair)
			then_expr := then_args.first

			else_args := then_args.rest.(^Pair)
			else_expr := else_args.first

			compile_expression(compiler, test_expr)

			jump_if_false_idx := len(compiler.bytecode.instructions)
			append(&compiler.bytecode.instructions, Instruction{op = .JUMP_IF_FALSE, arg = 0})

			compile_expression(compiler, then_expr)

			jump_idx := len(compiler.bytecode.instructions)
			append(&compiler.bytecode.instructions, Instruction{op = .JUMP, arg = 0})

			compiler.bytecode.instructions[jump_if_false_idx].arg = i32(
				len(compiler.bytecode.instructions),
			)

			compile_expression(compiler, else_expr)

			compiler.bytecode.instructions[jump_idx].arg = i32(len(compiler.bytecode.instructions))
			return
		} else if h == "quote" {
			args := p.rest.(^Pair)
			idx := add_constant(compiler, args.first)
			append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
			return
		} else if h == "lambda" {
			// (lambda (params...) body)
			args := p.rest.(^Pair)
			params_val := args.first
			body_expr := args.rest.(^Pair).first

			// 1. Jump over the body
			jump_idx := len(compiler.bytecode.instructions)
			append(&compiler.bytecode.instructions, Instruction{op = .JUMP, arg = 0})

			// 2. Body start
			start_ip := len(compiler.bytecode.instructions)

			// 3. Compile body
			compile_expression(compiler, body_expr)
			append(&compiler.bytecode.instructions, Instruction{op = .RET}) // Implicit return

			// 4. Patch jump
			compiler.bytecode.instructions[jump_idx].arg = i32(len(compiler.bytecode.instructions))

			// 5. Create Procedure value
			params: [dynamic]Symbol
			is_variadic := false
			curr := params_val
			for {
				#partial switch list in curr {
				case ^Pair:
					params_sym := list.first.(Symbol)
					append(&params, params_sym)
					curr = list.rest
				case Nil:
					break
				case Symbol:
					// Rest param
					append(&params, list)
					is_variadic = true
					break
				case:
					break
				}
				if is_variadic {break}
				if _, ok := curr.(Nil); ok {break}
				if _, ok := curr.(^Pair); !ok {
					// Fallback for improper list / unexpected cases
					break
				}
			}

			proc_val := new(Procedure)
			proc_val.params = params[:]
			proc_val.is_variadic = is_variadic

			proc_val.body = i64(start_ip) // HACK: Storing IP in body field if it was i64? No, body is Value.
			// We need to store IP in Procedure. Procedure struct has `body: Value`.
			// Let's store it as i64 in `body` for now, or change Procedure struct.
			// Given Value can be i64, this works for now.
			// But Procedure struct in value.odin says `body: Value`.

			// We need to add Procedure creation instruction?
			// No, we can create the Procedure object here and push it as constant?
			// But Procedure needs to capture env *at runtime*.
			// So we need `MAKE_CLOSURE` opcode?
			// `Procedure` struct in `value.odin` has `env`.
			// `PUSH_CONST` pushes a generic value. If we push a Procedure, it hasn't captured env yet.

			// Let's use `MAKE_CLOSURE` opcode.
			// It takes `start_ip` and `params` (as constant index).

			// For simplicity in this iteration:
			// We will push a "Prototype" Procedure as constant, then `MAKE_CLOSURE` will attach env.

			proc_proto := new(Procedure)
			proc_proto.params = params[:]
			proc_proto.body = i64(start_ip)

			idx := add_constant(compiler, proc_proto) // We need a way to wrap ^Procedure in Value.
			append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
			append(&compiler.bytecode.instructions, Instruction{op = .CLOSE_PROC})
			return
		} else if h == "reset" {
			// (reset expr)
			args := p.rest.(^Pair)
			expr := args.first

			append(&compiler.bytecode.instructions, Instruction{op = .RESET})
			compile_expression(compiler, expr)
			append(&compiler.bytecode.instructions, Instruction{op = .FINISH_RESET})
			return
		} else if h == "shift" {
			// (shift k expr)
			args := p.rest.(^Pair)
			k_sym := args.first.(Symbol)
			expr := args.rest.(^Pair).first

			// Push k symbol
			idx_sym := add_constant(compiler, k_sym)
			append(
				&compiler.bytecode.instructions,
				Instruction{op = .PUSH_CONST, arg = i32(idx_sym)},
			)

			// Emit SHIFT with placeholder arg (offset)
			shift_idx := len(compiler.bytecode.instructions)
			append(&compiler.bytecode.instructions, Instruction{op = .SHIFT, arg = 0})

			compile_expression(compiler, expr)

			append(&compiler.bytecode.instructions, Instruction{op = .FINISH_RESET})

			// Patch SHIFT offset
			// Offset should point to instruction AFTER FINISH_RESET.
			// Current len is ending.
			// Next instruction will be at `len`.
			// vm.ip at SHIFT execution is `shift_idx + 1`.
			// We want `cont.ip` to be `len(instructions)`.
			// So offset = len - (shift_idx + 1).
			offset := len(compiler.bytecode.instructions) - (shift_idx + 1)
			compiler.bytecode.instructions[shift_idx].arg = i32(offset)

			return
		}

		// Primitives
		if h == "+" || h == "-" || h == "*" || h == "/" || h == "=" || h == "<" || h == ">" {
			curr := p.rest
			num_args := 0
			for {
				#partial switch list in curr {
				case ^Pair:
					compile_expression(compiler, list.first)
					num_args += 1
					curr = list.rest
				case Nil:
					break
				case:
					break
				}
				if _, ok := curr.(Nil); ok {break}
				if _, ok := curr.(^Pair); !ok {
					// Handling dotted pairs for primitives if we wanted to
					break
				}
			}

			op: Op_Code
			switch h {
			case "+":
				op = .ADD
			case "-":
				op = .SUB
			case "*":
				op = .MUL
			case "/":
				op = .DIV
			case "=":
				op = .EQ
			case "<":
				op = .LT
			case ">":
				op = .GT
			}

			// For simplicity, we assume binary primitives for now if multiple args
			// A more robust compiler would handle N-ary primitives
			for i in 0 ..< num_args - 1 {
				append(&compiler.bytecode.instructions, Instruction{op = op})
			}
			return
		}
	}

	// Default: call
	curr := p.rest
	num_args := 0
	for {
		#partial switch list in curr {
		case ^Pair:
			compile_expression(compiler, list.first)
			num_args += 1
			curr = list.rest
		case Nil:
			break
		case:
			break
		}
		if _, ok := curr.(Nil); ok {break}
		if _, ok := curr.(^Pair); !ok {
			// This handles dotted pairs as arguments if we wanted to
			// compile_expression(c, curr)
			// num_args += 1
			break
		}
	}

	compile_expression(compiler, head)
	append(&compiler.bytecode.instructions, Instruction{op = .CALL, arg = i32(num_args)})
}

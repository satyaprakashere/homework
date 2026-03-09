package rekursion

import "core:fmt"
import "core:strings"

Compiler :: struct {
	bytecode: Bytecode,
	env:      ^Env,
}

compiler_init :: proc(env: ^Env) -> Compiler {
	return Compiler {
		bytecode = Bytecode {
			instructions = make([dynamic]Instruction),
			constants = make([dynamic]Value),
		},
		env = env,
	}
}

compile_expression :: proc(compiler: ^Compiler, expr: Value) {
	#partial switch e in expr {
	case Nil:
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_NIL})
	case nil:
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_NIL})
	case bool:
		op := e ? Op_Code.PUSH_TRUE : Op_Code.PUSH_FALSE
		append(&compiler.bytecode.instructions, Instruction{op = op})
	case i64, f64, string:
		idx := add_constant(compiler, e)
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
	case Symbol:
		if strings.contains(string(e), "lambda") {
			fmt.printf("WARNING: Emitting LOAD_VAR for %q\n", string(e))
		}
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

	cloned_val := clone_value(val)
	append(&compiler.bytecode.constants, cloned_val)
	// fmt.printf("DEBUG add_constant: Added new constant %v at index %d\n", val, len(compiler.bytecode.constants) - 1)
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
		if vb, ok := b.(Symbol); ok {
			res = (string(va) == string(vb))
		}
	}
	return res
}

compile_list :: proc(compiler: ^Compiler, p: ^Pair) {
	head := p.first
	#partial switch h in head {
	case Symbol:
		switch string(h) {
		case "define":
			compile_define(compiler, p); return
		case "if":
			compile_if(compiler, p); return
		case "defmacro":
			compile_defmacro(compiler, p); return
		case "quote":
			compile_quote(compiler, p); return
		case "quasiquote":
			compile_quasiquote(compiler, p); return
		case "lambda":
			compile_lambda(compiler, p); return
		case "begin":
			compile_begin(compiler, p); return
		case "reset":
			compile_reset(compiler, p); return
		case "shift":
			compile_shift(compiler, p); return
		case "+", "-", "*", "/", "=", "<", ">":
			compile_primitive(compiler, p, h); return
		}
	}

	// Macro Intercept
	if sym, ok := head.(Symbol); ok {
		if macro_val, found := env_lookup(compiler.env, sym); found {
			if m, is_macro := macro_val.(^Macro); is_macro {

				// DEBUG: Trace macro input
				if string(sym) == "let" || string(sym) == "and" || string(sym) == "or" {
					// fmt.printf(
					// 	"\nDEBUG: Intercepting macro '%v' with args: %v\n",
					// 	string(sym),
					// 	value_to_string(p.rest),
					// )
				}

				expanded_expr := compiler_evaluate_macro(compiler, m, p.rest)

				if string(sym) == "let" || string(sym) == "and" || string(sym) == "or" {
					// fmt.printf(
					// 	"DEBUG: Macro '%v' expanded to: %v\n\n",
					// 	string(sym),
					// 	value_to_string(expanded_expr),
					// )
				}

				compile_expression(compiler, expanded_expr)
				return
			}
		}
	}

	compile_call(compiler, p)
}

compile_define :: proc(compiler: ^Compiler, p: ^Pair) {
	args := p.rest.(^Pair)
	#partial switch def_head in args.first {
	case Symbol:
		compile_expression(compiler, args.rest.(^Pair).first)
		idx := add_constant(compiler, def_head)
		append(&compiler.bytecode.instructions, Instruction{op = .DEF_VAR, arg = i32(idx)})
	case ^Pair:
		name := def_head.first.(Symbol)
		lambda_args := new(Pair)
		lambda_args.first, lambda_args.rest = def_head.rest, args.rest
		lambda_expr := new(Pair)
		lambda_expr.first, lambda_expr.rest = Symbol("lambda"), lambda_args
		compile_expression(compiler, lambda_expr)
		idx := add_constant(compiler, name)
		append(&compiler.bytecode.instructions, Instruction{op = .DEF_VAR, arg = i32(idx)})
	case:
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_NIL})
	}
}

compiler_evaluate_macro :: proc(compiler: ^Compiler, m: ^Macro, args_val: Value) -> Value {
	// A macro is called with AST nodes as arguments instead of evaluated values.
	// We need to evaluate the macro body in a temporary VM, passing the arguments.

	// Create a temporary VM for expansion
	temp_vm := vm_init(compiler.env)
	// defer destroy_vm(&temp_vm)

	// Create an environment specifically for this macro call
	call_env := new(Env)
	call_env.parent = m.env
	call_env.values = make(map[Symbol]Value, 16)

	// Bind parameters
	curr_arg := args_val
	for param in m.params {
		if m.is_variadic && param == m.params[len(m.params) - 1] {
			env_define(call_env, param, curr_arg)
			curr_arg = Nil{}
			break
		}

		#partial switch pair in curr_arg {
		case ^Pair:
			env_define(call_env, param, pair.first)
			curr_arg = pair.rest
		case:
			fmt.println("Macro error: Not enough arguments")
			return Nil{}
		}
	}
	if m.is_variadic && curr_arg != nil {
		if _, ok := curr_arg.(Nil); !ok {
			env_define(call_env, m.params[len(m.params) - 1], curr_arg)
		}
	}

	// Compile the macro body into the current compiler to share constant IPs
	start_ip := len(compiler.bytecode.instructions)
	start_consts := len(compiler.bytecode.constants)

	compile_expression(compiler, m.body)
	append(&compiler.bytecode.instructions, Instruction{op = .RET})

	temp_vm.env = call_env
	temp_vm.ip = start_ip

	// Run the macro body
	result := vm_run(&temp_vm, &compiler.bytecode)

	// Truncate bytecode back to original state
	resize(&compiler.bytecode.instructions, start_ip)
	resize(&compiler.bytecode.constants, start_consts)

	return result
}

compile_defmacro :: proc(compiler: ^Compiler, p: ^Pair) {
	// (defmacro (name args...) body...) OR (defmacro name (lambda (args...) body...))
	// Standard Lisp: (defmacro name (args...) body...) -> wait, racket uses define-macro.
	// Let's support: `(defmacro name (args...) body...)`
	args := p.rest.(^Pair)
	name := args.first.(Symbol)

	macro_val := new(Macro)
	macro_val.env = compiler.env // Evaluate in current environment

	if pair, ok := args.rest.(^Pair); ok {
		// (args...)
		arg_list := pair.first

		// Parse params
		params := make([dynamic]Symbol)
		curr := arg_list
		is_variadic := false

		for curr != nil {
			if _, is_nil := curr.(Nil); is_nil {
				break
			} else if sym, is_sym := curr.(Symbol); is_sym {
				append(&params, sym)
				is_variadic = true
				break
			} else if p_arg, is_pair := curr.(^Pair); is_pair {
				if sym, is_sym := p_arg.first.(Symbol); is_sym {
					append(&params, sym)
				}
				curr = p_arg.rest
			} else {
				break
			}
		}

		macro_val.params = params[:]
		macro_val.is_variadic = is_variadic

		// Body is the rest of the arguments
		// We want an implicit `begin` block if there are multiple body statements
		body_list := pair.rest
		if body_pair, is_pair := body_list.(^Pair); is_pair {
			if _, is_nil := body_pair.rest.(Nil); is_nil {
				macro_val.body = body_pair.first
			} else {
				begin_sym := Symbol("begin")
				begin_pair := new(Pair)
				begin_pair.first = begin_sym
				begin_pair.rest = body_list
				macro_val.body = begin_pair
			}
		}
	}

	final_macro := macro_val
	if compiler.env.parent == nil {
		final_macro = clone_value(macro_val).(^Macro)
	}

	env_define(compiler.env, name, final_macro)
	append(&compiler.bytecode.instructions, Instruction{op = .PUSH_NIL})
}

compile_if :: proc(compiler: ^Compiler, p: ^Pair) {
	args, ok := p.rest.(^Pair)
	if !ok {
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_NIL})
		return
	}
	then_args, then_ok := args.rest.(^Pair)
	if !then_ok {
		compile_expression(compiler, args.first)
		append(&compiler.bytecode.instructions, Instruction{op = .POP})
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_NIL})
		return
	}
	else_args, else_ok := then_args.rest.(^Pair)

	compile_expression(compiler, args.first)
	jump_if_false_idx := len(compiler.bytecode.instructions)
	append(&compiler.bytecode.instructions, Instruction{op = .JUMP_IF_FALSE, arg = 0})

	compile_expression(compiler, then_args.first)
	jump_idx := len(compiler.bytecode.instructions)
	append(&compiler.bytecode.instructions, Instruction{op = .JUMP, arg = 0})

	compiler.bytecode.instructions[jump_if_false_idx].arg = i32(
		len(compiler.bytecode.instructions),
	)

	if else_ok {
		compile_expression(compiler, else_args.first)
	} else {
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_NIL})
	}

	compiler.bytecode.instructions[jump_idx].arg = i32(len(compiler.bytecode.instructions))
}

compile_quote :: proc(compiler: ^Compiler, p: ^Pair) {
	args := p.rest.(^Pair)
	idx := add_constant(compiler, args.first)
	append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
}

compile_quasiquote :: proc(compiler: ^Compiler, p: ^Pair) {
	args := p.rest.(^Pair)
	compile_quasiquote_expr(compiler, args.first)
}

compile_quasiquote_expr :: proc(compiler: ^Compiler, expr: Value) {
	#partial switch e in expr {
	case ^Pair:
		if sym, ok := e.first.(Symbol); ok {
			if string(sym) == "unquote" {
				// evaluate unquote
				compile_expression(compiler, e.rest.(^Pair).first)
				return
			}
		}

		is_splicing := false
		if first_pair, ok := e.first.(^Pair); ok {
			if sym, is_sym := first_pair.first.(Symbol);
			   is_sym && string(sym) == "unquote-splicing" {
				// evaluate the unquote-splicing argument
				compile_expression(compiler, first_pair.rest.(^Pair).first)
				is_splicing = true
			}
		}

		if !is_splicing {
			compile_quasiquote_expr(compiler, e.first)
		}

		compile_quasiquote_expr(compiler, e.rest)

		if is_splicing {
			append(&compiler.bytecode.instructions, Instruction{op = .CALL_APPEND})
		} else {
			append(&compiler.bytecode.instructions, Instruction{op = .CALL_CONS})
		}
	case:
		// atoms are just quoted
		idx := add_constant(compiler, e)
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
	}
}

compile_begin :: proc(compiler: ^Compiler, p: ^Pair) {
	curr := p.rest
	if _, is_nil := curr.(Nil); is_nil {
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_NIL})
		return
	}
	for curr != nil {
		if pair, ok := curr.(^Pair); ok {
			compile_expression(compiler, pair.first)
			if pair.rest != nil {
				if _, right_nil := pair.rest.(Nil); !right_nil {
					append(&compiler.bytecode.instructions, Instruction{op = .POP})
				}
			}
			curr = pair.rest
		} else {
			break
		}
	}
}

compile_lambda :: proc(compiler: ^Compiler, p: ^Pair) {
	args := p.rest.(^Pair)

	jump_idx := len(compiler.bytecode.instructions)
	append(&compiler.bytecode.instructions, Instruction{op = .JUMP, arg = 0})

	start_ip := len(compiler.bytecode.instructions)
	body_list := args.rest
	if body_pair, ok := body_list.(^Pair); ok {
		if _, is_nil := body_pair.rest.(Nil); !is_nil {
			begin_sym := Symbol("begin")
			begin_pair := new(Pair)
			begin_pair.first = begin_sym
			begin_pair.rest = body_list
			compile_expression(compiler, begin_pair)
		} else {
			compile_expression(compiler, body_pair.first)
		}
	} else {
		compile_expression(compiler, args.rest.(^Pair).first)
	}
	append(&compiler.bytecode.instructions, Instruction{op = .RET})

	compiler.bytecode.instructions[jump_idx].arg = i32(len(compiler.bytecode.instructions))

	proc_proto := compile_lambda_params(args.first, start_ip)
	idx := add_constant(compiler, proc_proto)
	append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
	append(&compiler.bytecode.instructions, Instruction{op = .CLOSE_PROC})
}

compile_lambda_params :: proc(params_val: Value, start_ip: int) -> ^Procedure {
	params: [dynamic]Symbol
	is_variadic := false
	curr := params_val
	for {
		#partial switch list in curr {
		case ^Pair:
			append(&params, list.first.(Symbol))
			curr = list.rest
		case Symbol:
			append(&params, list)
			is_variadic = true
			break
		}
		if is_variadic {break}
		if _, ok := curr.(Nil); ok {break}
		if _, ok := curr.(^Pair); !ok {break}
	}
	proc_val := new(Procedure)

	// Copy dynamic array to temp allocated slice
	perm_params := make([]Symbol, len(params))
	for p, i in params {
		perm_params[i] = p
	}

	proc_val.params = perm_params
	proc_val.is_variadic = is_variadic
	proc_val.body = i64(start_ip)
	return proc_val
}

compile_reset :: proc(compiler: ^Compiler, p: ^Pair) {
	args := p.rest.(^Pair)
	reset_idx := len(compiler.bytecode.instructions)

	append(&compiler.bytecode.instructions, Instruction{op = .RESET})
	compile_expression(compiler, args.first)
	append(&compiler.bytecode.instructions, Instruction{op = .FINISH_RESET})

	compiler.bytecode.instructions[reset_idx].arg = i32(len(compiler.bytecode.instructions))
}

compile_shift :: proc(compiler: ^Compiler, p: ^Pair) {
	args := p.rest.(^Pair)
	idx_sym := add_constant(compiler, args.first.(Symbol))
	append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx_sym)})
	shift_idx := len(compiler.bytecode.instructions)
	append(&compiler.bytecode.instructions, Instruction{op = .SHIFT, arg = 0})
	compile_expression(compiler, args.rest.(^Pair).first)
	append(&compiler.bytecode.instructions, Instruction{op = .SHIFT_YIELD})
	offset := len(compiler.bytecode.instructions) - (shift_idx + 1)
	compiler.bytecode.instructions[shift_idx].arg = i32(offset)
}

compile_primitive :: proc(compiler: ^Compiler, p: ^Pair, h: Symbol) {
	curr := p.rest
	num_args := 0
	for {
		#partial switch list in curr {
		case ^Pair:
			compile_expression(compiler, list.first)
			num_args += 1
			curr = list.rest
		}
		if _, ok := curr.(Nil); ok {break}
		if _, ok := curr.(^Pair); !ok {break}
	}
	op: Op_Code
	switch string(h) {
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
	for i in 0 ..< num_args - 1 {
		append(&compiler.bytecode.instructions, Instruction{op = op})
	}
}

compile_call :: proc(compiler: ^Compiler, p: ^Pair) {
	curr := p.rest
	num_args := 0
	for {
		#partial switch list in curr {
		case ^Pair:
			compile_expression(compiler, list.first)
			num_args += 1
			curr = list.rest
		}
		if _, ok := curr.(Nil); ok {break}
		if _, ok := curr.(^Pair); !ok {break}
	}
	compile_expression(compiler, p.first)
	append(&compiler.bytecode.instructions, Instruction{op = .CALL, arg = i32(num_args)})
}

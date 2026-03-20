package rekursion

import "core:fmt"

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

compile_expression :: proc(compiler: ^Compiler, expr: Value, is_tail := false) {
	#partial switch e in expr {
	case Nil, nil, bool:
		idx := add_constant(compiler, e)
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
	case i64, f64, string:
		idx := add_constant(compiler, e)
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
	case Symbol:
		idx := add_constant(compiler, e)
		append(&compiler.bytecode.instructions, Instruction{op = .LOAD_VAR, arg = i32(idx)})
	case ^Pair:
		compile_list(compiler, e, is_tail)
	case Array:
		for val in e.data {
			compile_expression(compiler, val)
		}
		// Emit call to 'array' primitive
		idx := add_constant(compiler, Symbol("array"))
		append(&compiler.bytecode.instructions, Instruction{op = .LOAD_VAR, arg = i32(idx)})
		append(&compiler.bytecode.instructions, Instruction{op = .CALL, arg = i32(len(e.data))})
	}
}

add_constant :: proc(compiler: ^Compiler, val: Value) -> int {
	for v, i in compiler.bytecode.constants {
		if value_equals(v, val) {
			return i
		}
	}

	cloned_val := clone_value(val, compiler.bytecode.constants.allocator)
	append(&compiler.bytecode.constants, cloned_val)
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

compile_list :: proc(compiler: ^Compiler, p: ^Pair, is_tail := false) {
	head := p.first
	#partial switch h in head {
	case Symbol:
		switch string(h) {
		case "define":
			compile_define(compiler, p); return
		case "if":
			compile_if(compiler, p, is_tail); return
		case "defmacro":
			compile_defmacro(compiler, p); return
		case "quote":
			compile_quote(compiler, p); return
		case "quasiquote":
			compile_quasiquote(compiler, p); return
		case "lambda":
			compile_lambda(compiler, p); return
		case "do":
			compile_do(compiler, p, is_tail); return
		case "let":
			compile_let(compiler, p, is_tail); return
		case "recur":
			compile_recur(compiler, p, is_tail); return
		case "goto":
			compile_goto(compiler, p, is_tail); return
		case "where":
			compile_where_error(compiler, p); return
		}
		if macro_val, found := env_lookup(compiler.env, h); found {
			if m, is_macro := macro_val.(^Macro); is_macro {
				expanded_expr := compiler_evaluate_macro(compiler, m, p.rest)
				compile_expression(compiler, expanded_expr, is_tail)
				return
			}
		}
		compile_call(compiler, p, is_tail)
	case:
		compile_call(compiler, p, is_tail)
	}
}

compile_where_error :: proc(compiler: ^Compiler, p: ^Pair) {
	fmt.eprintln("Error: 'where' can only be used at the end of a 'define' block")
	idx := add_constant(compiler, Nil{})
	append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
}

reconstruct_body_without_where :: proc(body: Value) -> Value {
	curr := body
	head: ^Pair = nil
	tail: ^Pair = nil

	for {
		p_curr, is_pair := curr.(^Pair)
		if !is_pair do break

		// If this is the last element (which we know is 'where'), don't add it
		if _, next_is_pair := p_curr.rest.(^Pair); !next_is_pair {
			break
		}

		new_node := new(Pair)
		new_node.first = p_curr.first
		new_node.rest = Nil{}

		if head == nil {
			head = new_node
			tail = new_node
		} else {
			tail.rest = new_node
			tail = new_node
		}
		curr = p_curr.rest
	}

	return head == nil ? Value(Nil{}) : Value(head)
}

compile_define :: proc(compiler: ^Compiler, p: ^Pair) {
	args := p.rest.(^Pair)
	#partial switch def_head in args.first {
	case Symbol:
		if _, is_nil := args.rest.(Nil); is_nil {
			fmt.println("Error: define missing value for", def_head)
			return
		}
		compile_expression(compiler, args.rest.(^Pair).first)
		idx := add_constant(compiler, def_head)
		append(&compiler.bytecode.instructions, Instruction{op = .DEF_VAR, arg = i32(idx)})
	case ^Pair:
		name := def_head.first.(Symbol)
		
		body := args.rest
		// Check for trailing (where ...)
		curr := body
		var_bindings: Value = Nil{}
		new_body: Value = Nil{}
		
		found_where := false
		for {
			p_curr, is_pair := curr.(^Pair)
			if !is_pair do break
			
			if p_next, next_is_pair := p_curr.rest.(^Pair); next_is_pair {
				curr = p_curr.rest
			} else {
				// Last element
				if last_p, ok := p_curr.first.(^Pair); ok {
					if sym, s_ok := last_p.first.(Symbol); s_ok && string(sym) == "where" {
						var_bindings = last_p.rest
						found_where = true
					}
				}
				break
			}
		}

		lambda_args := new(Pair)
		body_list: ^Pair = nil
		
		if found_where {
			new_body = reconstruct_body_without_where(body)
			
			let_expr := new(Pair)
			let_expr.first = Symbol("let")
			let_tail := new(Pair)
			let_tail.first = var_bindings
			let_tail.rest = new_body
			let_expr.rest = let_tail
			
			body_list = new(Pair)
			body_list.first = Value(let_expr)
			body_list.rest = Nil{}
		} else {
			// No where clause, use original body
			if p_body, ok := body.(^Pair); ok {
				body_list = p_body
			} else {
				body_list = new(Pair)
				body_list.first = body
				body_list.rest = Nil{}
			}
		}

		lambda_args.first, lambda_args.rest = def_head.rest, Value(body_list)
		lambda_expr := new(Pair)
		lambda_expr.first, lambda_expr.rest = Symbol("lambda"), lambda_args
		compile_expression(compiler, lambda_expr)
		idx := add_constant(compiler, name)
		append(&compiler.bytecode.instructions, Instruction{op = .DEF_VAR, arg = i32(idx)})
	case:
		idx := add_constant(compiler, Nil{})
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
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

		macro_val.params = make([]Symbol, len(params))
		for sym, i in params {
			macro_val.params[i] = sym
		}
		macro_val.is_variadic = is_variadic

		// We want an implicit `do` block if there are multiple body statements
		body_list := pair.rest
		if body_pair, is_pair := body_list.(^Pair); is_pair {
			if _, is_nil := body_pair.rest.(Nil); is_nil {
				macro_val.body = body_pair.first
			} else {
				begin_sym := Symbol("do")
				begin_pair := new(Pair)
				begin_pair.first = begin_sym
				begin_pair.rest = body_list
				macro_val.body = begin_pair
			}
		}
	}

	final_macro := macro_val
	if compiler.env.parent == nil {
		final_macro = clone_value(macro_val, compiler.env.values.allocator).(^Macro)
	}

	env_define(compiler.env, name, final_macro)
	idx := add_constant(compiler, Nil{})
	append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
}

compile_if :: proc(compiler: ^Compiler, p: ^Pair, is_tail := false) {
	args, ok := p.rest.(^Pair)
	if !ok {
		idx := add_constant(compiler, Nil{})
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
		return
	}
	then_args, then_ok := args.rest.(^Pair)
	if !then_ok {
		compile_expression(compiler, args.first)
		append(&compiler.bytecode.instructions, Instruction{op = .POP})
		idx := add_constant(compiler, Nil{})
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
		return
	}
	else_args, else_ok := then_args.rest.(^Pair)

	compile_expression(compiler, args.first)
	jump_if_false_idx := len(compiler.bytecode.instructions)
	append(&compiler.bytecode.instructions, Instruction{op = .JUMP_IF_FALSE, arg = 0})

	compile_expression(compiler, then_args.first, is_tail)
	jump_idx := len(compiler.bytecode.instructions)
	append(&compiler.bytecode.instructions, Instruction{op = .JUMP, arg = 0})

	compiler.bytecode.instructions[jump_if_false_idx].arg = i32(
		len(compiler.bytecode.instructions),
	)

	if else_ok {
		compile_expression(compiler, else_args.first, is_tail)
	} else {
		idx := add_constant(compiler, Nil{})
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
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
			sym_str := string(sym)
			if sym_str == "unquote" || sym_str == "comma" {
				// evaluate unquote
				compile_expression(compiler, e.rest.(^Pair).first)
				return
			}
		}

		is_splicing := false
		if first_pair, ok := e.first.(^Pair); ok {
			if sym, is_sym := first_pair.first.(Symbol); is_sym {
				sym_str := string(sym)
				if sym_str == "unquote-splicing" || sym_str == "comma-at" {
					// evaluate the unquote-splicing argument
					compile_expression(compiler, first_pair.rest.(^Pair).first)
					is_splicing = true
				}
			}
		}

		if !is_splicing {
			compile_quasiquote_expr(compiler, e.first)
		}

		compile_quasiquote_expr(compiler, e.rest)

		if is_splicing {
			idx := add_constant(compiler, Symbol("append"))
			append(&compiler.bytecode.instructions, Instruction{op = .LOAD_VAR, arg = i32(idx)})
			append(&compiler.bytecode.instructions, Instruction{op = .CALL, arg = 2})
		} else {
			idx := add_constant(compiler, Symbol("cons"))
			append(&compiler.bytecode.instructions, Instruction{op = .LOAD_VAR, arg = i32(idx)})
			append(&compiler.bytecode.instructions, Instruction{op = .CALL, arg = 2})
		}
	case:
		// atoms are just quoted
		idx := add_constant(compiler, e)
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
	}
}

compile_do :: proc(compiler: ^Compiler, p: ^Pair, is_tail := false) {
	curr := p.rest
	if _, is_nil := curr.(Nil); is_nil {
		idx := add_constant(compiler, Nil{})
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
		return
	}
	for {
		pair := curr.(^Pair) or_break
		_, is_last := pair.rest.(Nil)
		compile_expression(compiler, pair.first, is_tail && is_last)
		if !is_last {
			append(&compiler.bytecode.instructions, Instruction{op = .POP})
		}
		curr = pair.rest
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
			begin_sym := Symbol("do")
			begin_pair := new(Pair)
			begin_pair.first = begin_sym
			begin_pair.rest = body_list
			compile_expression(compiler, begin_pair, true)
		} else {
			compile_expression(compiler, body_pair.first, true)
		}
	} else if _, ok := body_list.(Nil); ok {
		idx := add_constant(compiler, Nil{})
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
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
		if sym, is_sym := curr.(Symbol); is_sym {
			append(&params, sym)
			is_variadic = true
			break
		}

		list := curr.(^Pair) or_break
		append(&params, list.first.(Symbol))
		curr = list.rest
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

// Procedures like compile_reset and compile_shift are removed.

compile_goto :: proc(compiler: ^Compiler, p: ^Pair, is_tail := false) {
	if !is_tail {
		fmt.eprintln("Error: 'goto' can only be used in tail position")
	}

	args := p.rest.(^Pair)
	// (goto func arg1 arg2...)
	target := args.first

	num_args := 0
	curr := args.rest
	for {
		list := curr.(^Pair) or_break
		compile_expression(compiler, list.first)
		num_args += 1
		curr = list.rest
	}

	compile_expression(compiler, target) // push proc last (on top)

	append(&compiler.bytecode.instructions, Instruction{op = .TAIL_CALL, arg = i32(num_args)})
}

compile_call :: proc(compiler: ^Compiler, p: ^Pair, is_tail := false) {
	curr := p.rest
	num_args := 0
	for {
		list := curr.(^Pair) or_break
		compile_expression(compiler, list.first)
		num_args += 1
		curr = list.rest
	}
	compile_expression(compiler, p.first, false)
	append(&compiler.bytecode.instructions, Instruction{op = .CALL, arg = i32(num_args)})
}

compile_recur :: proc(compiler: ^Compiler, p: ^Pair, is_tail := false) {
	if !is_tail {
		fmt.eprintln("Error: 'recur' can only be used in tail position")
	}

	curr := p.rest
	num_args := 0
	for {
		list := curr.(^Pair) or_break
		compile_expression(compiler, list.first)
		num_args += 1
		curr = list.rest
	}

	append(&compiler.bytecode.instructions, Instruction{op = .RECUR, arg = i32(num_args)})
}

compile_let :: proc(compiler: ^Compiler, p: ^Pair, is_tail := false) {
	// (let ((x 1) (y 2)) body...)
	args := p.rest.(^Pair)
	bindings := args.first
	body := args.rest

	// 1. Evaluate all binding values first
	num_bindings := 0
	curr := bindings
	for {
		b_p := curr.(^Pair) or_break
		binding := b_p.first.(^Pair)
		val_expr := binding.rest.(^Pair).first
		compile_expression(compiler, val_expr, false)
		num_bindings += 1
		curr = b_p.rest
	}

	// 2. Push new environment
	append(&compiler.bytecode.instructions, Instruction{op = .PUSH_ENV})

	// 3. Define variables in REVERSE order (since values are on stack)
	// We need to collect symbols first to do it in reverse or just handle it.
	// Actually, let's collect symbols first.
	symbols := make([dynamic]Symbol, context.temp_allocator)
	defer delete(symbols)
	curr = bindings
	for {
		b_p := curr.(^Pair) or_break
		binding := b_p.first.(^Pair)
		name := binding.first.(Symbol)
		append(&symbols, name)
		curr = b_p.rest
	}

	for i := len(symbols) - 1; i >= 0; i -= 1 {
		idx := add_constant(compiler, symbols[i])
		append(&compiler.bytecode.instructions, Instruction{op = .DEF_VAR, arg = i32(idx)})
		append(&compiler.bytecode.instructions, Instruction{op = .POP}) // DEF_VAR pushes name
	}

	// 4. Compile body
	compile_do(compiler, &Pair{first = Symbol("do"), rest = body}, is_tail)

	// 5. Pop environment
	append(&compiler.bytecode.instructions, Instruction{op = .POP_ENV})
}

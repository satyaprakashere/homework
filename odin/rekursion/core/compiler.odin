package rekursion

import "core:fmt"

Compiler :: struct {
	bytecode: Bytecode,
	env:      ^Env,
}

compiler_init :: proc(env: ^Env, allocator := context.allocator) -> Compiler {
	return Compiler {
		bytecode = Bytecode {
			instructions = make([dynamic]Instruction, allocator),
			constants = make([dynamic]Value, allocator),
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
		if value_equal(v, val) {
			return i
		}
	}

	cloned_val := clone_value(val, compiler.bytecode.constants.allocator)
	append(&compiler.bytecode.constants, cloned_val)
	return len(compiler.bytecode.constants) - 1
}

compile_list :: proc(compiler: ^Compiler, p: ^Pair, is_tail := false) {
	head := p.first
	#partial switch h in head {
	case Symbol:
		if compile_special_form(compiler, p, string(h), is_tail) do return
		
		macro_val, found := env_lookup(compiler.env, h)
		if m, ok := macro_val.(^Macro); found && ok {
			expanded_expr := compiler_evaluate_macro(compiler, m, p.rest)
			compile_expression(compiler, expanded_expr, is_tail)
			return
		}
		
		compile_call(compiler, p, is_tail)
	case:
		compile_call(compiler, p, is_tail)
	}
}

compile_special_form :: proc(compiler: ^Compiler, p: ^Pair, name: string, is_tail: bool) -> bool {
	switch name {
	case "define":      compile_define(compiler, p); return true
	case "if":          compile_if(compiler, p, is_tail); return true
	case "defmacro":    compile_defmacro(compiler, p); return true
	case "quote":       compile_quote(compiler, p); return true
	case "quasiquote":  compile_quasiquote(compiler, p); return true
	case "lambda":      compile_lambda(compiler, p); return true
	case "do":          compile_do(compiler, p, is_tail); return true
	case "let":         compile_let(compiler, p, is_tail); return true
	case "recur":       compile_recur(compiler, p, is_tail); return true
	case "goto":        compile_goto(compiler, p, is_tail); return true
	case "where":       compile_where_error(compiler, p); return true
	}
	return false
}

compile_where_error :: proc(compiler: ^Compiler, p: ^Pair) {
	fmt.eprintln("Error: 'where' can only be used at the end of a 'define' block")
	idx := add_constant(compiler, Nil{})
	append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
}

reconstruct_body_without_where :: proc(body: Value) -> Value {
	curr := body
	head, tail: ^Pair = nil, nil

	for {
		p_curr, is_pair := curr.(^Pair)
		if !is_pair do break

		// Check if next is the last (the 'where' clause)
		_, next_is_pair := p_curr.rest.(^Pair)
		if !next_is_pair do break

		new_node := new(Pair)
		new_node.first = p_curr.first
		new_node.rest = Nil{}

		if head == nil {
			head, tail = new_node, new_node
		} else {
			tail.rest, tail = new_node, new_node
		}
		curr = p_curr.rest
	}

	return Value(head) if head != nil else Nil{}
}

find_where_clause :: proc(body: Value) -> (Value, bool) {
	curr := body
	for {
		p_curr, is_pair := curr.(^Pair)
		if !is_pair do break

		// If this is the last element
		p_next, next_is_pair := p_curr.rest.(^Pair)
		if !next_is_pair {
			last_p, ok := p_curr.first.(^Pair)
			if !ok do break
			sym, s_ok := last_p.first.(Symbol)
			if s_ok && string(sym) == "where" do return last_p.rest, true
			break
		}
		curr = p_curr.rest
	}
	return Nil{}, false
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

		var_bindings, found_where := find_where_clause(body)
		new_body := reconstruct_body_without_where(body) if found_where else body

		lambda_body: Value = new_body
		if found_where {
			let_expr := new(Pair)
			let_expr.first, let_expr.rest = Symbol("let"), new(Pair)
			let_tail := let_expr.rest.(^Pair)
			let_tail.first, let_tail.rest = var_bindings, new_body
			lambda_body = new(Pair)
			lambda_body.(^Pair).first, lambda_body.(^Pair).rest = Value(let_expr), Nil{}
		}

		lambda_args := new(Pair)
		lambda_args.first, lambda_args.rest = def_head.rest, lambda_body

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
		is_last_variadic := m.is_variadic && param == m.params[len(m.params) - 1]
		if is_last_variadic {
			env_define(call_env, param, curr_arg)
			curr_arg = Nil{}
			break
		}

		pair, is_pair := curr_arg.(^Pair)
		if !is_pair {
			fmt.println("Macro error: Not enough arguments")
			return Nil{}
		}
		
		env_define(call_env, param, pair.first)
		curr_arg = pair.rest
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
	args := p.rest.(^Pair)
	name := args.first.(Symbol)

	macro_val := new(Macro)
	macro_val.env = compiler.env // Evaluate in current environment

	macro_args_pair, ok := args.rest.(^Pair)
	if !ok {
		fmt.println("Error: defmacro missing arguments or body for", name)
		return
	}

	params, is_variadic := parse_params_to_symbols(macro_args_pair.first)
	macro_val.params, macro_val.is_variadic = params, is_variadic

	body_list := macro_args_pair.rest
	body_pair, is_pair := body_list.(^Pair)

	is_rest_nil := false
	if is_pair {
		_, is_rest_nil = body_pair.rest.(Nil)
	}

	if !is_pair || is_rest_nil {
		macro_val.body = body_pair.first if is_pair else body_list
	} else {
		// Implicit (do ...)
		do_expr := new(Pair)
		do_expr.first, do_expr.rest = Symbol("do"), body_list
		macro_val.body = do_expr
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
		if compile_unquote_expr(compiler, e) do return

		is_splicing := false
		if first_pair, ok := e.first.(^Pair); ok {
			is_splicing = compile_unquote_splicing_expr(compiler, first_pair)
		}

		if !is_splicing {
			compile_quasiquote_expr(compiler, e.first)
		}

		compile_quasiquote_expr(compiler, e.rest)

		op_sym := Symbol("append") if is_splicing else Symbol("cons")
		idx := add_constant(compiler, op_sym)
		append(&compiler.bytecode.instructions, Instruction{op = .LOAD_VAR, arg = i32(idx)})
		append(&compiler.bytecode.instructions, Instruction{op = .CALL, arg = 2})
	case:
		idx := add_constant(compiler, e)
		append(&compiler.bytecode.instructions, Instruction{op = .PUSH_CONST, arg = i32(idx)})
	}
}

compile_unquote_expr :: proc(compiler: ^Compiler, e: ^Pair) -> bool {
	sym, ok := e.first.(Symbol)
	if !ok do return false
	
	sym_str := string(sym)
	if sym_str != "unquote" && sym_str != "comma" do return false
	
	compile_expression(compiler, e.rest.(^Pair).first)
	return true
}

compile_unquote_splicing_expr :: proc(compiler: ^Compiler, first_pair: ^Pair) -> bool {
	sym, is_sym := first_pair.first.(Symbol)
	if !is_sym do return false
	
	sym_str := string(sym)
	if sym_str != "unquote-splicing" && sym_str != "comma-at" do return false
	
	compile_expression(compiler, first_pair.rest.(^Pair).first)
	return true
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
	symbols, is_variadic := parse_params_to_symbols(params_val)
	
	proc_val := new(Procedure)
	proc_val.params = symbols
	proc_val.is_variadic = is_variadic
	proc_val.body = i64(start_ip)
	return proc_val
}

parse_params_to_symbols :: proc(params_val: Value) -> (symbols: []Symbol, is_variadic: bool) {
	params: [dynamic]Symbol
	is_var: bool = false
	curr := params_val
	
	for {
		if sym, ok := curr.(Symbol); ok {
			append(&params, sym)
			is_var = true
			break
		}

		list, ok := curr.(^Pair)
		if !ok do break
		
		#partial switch s in list.first {
		case Symbol: append(&params, s)
		case: fmt.println("Error: expected symbol in parameter list")
		}
		curr = list.rest
	}

	perm_params := make([]Symbol, len(params))
	for p, i in params {
		perm_params[i] = p
	}
	return perm_params, is_var
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

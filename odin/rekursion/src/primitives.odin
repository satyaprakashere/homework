package rekursion

import "core:fmt"

setup_primitives :: proc(env: ^Env) {
	env_define(env, Symbol("+"), Builtin(builtin_add))
	env_define(env, Symbol("-"), Builtin(builtin_sub))
	env_define(env, Symbol("*"), Builtin(builtin_mul))
	env_define(env, Symbol("/"), Builtin(builtin_div))
	env_define(env, Symbol("cons"), Builtin(builtin_cons))
	env_define(env, Symbol("first"), Builtin(builtin_first))
	env_define(env, Symbol("rest"), Builtin(builtin_rest))
	env_define(env, Symbol("array"), Builtin(builtin_array))
	env_define(env, Symbol("print"), Builtin(builtin_print))
	env_define(env, Symbol("table"), Builtin(builtin_make_table))
	env_define(env, Symbol("get"), Builtin(builtin_table_get))
	env_define(env, Symbol("set"), Builtin(builtin_table_set))
	env_define(env, Symbol("set-parent"), Builtin(builtin_table_set_parent))
}

builtin_add :: proc(args: []Value) -> Value {
	res: i64 = 0
	for a in args {
		res += a.(i64)
	}
	return res
}

builtin_sub :: proc(args: []Value) -> Value {
	if len(args) == 0 {return i64(0)}
	res := args[0].(i64)
	for i in 1 ..< len(args) {
		res -= args[i].(i64)
	}
	return res
}

builtin_mul :: proc(args: []Value) -> Value {
	res: i64 = 1
	for a in args {
		res *= a.(i64)
	}
	return res
}

builtin_div :: proc(args: []Value) -> Value {
	if len(args) == 0 {return i64(1)}
	res := args[0].(i64)
	for i in 1 ..< len(args) {
		res /= args[i].(i64)
	}
	return res
}

builtin_cons :: proc(args: []Value) -> Value {
	if len(args) != 2 {return Nil{}}
	pair := new(Pair)
	pair.first = args[0]
	pair.rest = args[1]
	return pair
}

builtin_first :: proc(args: []Value) -> Value {
	if len(args) != 1 {return Nil{}}
	pair, ok := args[0].(^Pair)
	if !ok {return Nil{}}
	return pair.first
}

builtin_rest :: proc(args: []Value) -> Value {
	if len(args) != 1 {return Nil{}}
	pair, ok := args[0].(^Pair)
	if !ok {return Nil{}}
	return pair.rest
}

builtin_array :: proc(args: []Value) -> Value {
	if len(args) == 0 {return Nil{}}

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

	return head
}

builtin_print :: proc(args: []Value) -> Value {
	for arg in args {
		fmt.print(value_to_string(arg))
		fmt.print(" ")
	}
	fmt.println()
	return Nil{}
}

builtin_make_table :: proc(args: []Value) -> Value {
	t := new(Table)
	t.data = make(map[string]Value)
	return t
}

builtin_table_get :: proc(args: []Value) -> Value {
	if len(args) != 2 {return Nil{}}

	t, ok := args[0].(^Table)
	if !ok {return Nil{}}

	key_val := args[1]
	key: string
	#partial switch k in key_val {
	case string:
		key = k
	case Symbol:
		key = string(k)
	case:
		// Convert key to string if not symbol/string?
		// Lone Lisp uses direct values. We restrict to strings for now.
		return Nil{}
	}

	curr := t
	for curr != nil {
		if val, found := curr.data[key]; found {
			return val
		}
		curr = curr.parent
	}

	return Nil{}
}

builtin_table_set :: proc(args: []Value) -> Value {
	if len(args) != 3 {return Nil{}}

	t, ok := args[0].(^Table)
	if !ok {return Nil{}}

	key_val := args[1]
	key: string
	#partial switch k in key_val {
	case string:
		key = k
	case Symbol:
		key = string(k)
	case:
		return Nil{}
	}

	val := args[2]
	t.data[key] = val
	return val
}

builtin_table_set_parent :: proc(args: []Value) -> Value {
	if len(args) != 2 {return Nil{}}

	t, ok := args[0].(^Table)
	if !ok {return Nil{}}

	parent, ok_p := args[1].(^Table)
	if !ok_p {
		// Allow nil parent?
		if _, is_nil := args[1].(Nil); is_nil {
			t.parent = nil
			return Nil{}
		}
		return Nil{}
	}

	t.parent = parent
	return parent
}

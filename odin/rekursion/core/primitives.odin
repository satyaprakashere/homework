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
	env_define(env, Symbol("car"), Builtin(builtin_first))
	env_define(env, Symbol("cdr"), Builtin(builtin_rest))
	env_define(env, Symbol("array"), Builtin(builtin_array))
	env_define(env, Symbol("print"), Builtin(builtin_print))
	env_define(env, Symbol("table"), Builtin(builtin_make_table))
	env_define(env, Symbol("get"), Builtin(builtin_table_get))
	env_define(env, Symbol("set"), Builtin(builtin_table_set))
	env_define(env, Symbol("set-parent"), Builtin(builtin_table_set_parent))
	env_define(env, Symbol("and"), Builtin(builtin_and))

	// Predicates
	env_define(env, Symbol("is-null"), Builtin(builtin_is_null))
	env_define(env, Symbol("is-pair"), Builtin(builtin_is_pair))
	env_define(env, Symbol("is-number"), Builtin(builtin_is_number))
	env_define(env, Symbol("is-symbol"), Builtin(builtin_is_symbol))
	env_define(env, Symbol("is-boolean"), Builtin(builtin_is_boolean))
	env_define(env, Symbol("is-string"), Builtin(builtin_is_string))
	env_define(env, Symbol("is-procedure"), Builtin(builtin_is_procedure))
	env_define(env, Symbol("is-table"), Builtin(builtin_is_table))

	// Converters
	env_define(env, Symbol("number-to-string"), Builtin(builtin_number_to_string))
	env_define(env, Symbol("number->string"), Builtin(builtin_number_to_string))
	env_define(env, Symbol("symbol-to-string"), Builtin(builtin_symbol_to_string))
	env_define(env, Symbol("string-append"), Builtin(builtin_string_append))

	// Equality
	env_define(env, Symbol("eq"), Builtin(builtin_eq))
	env_define(env, Symbol("eq?"), Builtin(builtin_eq))
	env_define(env, Symbol("equal"), Builtin(builtin_equal))
}

builtin_add :: proc(args: []Value) -> Value {
	res: i64 = 0
	// TODO: Add optimizations in layer 2
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

	key, key_ok := get_string_key(args[1])
	if !key_ok {return Nil{}}

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

	key, key_ok := get_string_key(args[1])
	if !key_ok {return Nil{}}

	val := args[2]
	t.data[key] = val
	return val
}

get_string_key :: proc(v: Value) -> (string, bool) {
	#partial switch k in v {
	case string:
		return k, true
	case Symbol:
		return string(k), true
	}
	return "", false
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

// Predicates
builtin_is_null :: proc(args: []Value) -> Value {
	if len(args) != 1 {return false}
	_, ok := args[0].(Nil)
	return ok
}

builtin_is_pair :: proc(args: []Value) -> Value {
	if len(args) != 1 {return false}
	_, ok := args[0].(^Pair)
	return ok
}

builtin_is_number :: proc(args: []Value) -> Value {
	if len(args) != 1 {return false}
	_, ok1 := args[0].(i64)
	_, ok2 := args[0].(f64)
	return ok1 || ok2
}

builtin_is_symbol :: proc(args: []Value) -> Value {
	if len(args) != 1 {return false}
	_, ok := args[0].(Symbol)
	return ok
}

builtin_is_boolean :: proc(args: []Value) -> Value {
	if len(args) != 1 {return false}
	_, ok := args[0].(bool)
	return ok
}

builtin_is_string :: proc(args: []Value) -> Value {
	if len(args) != 1 {return false}
	_, ok := args[0].(string)
	return ok
}

builtin_is_procedure :: proc(args: []Value) -> Value {
	if len(args) != 1 {return false}
	#partial switch _ in args[0] {
	case ^Procedure, Builtin, ^Continuation:
		return true
	}
	return false
}

builtin_is_table :: proc(args: []Value) -> Value {
	if len(args) != 1 {return false}
	_, ok := args[0].(^Table)
	return ok
}

// Converters
builtin_number_to_string :: proc(args: []Value) -> Value {
	if len(args) != 1 {return Nil{}}
	#partial switch n in args[0] {
	case i64:
		return fmt.tprintf("%d", n)
	case f64:
		return fmt.tprintf("%f", n)
	}
	return Nil{}
}

builtin_symbol_to_string :: proc(args: []Value) -> Value {
	if len(args) != 1 {return Nil{}}
	if s, ok := args[0].(Symbol); ok {
		return string(s)
	}
	return Nil{}
}

import "core:strings"

builtin_string_append :: proc(args: []Value) -> Value {
	if len(args) == 0 {return string("")}
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
	// Need to clone to the actual context allocator which might be arena
	return strings.clone(strings.to_string(sb))
}

// Equality
builtin_eq :: proc(args: []Value) -> Value {
	if len(args) != 2 {return false}
	a, b := args[0], args[1]

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
		// eq check for strings is pointer equality
		// But Odin strings might just compare content if we use `==`?
		// R5RS says `eq?` on strings might be false even if identical content.
		vb, ok := b.(string); return ok && va == vb
	case Builtin:
		// Not really comparable, but fast check
		return false
	case ^Pair:
		vb, ok := b.(^Pair); return ok && va == vb
	case ^Procedure:
		vb, ok := b.(^Procedure); return ok && va == vb
	case ^Continuation:
		vb, ok := b.(^Continuation); return ok && va == vb
	case ^Table:
		vb, ok := b.(^Table); return ok && va == vb
	}
	return false
}

builtin_equal :: proc(args: []Value) -> Value {
	if len(args) != 2 {return false}
	// value_equals is already doing deep structural equality but we need to import it or make it public.
	// Oh, value_equals is in compiler.odin and is NOT doing deep structurally yet!
	// WAIT, compiler.odin has value_equals! We need to expose a true equal method.
	return rekursion_value_equal(args[0], args[1])
}

rekursion_value_equal :: proc(a, b: Value) -> bool {
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
		if va == vb {return true} 	// Same pointer
		return rekursion_value_equal(va.first, vb.first) && rekursion_value_equal(va.rest, vb.rest)
	case Array:
		vb, ok := b.(Array)
		if !ok || len(va.data) != len(vb.data) {return false}
		for i in 0 ..< len(va.data) {
			if !rekursion_value_equal(va.data[i], vb.data[i]) {return false}
		}
		return true
	case ^Table, ^Procedure, ^Continuation, Builtin:
		// Structural equality for these is typically just eq?
		return builtin_eq([]Value{a, b}).(bool)
	}
	return false
}

builtin_and :: proc(args: []Value) -> Value {
	for arg in args {
		if !arg.(bool) {
			return false
		}
	}
	return true
}

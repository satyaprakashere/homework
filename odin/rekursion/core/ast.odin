package rekursion

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:unicode"

Value :: union {
	Nil,
	bool,
	i64,
	f64,
	string,
	Symbol,
	Array,
	Builtin,
	^Pair,
	^Macro,
	^Procedure,
	^Continuation,
}

Nil :: struct {}

Symbol :: distinct string

Pair :: struct {
	first: Value,
	rest:  Value,
}

Procedure :: struct {
	params:      []Symbol,
	body:        Value,
	env:         ^Env,
	is_variadic: bool,
}

Macro :: struct {
	params:      []Symbol,
	body:        Value,
	env:         ^Env,
	is_variadic: bool,
}

Array :: struct {
	data: [dynamic]Value,
}

clone_value :: proc(v: Value, allocator: mem.Allocator = context.allocator) -> Value {
	#partial switch val in v {
	case string:
		return strings.clone(val, allocator)
	case Symbol:
		return Symbol(strings.clone(string(val), allocator))
	case Array:
		cloned_data := make([dynamic]Value, len(val.data), allocator = allocator)
		for item, i in val.data {
			cloned_data[i] = clone_value(item, allocator)
		}
		return Array{data = cloned_data}
	case ^Pair:
		new_pair := new(Pair, allocator)
		new_pair.first = clone_value(val.first, allocator)
		new_pair.rest = clone_value(val.rest, allocator)
		return new_pair
	case ^Procedure:
		new_proc := new(Procedure, allocator)
		new_proc.is_variadic = val.is_variadic
		new_proc.env = val.env // Environment is shared
		new_proc.body = clone_value(val.body, allocator)

		cloned_params := make([]Symbol, len(val.params), allocator)
		for p, i in val.params {
			cloned_params[i] = clone_value(p, allocator).(Symbol)
		}
		new_proc.params = cloned_params
		return new_proc
	case ^Macro:
		new_macro := new(Macro, allocator)
		new_macro.is_variadic = val.is_variadic
		new_macro.env = val.env // Environment is shared
		new_macro.body = clone_value(val.body, allocator)
		cloned_params := make([]Symbol, len(val.params), allocator)
		for p, i in val.params {
			cloned_params[i] = clone_value(p, allocator).(Symbol)
		}
		new_macro.params = cloned_params
		return new_macro
	}
	return v
}

array_to_string :: proc(v: Array, allocator := context.allocator) -> string {
	sb: strings.Builder
	strings.builder_init(&sb, context.temp_allocator)
	defer strings.builder_destroy(&sb)
	strings.write_string(&sb, "[")
	for val, i in v.data {
		strings.write_string(&sb, value_to_string(val))
		if i < len(v.data) - 1 {
			strings.write_string(&sb, " ")
		}
	}
	strings.write_string(&sb, "]")
	return strings.clone(strings.to_string(sb), allocator)
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

is_symbol_char :: proc(r: rune) -> bool {
	if unicode.is_letter(r) || unicode.is_digit(r) {return true}
	return strings.contains_rune("+-*/<=>?!_#$", r)
}

value_to_string :: proc(v: Value, allocator := context.allocator) -> string {
	if s, ok := simple_value_to_string(v, allocator); ok {return s}
	return complex_value_to_string(v, allocator)
}

simple_value_to_string :: proc(v: Value, allocator := context.allocator) -> (string, bool) {
	#partial switch val in v {
	case Nil:
		return "nil", true
	case bool:
		return val ? "true" : "false", true
	case i64:
		return fmt.aprintf("%v", val, allocator = allocator), true
	case f64:
		return fmt.aprintf("%v", val, allocator = allocator), true
	case string:
		return fmt.aprintf("\"%v\"", val, allocator = allocator), true
	case Symbol:
		return string(val), true
	}
	return "||unknown simple value|", false
}

complex_value_to_string :: proc(v: Value, allocator := context.allocator) -> string {
	#partial switch val in v {
	case ^Pair:
		return pair_to_string(val, allocator)
	case ^Procedure:
		return "|procedure|"
	case Builtin:
		return "|builtin|"
	case ^Continuation:
		return "|continuation|"
	case Array:
		return array_to_string(val, allocator)
	case ^Macro:
		return "|macro|"
	}
	return "||unknown complex value||"
}

value_equal :: proc(a, b: Value) -> bool {
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
		return value_equal(va.first, vb.first) && value_equal(va.rest, vb.rest)
	case Array:
		vb, ok := b.(Array)
		if !ok || len(va.data) != len(vb.data) {return false}
		for i in 0 ..< len(va.data) {
			if !value_equal(va.data[i], vb.data[i]) {return false}
		}
		return true
	case ^Procedure:
		vb, ok := b.(^Procedure); return ok && va == vb
	case Builtin:
		vb, ok := b.(Builtin); return ok && (rawptr(va) == rawptr(vb))
	case ^Continuation:
		vb, ok := b.(^Continuation); return ok && va == vb
	case ^Macro:
		vb, ok := b.(^Macro); return ok && va == vb
	}
	return false
}

pair_to_string :: proc(p: ^Pair, allocator := context.allocator) -> string {
	sb: strings.Builder
	strings.builder_init(&sb, context.temp_allocator)
	defer strings.builder_destroy(&sb)
	strings.write_string(&sb, "(")
	curr := p
	for {
		strings.write_string(&sb, value_to_string(curr.first))
		next, done := format_pair_rest(&sb, curr)
		if done {break}
		curr = next
	}
	return strings.clone(strings.to_string(sb), allocator)
}

format_pair_rest :: proc(sb: ^strings.Builder, curr: ^Pair) -> (^Pair, bool) {
	#partial switch next in curr.rest {
	case ^Pair:
		strings.write_string(sb, " ")
		return next, false
	case Nil:
		strings.write_string(sb, ")")
		return nil, true
	case:
		strings.write_string(sb, " . ")
		strings.write_string(sb, value_to_string(curr.rest))
		strings.write_string(sb, ")")
		return nil, true
	}
}

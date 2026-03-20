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

array_to_string :: proc(v: Array) -> string {
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
	return strings.clone(strings.to_string(sb), context.allocator)
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

value_to_string :: proc(v: Value) -> string {
	if s, ok := simple_value_to_string(v); ok {return s}
	return complex_value_to_string(v)
}

simple_value_to_string :: proc(v: Value) -> (string, bool) {
	#partial switch val in v {
	case Nil:
		return "nil", true
	case bool:
		return val ? "true" : "false", true
	case i64:
		return fmt.aprintf("%v", val, allocator = context.allocator), true
	case f64:
		return fmt.aprintf("%v", val, allocator = context.allocator), true
	case string:
		return fmt.aprintf("\"%v\"", val, allocator = context.allocator), true
	case Symbol:
		return string(val), true
	}
	return "||unknown simple value|", false
}

complex_value_to_string :: proc(v: Value) -> string {
	#partial switch val in v {
	case ^Pair:
		return pair_to_string(val)
	case ^Procedure:
		return "|procedure|"
	case Builtin:
		return "|builtin|"
	case ^Continuation:
		return "|continuation|"
	case Array:
		return array_to_string(val)
	case ^Macro:
		return "|macro|"
	}
	return "||unknown complex value||"
}

pair_to_string :: proc(p: ^Pair) -> string {
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
	return strings.clone(strings.to_string(sb), context.allocator)
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

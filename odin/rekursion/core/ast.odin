package rekursion

import "core:fmt"
import "core:strings"

Value :: union {
	Nil,
	bool,
	i32,
	i64,
	f32,
	f64,
	string,
	Symbol,
	Array,
	Builtin,
	^Pair,
	^Table,
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

Builtin :: proc(args: []Value) -> Value

Macro :: struct {
	params:      []Symbol,
	body:        Value,
	env:         ^Env,
	is_variadic: bool,
}

Env :: struct {
	parent: ^Env,
	values: map[Symbol]Value,
}

Continuation :: struct {
	// Note: CallFrame definition is in vm.odin, but we need to reference it or equivalent?
	// Actually, vm.odin uses CallFrame, Continuation stores it.
	// We need to move CallFrame definition to value.odin or make it public?
	// Or we just store opaque data in Continuation?
	// Let's add frames to Continuation struct.
	// But CallFrame is in `vm.odin`.
	// Circular dependency if we import vm in value?
	// Move CallFrame to value.odin?
	// Yes, allow it.
	stack:  [dynamic]Value, // Captured stack segment
	frames: [dynamic]CallFrame,
	ip:     int, // Resume instruction pointer
}

Array :: struct {
	data: [dynamic]Value,
}

Table :: struct {
	parent: ^Table,
	data:   map[string]Value,
}

CallFrame :: struct {
	return_ip: int,
	env:       ^Env,
	is_reset:  bool,
	sp:        int,
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
		return fmt.tprintf("%v", val), true
	case f64:
		return fmt.tprintf("%v", val), true
	case string:
		return fmt.tprintf("\"%v\"", val), true
	case Symbol:
		return string(val), true
	}
	return "", false
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
	case ^Table:
		return "|table|"
	case ^Macro:
		return "|macro|"
	}
	return "|unknown|"
}

pair_to_string :: proc(p: ^Pair) -> string {
	sb: strings.Builder
	strings.builder_init(&sb)
	defer strings.builder_destroy(&sb)
	strings.write_string(&sb, "(")
	curr := p
	for {
		strings.write_string(&sb, value_to_string(curr.first))
		next, done := format_pair_rest(&sb, curr)
		if done {break}
		curr = next
	}
	return strings.to_string(sb)
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

array_to_string :: proc(v: Array) -> string {
	sb: strings.Builder
	strings.builder_init(&sb)
	defer strings.builder_destroy(&sb)
	strings.write_string(&sb, "[")
	for val, i in v.data {
		strings.write_string(&sb, value_to_string(val))
		if i < len(v.data) - 1 {
			strings.write_string(&sb, " ")
		}
	}
	strings.write_string(&sb, "]")
	return strings.to_string(sb)
}

destroy_value :: proc(v: Value) {
	// Value lifecycle is now managed by arenas for AST/evaluation.
	// Long-lived values (global_env) use the tracking allocator,
	// but are technically living until application exit anyway.
}

destroy_values :: proc(vals: []Value) {
}

destroy_continuation :: proc(c: ^Continuation) {
}

destroy_table :: proc(t: ^Table) {
}

destroy_procedure :: proc(p: ^Procedure) {
}

destroy_call_frame :: proc(c: CallFrame) {
}

destroy_call_frames :: proc(frames: []CallFrame) {
}

destroy_env :: proc(e: ^Env) {
	if e == nil {return}
	delete(e.values)
	free(e)
}

clone_value :: proc(v: Value) -> Value {
	alloc := context.allocator

	#partial switch val in v {
	case string:
		return strings.clone(val)
	case Symbol:
		return Symbol(strings.clone(string(val)))
	case Array:
		cloned_data := make([dynamic]Value, len(val.data))
		for item, i in val.data {
			cloned_data[i] = clone_value(item)
		}
		return Array{data = cloned_data}
	case ^Pair:
		new_pair := new(Pair)
		new_pair.first = clone_value(val.first)
		new_pair.rest = clone_value(val.rest)
		return new_pair
	case ^Procedure:
		new_proc := new(Procedure)
		new_proc.is_variadic = val.is_variadic
		new_proc.env = val.env // Environment is shared
		new_proc.body = clone_value(val.body)

		cloned_params := make([]Symbol, len(val.params))
		for p, i in val.params {
			cloned_params[i] = clone_value(p).(Symbol)
		}
		new_proc.params = cloned_params
		return new_proc
	case ^Table:
		new_table := new(Table)
		// we don't clone the parent deeply to avoid infinite loops and because parent tables
		// should already be in the global env if assigned.
		new_table.parent = val.parent
		new_table.data = make(map[string]Value, 16)
		for k, v in val.data {
			new_table.data[k] = clone_value(v)
		}
		return new_table
	case ^Macro:
		new_macro := new(Macro)
		new_macro.is_variadic = val.is_variadic
		new_macro.env = val.env // Environment is shared
		new_macro.body = clone_value(val.body)
		cloned_params := make([]Symbol, len(val.params))
		for p, i in val.params {
			cloned_params[i] = clone_value(p).(Symbol)
		}
		new_macro.params = cloned_params
		return new_macro
	}

	return v
}

package rekursion

import "core:fmt"
import "core:strings"

Value :: union {
	Nil,
	bool,
	i64,
	f64,
	string,
	Symbol,
<<<<<<< HEAD
	^Pair,
	^Procedure,
	Builtin,
	^Continuation,
	Array,
=======
	Array,
	Builtin,
	^Pair,
	^Procedure,
	^Continuation,
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)
	^Table,
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
	#partial switch val in v {
	case Nil:
		return "Nil"
	case bool:
		return val ? "True" : "False"
	case i64:
		return fmt.tprintf("%v", val)
	case f64:
		return fmt.tprintf("%v", val)
	case string:
		return fmt.tprintf("\"%v\"", val)
	case Symbol:
		return string(val)
	case ^Pair:
		return pair_to_string(val)
	case ^Procedure:
		return "|Procedure|"
	case Builtin:
		return "|Builtin|"
	case ^Continuation:
		return "|Continuation|"
	case Array:
		return array_to_string(val)
	case ^Table:
		return "|Table|"
	}
	return "|Unknown|"
}

pair_to_string :: proc(p: ^Pair) -> string {
	sb: strings.Builder
	strings.builder_init(&sb)
	strings.write_string(&sb, "(")

	curr := p
	for {
		strings.write_string(&sb, value_to_string(curr.first))

		#partial switch next in curr.rest {
		case ^Pair:
			strings.write_string(&sb, " ")
			curr = next
		case Nil:
			strings.write_string(&sb, ")")
			return strings.to_string(sb)
		case:
			strings.write_string(&sb, " . ")
			strings.write_string(&sb, value_to_string(curr.rest))
			strings.write_string(&sb, ")")
			return strings.to_string(sb)
		}
	}
}

array_to_string :: proc(v: Array) -> string {
	sb: strings.Builder
	strings.builder_init(&sb)
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
<<<<<<< HEAD
=======

destroy_value :: proc(v: Value) {
	#partial switch val in v {
	case ^Pair:
		destroy_value(val.first)
		destroy_value(val.rest)
	case ^Procedure:
		destroy_procedure(val)
	case ^Continuation:
		destroy_continuation(val)
	case ^Table:
		destroy_table(val)
	}
}

destroy_values :: proc(vals: []Value) {
	for val in vals {
		destroy_value(val)
	}
}

destroy_continuation :: proc(c: ^Continuation) {
	delete(c.stack)
	delete(c.frames)
}

destroy_table :: proc(t: ^Table) {
	delete(t.data)
}

destroy_procedure :: proc(p: ^Procedure) {
	destroy_value(p.body)
	// destroy_env(p.env) // DON'T DO THIS: env is shared
}

destroy_call_frame :: proc(c: CallFrame) {
	// destroy_env(c.env) // DON'T DO THIS: env is shared
}

destroy_call_frames :: proc(frames: []CallFrame) {
	for frame in frames {
		destroy_call_frame(frame)
	}
}

destroy_env :: proc(e: ^Env) {
	if e == nil {return}
	// destroy_env(e.parent) // DON'T DO THIS: parent is shared
	delete(e.values)
}
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)

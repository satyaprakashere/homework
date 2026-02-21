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
	^Pair,
	^Procedure,
	Builtin,
	^Continuation,
	Array,
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

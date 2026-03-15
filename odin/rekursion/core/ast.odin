package rekursion

import "core:fmt"
import "core:strings"

// Types and basic helpers are now in types_shared.odin

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

destroy_env :: proc(e: ^Env) {
	if e == nil {return}
	delete(e.values)
	free(e)
}

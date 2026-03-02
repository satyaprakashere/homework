package tests

import "../core"
import "core:fmt"
import "core:testing"

@(test)
test_arrays :: proc(t: ^testing.T) {
	fmt.println("Running minimal array test...")
	global_env := new(core.Env)
	global_env.values = make(map[core.Symbol]core.Value)
	core.setup_primitives(global_env)

	source := `(define arr (array 1 2 3)) arr`

	p := core.parser_init(source)
	expr := core.parse_expression(&p)

	c := core.compiler_init(global_env)
	core.compile_expression(&c, expr)
	append(&c.bytecode.instructions, core.Instruction{op = .RET})

	vm := core.vm_init(global_env)
	res := core.vm_run(&vm, &c.bytecode)
	fmt.println(core.value_to_string(res))
}

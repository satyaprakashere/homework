package tests

import "../core"
import "core:fmt"
import "core:os"
import "core:testing"

@(test)
test_debug :: proc(t: ^testing.T) {
	global_env := new(core.Env)
	global_env.values = make(map[core.Symbol]core.Value)
	core.setup_primitives(global_env)

	c := core.compiler_init(global_env)
	vm := core.vm_init(global_env)

	// fmt.println("--- Parsing ---")
	// os.flush(os.stdout)
	source := `(reset (+ 1 (shift k (+ (k 2) (k 2)))))`
	p := core.parser_init(source)
	expr := core.parse_expression(&p)

	// fmt.println("--- Compiling ---")
	// os.flush(os.stdout)
	core.compile_expression(&c, expr)
	append(&c.bytecode.instructions, core.Instruction{op = .RET})

	// fmt.println("--- Bytecode ---")
	for inst, i in c.bytecode.instructions {
		// fmt.printf("%d: %v %v\n", i, inst.op, inst.arg)
	}
	// fmt.println("--- Execution ---")
	vm.ip = 0
	result := core.vm_run(&vm, &c.bytecode)
	actual := core.value_to_string(result)
	testing.expect_value(t, actual, "6")
	fmt.printf("Result: %v\n", actual)
}

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

	fmt.println("--- Parsing ---")
	os.flush(os.stdout)
	source := `(reset (+ 1 (shift k (+ (k 2) (k 2)))))`
	p := core.parser_init(source)
	expr := core.parse_expression(&p)

	fmt.println("--- Compiling ---")
	os.flush(os.stdout)
	core.compile_expression(&c, expr)
	append(&c.bytecode.instructions, core.Instruction{op = .RET})

	fmt.println("--- Bytecode ---")
	for inst, i in c.bytecode.instructions {
		fmt.printf("%d: %v %v\n", i, inst.op, inst.arg)
	}
	fmt.println("--- Execution ---")
	vm.ip = 0
	steps := 0
	for vm.ip < len(c.bytecode.instructions) {
		steps += 1
		if steps > 200 {fmt.println("HANG"); break}
		inst := c.bytecode.instructions[vm.ip]
		vm.ip += 1
		if _, quit := core.vm_exec_inst(&vm, &c.bytecode, inst); quit {
			break
		}
	}
	if len(vm.stack) > 0 {
		fmt.println("Result:", core.value_to_string(pop(&vm.stack)))
	}
}

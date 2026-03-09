package tests

import rekursion "../core"
import "core:fmt"
import "core:log"
import "core:mem/virtual"
import "core:os"
import "core:testing"

@(test)
test_boolean :: proc(t: ^testing.T) {
	context.logger = log.create_console_logger()
	arena: virtual.Arena
	if err := virtual.arena_init_growing(&arena); err != nil {
		fmt.printf("Failed to init arena: %v\n", err)
		os.exit(1)
	}
	defer virtual.arena_destroy(&arena)

	global_env := new(rekursion.Env)
	global_env.values = make(map[rekursion.Symbol]rekursion.Value)
	rekursion.setup_primitives(global_env)

	c := rekursion.compiler_init(global_env)
	vm := rekursion.vm_init(global_env)

	rekursion.load_stdlib(&c, &vm)
	rekursion.load_scheme(&c, &vm)

	code := "(not #t)"
	fmt.println("Compiling:", code)
	p := rekursion.parser_init(code)
	expr := rekursion.parse_expression(&p)
	fmt.printf("Parsed Expr: %v\n", expr)
	start_ip := len(c.bytecode.instructions)
	rekursion.compile_expression(&c, expr)
	append(&c.bytecode.instructions, rekursion.Instruction{op = .RET})

	vm.ip = start_ip
	result := rekursion.vm_run(&vm, &c.bytecode)
	actual := rekursion.value_to_string(result)
	testing.expect_value(t, actual, "false")
	fmt.printf("Result: %v\n", actual)
}

package tests

import "../core"
import "core:fmt"
import "core:mem/virtual"
import "core:os"
import "core:testing"
import "core:log"

@(test)
test_main :: proc(t: ^testing.T) {
	context.logger = log.create_console_logger()

	// Prepare an arena allocator for this iteration of the test
	arena: virtual.Arena
	if err := virtual.arena_init_growing(&arena); err != nil {
		fmt.printf("Failed to init arena: %v\n", err)
		os.exit(1)
	}
	defer virtual.arena_destroy(&arena)

	// Set up standard allocator as temporary so environment logic works correctly
	context.temp_allocator = context.allocator
	context.allocator = virtual.arena_allocator(&arena)

	global_env := new(core.Env)
	global_env.values = make(map[core.Symbol]core.Value)

	core.setup_primitives(global_env)

	c := core.compiler_init(global_env)
	vm := core.vm_init(global_env)
	core.load_stdlib(&c, &vm)

	test_content := "(let ((x 1) (y 2)) (+ x y))"

	p := core.parser_init(string(test_content))
	expr := core.parse_expression(&p)

	start_ip := len(c.bytecode.instructions)
	core.compile_expression(&c, expr)

	fmt.printf("Successfully compiled let!\n")
	append(&c.bytecode.instructions, core.Instruction{op = .RET})

	vm2 := core.vm_init(global_env)
	vm2.ip = start_ip
	result := core.vm_run(&vm2, &c.bytecode)
	actual := core.value_to_string(result)
	testing.expect_value(t, actual, "3")
	fmt.printf("Result let: %v\n", actual)
}

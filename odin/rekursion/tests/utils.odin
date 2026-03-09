package tests

import "../core"
import "core:fmt"
import "core:log"
import "core:mem/virtual"
import "core:os"
import "core:strings"
import "core:testing"

run_scm_tests :: proc(t: ^testing.T, filename: string) {
	context.logger = log.create_console_logger()

	// Prepare an arena allocator
	arena: virtual.Arena
	if err := virtual.arena_init_growing(&arena); err != nil {
		fmt.printf("Failed to init arena: %v\n", err)
		os.exit(1)
	}
	defer virtual.arena_destroy(&arena)

	context.temp_allocator = context.allocator
	context.allocator = virtual.arena_allocator(&arena)

	global_env := new(core.Env)
	global_env.values = make(map[core.Symbol]core.Value)
	core.setup_primitives(global_env)

	c := core.compiler_init(global_env)
	vm := core.vm_init(global_env)

	core.load_stdlib(&c, &vm)
	core.load_scheme(&c, &vm)

	data, errf := os.read_entire_file(filename, context.allocator)
	if errf != nil {
		fmt.printf("Error: Could not read %s\n", filename)
		os.exit(1)
	}
	defer delete(data, context.allocator)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	for line in lines {
		trimmed := strings.trim_space(line)
		if trimmed == "" || strings.has_prefix(trimmed, ";") {continue}

		parts := strings.split(trimmed, ";; =>")
		if len(parts) < 2 {continue}

		code := strings.trim_space(parts[0])
		expected := strings.trim_space(parts[1])

		parser := core.parser_init(code)
		start_ip := len(c.bytecode.instructions)

		for {
			expr := core.parse_expression(&parser)
			if _, ok := expr.(core.Nil); ok {
				if parser.lexer.offset >= len(parser.lexer.source) {
					break
				}
			}
			core.compile_expression(&c, expr)
		}

		append(&c.bytecode.instructions, core.Instruction{op = .RET})

		vm.ip = start_ip
		result := core.vm_run(&vm, &c.bytecode)
		actual := core.value_to_string(result)
		testing.expect_value(t, actual, expected)
	}
}

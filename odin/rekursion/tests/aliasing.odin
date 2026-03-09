package tests

import "../core"
import "core:fmt"
import "core:mem/virtual"
import "core:os"
import "core:strings"
import "core:testing"

@(test)
test_aliasing :: proc(t: ^testing.T) {
	// Prepare an arena allocator
	arena : virtual.Arena
	err   := virtual.arena_init_growing(&arena)

    assert(err == nil)
	defer virtual.arena_destroy(&arena)

	context.temp_allocator = context.allocator
	context.allocator      = virtual.arena_allocator(&arena)

	global_env       := new(core.Env)
	global_env.values = make(map[core.Symbol]core.Value)
	core.setup_primitives(global_env)

	c  := core.compiler_init(global_env)
	vm := core.vm_init(global_env)
	core.load_stdlib(&c, &vm)

	data, errf := os.read_entire_file("tests/cases/aliasing.scm", context.allocator)
	assert(errf == nil)
	defer delete(data, context.allocator)

	content := string(data)
	lines   := strings.split(content, "\n")
	defer delete(lines)

	for line in lines {
		trimmed := strings.trim_space(line)
		if trimmed == "" || strings.has_prefix(trimmed, ";") {
			continue// move_on or ignore
		}

		parts := strings.split(trimmed, ";; =>")
		if len(parts) < 2 {
			continue// move_on or ignore
		}

		code := strings.trim_space(parts[0])
		expected := strings.trim_space(parts[1])

		parser := core.parser_init(code)
		start_ip := len(c.bytecode.instructions)

		for {
			expr := core.parse_expression(&parser)
            // what's happening here?
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

package tests

import core "../core"
import "core:log"

import "core:fmt"
import "core:mem/virtual"
import "core:os"
import "core:strings"
import "core:testing"

@(test)
tests :: proc(t: ^testing.T) {
	context.logger = log.create_console_logger()

	handle, err := os.open("out/logs/tests_debug.log", os.O_APPEND | os.O_WRONLY | os.O_CREATE)
	assert(err == nil)
	defer os.close(handle)

	log.info("Running tests from tests.scm...")
	os.write_string(handle, "Started tests runner\n")

	// Read tests.scm
	data, errf := os.read_entire_file("tests/cases/minimal-lisp.scm", context.allocator)
	if errf != nil {
		log.info("Error: Could not read tests.scm")
		os.exit(1)
	}
	defer delete(data, context.allocator)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

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

	core.load_file("lib/stdlib.scm", &c, &vm)


	for line, i in lines {
		trimmed := strings.trim_space(line)
		if trimmed == "" || strings.has_prefix(trimmed, ";") {continue}

		log_msg := fmt.tprintf("Running: %s\n", trimmed)
		os.write_string(handle, log_msg)

		// Parse expected output from comment
		parts := strings.split(trimmed, ";; =>")
		if len(parts) < 2 {
			continue
		}

		code := strings.trim_space(parts[0])
		expected := strings.trim_space(parts[1])


		// Run code
		p := core.parser_init(code)
		expr := core.parse_expression(&p)
		start_ip := len(c.bytecode.instructions)

		core.compile_expression(&c, expr)
		// Add return
		append(&c.bytecode.instructions, core.Instruction{op = .RET})

		vm.ip = start_ip
		result := core.vm_run(&vm, &c.bytecode)
		fmt.printf("Result: %v\n", result)

		actual := core.value_to_string(result)
		testing.expect_value(t, actual, expected)
	}


}

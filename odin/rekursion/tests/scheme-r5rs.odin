package tests

import "../core"
import "core:log"

import "core:fmt"
import "core:mem/virtual"
import "core:os"
import "core:strings"
import "core:testing"

@(test)
test_r5rs :: proc(t: ^testing.T) {
	context.logger = log.create_console_logger()

	handle, err := os.open("out/logs/tests_debug.log", os.O_APPEND | os.O_WRONLY | os.O_CREATE)
	if err != nil {
		log.error("Error: Could not open tests_debug.log")
		os.exit(1)
	}
	defer os.close(handle)
	log.info("Running R5RS tests from r5rs_compliance.scm...")
	os.write_string(handle, "Started R5RS tests runner\n")

	// Read tests
	data, errf := os.read_entire_file("tests/cases/r5rs_compliance.scm", context.allocator)
	if errf != nil {
		log.info("Error: Could not read r5rs_compliance.scm")
		os.exit(1)
	}
	defer delete(data, context.allocator)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

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

	for line, i in lines {
		trimmed := strings.trim_space(line)
		if trimmed == "" || strings.has_prefix(trimmed, ";") {continue}

		log_msg := fmt.tprintf("Running: %s\n", trimmed)
		os.write_string(handle, log_msg)

		parts := strings.split(trimmed, ";; =>")
		if len(parts) < 2 {
			continue
		}

		code := strings.trim_space(parts[0])
		expected := strings.trim_space(parts[1])

		p := core.parser_init(code)
		expr := core.parse_expression(&p)
		start_ip := len(c.bytecode.instructions)

		core.compile_expression(&c, expr)
		append(&c.bytecode.instructions, core.Instruction{op = .RET})

		vm.ip = start_ip
		result := core.vm_run(&vm, &c.bytecode)

		actual := core.value_to_string(result)
		testing.expect_value(t, actual, expected)
	}
}

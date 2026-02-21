package rekursion

import "core:fmt"
import "core:os"
import "core:strings"
import "core:testing"

@(test)
tests :: proc(_: ^testing.T) {
	fmt.println("Running tests from tests.scm...")
	os.write_entire_file("tests_debug.log", transmute([]u8)string("Started tests runner\n"))

	// Read tests.scm
	data, ok := os.read_entire_file("tests/tests.scm")
	if !ok {
		fmt.println("Error: Could not read tests.scm")
		os.exit(1)
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	global_env := new(Env)
	global_env.values = make(map[Symbol]Value)
	setup_primitives(global_env)

	c := compiler_init()
	vm := vm_init(global_env)

	failed := 0
	passed := 0

	for line, i in lines {
		trimmed := strings.trim_space(line)
		if trimmed == "" || strings.has_prefix(trimmed, ";") {continue}

		log_msg := fmt.tprintf("Running: %s\n", trimmed)
		os.write_entire_file("tests_debug.log", transmute([]u8)log_msg)

		// Parse expected output from comment
		parts := strings.split(trimmed, ";; =>")
		if len(parts) < 2 {
			continue
		}

		code := strings.trim_space(parts[0])
		expected := strings.trim_space(parts[1])

		// Run code
		p := parser_init(code)
		expr := parse_expression(&p)

		start_ip := len(c.bytecode.instructions)

		compile_expression(&c, expr)

		// Add return
		append(&c.bytecode.instructions, Instruction{op = .RET})

		vm.ip = start_ip
		result := vm_run(&vm, &c.bytecode)

		actual := value_to_string(result)

		if actual == expected {
			passed += 1
			// fmt.printf("PASS: %s => %s\n", code, actual)
		} else {
			failed += 1
			fmt.printf("FAIL: Line %d: %s\n", i + 1, code)
			fmt.printf("  Expected: %s\n", expected)
			fmt.printf("  Actual:   %s\n", actual)
		}
	}

	fmt.printf("\n%d passed, %d failed\n", passed, failed)

	if failed > 0 {
		os.exit(1)
	}
}

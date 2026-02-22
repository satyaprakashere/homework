package rekursion

import "core:fmt"
import "core:os"
import "core:strings"
import "core:testing"

<<<<<<< HEAD
@(test)
tests :: proc(_: ^testing.T) {
	fmt.println("Running tests from tests.scm...")
	os.write_entire_file("tests_debug.log", transmute([]u8)string("Started tests runner\n"))
=======
ENABLE_MEM_TRACKING :: #config(ENABLE_MEM_TRACKING, false)
@(test)
tests :: proc(t: ^testing.T) {
	handle, err := os.open("tests_debug.log", os.O_APPEND | os.O_WRONLY | os.O_CREATE, 0o644)
	if err != nil {
		fmt.println("Error: Could not open tests_debug.log")
		os.exit(1)
	}
	defer os.close(handle)
	fmt.println("Running tests from tests.scm...")
	os.write_string(handle, "Started tests runner\n")
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)

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
<<<<<<< HEAD
	vm := vm_init(global_env)
=======
	defer destroy_compiler(&c)
	vm := vm_init(global_env)
	defer destroy_vm(&vm)
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)

	failed := 0
	passed := 0

	for line, i in lines {
		trimmed := strings.trim_space(line)
		if trimmed == "" || strings.has_prefix(trimmed, ";") {continue}

		log_msg := fmt.tprintf("Running: %s\n", trimmed)
<<<<<<< HEAD
		os.write_entire_file("tests_debug.log", transmute([]u8)log_msg)
=======
		os.write_string(handle, log_msg)
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)

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
<<<<<<< HEAD

=======
		fmt.printf("Parsed: %v\n", expr)
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)
		start_ip := len(c.bytecode.instructions)

		compile_expression(&c, expr)

		// Add return
		append(&c.bytecode.instructions, Instruction{op = .RET})

		vm.ip = start_ip
		result := vm_run(&vm, &c.bytecode)
<<<<<<< HEAD

		actual := value_to_string(result)

		if actual == expected {
			passed += 1
			// fmt.printf("PASS: %s => %s\n", code, actual)
=======
		fmt.printf("Result: %v\n", result)

		actual := value_to_string(result)
		testing.expect_value(t, actual, expected)
		if actual == expected {
			passed += 1
			fmt.printf("PASS: %s => %s => %s\n", code, expected, actual)
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)
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

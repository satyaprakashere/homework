package rekursion

import "core:bufio"
import "core:fmt"
import "core:os"
import "core:strings"

main :: proc() {
	fmt.println("Scheme Bytecode Interpreter in Odin")
	fmt.println("Press Ctrl+C to exit")

	global_env := new(Env)
	global_env.values = make(map[Symbol]Value)

	setup_primitives(global_env)

	r_stream := os.stream_from_handle(os.stdin)
	reader: bufio.Reader
	bufio.reader_init(&reader, r_stream)
	defer bufio.reader_destroy(&reader)

	for {
		fmt.print("> ")
		line, err := bufio.reader_read_string(&reader, '\n')
		if err != nil {
<<<<<<< HEAD
=======
			if err != .EOF {
				fmt.printf("Error reading: %v\n", err)
			}
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)
			break
		}

		line = strings.trim_space(line)
		if line == "" {continue}

		p := parser_init(line)
		expr := parse_expression(&p)
<<<<<<< HEAD

		c := compiler_init()
=======
		defer destroy_value(expr)

		c := compiler_init()
		defer destroy_compiler(&c)
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)
		compile_expression(&c, expr)

		// Add a return at the end if not there
		append(&c.bytecode.instructions, Instruction{op = .RET})

		vm := vm_init(global_env)
<<<<<<< HEAD
=======
		defer destroy_vm(&vm)
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)
		result := vm_run(&vm, &c.bytecode)

		fmt.printf("=> %s\n", value_to_string(result))
	}
}

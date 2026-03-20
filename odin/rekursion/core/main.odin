package rekursion

import "core:bufio"
import "core:fmt"
import "core:log"
import "core:mem/virtual"
import "core:os"
import "core:strings"

main :: proc() {
	context.logger = log.create_console_logger()
	log.info("Scheme Bytecode Interpreter written in Odin\nPress Ctrl+C to exit")

	global_env := new(Env)
	global_env.values = make(map[Symbol]Value)
	setup_primitives(global_env)
	defer free(global_env)
	defer delete(global_env.values)

	r_stream := os.to_stream(os.stdin)
	reader: bufio.Reader
	bufio.reader_init(&reader, r_stream)
	defer bufio.reader_destroy(&reader)

	// Prepare arena allocator for current statement parsing/compiling/execution
	arena: virtual.Arena
	if err := virtual.arena_init_growing(&arena); err != nil {
		log.error("Failed to init arena: %v\n", err)
		return
	}
	defer virtual.arena_destroy(&arena)

	// Let standard allocator be temp so global_env can use temp_allocator
	context.temp_allocator = context.allocator
	context.allocator = virtual.arena_allocator(&arena)

	// TODO: do we need to pass env to compiler and vm?
	c := compiler_init(global_env)
	vm := vm_init(global_env)

	load_file("lib/stdlib.scm", &c, &vm)
	load_file("lib/scheme.scm", &c, &vm)
	load_file("lib/actor.scm", &c, &vm)

	for {repl_step(&reader, &c, &vm)}
}

repl_step :: proc(reader: ^bufio.Reader, c: ^Compiler, vm: ^VM) {
	fmt.print("> ")

	full_source: strings.Builder
	strings.builder_init(&full_source)
	defer strings.builder_destroy(&full_source)

	paren_balance := 0
	in_string := false
	first_line := true

	for {
		line, err := bufio.reader_read_string(reader, '\n')
		if err != nil {
			if err != .EOF {log.info("Error reading: %v\n", err)}
			if strings.builder_len(full_source) == 0 do os.exit(0)
			break
		}

		strings.write_string(&full_source, line)

		// Count parentheses in the new line, being careful about strings and comments
		for i := 0; i < len(line); i += 1 {
			char := line[i]
			if in_string {
				if char == '"' && (i == 0 || line[i - 1] != '\\') {
					in_string = false
				}
			} else {
				if char == '"' {
					in_string = true
				} else if char == '(' || char == '[' {
					paren_balance += 1
				} else if char == ')' || char == ']' {
					paren_balance -= 1
				} else if char == ';' {
					break // Comment, rest of line is ignored
				}
			}
		}

		if paren_balance <= 0 && strings.trim_space(strings.to_string(full_source)) != "" {
			break
		}
		fmt.print("  ") // Indent for multi-line input
	}

	source := strings.to_string(full_source)
	if strings.trim_space(source) == "" {return}

	p := parser_init(source)
	for {
		tok := parser_peek(&p)
		if tok.type == .EOF do break

		expr := parse_expression(&p)
		start_ip := len(c.bytecode.instructions)

		compile_expression(c, expr)
		append(&c.bytecode.instructions, Instruction{op = .RET})

		vm.ip = start_ip
		result := vm_run(vm, &c.bytecode)
		if vm.errored {
			vm.errored = false
			return
		}
		log.info("=> %s\n", value_to_string(result))
	}
}

load_file :: proc(path: string, compiler: ^Compiler, vm: ^VM) {
	// log.info("Loading file: %s", path)
	data, err := os.read_entire_file(path, context.allocator)
	assert(err == nil)
	defer delete(data, context.allocator)

	content := string(data)
	parser := parser_init(content)
	for {
		tok := parser_peek(&parser)
		if tok.type == .EOF {break}

		expr := parse_expression(&parser)
		start_ip := len(compiler.bytecode.instructions)

		compile_expression(compiler, expr)
		append(&compiler.bytecode.instructions, Instruction{op = .RET})

		vm.ip = start_ip
		vm_run(vm, &compiler.bytecode)
		if vm.errored {
			fmt.eprintf("Error loading file %s: %s\n", path, vm.error_msg)
			return
		}
	}
}

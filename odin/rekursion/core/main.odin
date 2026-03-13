package rekursion

import "core:bufio"
import "core:fmt"
import "core:log"
import "core:mem/virtual"
import "core:os"
import "core:strings"

main :: proc() {
	context.logger = log.create_console_logger()
	log.info("Scheme Bytecode Interpreter in Odin\nPress Ctrl+C to exit")

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

load_file :: proc(path: string, compiler: ^Compiler, vm: ^VM) {
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
	}
}

repl_step :: proc(reader: ^bufio.Reader, c: ^Compiler, vm: ^VM) {
	fmt.print("> ")

	line, err := bufio.reader_read_string(reader, '\n')
	if err != nil {
		if err != .EOF {log.info("Error reading: %v\n", err)}
		os.exit(0)
	}
	// defer delete(line)

	line = strings.trim_space(line)
	if line == "" {return}

	p := parser_init(line)
	expr := parse_expression(&p)
	start_ip := len(c.bytecode.instructions)

	compile_expression(c, expr)
	append(&c.bytecode.instructions, Instruction{op = .RET})

	vm.ip = start_ip
	result := vm_run(vm, &c.bytecode)
	log.info("=> %s\n", value_to_string(result))
}

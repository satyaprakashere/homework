package rekursion

import "core:bufio"
import "core:fmt"
import "core:log"
import "core:mem/virtual"
import "core:os"
import "core:strings"

main :: proc() {
	context.logger = log.create_console_logger()
	// tracking_allocator: mem.Tracking_Allocator
	// mem.tracking_allocator_init(&tracking_allocator, context.allocator)
	// context.allocator = mem.tracking_allocator(&tracking_allocator)
	// defer {
	// 	if len(tracking_allocator.allocation_map) > 0 {
	// 		fmt.println()
	// 		for _, leak in tracking_allocator.allocation_map {
	// 			fmt.printf("%v leaking %v bytes\n", leak.location, leak.size)
	// 		}
	// 	}
	// 	if len(tracking_allocator.bad_free_array) > 0 {
	// 		fmt.println()
	// 		for bad_free in tracking_allocator.bad_free_array {
	// 			fmt.printf("%v bad free at %v\n", bad_free.location, bad_free.memory)
	// 		}
	// 	}
	// 	mem.tracking_allocator_destroy(&tracking_allocator)
	// }

	log.info("Scheme Bytecode Interpreter in Odin\nPress Ctrl+C to exit")

	global_env := new(Env)
	global_env.values = make(map[Symbol]Value)
	setup_primitives(global_env)

	r_stream := os.stream_from_handle(os.stdin)
	reader: bufio.Reader
	bufio.reader_init(&reader, r_stream)
	defer bufio.reader_destroy(&reader)

	// Prepare arena allocator for current statement parsing/compiling/execution
	arena: virtual.Arena
	if err := virtual.arena_init_growing(&arena); err != nil {
		fmt.printf("Failed to init arena: %v\n", err)
		return
	}
	defer virtual.arena_destroy(&arena)

	// Let standard allocator be temp so global_env can use temp_allocator
	context.temp_allocator = context.allocator
	context.allocator = virtual.arena_allocator(&arena)

	// TODO: do we need to pass env to compiler and vm?
	c := compiler_init(global_env)
	vm := vm_init(global_env)

	load_stdlib(&arena, global_env, &c, &vm)

	for {repl_step(&arena, &reader, &c, &vm)}
}

load_stdlib :: proc(arena: ^virtual.Arena, env: ^Env, c: ^Compiler, vm: ^VM) {
	data, ok := os.read_entire_file("lib/stdlib.scm")
	if !ok {
		log.error("Warning: Could not load lib/stdlib.scm")
		return
	}
	defer delete(data)

	content := string(data)

	p := parser_init(content)
	for {
		tok := parser_peek(&p)
		if tok.type == .EOF {break}

		expr := parse_expression(&p)

		start_ip := len(c.bytecode.instructions)
		compile_expression(c, expr)
		append(&c.bytecode.instructions, Instruction{op = .RET})
		vm.ip = start_ip
		vm_run(vm, &c.bytecode)
	}
}

repl_step :: proc(arena: ^virtual.Arena, reader: ^bufio.Reader, c: ^Compiler, vm: ^VM) {
	fmt.print("> ")

	line, err := bufio.reader_read_string(reader, '\n')
	if err != nil {
		if err != .EOF {fmt.printf("Error reading: %v\n", err)}
		os.exit(0)
	}
	defer delete(line)

	line = strings.trim_space(line)
	if line == "" {return}
	p := parser_init(line)
	expr := parse_expression(&p)

	start_ip := len(c.bytecode.instructions)
	compile_expression(c, expr)
	append(&c.bytecode.instructions, Instruction{op = .RET})
	vm.ip = start_ip
	result := vm_run(vm, &c.bytecode)
	fmt.printf("=> %s\n", value_to_string(result))
}

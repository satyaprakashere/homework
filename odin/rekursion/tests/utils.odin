package tests

import "../core"
import "core:log"
import "core:mem/virtual"
import "core:os"
import "core:strings"
import "core:testing"

run_scm_tests :: proc(t: ^testing.T, filename: string, extra_libs: []string = nil) {
	// context.logger = log.create_console_logger()
	// defer log.destroy_console_logger(context.logger)

	// Prepare an arena allocator
	arena: virtual.Arena
	err := virtual.arena_init_growing(&arena)
	assert(err == nil, "Failed to init arena")
	defer virtual.arena_destroy(&arena)

	// Save original context to restore it for defers if needed (though defers capture implicitly?)
	// Actually, in Odin, context is restored automatically when returning, BUT deferred statements
	// execute with the context AT THE TIME OF DEFER execution, which is at the end.
	// So let's push the context correctly.

	// Create environment BEFORE swapping allocator, if we want it to persist or be destroyed
	// Wait, we want everything to be in the arena.

	context.temp_allocator = context.allocator
	context.allocator = virtual.arena_allocator(&arena)

	global_env := new(core.Env)
	global_env.values = make(map[core.Symbol]core.Value)
	core.setup_primitives(global_env)

	c := core.compiler_init(global_env)
	vm := core.vm_init(global_env)

	core.load_file("lib/stdlib.scm", &c, &vm)

	for lib in extra_libs {
		core.load_file(lib, &c, &vm)
	}

	data, errf := os.read_entire_file(filename, context.allocator)
	assert(errf == nil, "Failed to read file")
	defer delete(data, context.allocator)

	content := string(data)
	p := core.parser_init(content)

	for {
		// Remember offset BEFORE peek so we include leading whitespace/comments if needed
		start_offset := p.lexer.offset
		if core.parser_peek(&p).type == .EOF {
			break
		}

		expr := core.parse_expression(&p)
		end_offset := p.lexer.offset

		// Read following characters to look for expectation in comments
		expectation := ""
		found_exp := false

		// Check the rest of the line for ;; =>
		post_expr := content[end_offset:]
		line_end := strings.index_byte(post_expr, '\n')
		if line_end == -1 {
			line_end = len(post_expr)
		}
		comment_line := post_expr[:line_end]

		if parts := strings.split(comment_line, ";; =>"); len(parts) > 1 {
			expectation = strings.trim_space(parts[1])
			found_exp = true
		} else if parts := strings.split(comment_line, "; =>"); len(parts) > 1 {
			expectation = strings.trim_space(parts[1])
			found_exp = true
		}

		start_ip := len(c.bytecode.instructions)
		core.compile_expression(&c, expr)
		append(&c.bytecode.instructions, core.Instruction{op = .RET})

		// Track which code segment this IP range belongs to
		vm.ip = start_ip
		final_result := core.vm_run(&vm, &c.bytecode)

		if found_exp {
			actual := core.value_to_string(final_result)
			if actual != expectation {
				log.errorf(
					"FAIL in %s:\n  CODE: %s\n  EXP:  %s\n  ACT:  %s\n",
					filename,
					strings.trim_space(content[start_offset:end_offset]),
					expectation,
					actual,
				)
				testing.fail(t)
			}
		}

		free_all(context.temp_allocator)
	}
}

const std = @import("std");
const Value = @import("value.zig").Value;
const ValueArray = @import("value.zig").ValueArray;
const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;
const VM = @import("vm.zig").VM;
const Compiler = @import("compiler.zig").Compiler;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len == 1) {
        std.debug.print("Usage: rekursion [path]\n", .{});
        std.process.exit(64);
    }

    const path = args[1];
    const source = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .unlimited);
    defer allocator.free(source);

    var chunk = Chunk.init(allocator);
    defer chunk.deinit();

    if (!try Compiler.compile(source, &chunk)) {
        std.process.exit(65);
    }

    // chunk.disassemble("Script");

    var vm = try VM.init(allocator);
    defer vm.deinit();

    _ = try vm.interpret(&chunk);
}

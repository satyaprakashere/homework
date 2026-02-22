const std = @import("std");
const Value = @import("value.zig").Value;
const ValueArray = @import("value.zig").ValueArray;
const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;
const VM = @import("vm.zig").VM;
const Compiler = @import("compiler.zig").Compiler;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len == 1) {
        std.debug.print("Usage: rekursion [path]\n", .{});
        std.process.exit(64);
    }

    const path = args[1];
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const source = try file.readToEndAlloc(allocator, 1024 * 1024);
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

const std = @import("std");
const RChunk = @import("chunk.zig");
const VM = @import("vm.zig").VM;

const Chunk = RChunk.Chunk;

pub fn main(init: std.process.Init) !void {
    std.debug.print("Hello, There! Welcome to Rekursion bytecode interpreter\n", .{});
    const allocator = init.gpa;

    var chunks = try Chunk.init(allocator);
    defer chunks.deinit();


    var vm = try VM.initChunk(allocator, &chunks);
    defer vm.deinit();

    try chunks.writeChunk(RChunk.OpCode.RETURN);
    try chunks.writeChunk(RChunk.OpCode.CONSTANT);

    Chunk.deassembleChunk(&chunks, "instruction");
}

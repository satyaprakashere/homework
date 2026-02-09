const std = @import("std");
const RChunk = @import("chunk.zig");
const VM = @import("vm.zig").VM;

const Chunk = RChunk.Chunk;

pub fn main() !void {
    std.debug.print("Hello, There! Welcome to Rekursion bytecode interpreter\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var chunks = try Chunk.init(allocator);
    defer chunks.deinit();

    var vm = try VM.initChunk(allocator, &chunks);
    defer vm.deinit();

    try chunks.writeChunk(RChunk.OpCode.RETURN);
    try chunks.writeChunk(RChunk.OpCode.CONSTANT);

    Chunk.deassembleChunk(&chunks, "instruction");
}

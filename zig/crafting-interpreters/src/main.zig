const std = @import("std");
const VM = @import("vm.zig").VM;
const RChunk = @import("chunk.zig");
const Stack = @import("stack.zig").Stack;
const Queue = @import("queue.zig").Queue;
const CQueue = @import("cqueue.zig").CQueue;

const Chunk = RChunk.Chunk;

pub fn main() !void {
    std.debug.print("Hello, There! Welcome to Rekursion bytecode interpreter\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var chunks = try Chunk.init(allocator);
    defer chunks.deinit();

    var vm = VM.initChunk(allocator, &chunks);
    defer vm.deinit();

    try chunks.writeChunk(RChunk.OpCode.RETURN);
    try chunks.writeChunk(RChunk.OpCode.CONSTANT);

    Chunk.deassembleChunk(&chunks, "instruction");

}

test "testing stack and queue" {
    var stack = Stack(i32).init(std.testing.allocator);
    defer stack.deinit();

    try stack.push(1);
    try stack.pushSlice(&[2]i32{ 2, 3 });

    try std.testing.expect(try stack.pop() == 3);
    try std.testing.expect(try stack.pop() == 2);
    try std.testing.expect(try stack.pop() == 1);

    var queue = Queue(i32).init(std.testing.allocator);
    defer queue.deinit();

    try queue.enqueue(1);
    try queue.enqueueSlice(&[2]i32{ 2, 3 });

    try std.testing.expect(try queue.dequeue() == 1);
    try std.testing.expect(try queue.dequeue() == 2);
    try std.testing.expect(try queue.dequeue() == 3);

    var cqueue = CQueue(i32).init(std.testing.allocator);
    defer cqueue.deinit();

    try cqueue.enqueue(1);
    try cqueue.enqueue(2);

    try std.testing.expect(try cqueue.dequeue() == 1);

    try cqueue.enqueue(3);
    try cqueue.enqueueSlice(&[3]i32{ 4, 5, 6 });

    try std.testing.expect(try cqueue.dequeue() == 2);
    try std.testing.expectEqualSlices(i32, try cqueue.dequeueSlice(2), &[_]i32{ 3, 4 });
}

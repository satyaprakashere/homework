const std = @import("std");

fn ArenaAllocator() type {
    return struct {

        // pub fn deinit(self: *ArenaAllocator) void {
        // }

        // pub fn alloc(self: *ArenaAllocator, size: usize) ?[*]u8 {

        // }

        // pub fn free(ptr: [*]u8) void {
        // }
    };
}

pub fn main() !void {
    const allocator = std.ArenaAllocator.init().alloc(10240, 4096) orelse return error.MallocFailed;
    defer allocator.deinit();
}

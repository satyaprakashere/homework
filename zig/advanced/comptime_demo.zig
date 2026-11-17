const std = @import("std");

// Comptime: A function that takes a type and returns a type
fn List(comptime T: type) type {
    return struct {
        items: []T,
        len: usize,

        pub fn init(allocator: std.mem.Allocator) !@This() {
            return .{
                .items = try allocator.alloc(T, 10),
                .len = 0,
            };
        }
    };
}

pub fn runComptimeDemo() !void {
    std.debug.print("\n--- 1. Comptime Demo ---\n", .{});
    const IntList = List(i32);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    
    const list = try IntList.init(allocator);
    defer allocator.free(list.items);
    
    std.debug.print("Created a List of i32 at comptime!\n", .{});
}

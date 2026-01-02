const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    const gpa = std.heap.page_allocator;

    var stack = try Stack(i32).initCapacity(gpa, 1000);
    defer stack.deinit();

    try stack.pushSlice(&[3]i32{ 10, 20, 30 });

    std.debug.print("Top: {}\n", .{stack.peek().?}); // 30

    while (!stack.isEmpty()) {
        const val = stack.pop().?;
        std.debug.print("Popped: {}\n", .{val});
    }

    testPop(&stack);
}

fn testPop(stack: *Stack(i32)) void {
    if (stack.pop()) |v| {
        std.debug.print("Popped: {}\n", .{v});
    } else {
        std.debug.print("Stack is empty\n", .{});
    }
}

pub fn Stack(comptime T: type) type {
    return struct {
        allocator: Allocator,
        list: std.ArrayList(T),

        pub fn initCapacity(allocator: Allocator, comptime capacity: usize) Allocator.Error!Stack(T) {
            return Stack(T){ .allocator = allocator, .list = try std.ArrayList(T).initCapacity(allocator, capacity) };
        }

        pub fn deinit(self: *Stack(T)) void {
            self.list.deinit(self.allocator);
        }

        pub fn push(self: *Stack(T), value: T) !void {
            try self.list.append(self.allocator, value);
        }

        pub fn pushSlice(self: *Stack(T), value: []const T) !void {
            try self.list.appendSlice(self.allocator, value);
        }

        pub fn pop(self: *Stack(T)) ?T {
            if (self.list.items.len == 0) {
                return null;
            }
            return self.list.pop() orelse unreachable;
        }

        pub fn popSlice(self: *Stack(T), n: usize) ?[]T {
            if (self.list.items.len < n) {
                return null;
            }
            return self.list.popLast(n);
        }

        pub fn peek(self: *Stack(T)) ?T {
            if (self.list.items.len == 0) {
                return null;
            }
            return self.list.items[self.list.items.len - 1];
        }

        pub fn isEmpty(self: *Stack(T)) bool {
            return self.list.items.len == 0;
        }

    };
}

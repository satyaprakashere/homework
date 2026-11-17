const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn Queue(comptime T: type) type {
    return struct {
        allocator: Allocator,
        list: std.ArrayList(T),

        pub fn initCapacity(allocator: std.mem.Allocator, comptime capacity: usize) Allocator.Error!Queue(T) {
            return Queue(T){ .allocator = allocator, .list = try std.ArrayList(T).initCapacity(allocator, capacity) };
        }

        pub fn deinit(self: *Queue(T)) void {
            self.list.deinit(self.allocator);
        }

        pub fn enqueue(self: *Queue(T), value: T) !void {
            try self.list.append(self.allocator, value);
        }

        pub fn enqueueSlice(self: *Queue(T), value: []const T) !void {
            try self.list.appendSlice(self.allocator, value);
        }

        pub fn dequeue(self: *Queue(T)) !T {
            if (self.list.items.len == 0)
                return err.emptyEqueue;

            const value = self.list.items[0];
            _ = self.list.orderedRemove(0); // Shift elements left
            return value;
        }

        pub fn dequeueSlice(self: *Queue(T), size: usize) ![]T {
            if (self.list.items.len == 0)
                return err.emptyEqueue;

            const value = self.list.items[0..size];
            _ = self.list.orderedRemoveRange(0, size); // Shift elements left
            return value;
        }

        pub fn isEmpty(self: *Queue(T)) bool {
            return self.list.items.len == 0;
        }

        pub const err = error{emptyEqueue};
    };
}

test "testing queue" {
    var queue = try Queue(i32).initCapacity(std.testing.allocator, 1000);
    defer queue.deinit();

    try queue.enqueue(1);
    try queue.enqueueSlice(&[2]i32{ 2, 3 });

    try std.testing.expect(try queue.dequeue() == 1);
    try std.testing.expect(try queue.dequeue() == 2);
    try std.testing.expect(try queue.dequeue() == 3);
}

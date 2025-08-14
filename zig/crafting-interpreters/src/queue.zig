const std = @import("std");

pub fn Queue(comptime T: type) type {
    return struct {
        list: std.ArrayList(T),

        pub fn init(allocator: std.mem.Allocator) Queue(T) {
            return Queue(T){ .list = std.ArrayList(T).init(allocator) };
        }

        pub fn initCapacity(allocator: std.mem.Allocator, comptime capacity: usize) Queue(T) {
            return Queue(T){ .list = std.ArrayList(T).initCapacity(allocator, capacity) };
        }

        pub fn deinit(self: *Queue(T)) void {
            self.list.deinit();
        }

        pub fn enqueue(self: *Queue(T), value: T) !void {
            try self.list.append(value);
        }

        pub fn enqueueSlice(self: *Queue(T), value: []const T) !void {
            try self.list.appendSlice(value);
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

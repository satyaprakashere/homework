const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn CQueue(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        list: std.ArrayList(T),
        index: usize,
        rindex: usize,

        pub fn initCapacity(allocator: Allocator, comptime capacity: usize) Allocator.Error!CQueue(T) {
            return CQueue(T){
                .allocator = allocator,
                .index = 0,
                .rindex = 0,
                .list = try std.ArrayList(T).initCapacity(allocator, capacity),
            };
        }

        pub fn deinit(self: *CQueue(T)) void {
            self.list.deinit(self.allocator);
        }

        pub fn enqueue(self: *CQueue(T), value: T) !void {
            if (self.list.capacity == self.list.items.len and (self.rindex < self.index)) {
                self.list.items[self.rindex] = value;
                self.rindex += 1;
            } else {
                try self.list.append(self.allocator, value);
            }
        }

        pub fn enqueueSlice(self: *CQueue(T), values: []const T) !void {
            const mid = self.list.capacity - self.list.items.len;
            if (self.list.capacity < self.list.items.len + values.len) {
                try self.list.appendSlice(self.allocator, values[0..mid]);
            } else {
                try self.list.appendSlice(self.allocator, values);
                return;
            }
            const rest = (self.rindex + (values.len - mid));
            if (self.list.capacity == self.list.items.len and rest < self.index) {
                std.debug.assert((rest - self.rindex) == (values.len - mid));
                std.mem.copyBackwards(i32, self.list.items[self.rindex..rest], values[mid..]);
            } else {
                try self.list.appendSlice(self.allocator, values);
            }
        }

        pub fn dequeue(self: *CQueue(T)) !T {
            if (self.index >= self.list.items.len)
                return err.emptyQueue;

            const value = self.list.items[self.index];
            self.index += 1;
            return value;
        }

        pub fn dequeueSlice(self: *CQueue(T), size: usize) ![]const T {
            if (self.index + size >= self.list.items.len)
                return err.emptyQueue;

            const value = self.list.items[self.index .. self.index + size];
            self.index += size;
            return value;
        }

        pub fn isEmpty(self: *CQueue(T)) bool {
            return self.list.items.len == 0;
        }

        pub const err = error{emptyQueue};
    };
}

test "testing cqueue" {
    var cqueue = try CQueue(i32).initCapacity(std.testing.allocator, 1000);
    defer cqueue.deinit();

    try cqueue.enqueue(1);
    try cqueue.enqueue(2);

    try std.testing.expect(try cqueue.dequeue() == 1);

    try cqueue.enqueue(3);
    try cqueue.enqueueSlice(&[3]i32{ 4, 5, 6 });

    try std.testing.expect(try cqueue.dequeue() == 2);
    try std.testing.expectEqualSlices(i32, try cqueue.dequeueSlice(2), &[_]i32{ 3, 4 });
}

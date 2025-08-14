const std = @import("std");

pub fn CQueue(comptime T: type) type {
    return struct {
        list: std.ArrayList(T),
        index: usize,
        rindex: usize,

        pub fn init(allocator: std.mem.Allocator) CQueue(T) {
            return CQueue(T){
                .index = 0,
                .rindex = 0,
                .list = std.ArrayList(T).init(allocator),
            };
        }

        pub fn initCapacity(allocator: std.mem.Allocator, comptime capacity: usize) CQueue(T) {
            return CQueue(T){
                .index = 0,
                .rindex = 0,
                .list = std.ArrayList(T).initCapacity(allocator, capacity),
            };
        }

        pub fn deinit(self: *CQueue(T)) void {
            self.list.deinit();
        }

        pub fn enqueue(self: *CQueue(T), value: T) !void {
            if (self.list.capacity == self.list.items.len and (self.rindex < self.index)) {
                self.list.items[self.rindex] = value;
                self.rindex += 1;
            } else {
                try self.list.append(value);
            }
        }

        pub fn enqueueSlice(self: *CQueue(T), values: []const T) !void {
            const mid = self.list.capacity - self.list.items.len;
            if (self.list.capacity < self.list.items.len + values.len) {
                try self.list.appendSlice(values[0..mid]);
            } else {
                try self.list.appendSlice(values);
                return;
            }
            const rest = (self.rindex + (values.len - mid));
            if (self.list.capacity == self.list.items.len and rest < self.index) {
                std.debug.assert((rest - self.rindex) == (values.len - mid));
                std.mem.copyBackwards(i32, self.list.items[self.rindex..rest], values[mid..]);
            } else {
                try self.list.appendSlice(values);
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

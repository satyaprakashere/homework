const std = @import("std");

pub fn ModArray(comptime T: type) type {
    return struct {
        array: []T,
        capacity: usize,

        pub fn initCapacity(comptime capacity: usize) ModArray(T) {
            const cap = comptime nextPowerOfTwo(capacity);
            return ModArray(T){ .capacity = cap, .array = [cap]T };
        }

        pub fn deinit(self: *ModArray(T)) void {
            self.capacity = 0;
        }

        pub fn get(self: *ModArray(T), index: usize) T {
            return self.array[index & (self.capacity - 1)];
        }

        pub fn set(self: *ModArray(T), index: usize, value: T) void {
            self.array[index & (self.capacity - 1)] = value;
        }

        fn nextPowerOfTwo(comptime n: usize) usize {
            var x = n;
            x -= 1;
            x |= x >> 1;
            x |= x >> 2;
            x |= x >> 4;
            x |= x >> 8;
            x |= x >> 16;
            return x + 1;
        }
    };
}

test "ModArray" {
    var array = ModArray(i32).initCapacity(16);
    defer array.deinit();

    array.set(0, 42);
    try std.testing.expectEqual(array.get(16), 42);
}

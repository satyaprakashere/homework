const std = @import("std");
const Allocator = std.mem.Allocator;

pub const ValueType = enum {
    float,
    boolean,
    nil,
};

pub const Value = union(ValueType) {
    float: f64,
    boolean: bool,
    nil: void,

    pub fn isFloat(self: Value) bool {
        return self == .float;
    }

    pub fn isBoolean(self: Value) bool {
        return self == .boolean;
    }

    pub fn isNil(self: Value) bool {
        return self == .nil;
    }

    pub fn asFloat(self: Value) f64 {
        return self.float;
    }

    pub fn asBoolean(self: Value) bool {
        return self.boolean;
    }

    pub fn print(self: Value) void {
        switch (self) {
            .float => |v| std.debug.print("{d}", .{v}),
            .boolean => |v| std.debug.print("{}", .{v}),
            .nil => std.debug.print("nil", .{}),
        }
    }
};

pub const ValueArray = struct {
    values: std.ArrayList(Value),
    allocator: Allocator,

    pub fn init(allocator: Allocator) ValueArray {
        return ValueArray{
            .values = .empty,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ValueArray) void {
        self.values.deinit(self.allocator);
    }

    pub fn write(self: *ValueArray, value: Value) !void {
        try self.values.append(self.allocator, value);
    }
};

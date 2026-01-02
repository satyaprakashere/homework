const std = @import("std");
const base = @import("base.zig");
const Allocator = std.mem.Allocator;

fn constf(comptime T: type, y: *T, _: anytype) T {
    return y.*;
}

pub fn constant(comptime T: type, x: T) base.Closure(T) {
    return base.Closure(T).init(&x, constf);
}

pub fn succInt(x: i32) i32 {
    return x +% 1;
}

fn succf(comptime T: type, comptime U: type, x: T, args: []U(T)) base.recursive(T, U) {
    return U(T).successor(x, args);
}

pub fn succ(comptime T: type, comptime U: type) base.Closure(T, U) {
    return base.recursive(T, U).init(succf);
}

pub fn projection(comptime T: type, slice: []const T, i: usize) ?T {
    return slice[i];
}

pub fn compose(comptime T: type, comptime U: type , comptime V: type, allocator: Allocator,
    h: *const fn ([]const U) V, gs: []*const fn ([]const T) U) Fn2Closure(T, U, V) {

    const ClosureType = Fn2Closure(T, U, V);
    const closure = ClosureType.init(allocator, gs, h);
    return closure;
}

fn tuple(comptime types: anytype) type {
    return std.meta.Tuple(types);
}

fn tuples(comptime types: []type) type {
    return std.meta.Tuple(types);
}

fn getReturnTypes(comptime funcs: anytype) type {
    const FuncSlice = @TypeOf(funcs);
    const func_type_info = @typeInfo(FuncSlice);

    // Get the child type (the function pointer type)
    const FuncPtr = func_type_info.pointer.child;
    const func_info = @typeInfo(FuncPtr);

    // Extract the return type from the function
    const ReturnType = func_info.@"fn".return_type.?;

    // Create a slice of return types (array of the return type)
    var types: [funcs.len]type = undefined;
    for (0..funcs.len) |i| {
        types[i] = ReturnType;
    }

    return std.meta.Tuple(&types);
}

pub fn composeT(comptime T: anytype, comptime U: anytype , comptime V: type, allocator: Allocator,
    h: *const fn ([]const U) V, gs: []*const fn (tuple(T)) U) Fn2Closure(T, U, V) {

    const ClosureType = Fn2Closure(T, U, V);
    const closure = ClosureType.init(allocator, gs, h);
    return closure;
}

pub fn Fn2Closure(comptime T: type, comptime U: type, comptime V: type) type {
    return struct {
        allocator: Allocator,
        gs: []*const fn ([]const T) U,
        h: *const fn ([]const U) V,

        pub fn init(allocator: Allocator, ctx: []*const fn ([]const T) U, func: *const fn ([]const U) V) @This() {
            return Fn2Closure(T, U, V){ .gs = ctx, .h = func, .allocator = allocator };
        }

        pub fn call(self: @This(), args: []const T) Allocator.Error!V {
            var result = try self.allocator.alloc(U, self.gs.len);
            for (self.gs, 0..) |g, i| {
                result[i] = g(args);
            }
            defer self.allocator.free(result);
            return self.h(result);
        }
    };
}

// fn primitiveOperator() anytype {undefined}

// fn muOperator() anytype {undefined}

pub fn main() !void {
    std.debug.print("Constant fun : {} \n", .{ constant(i32, 20).call(.{ 7, 8 }) });
}

fn sum(nums: []const i64) i64 {
    var total: i64 = 0;
    for (nums) |n| {
        total += n;
    }
    return total;
}

fn add(nums: []const i64) i64 {
    return nums[0] +% nums[1];
}

fn mult(nums: []const i32) i64 {
    return nums[0] *% nums[0];
}

fn square(allocator: Allocator, nums: []const i32) Allocator.Error![]i64 {
    var result = try allocator.alloc(i64, nums.len);
    for (nums, 0..) |num, i| {
        result[i] = num * num;
    }
    return result;
}

fn sqr(num: i32) i64 {
    const num64: i64 = num;
    return num64 * num64;
}

fn id(comptime T: type) type {
    return T;
}

test "Constant" {
    try std.testing.expectEqual(constant(i32, 20).call(.{ 7, 8 }), 20);
}

test "Successor for int32" {
    try std.testing.expectEqual(10, succInt(9));
}

test "Projection" {
    try std.testing.expectEqual(projection(i32, &[_]i32{ 1, 2, 3 }, 1).?, 2);
}

test "Compose" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var funcs = [_]*const fn ([]i32) i64 {&mult, &mult};
    var f = compose(i32, i64, i64, allocator, sum, &funcs);
    var args = try allocator.alloc(i32, 2);
    args[0] = 3;
    args[1] = 4;
    defer allocator.free(args);

    try std.testing.expectEqual(18, f.call(args));
}

test "Primitive Recursion" {

}

test "MU Operator" {

}

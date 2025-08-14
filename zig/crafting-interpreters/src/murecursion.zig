const std = @import("std");
const base = @import("base.zig");

fn constf(comptime T: type, y: *T, _: anytype) T {
    return y.*;
}

pub fn constant(comptime T: type, x: T) base.Closure(T) {
    return base.Closure(T).init(&x, constf);
}

fn succf(comptime T: type, comptime U: type, x: T, args: []U(T)) base.Recursive(T, U) {
    return U(T).successor(x, args);
}

pub fn succ(comptime T: type, comptime U: type) fn (T, []U(T)) U(T) {
    return base.Recursive(T, U).init(succf);
}

pub fn projection(comptime T: type, slice: []const T, i: usize) ?T {
    return slice[i];
}

pub fn compose(comptime T: type, comptime U: fn (type) type , comptime V: type, h: fn ([]U(T)) T, gs: []fn (V) U(T), args: V) T {
    const res = (base.map(U(T), T, gs, apply(T, U, V, args)));
    return @call(.auto, h, .{res[0]});
}

fn lambdaG(comptime R: type, comptime Ctx: type, x: *const Ctx, g: fn (Ctx) R) R {
    return @call(.auto, g, x);
}

fn apply(comptime T: type, comptime U: fn (type) type, comptime V: type, x: V) fn (fn (V) U(T)) U(T) {
    return base.FnClosure(U(T), V).init(&x, lambdaG).call;
}

// fn primitiveOperator() anytype {undefined}

// fn muOperator() anytype {undefined}

pub fn main() !void {
    std.debug.print("Constant fun : {} \n", .{constant(i32, 20).call(.{ 7, 8 })});
}

fn add(a: i64, b: i64) i64 {
    return a + b;
}

fn mult(a: i32, b: i32) i64 {
    return a * b;
}

fn square(nums: []i64) i64 {
    return mult(nums[0], nums[0]);
}

fn id(comptime T: type) type {
    return T;
}

test "Constant" {
    try std.testing.expectEqual(constant(i32, 20).call(.{ 7, 8 }), 20);
}

test "Succ" {

}

test "Projection" {
    try std.testing.expectEqual(projection(i32, &[_]i32{ 1, 2, 3 }, 1).?, 2);
}

test "Compose" {
    // try std.testing.expectEqual(25, compose(i64, id, i32, square, {mult}, .{3, 4}));
}

test "Primitive Recursion" {

}

test "MU Operator" {

}

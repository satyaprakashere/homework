const std = @import("std");

pub const Num = i64;
pub const NumArray = []Num;

pub fn initNumArray() NumArray {
    return NumArray{};
}

pub fn writeNumArray(array: NumArray, num: Num) NumArray {
    array.append(num);
    return array;
}

pub fn freeNumArray(array: NumArray) void {
    array.deinit();
}

pub fn map(
    comptime T: type,
    comptime U: type,
    input: []const T,
    f: fn (T) U,
) []U {
    const allocator = std.heap.page_allocator;
    var output = allocator.alloc(U, input.len) catch unreachable;

    for (input, 0..) |item, i| {
        output[i] = f(item);
    }
    return output;
}

pub fn Closure(comptime Ctx: type) type {
    return struct {
        ctx: *const Ctx,
        func: fn (comptime type, *const Ctx, anytype) Ctx,

        pub fn init(ctx: *const Ctx, func: fn (comptime type, *const Ctx, anytype) Ctx) Closure(Ctx) {
            return Closure(Ctx){ .ctx = ctx, .func = func };
        }

        pub fn call(self: @This(), args: anytype) Ctx {
            return self.func(Ctx, self.ctx, args);
        }
    };
}

pub fn FnClosure(comptime R: type, Ctx: type) type {
    return struct {
        ctx: *const Ctx,
        func: fn (comptime type, comptime type, *const Ctx, fn (Ctx) R) R,

        pub fn init(ctx: *const Ctx, func: fn (comptime type, *const Ctx, fn (Ctx) R) R) Closure(R, Ctx) {
            return Closure(Ctx){ .ctx = ctx, .func = func };
        }

        pub fn call(self: @This(), args: fn (Ctx) R) R {
            return self.func(R, Ctx, self.ctx, args);
        }
    };
}

pub fn recursive(comptime T: type, comptime U: type) type {
    return struct {
        func: fn (comptime type, comptime type, T, []U(T)) U(T),

        pub fn init(func: fn (comptime type, comptime type, T, []U(T)) U(T)) Closure(T, U) {
            return Closure(T){ .func = func };
        }

        pub fn call(self: @This(), x: T, args: []U(T)) U(T) {
            return self.func(T, U, x, args);
        }
    };
}

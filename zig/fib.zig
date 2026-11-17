const std = @import("std");

const nat = u32;

pub fn main() !void {
    const n = 98765432;
    const result = fib(n);
    std.debug.print("The {d}th Fibonacci number is {d}\n", .{ n, result });
}

fn fib(n: nat) nat {
    return fibH(0, 1, n);
}

fn fibH(a: nat, b: nat, n: nat) nat {
    if (n == 0) {
        return a;
    } else {
        return @call(.always_tail, fibH, .{ b, (a +% b), n - 1 });
    }
}

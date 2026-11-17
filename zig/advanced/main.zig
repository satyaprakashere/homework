const std = @import("std");
const comptime_demo = @import("comptime_demo.zig");
const runtime_error_demo = @import("runtime_error_demo.zig");
const memory_demo = @import("memory_demo.zig");
const concurrency_demo = @import("concurrency_demo.zig");

pub fn main() !void {
    std.debug.print("=== Zig Advanced Learning Lab ===\n", .{});

    std.debug.print("\n--- Comptime Demo ---\n", .{});
    try comptime_demo.runComptimeDemo();

    std.debug.print("\n--- Runtime Error Demo ---\n", .{});
    try runtime_error_demo.runRuntimeErrorDemo();

    std.debug.print("\n--- Memory Demo ---\n", .{});
    try memory_demo.runMemoryDemo();

    std.debug.print("\n--- Concurrency Demo ---\n", .{});
    try concurrency_demo.runConcurrencyDemo();

    std.debug.print("\n=== Lab Complete ===\n", .{});
}

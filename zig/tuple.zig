const std = @import("std");

const MyTuple = struct { i32, f32, bool };
const tuple: MyTuple = .{ 1, 2.5, true };
const tuple2 = .{tuple, tuple, tuple};

pub fn main() !void {
	// Access elements
	std.debug.print("First: {d}\n", .{tuple[0]});
	std.debug.print("Second: {d}\n", .{tuple[1]});
	std.debug.print("Third: {}\n", .{tuple[2]});
	
	std.debug.print("First: {d}\n", .{tuple2[0][0]});
	std.debug.print("Second: {d}\n", .{tuple2[1][0]});
}

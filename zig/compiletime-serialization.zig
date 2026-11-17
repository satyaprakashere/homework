const std = @import("std");

const Shape = union(enum) {
    Circle: f64,
    Rectangle: struct {
        width: f64,
        height: f64,
    },
};

fn serializeType(comptime T: type) []const u8 {
    const info = @typeInfo(T);
    var buf: [256]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);

    switch (info) {
        .@"union" => |union_info| {
            w.print("union {s} {{\n", .{@typeName(T)}) catch unreachable;
            for (union_info.field_names, union_info.field_types) |field_name, field_type| {
                w.print("  {s}: ", .{field_name}) catch unreachable;
                switch (@typeInfo(field_type)) {
                    .float => w.print("f64", .{}) catch unreachable,
                    .@"struct" => |struct_info| {
                        w.print("struct {{ ", .{}) catch unreachable;
                        for (struct_info.field_names) |sf_name| {
                            w.print("{s}: f64; ", .{sf_name}) catch unreachable;
                        }
                        w.print("}}", .{}) catch unreachable;
                    },
                    else => w.print("unknown", .{}) catch unreachable,
                }
                w.print(";\n", .{}) catch unreachable;
            }
            w.print("}}", .{}) catch unreachable;
        },
        else => w.print("unknown type", .{}) catch unreachable,
    }
    const buffered = w.buffered();
    const final_str: [buffered.len]u8 = buffered[0..buffered.len].*;
    return &final_str;
}

pub fn main() void {
    const shape_type_str = comptime serializeType(Shape);
    std.debug.print("Shape type info:\n{s}\n", .{shape_type_str});
}

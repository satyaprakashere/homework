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
    var fbs = std.io.fixedBufferStream(&buf);
    const w = fbs.writer();

    switch (info) {
        .@"union" => |union_info| {
            w.print("union {} {{\n", .{@typeName(T)}) catch unreachable;
            for (union_info.fields) |field| {
                w.print("  {}: ", .{field.name}) catch unreachable;
                switch (@typeInfo(field.field_type)) {
                    .Float => w.print("f64", .{}) catch unreachable,
                    .Struct => |struct_info| {
                        w.print("struct {{ ", .{}) catch unreachable;
                        for (struct_info.fields) |sf| {
                            w.print("{}: f64; ", .{sf.name}) catch unreachable;
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
    return buf[0..fbs.pos];
}

pub fn main() void {
    const shape_type_str = serializeType(Shape);
    std.debug.print("Shape type info:\n{s}\n", .{shape_type_str});
}

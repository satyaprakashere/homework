const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var dir = try std.fs.cwd().openDir("tests", .{ .iterate = true });
    defer dir.close();

    var walker = dir.iterate();
    var failed: bool = false;

    while (try walker.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".scm")) continue;

        std.debug.print("Running {s}...", .{entry.name});

        const file = try dir.openFile(entry.name, .{});
        const source = try file.readToEndAlloc(allocator, 1024 * 1024);
        file.close();
        defer allocator.free(source);

        // Find expected output
        var expected: ?[]const u8 = null;
        var lines = std.mem.splitScalar(u8, source, '\n');
        while (lines.next()) |line| {
            if (std.mem.indexOf(u8, line, "; expect: ")) |idx| {
                expected = line[idx + "; expect: ".len ..];
                break;
            }
        }

        if (expected) |exp| {
            // Run the interpreter
            const result = try std.process.Child.run(.{
                .allocator = allocator,
                .argv = &[_][]const u8{ "zig", "run", "src/main.zig", "--", try std.fs.path.join(allocator, &[_][]const u8{ "tests", entry.name }) },
            });
            defer allocator.free(result.stdout);
            defer allocator.free(result.stderr);

            const trimmed_out = std.mem.trim(u8, result.stdout, " \n\r");
            const trimmed_exp = std.mem.trim(u8, exp, " \n\r");

            if (!std.mem.eql(u8, trimmed_out, trimmed_exp)) {
                std.debug.print(" FAIL\nExpected: '{s}'\nGot: '{s}'\n", .{ trimmed_exp, trimmed_out });
                failed = true;
            } else {
                std.debug.print(" OK\n", .{});
            }
        } else {
            std.debug.print(" SKIP (no expectation)\n", .{});
        }
    }

    if (failed) std.process.exit(1);
}

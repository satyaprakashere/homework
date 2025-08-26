const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "recur",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.graph.host,
        }),
    });

    // exe.addCSourceFile(.{ .file = b.path("lib/memory.c") });
    // exe.addIncludePath(b.path("lib"));
    // exe.linkLibC();

    // const graph = b.dependency(
    //     "graph",
    //     .{ .target = target, .optimize = optimize },
    // );

    // exe.root_module.addImport("graph", graph.module("graph"));

    b.installArtifact(exe);
    const run_exe = b.addRunArtifact(exe);

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}

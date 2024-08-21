const std = @import("std");

fn pkgConfig(b: *std.Build, exe: *std.Build.Step.Compile) !void {
    _ = b;

    const argv = [_][]const u8{ "pkg-config", "--cflags", "--libs", "gtk+-3.0", "vte-2.91" };
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    defer if (gpa.deinit() == .leak) {
        @panic("mem leaked");
    };

    const allocator = gpa.allocator();

    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &argv,
    });

    defer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }

    var it = std.mem.tokenize(u8, result.stdout, " ");

    while (it.next()) |parameter| {
        const trimmed_parameter = std.mem.trim(u8, parameter, "\n");

        // prevents the current flag of being a single \n and have no content.
        if (std.mem.eql(u8, trimmed_parameter, "")) {
            continue;
        }

        var value = parameter[2..];

        if (std.mem.endsWith(u8, value, "\n")) {
            value = value[0 .. value.len - 1];
        }

        if (std.mem.startsWith(u8, parameter, "-I")) {
            exe.addIncludePath(.{ .cwd_relative = value });
        } else if (std.mem.startsWith(u8, parameter, "-l")) {
            exe.linkSystemLibrary(value);
        }
    }
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "Harakara",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();
    pkgConfig(b, exe) catch unreachable;

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

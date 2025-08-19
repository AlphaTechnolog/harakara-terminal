const std = @import("std");

const LinkPayload = struct {
    b: *std.Build,
    exe: *std.Build.Step.Compile,
    allocator: ?std.mem.Allocator = null,
    verbose: bool = false,
};

fn pkgConfigLink(comptime libs: anytype) fn (opts: LinkPayload) anyerror!void {
    const T = @TypeOf(libs);
    return struct {
        fn exer(opts: LinkPayload) anyerror!void {
            const libraries = @as(T, libs);
            const b = opts.b;
            const exe = opts.exe;
            const verbose = opts.verbose;
            const allocator = opts.allocator orelse b.allocator;

            const argv = [_][]const u8{ "pkg-config", "--cflags", "--libs" } ++ libraries;

            const result = try std.process.Child.run(.{
                .allocator = allocator,
                .argv = &argv,
            });

            defer {
                allocator.free(result.stdout);
                allocator.free(result.stderr);
            }

            if (result.term.Exited == 1) {
                const stderr = std.io.getStdErr().writer();
                const fmtted = try std.mem.join(allocator, ", ", &libraries);
                try stderr.print("Unable to link libraries: {s}\n", .{fmtted});
                try stderr.print("{s}\n", .{result.stderr});
                return error.UnableToLink;
            }

            var it = std.mem.tokenizeAny(u8, result.stdout, " ");
            while (it.next()) |parameter| {
                const trimmed = std.mem.trim(u8, parameter, "\n");
                if (trimmed.len == 0) continue;

                var value = parameter[2..];
                if (std.mem.endsWith(u8, value, "\n")) {
                    value = value[0 .. value.len - 1];
                }

                const stdout = std.io.getStdOut().writer();
                if (std.mem.startsWith(u8, parameter, "-I")) {
                    if (verbose) try stdout.print("-> include('{s}');\n", .{value});
                    exe.addIncludePath(.{ .cwd_relative = value });
                } else if (std.mem.startsWith(u8, parameter, "-l")) {
                    if (verbose) try stdout.print("-> link('{s}');\n", .{value});
                    exe.linkSystemLibrary(value);
                }
            }
        }
    }.exer;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "harakara_terminal",
        .root_module = exe_mod,
    });

    const verbose = b.option(bool, "verbose-build", "Enable verbosity during build") orelse false;
    exe.linkLibC();

    pkgConfigLink([_][]const u8{ "gtk+-3.0", "vte-2.91" })(.{
        .b = b,
        .exe = exe,
        .verbose = verbose,
    }) catch unreachable;

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");

    test_step.dependOn(&run_exe_unit_tests.step);
}

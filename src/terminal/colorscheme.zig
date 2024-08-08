const std = @import("std");
const Terminal = @import("./init.zig");

const mem = std.mem;
const posix = std.posix;
const debug = std.debug;
const process = std.process;
const fs = std.fs;
const ArrayList = std.ArrayList;

const Self = @This();

allocator: mem.Allocator,
terminal: *Terminal,

pub fn init(allocator: mem.Allocator, terminal: *Terminal) Self {
    return Self{
        .terminal = terminal,
        .allocator = allocator,
    };
}

fn createFolderIfPossible(dirname: []const u8) !fs.Dir {
    posix.mkdir(dirname, 0o755) catch |err| {
        if (err != posix.MakeDirError.PathAlreadyExists)
            @panic(@errorName(err));

        return try fs.openDirAbsolute(dirname, .{ .access_sub_paths = false });
    };

    return try fs.openDirAbsolute(dirname, .{ .access_sub_paths = false });
}

fn createConfigFiles(_: Self, dirname_path: []u8) !void {
    const config_folder = try createFolderIfPossible(dirname_path);

    const config_file = try config_folder.createFile("./config.toml", .{
        .read = true,
        .truncate = false,
        .exclusive = false,
        .mode = 0o644,
    });

    defer config_file.close();

    var buf: [1024]u8 = undefined;
    const size = try config_file.readAll(buf[0..]);
    const contents = buf[0..size];

    if (std.mem.eql(u8, contents, "")) {
        // try config_file.writeAll("hello world");
    }
}

pub fn setup(self: Self) !void {
    const home = posix.getenv("HOME") orelse @panic("HOME missing");
    var config_dir = ArrayList(u8).init(self.allocator);
    defer config_dir.deinit();

    try config_dir.appendSlice(home);
    try config_dir.appendSlice("/.config/harakara");

    self.createConfigFiles(config_dir.items) catch |err| {
        debug.panic(
            "[{s}] Unable to create default config files\n",
            .{@errorName(err)},
        );

        process.exit(1);
    };
}

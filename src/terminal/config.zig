const std = @import("std");
const toml = @import("../extern/toml.zig");

const mem = std.mem;
const fs = std.fs;
const debug = std.debug;
const posix = std.posix;
const ArrayList = std.ArrayList;

const assert = debug.assert;
const eql = mem.eql;

const Self = @This();

allocator: mem.Allocator,

pub const Parser = struct {
    allocator: mem.Allocator,
    contents: []u8,
    result: ?*Result,

    pub const Result = struct {
        allocator: mem.Allocator,

        font: struct {
            family: ?[]u8,
            size: i64,
        },

        pub fn init(allocator: mem.Allocator) !*Result {
            var instance = try allocator.create(Result);
            instance.allocator = allocator;
            instance.font = .{ .family = null, .size = 0 };
            return instance;
        }

        pub fn deinit(self: *Result) void {
            if (self.font.family) |family| {
                self.allocator.free(family);
            }

            self.allocator.destroy(self);
        }
    };

    pub fn init(allocator: mem.Allocator, contents: []u8) Parser {
        return Parser{
            .allocator = allocator,
            .contents = contents,
            .result = null,
        };
    }

    fn parseFont(self: *Parser, table: *toml.Table) !void {
        if (table.keys.get("font")) |font| {
            assert(font == .Table);

            if (font.Table.keys.get("family")) |family| {
                assert(family == .String);

                self.result.?.font.family = try self.allocator.dupe(
                    u8,
                    family.String,
                );
            }

            if (font.Table.keys.get("size")) |size| {
                assert(size == .Integer);
                self.result.?.font.size = size.Integer;
            }
        }
    }

    // implement proper config parsing error handler, something like
    // a popup might be *Awesome!*.
    fn handleError(_: Parser, err: anyerror) void {
        const errcode = @as([]const u8, @errorName(err));
        const stdout = std.io.getStdOut().writer();
        stdout.print("Error code {s} occurred!\n", .{errcode}) catch unreachable;
    }

    pub fn parse(self: *Parser) !*Result {
        self.result = try Result.init(self.allocator);

        var parser = try toml.parseContents(
            self.allocator,
            self.contents,
        );

        defer parser.deinit();

        var table = try parser.parse();
        defer table.deinit();

        self.parseFont(table) catch |err| self.handleError(err);

        return self.result orelse @panic("result was not initialised");
    }
};

pub fn init(allocator: mem.Allocator) Self {
    return Self{ .allocator = allocator };
}

fn createFolderIfPossible(dirname: []const u8) !fs.Dir {
    posix.mkdir(dirname, 0o755) catch |err| {
        if (err != posix.MakeDirError.PathAlreadyExists)
            @panic(@errorName(err));

        return try fs.openDirAbsolute(dirname, .{ .access_sub_paths = false });
    };

    return try fs.openDirAbsolute(dirname, .{
        .access_sub_paths = false,
    });
}

fn createConfigFiles(self: Self, dirname_path: []u8) ![]u8 {
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

    if (eql(u8, contents, "")) {
        const new_content = @embedFile("../resources/config.toml");
        try config_file.writeAll(new_content);
        return try self.allocator.dupe(u8, new_content);
    }

    return try self.allocator.dupe(u8, contents);
}

pub fn parse(self: Self) !*Parser.Result {
    const home = posix.getenv("HOME") orelse @panic("$HOME missing");
    var config_dir = ArrayList(u8).init(self.allocator);
    defer config_dir.deinit();

    try config_dir.appendSlice(home);
    try config_dir.appendSlice("/.config/harakara");

    const config = self.createConfigFiles(config_dir.items) catch |err| {
        debug.panic(
            "[{s}] Unable to create config files!\n",
            .{@errorName(err)},
        );
    };

    defer self.allocator.free(config);

    var parser = Parser.init(self.allocator, config);
    return try parser.parse();
}

const std = @import("std");
const toml = @import("../extern/toml.zig");

const mem = std.mem;
const fs = std.fs;
const debug = std.debug;
const posix = std.posix;
const ArrayList = std.ArrayList;

const eql = mem.eql;

const Self = @This();

allocator: mem.Allocator,

pub const Parser = struct {
    allocator: mem.Allocator,
    contents: []u8,
    result: ?*Result,

    const ColorsResult = struct {
        black: ?[]u8,
        blue: ?[]u8,
        cyan: ?[]u8,
        green: ?[]u8,
        magenta: ?[]u8,
        red: ?[]u8,
        white: ?[]u8,
        yellow: ?[]u8,
    };

    pub const Result = struct {
        allocator: mem.Allocator,

        font: struct {
            family: ?[]u8,
            size: i64,
        },

        window: struct {
            padding: ?i64,
        },

        cursor: struct {
            shape: ?[]u8,
            blinking: bool,
        },

        colors: struct {
            background: ?[]u8,
            foreground: ?[]u8,
            normal: ColorsResult,
            bright: ColorsResult,

            extra: struct {
                zoom_indicator: ?[]u8,
            },
        },

        pub fn init(allocator: mem.Allocator) !*Result {
            var instance = try allocator.create(Result);

            instance.allocator = allocator;
            instance.font = .{ .family = null, .size = 0 };
            instance.cursor = .{ .shape = null, .blinking = true };
            instance.window = .{ .padding = null };

            instance.colors = .{
                .background = null,
                .foreground = null,
                .extra = .{ .zoom_indicator = null },
                .normal = .{
                    .black = null,
                    .blue = null,
                    .cyan = null,
                    .green = null,
                    .magenta = null,
                    .red = null,
                    .white = null,
                    .yellow = null,
                },
                .bright = .{
                    .black = null,
                    .blue = null,
                    .cyan = null,
                    .green = null,
                    .magenta = null,
                    .red = null,
                    .white = null,
                    .yellow = null,
                },
            };

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

    const ParsingError = error{
        InvalidSchema,
        InvalidCursor,
    };

    fn assert(cond: bool) ParsingError!void {
        if (!cond) {
            return error.InvalidSchema;
        }
    }

    fn parseFont(self: *Parser, table: *toml.Table) !void {
        if (table.keys.get("font")) |font| {
            try assert(font == .Table);

            if (font.Table.keys.get("family")) |family| {
                try assert(family == .String);

                self.result.?.font.family = try self.allocator.dupe(
                    u8,
                    family.String,
                );
            }

            if (font.Table.keys.get("size")) |size| {
                try assert(size == .Integer);
                self.result.?.font.size = size.Integer;
            }
        }
    }

    inline fn dupString(
        self: *Parser,
        into: *?[]u8,
        value_ref: *const []const u8,
    ) !void {
        const allocator = self.allocator;
        into.* = try allocator.dupe(u8, value_ref.*);
    }

    fn parseTermColors(
        self: *Parser,
        table: *const toml.Value,
        colors: *ColorsResult,
    ) !void {
        try assert(table.* == .Table);

        if (table.*.Table.keys.get("black")) |black| {
            try assert(black == .String);
            try self.dupString(&colors.*.black, &black.String);
        }

        if (table.*.Table.keys.get("blue")) |blue| {
            try assert(blue == .String);
            try self.dupString(&colors.*.blue, &blue.String);
        }

        if (table.*.Table.keys.get("cyan")) |cyan| {
            try assert(cyan == .String);
            try self.dupString(&colors.*.cyan, &cyan.String);
        }

        if (table.*.Table.keys.get("green")) |green| {
            try assert(green == .String);
            try self.dupString(&colors.*.green, &green.String);
        }

        if (table.*.Table.keys.get("magenta")) |magenta| {
            try assert(magenta == .String);
            try self.dupString(&colors.*.magenta, &magenta.String);
        }

        if (table.*.Table.keys.get("red")) |red| {
            try assert(red == .String);
            try self.dupString(&colors.*.red, &red.String);
        }

        if (table.*.Table.keys.get("white")) |white| {
            try assert(white == .String);
            try self.dupString(&colors.*.white, &white.String);
        }

        if (table.*.Table.keys.get("yellow")) |yellow| {
            try assert(yellow == .String);
            try self.dupString(&colors.*.yellow, &yellow.String);
        }
    }

    fn parseCursor(self: *Parser, table: *toml.Table) !void {
        if (table.keys.get("cursor")) |cursor| {
            try assert(cursor == .Table);

            if (cursor.Table.keys.get("shape")) |shape| {
                try assert(shape == .String);

                const valid_cursors = [_][]const u8{
                    "block",
                    "ibeam",
                    "underline",
                };

                var ok = false;

                for (valid_cursors) |element| {
                    if (std.mem.eql(u8, element, shape.String)) {
                        ok = true;
                        break;
                    }
                }

                if (!ok) {
                    return error.InvalidCursor;
                }

                self.result.?.cursor.shape = try self.allocator.dupe(
                    u8,
                    shape.String,
                );
            }

            if (cursor.Table.keys.get("blinking")) |blinking| {
                self.result.?.cursor.blinking = blinking.Boolean;
            }
        }
    }

    fn parseWindow(self: *Parser, table: *toml.Table) !void {
        if (table.keys.get("window")) |window| {
            try assert(window == .Table);

            if (window.Table.keys.get("padding")) |padding| {
                try assert(padding == .Integer);
                self.result.?.window.padding = padding.Integer;
            }
        }
    }

    fn parseColors(self: *Parser, table: *toml.Table) !void {
        if (table.keys.get("colors")) |colors| {
            try assert(colors == .Table);

            if (colors.Table.keys.get("background")) |background| {
                try assert(background == .String);
                self.result.?.colors.background = try self.allocator.dupe(
                    u8,
                    background.String,
                );
            }

            if (colors.Table.keys.get("foreground")) |foreground| {
                try assert(foreground == .String);
                self.result.?.colors.foreground = try self.allocator.dupe(
                    u8,
                    foreground.String,
                );
            }

            if (colors.Table.keys.get("extra")) |extra| {
                try assert(extra == .Table);

                if (extra.Table.keys.get("zoom-indicator")) |zoom_indicator| {
                    try assert(zoom_indicator == .String);
                    self.result.?.colors.extra.zoom_indicator = try self.allocator.dupe(
                        u8,
                        zoom_indicator.String,
                    );
                }
            }

            if (colors.Table.keys.get("normal")) |normal| {
                try self.parseTermColors(
                    &normal,
                    &self.result.?.colors.normal,
                );
            }

            if (colors.Table.keys.get("bright")) |bright| {
                try self.parseTermColors(
                    &bright,
                    &self.result.?.colors.bright,
                );
            }
        }
    }

    // implement proper config parsing error handler, something like
    // a popup might be *Awesome!*.
    fn handleError(_: Parser, err: anyerror) void {
        const errcode = @as([]const u8, @errorName(err));
        const stdout = std.io.getStdOut().writer();
        stdout.print("Error code '{s}' occurred!\n", .{errcode}) catch unreachable;
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
        self.parseCursor(table) catch |err| self.handleError(err);
        self.parseWindow(table) catch |err| self.handleError(err);
        self.parseColors(table) catch |err| self.handleError(err);

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
        const stderr = std.io.getStdErr().writer();
        try stderr.print("[INFO] Writing default config into ~/.config/harakara/config.toml!\n", .{});
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

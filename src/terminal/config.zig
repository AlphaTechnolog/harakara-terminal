const std = @import("std");
const builtin = @import("builtin");
const Config = @import("../extern/config.zig");

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

        pub fn deinit(self: *ColorsResult, alloc: std.mem.Allocator) void {
            inline for (std.meta.fields(@This())) |field| {
                if (field.type == ?[]u8) {
                    if (@field(self, field.name)) |*value| {
                        alloc.free(value.*);
                    }
                }
            }
        }
    };

    const Vector = struct {
        x: ?i64,
        y: ?i64,
    };

    pub const Result = struct {
        allocator: mem.Allocator,

        font: struct {
            family: ?[]u8,
            size: ?i64,

            pub fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
                if (self.family) |family| alloc.free(family);
            }
        },

        window: struct {
            padding: ?i64,
            default_dimensions: ?Vector,
        },

        cursor: struct {
            shape: ?[]u8,
            blinking: bool,

            pub fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
                if (self.shape) |shape| alloc.free(shape);
            }
        },

        colors: struct {
            background: ?[]u8,
            foreground: ?[]u8,
            normal: ColorsResult,
            bright: ColorsResult,

            extra: struct {
                zoom_indicator: ?[]u8,
            },

            pub fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
                if (self.background) |background| alloc.free(background);
                if (self.foreground) |foreground| alloc.free(foreground);
                self.normal.deinit(alloc);
                self.bright.deinit(alloc);
                if (self.extra.zoom_indicator) |indicator| alloc.free(indicator);
            }
        },

        pub fn init(allocator: mem.Allocator) !*Result {
            var instance = try allocator.create(Result);

            instance.allocator = allocator;
            instance.font = .{ .family = null, .size = null };
            instance.cursor = .{ .shape = null, .blinking = true };

            instance.window = .{
                .padding = null,
                .default_dimensions = null,
            };

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
            self.font.deinit(self.allocator);
            self.cursor.deinit(self.allocator);
            self.colors.deinit(self.allocator);
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

    const ParsingError = error{InvalidSchema};

    inline fn assert(cond: bool) ParsingError!void {
        if (!cond) {
            return error.InvalidSchema;
        }
    }

    pub fn parse(self: *Parser) !*Result {
        self.result = try Result.init(self.allocator);

        const alloc = self.allocator;

        var parsed = try Config.parseString(self.allocator, self.contents);
        defer parsed.deinit();

        if (parsed.get("font")) |font| {
            if (font.get("family")) |family| {
                try assert(family.value == .string);
                self.result.?.font.family = try alloc.dupe(u8, family.value.string);
            }
            if (font.get("size")) |size| {
                try assert(size.value == .int);
                self.result.?.font.size = size.value.int;
            }
        }

        if (parsed.get("cursor")) |cursor| {
            if (cursor.get("blinking")) |blinking| {
                try assert(blinking.value == .boolean);
                self.result.?.cursor.blinking = blinking.value.boolean;
            }
            if (cursor.get("shape")) |shape| {
                try assert(shape.value == .string);

                const valid_cursors = [_][]const u8{
                    "block",
                    "ibeam",
                    "underline",
                };

                const exists = ok: {
                    inline for (valid_cursors) |element| {
                        if (std.mem.eql(u8, element, shape.value.string)) {
                            break :ok true;
                        }
                    }
                    break :ok false;
                };

                try assert(exists);
                self.result.?.cursor.shape = try alloc.dupe(u8, shape.value.string);
            }
        }

        if (parsed.get("window")) |window| {
            if (window.get("padding")) |padding| {
                try assert(padding.value == .int);
                self.result.?.window.padding = padding.value.int;
            }
            const dimensions = &self.result.?.window.default_dimensions;
            if (dimensions.* == null) dimensions.* = .{ .x = null, .y = null };
            dimensions.*.?.x = w: {
                if (window.get("width")) |value| {
                    try assert(value.value == .int);
                    break :w value.value.int;
                }
                break :w null;
            };
            dimensions.*.?.y = h: {
                if (window.get("height")) |value| {
                    try assert(value.value == .int);
                    break :h value.value.int;
                }
                break :h null;
            };
        }

        if (parsed.get("colors")) |table| {
            var colors_table = self.result.?.colors;
            const colors = [_]struct { ptr: *?[]u8, key: []const u8 }{
                .{ .ptr = &colors_table.background, .key = "background" },
                .{ .ptr = &colors_table.foreground, .key = "foreground" },
                .{ .ptr = &colors_table.extra.zoom_indicator, .key = "zoom_indicator" },
                .{ .ptr = &colors_table.normal.black, .key = "black" },
                .{ .ptr = &colors_table.normal.blue, .key = "blue" },
                .{ .ptr = &colors_table.normal.cyan, .key = "cyan" },
                .{ .ptr = &colors_table.normal.cyan, .key = "cyan" },
                .{ .ptr = &colors_table.normal.green, .key = "green" },
                .{ .ptr = &colors_table.normal.magenta, .key = "magenta" },
                .{ .ptr = &colors_table.normal.red, .key = "red" },
                .{ .ptr = &colors_table.normal.white, .key = "white" },
                .{ .ptr = &colors_table.normal.yellow, .key = "yellow" },
                .{ .ptr = &colors_table.bright.black, .key = "bright_black" },
                .{ .ptr = &colors_table.bright.blue, .key = "bright_blue" },
                .{ .ptr = &colors_table.bright.cyan, .key = "bright_cyan" },
                .{ .ptr = &colors_table.bright.cyan, .key = "bright_cyan" },
                .{ .ptr = &colors_table.bright.green, .key = "bright_green" },
                .{ .ptr = &colors_table.bright.magenta, .key = "bright_magenta" },
                .{ .ptr = &colors_table.bright.red, .key = "bright_red" },
                .{ .ptr = &colors_table.bright.white, .key = "bright_white" },
                .{ .ptr = &colors_table.bright.yellow, .key = "bright_yellow" },
            };
            inline for (colors) |color| {
                if (table.get(color.key)) |config_color| {
                    try assert(config_color.value == .string);
                    color.ptr.* = try alloc.dupe(u8, config_color.value.string);
                }
            }
        }

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

    // tryna stat if possible, if the file doesn't exists we're gonna try to create it.
    const stat: ?std.fs.Dir.Stat = value: {
        break :value config_folder.statFile("config.cnf") catch |err| {
            if (err != error.FileNotFound) {
                return err;
            }

            break :value null;
        };
    };

    // if the file exists we'll just read it and return it immediately, without creating it.
    if (stat) |file_stat| {
        var config_file = try config_folder.openFile("config.cnf", .{});
        defer config_file.close();

        return try config_file.readToEndAlloc(
            self.allocator,
            file_stat.size,
        );
    }

    const config_file = try config_folder.createFile("./config.cnf", .{
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
        try stderr.print("[INFO] Writing default config into ~/.config/harakara/config.cnf!\n", .{});
        const new_content = @embedFile("../resources/config.cnf");
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

    if (builtin.mode == .Debug) {
        std.debug.print("Loading config file:\n{s}\n", .{
            config,
        });
    }

    var parser = Parser.init(self.allocator, config);
    return try parser.parse();
}

const std = @import("std");
const Config = @import("./config.zig");
const Terminal = @import("./init.zig");
const VteTerminal = @import("../lib/vte.zig");

const mem = std.mem;
const fmt = std.fmt;

const Self = @This();

allocator: mem.Allocator,
terminal: *Terminal,
config: *Config.Parser.Result,

pub fn init(allocator: mem.Allocator, terminal: *Terminal) !Self {
    const config = Config.init(allocator);

    return Self{
        .terminal = terminal,
        .allocator = allocator,
        .config = try config.parse(),
    };
}

fn setupFont(self: Self, terminal: *VteTerminal) !void {
    const font_format = try fmt.allocPrint(self.allocator, "{s} {d}", .{
        self.config.font.family orelse "monospace",
        self.config.font.size,
    });

    defer self.allocator.free(font_format);

    terminal.setFontFromString(@ptrCast(font_format));
}

pub fn setup(self: Self, terminal: *VteTerminal) !void {
    try self.setupFont(terminal);
}

pub fn deinit(self: *Self) void {
    self.config.deinit();
}

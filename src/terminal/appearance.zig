const std = @import("std");
const Config = @import("./config.zig");
const Terminal = @import("./init.zig");
const VteTerminal = @import("../lib/vte.zig");
const GdkRGBA = @import("../lib/gdk_rgba.zig");

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

fn setupColorscheme(self: Self, terminal: *VteTerminal) !void {
    const background_color: [:0]const u8 = @ptrCast(self.config.colors.background orelse "#141414");
    const foreground_color: [:0]const u8 = @ptrCast(self.config.colors.foreground orelse "#ffffff");

    var background_rgba = try GdkRGBA.fromFormat(background_color);
    var foreground_rgba = try GdkRGBA.fromFormat(foreground_color);

    try terminal.setColors(
        &foreground_rgba,
        &background_rgba,
        VteTerminal.TerminalColorPalette.fromConfig(self.config),
    );
}

pub fn setup(self: Self, terminal: *VteTerminal) !void {
    try self.setupFont(terminal);
    try self.setupColorscheme(terminal);
}

pub fn deinit(self: *Self) void {
    self.config.deinit();
}

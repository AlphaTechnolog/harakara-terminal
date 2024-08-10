const std = @import("std");
const Config = @import("./config.zig");
const VteTerminal = @import("../lib/vte.zig");
const GdkRGBA = @import("../lib/gdk_rgba.zig");

const mem = std.mem;
const fmt = std.fmt;

const Self = @This();

/// The used memory allocator object.
allocator: mem.Allocator,

/// The current terminal pointer instance.
terminal: *VteTerminal,

/// The configuration parser result ptr object.
config: *Config.Parser.Result,

/// Initialiases the appearance component
pub fn init(allocator: mem.Allocator, terminal: *VteTerminal) !Self {
    const config = Config.init(allocator);

    return Self{
        .terminal = terminal,
        .allocator = allocator,
        .config = try config.parse(),
    };
}

/// Setups the terminal font by using the parsed configuration file.
fn setupFont(self: Self) !void {
    const font_format = try fmt.allocPrint(self.allocator, "{s} {d}", .{
        self.config.font.family orelse "monospace",
        self.config.font.size,
    });

    defer self.allocator.free(font_format);

    self.terminal.setFontFromString(@ptrCast(font_format));
}

/// Setups the colorscheme of the terminal by using the parsed configuration file.
fn setupColorscheme(self: Self) !void {
    const background_color: [:0]const u8 = @ptrCast(self.config.colors.background orelse "#141414");
    const foreground_color: [:0]const u8 = @ptrCast(self.config.colors.foreground orelse "#ffffff");

    var background_rgba = try GdkRGBA.fromFormat(background_color);
    var foreground_rgba = try GdkRGBA.fromFormat(foreground_color);

    try self.terminal.setColors(
        &foreground_rgba,
        &background_rgba,
        VteTerminal.TerminalColorPalette.fromConfig(self.config),
    );
}

/// This function will start the process of applying the appearance-related
/// configurations to the terminal.
pub fn setup(self: Self) !void {
    try self.setupFont();
    try self.setupColorscheme();
}

/// Releases allocated memory from the config file.
pub fn deinit(self: *Self) void {
    self.config.deinit();
}

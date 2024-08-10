const c = @import("./c.zig");
const utils = @import("./utils.zig");
const enums = @import("./enums.zig");
const Widget = @import("./widget.zig");
const PangoFontDescription = @import("./pango_font_description.zig");
const GdkRGBA = @import("./gdk_rgba.zig");
const Config = @import("../terminal/config.zig");

const Self = @This();

ptr: *c.VteTerminal,

pub fn init() Self {
    return Self{
        .ptr = @as(*c.VteTerminal, @ptrCast(c.vte_terminal_new())),
    };
}

pub inline fn toRaw(self: Self) *c.VteTerminal {
    return self.ptr;
}

pub fn spawnAsync(
    self: Self,
    flags: enums.PtyFlags,
    wkgdir: ?[:0]const u8,
    command: [:0]const u8,
    env: ?[][:0]const u8,
    spawn_flags: enums.SpawnFlags,
    child_setup_func: ?c.GSpawnChildSetupFunc,
    timeout: c_int,
    cancellable: ?*c.GCancellable,
) void {
    c.vte_terminal_spawn_async(
        self.toRaw(),
        @intFromEnum(flags),
        if (wkgdir) |d| d.ptr else null,
        @as([*c][*c]c.gchar, @constCast(@ptrCast(&[2][*c]c.gchar{
            c.g_strdup(command.ptr),
            null,
        }))),
        if (env) |e| @as([*c][*c]u8, @ptrCast(e)) else null,
        @intFromEnum(spawn_flags),
        child_setup_func orelse null,
        @as(?*anyopaque, @ptrFromInt(@as(c_int, 0))),
        null,
        timeout,
        cancellable orelse null,
        null,
        @as(?*anyopaque, @ptrFromInt(@as(c_int, 0))),
    );
}

pub inline fn asWidget(self: Self) Widget {
    return Widget.init(@as(*c.GtkWidget, @ptrCast(self.toRaw())));
}

pub inline fn connect(
    self: Self,
    signal: [:0]const u8,
    callback: c.GCallback,
    data: ?c.gpointer,
) void {
    self.asWidget().connect(
        signal,
        callback,
        data,
    );
}

pub fn connectChildExited(
    self: Self,
    callback: c.GCallback,
    data: ?c.gpointer,
) void {
    self.connect(
        "child_exited",
        callback,
        data,
    );
}

pub fn setFont(self: Self, font: PangoFontDescription) void {
    c.vte_terminal_set_font(self.toRaw(), font.toRaw());
}

pub fn setFontFromString(self: Self, font: [:0]const u8) void {
    const value = PangoFontDescription.fromString(font);
    defer value.free();
    self.setFont(value);
}

pub fn setBoldIsBright(self: Self, value: bool) void {
    c.vte_terminal_set_bold_is_bright(
        self.toRaw(),
        utils.boolToCInt(value),
    );
}

pub const TerminalColorPalette = struct {
    normal: RegularColors,
    bright: RegularColors,

    const RegularColors = struct {
        black: ?[]u8,
        blue: ?[]u8,
        cyan: ?[]u8,
        green: ?[]u8,
        magenta: ?[]u8,
        red: ?[]u8,
        white: ?[]u8,
        yellow: ?[]u8,
    };

    // creates a new terminal color palette from a given color config
    pub fn fromConfig(config: *Config.Parser.Result) @This() {
        const config_value = config.*;

        return @This(){
            .normal = .{
                .black = config_value.colors.normal.black,
                .red = config_value.colors.normal.red,
                .green = config_value.colors.normal.green,
                .yellow = config_value.colors.normal.yellow,
                .blue = config_value.colors.normal.blue,
                .magenta = config_value.colors.normal.magenta,
                .cyan = config_value.colors.normal.cyan,
                .white = config_value.colors.normal.white,
            },
            .bright = .{
                .black = config_value.colors.bright.black,
                .red = config_value.colors.bright.red,
                .green = config_value.colors.bright.green,
                .yellow = config_value.colors.bright.yellow,
                .blue = config_value.colors.bright.blue,
                .magenta = config_value.colors.bright.magenta,
                .cyan = config_value.colors.bright.cyan,
                .white = config_value.colors.bright.white,
            },
        };
    }

    // converts a `TerminalColorPalette` into a vte terminal palette
    pub inline fn toVteFormat(self: TerminalColorPalette) ![*c]const c.GdkRGBA {
        var normal_black = try GdkRGBA.fromFormat(@ptrCast(self.normal.black orelse "#181818"));
        var normal_red = try GdkRGBA.fromFormat(@ptrCast(self.normal.red orelse "#ab4642"));
        var normal_green = try GdkRGBA.fromFormat(@ptrCast(self.normal.green orelse "#a1b56c"));
        var normal_yellow = try GdkRGBA.fromFormat(@ptrCast(self.normal.yellow orelse "#f7ca88"));
        var normal_blue = try GdkRGBA.fromFormat(@ptrCast(self.normal.blue orelse "#7cafc2"));
        var normal_magenta = try GdkRGBA.fromFormat(@ptrCast(self.normal.magenta orelse "#ba8baf"));
        var normal_cyan = try GdkRGBA.fromFormat(@ptrCast(self.normal.cyan orelse "#86c1b9"));
        var normal_white = try GdkRGBA.fromFormat(@ptrCast(self.normal.white orelse "#d8d8d8"));

        var bright_black = try GdkRGBA.fromFormat(@ptrCast(self.bright.black orelse "#242424"));
        var bright_red = try GdkRGBA.fromFormat(@ptrCast(self.bright.red orelse "#ab4642"));
        var bright_green = try GdkRGBA.fromFormat(@ptrCast(self.bright.green orelse "#a1b56c"));
        var bright_yellow = try GdkRGBA.fromFormat(@ptrCast(self.bright.yellow orelse "#f7ca88"));
        var bright_blue = try GdkRGBA.fromFormat(@ptrCast(self.bright.blue orelse "#7cafc2"));
        var bright_magenta = try GdkRGBA.fromFormat(@ptrCast(self.bright.magenta orelse "#ba8baf"));
        var bright_cyan = try GdkRGBA.fromFormat(@ptrCast(self.bright.cyan orelse "#86c1b9"));
        var bright_white = try GdkRGBA.fromFormat(@ptrCast(self.bright.white orelse "#d8d8d8"));

        const palette = [_]c.GdkRGBA{
            normal_black.toRaw(),
            normal_red.toRaw(),
            normal_green.toRaw(),
            normal_yellow.toRaw(),
            normal_blue.toRaw(),
            normal_magenta.toRaw(),
            normal_cyan.toRaw(),
            normal_white.toRaw(),
            bright_black.toRaw(),
            bright_red.toRaw(),
            bright_green.toRaw(),
            bright_yellow.toRaw(),
            bright_blue.toRaw(),
            bright_magenta.toRaw(),
            bright_cyan.toRaw(),
            bright_white.toRaw(),
        };

        return @as([*c]const c.GdkRGBA, @ptrCast(@alignCast(&palette)));
    }
};

pub fn setColors(
    self: Self,
    fg_color: *GdkRGBA,
    bg_color: *GdkRGBA,
    palette: TerminalColorPalette,
) !void {
    c.vte_terminal_set_colors(
        self.toRaw(),
        &fg_color.toRaw(),
        &bg_color.toRaw(),
        try palette.toVteFormat(),
        16,
    );
}

pub fn copyClipboardFormat(self: Self, format: enums.Format) void {
    c.vte_terminal_copy_clipboard_format(
        self.toRaw(),
        @intFromEnum(format),
    );
}

pub fn pastePrimary(self: Self) void {
    c.vte_terminal_paste_primary(self.toRaw());
}

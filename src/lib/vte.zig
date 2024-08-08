const c = @import("./c.zig");

const utils = @import("./utils.zig");
const enums = @import("./enums.zig");
const Widget = @import("./widget.zig");
const PangoFontDescription = @import("./pango_font_description.zig");

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

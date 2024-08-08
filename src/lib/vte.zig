const c = @import("./c.zig");
const enums = @import("./enums.zig");
const Widget = @import("./widget.zig");

const Self = @This();

ptr: *c.VteTerminal,

pub fn init() Self {
    return Self{
        .ptr = @as(*c.VteTerminal, @ptrCast(c.vte_terminal_new())),
    };
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
        self.ptr,
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
    return Widget.init(@as(*c.GtkWidget, @ptrCast(self.ptr)));
}

pub fn connectChildExited(
    self: Self,
    callback: ?*const fn (*c.VteTerminal, ?*anyopaque) void,
    data: ?c.gpointer,
) void {
    self.asWidget().connect(
        *c.VteTerminal,
        "child_exited",
        callback,
        data,
    );
}

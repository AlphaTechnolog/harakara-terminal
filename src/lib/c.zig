pub usingnamespace @cImport({
    @cInclude("gtk/gtk.h");
    @cInclude("vte/vte.h");
});

const c = @cImport({
    @cInclude("gtk/gtk.h");
    @cInclude("vte/vte.h");
});

/// Makes g_signal_connect work because of anyopaque types
pub fn gSignalConnect(instance: c.gpointer, detailed_signal: [*c]const c.gchar, c_handler: c.GCallback, data: c.gpointer) c.gulong {
    var zero: u32 = 0;
    const flags: *c.GConnectFlags = @ptrCast(&zero);
    return c.g_signal_connect_data(instance, detailed_signal, c_handler, data, null, flags.*);
}

/// same as with g_signal_connect_()
pub fn gSignalConnectSwapped(instance: c.gpointer, detailed_signal: [*c]const c.gchar, c_handler: c.GCallback, data: c.gpointer) c.gulong {
    return c.g_signal_connect_data(instance, detailed_signal, c_handler, data, null, c.G_CONNECT_SWAPPED);
}

// spawns async at a VteTerminal
// pub fn spawnAsync(
//     instance: *c.VteTerminal,
//     flags: PtyFlags,
//     wkgdir: ?[:0]const u8,
//     command: [:0]const u8,
//     env: ?[][:0]const u8,
//     spawn_flags: SpawnFlags,
//     child_setup_func: ?c.GSpawnChildSetupFunc,
//     timeout: c_int,
//     cancellable: ?*c.GCancellable,
// ) void {
//     c.vte_terminal_spawn_async(
//         instance,
//         @intFromEnum(flags),
//         if (wkgdir) |d| d.ptr else null,
//         @as([*c][*c]c.gchar, @ptrCast(&([2][*c]c.gchar{
//             c.g_strdup(command.ptr),
//             null,
//         }))),
//         if (env) |e| @as([*c][*c]u8, @ptrCast(e)) else null,
//         @intFromEnum(spawn_flags),
//         if (child_setup_func) |f| f else null,
//         @as(?*anyopaque, @ptrFromInt(@as(c_int, 0))),
//         null,
//         timeout,
//         if (cancellable) |cn| cn else null,
//         null,
//         @as(?*anyopaque, @ptrFromInt(@as(c_int, 0))),
//         // @intToPtr(?*anyopaque, @as(c_int, 0)),
//     );
// }

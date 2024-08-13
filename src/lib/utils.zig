const c = @import("./c.zig");

/// Converts a given boolean into a c_int value, useful when
/// dealing with gboolean types or others.
pub inline fn boolToCInt(boolean: bool) c_int {
    return @as(c_int, if (boolean) 1 else 0);
}

/// Converts a gboolean into a zig's native bool type.
pub inline fn gboolToBool(boolean: c.gboolean) bool {
    return boolean == 1;
}

/// Connects a given `gpointer` to a `detailed_signal` with the
/// given callback (`c_handler`) by passing a given `data`.
///
/// see: `utils.castGCallback`: To pass your callback.
/// see: `utils.castGPointer`: To pass your data.
/// see: `utils.castFromGPointer`: To retrieve your data from within your callback.
pub fn signalConnect(
    instance: c.gpointer,
    detailed_signal: [*c]const c.gchar,
    c_handler: c.GCallback,
    data: ?c.gpointer,
) c.gulong {
    var zero: u32 = 0;
    const flags: *c.GConnectFlags = @as(*c.GConnectFlags, @ptrCast(&zero));

    return c.g_signal_connect_data(
        instance,
        detailed_signal,
        c_handler,
        data orelse null,
        null,
        flags.*,
    );
}

/// Converts any function or any type into a c.GSourceFunc
/// by performing the needed casts to satisfy zig.
pub inline fn castGSourceFunc(callback: anytype) c.GSourceFunc {
    return @constCast(@ptrCast(@alignCast(&callback)));
}

/// Converts any function or any type into a c.GCallback
/// by performing the needed casts to satisfy zig.
pub inline fn castGCallback(callback: anytype) c.GCallback {
    return @constCast(@ptrCast(@alignCast(&callback)));
}

/// Converts any pointer into a `gpointer` by performing
/// the needed casts to satisfy zig.
pub inline fn castGPointer(element: anytype) c.gpointer {
    return @constCast(@ptrCast(element));
}

/// From a given `element (c.gpointer)` this will return a pointer
/// of the type `*T`. Useful when dealing with gpointers from within
/// c.GCallback objects.
pub inline fn castFromGPointer(
    comptime T: type,
    element: c.gpointer,
) *T {
    return @as(*T, @ptrCast(@alignCast(element)));
}

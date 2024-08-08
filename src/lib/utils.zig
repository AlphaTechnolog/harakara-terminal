const c = @import("./c.zig");

pub inline fn boolToCInt(boolean: bool) c_int {
    return @as(c_int, if (boolean) 1 else 0);
}

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

const c = @import("./c.zig");

const Self = @This();

pub fn add(
    interval: u32,
    c_handler: c.GSourceFunc,
    data: ?c.gpointer,
) u32 {
    return c.g_timeout_add(
        interval,
        c_handler,
        data orelse null,
    );
}

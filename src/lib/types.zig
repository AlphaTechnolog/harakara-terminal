const c = @import("./c.zig");

/// Reimplementation of the GdkEventKey type since it's broken
/// when using zig translate-c because of bitfields.
pub const GdkEventKey = extern struct {
    type: c.GdkEventType,
    window: ?*anyopaque,
    send_event: c.gint8,
    time: c.guint32,
    state: c.guint,
    keyval: c.guint,
    length: c.gint,
    string: [*c]c.gchar,
    hardware_keycode: c.guint16,
    group: c.guint8,
    is_modifier: c.guint,
};

/// Converts a given `*c.GdkEventKey` into a proper `*GdkEventKey`.
pub inline fn intoGdkEventKey(ptr: *c.GdkEventKey) *GdkEventKey {
    return @constCast(@alignCast(@ptrCast(ptr)));
}

const c = @import("./c.zig");

const Self = @This();

ptr: *c.GObject,

/// Initialiases a new gobject instance.
pub fn init(instance: *c.GObject) Self {
    return Self{
        .ptr = instance,
    };
}

/// Converts the given gobject into a `*c.GObject` ptr.
pub inline fn toRaw(self: Self) *c.GObject {
    return self.ptr;
}

/// Unrefs the current gobject instance.
pub fn unref(self: Self) void {
    c.g_object_unref(self.toRaw());
}

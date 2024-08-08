const c = @import("./c.zig");

const Self = @This();

ptr: *c.GObject,

pub fn init(instance: *c.GObject) Self {
    return Self{
        .ptr = instance,
    };
}

pub inline fn toRaw(self: Self) *c.GObject {
    return self.ptr;
}

pub fn unref(self: Self) void {
    c.g_object_unref(self.toRaw());
}

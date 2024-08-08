const c = @import("./c.zig");
const utils = @import("./utils.zig");
const enums = @import("./enums.zig");

const GObject = @import("./gobject.zig");
const GApplication = @import("./gapplication.zig");

const Self = @This();

ptr: *c.GtkApplication,

pub fn init(id: [*c]const u8, flags: enums.GApplicationFlags) Self {
    const flag: c_uint = @intFromEnum(flags);
    const app = c.gtk_application_new(id, flag) orelse @panic("invalid app!");
    return Self{ .ptr = app };
}

pub inline fn toRaw(self: Self) *c.GtkApplication {
    return self.ptr;
}

pub inline fn toGObject(self: Self) GObject {
    return GObject.init(@as(*c.GObject, @ptrCast(self.toRaw())));
}

pub inline fn toGApplication(self: Self) GApplication {
    return GApplication.init(@as(*c.GApplication, @ptrCast(
        self.toRaw(),
    )));
}

pub fn connect(
    self: Self,
    detailed_signal: [*c]const u8,
    callback: ?*const fn (*c.GtkApplication, ?*anyopaque) void,
    data: c.gpointer,
) c.gulong {
    return utils.signalConnect(
        *c.GtkApplication,
        self.toRaw(),
        detailed_signal,
        callback,
        data orelse null,
    );
}

const c = @import("./c.zig");
const utils = @import("./utils.zig");
const enums = @import("./enums.zig");

const GObject = @import("./gobject.zig");
const GApplication = @import("./gapplication.zig");

const Self = @This();

ptr: *c.GtkApplication,

/// Initialiases a new `Application` instance by using the provided
/// app id and app flags.
///
/// see: `enums.GApplicationFlags`: To see the available app flags.
pub fn init(id: [*c]const u8, flags: enums.GApplicationFlags) Self {
    const flag: c_uint = @intFromEnum(flags);
    const app = c.gtk_application_new(id, flag) orelse @panic("invalid app!");
    return Self{ .ptr = app };
}

/// Returns the raw `*c.GtkApplication` ptr.
pub inline fn toRaw(self: Self) *c.GtkApplication {
    return self.ptr;
}

/// Converts this `Application` into a `GObject`.
pub inline fn toGObject(self: Self) GObject {
    return GObject.init(@as(*c.GObject, @ptrCast(self.toRaw())));
}

/// Converts this `Application` into a `GApplication`.
pub inline fn toGApplication(self: Self) GApplication {
    return GApplication.init(@as(*c.GApplication, @ptrCast(
        self.toRaw(),
    )));
}

/// Connect this `Application` to a signal by using a detailed_signal,
/// a callback and given data to that callback.
///
/// see: `utils.castGCallback` for passing your callback
/// see: `utils.castFromGPointer` to receive your data from a gpointer
/// see: `utils.castGPointer` to pass your data as a gpointer
pub fn connect(
    self: Self,
    detailed_signal: [*c]const u8,
    callback: c.GCallback,
    data: c.gpointer,
) void {
    _ = utils.signalConnect(
        self.toRaw(),
        detailed_signal,
        callback,
        data orelse null,
    );
}

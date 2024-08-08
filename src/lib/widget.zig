const c = @import("./c.zig");
const utils = @import("./utils.zig");

const Self = @This();

ptr: *c.GtkWidget,

pub fn init(widget: *c.GtkWidget) Self {
    return Self{
        .ptr = widget,
    };
}

pub fn connect(
    self: Self,
    instance_type: type,
    sig: [:0]const u8,
    callback: ?*const fn (instance_type, ?*anyopaque) void,
    data: ?c.gpointer,
) void {
    _ = utils.signalConnect(
        instance_type,
        self.ptr,
        sig.ptr,
        callback,
        data,
    );
}

pub inline fn toRaw(self: Self) *c.GtkWidget {
    return self.ptr;
}

pub fn destroy(self: Self) void {
    c.gtk_widget_destroy(self.toRaw());
}

pub fn showAll(self: Self) void {
    c.gtk_widget_show_all(self.toRaw());
}

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
    sig: [:0]const u8,
    callback: c.GCallback,
    data: ?c.gpointer,
) void {
    _ = utils.signalConnect(
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

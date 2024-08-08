const c = @import("./c.zig");
const Widget = @import("./widget.zig");

const Self = @This();

ptr: *c.GtkContainer,

pub fn init(instance: *c.GtkContainer) Self {
    return Self{
        .ptr = instance,
    };
}

pub inline fn toRaw(self: Self) *c.GtkContainer {
    return self.ptr;
}

pub inline fn asWidget(self: Self) Widget {
    return Widget.init(@as(*c.GtkWidget, @ptrCast(self.toRaw())));
}

pub fn add(self: Self, widget: Widget) void {
    c.gtk_container_add(self.toRaw(), widget.toRaw());
}
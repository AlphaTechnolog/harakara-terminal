const c = @import("./c.zig");
const Widget = @import("./widget.zig");
const Container = @import("./container.zig");

const Self = @This();

ptr: [*c]c.GtkOverlay,

pub fn init() Self {
    return Self{
        .ptr = @as(*c.GtkOverlay, @ptrCast(c.gtk_overlay_new())),
    };
}

pub inline fn toRaw(self: Self) *c.GtkOverlay {
    return self.ptr;
}

pub inline fn asWidget(self: Self) Widget {
    return Widget.init(@as(*c.GtkWidget, @ptrCast(self.toRaw())));
}

pub inline fn asContainer(self: Self) Container {
    return Container.init(@as(*c.GtkContainer, @ptrCast(self.toRaw())));
}

pub fn addOverlay(self: Self, widget: Widget) void {
    c.gtk_overlay_add_overlay(self.toRaw(), widget.toRaw());
}

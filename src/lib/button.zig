const c = @import("./c.zig");
const Widget = @import("./widget.zig");
const Container = @import("./container.zig");

const Self = @This();

ptr: [*c]c.GtkButton,

pub fn init() Self {
    return Self{
        .ptr = @as(*c.GtkButton, @ptrCast(c.gtk_button_new())),
    };
}

pub inline fn toRaw(self: Self) *c.GtkButton {
    return self.ptr;
}

pub inline fn asWidget(self: Self) Widget {
    return Widget.init(@as(*c.GtkWidget, @ptrCast(self.toRaw())));
}

pub inline fn asContainer(self: Self) Container {
    return Container.init(@as(*c.GtkContainer, @ptrCast(self.toRaw())));
}

pub fn connect(
    self: Self,
    detailed_signal: [:0]const u8,
    c_handler: c.GCallback,
    user_data: ?c.gpointer,
) void {
    self.asWidget().connect(
        detailed_signal,
        c_handler,
        user_data,
    );
}

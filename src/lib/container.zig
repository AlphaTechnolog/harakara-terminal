const c = @import("./c.zig");
const Widget = @import("./widget.zig");

const Self = @This();

ptr: *c.GtkContainer,

/// Initialiases the current `Container` instance.
pub fn init(instance: *c.GtkContainer) Self {
    return Self{
        .ptr = instance,
    };
}

/// Returns the raw `*c.GtkContainer` ptr.
pub inline fn toRaw(self: Self) *c.GtkContainer {
    return self.ptr;
}

/// Converts the current `Container` into a `Widget` instance.
pub inline fn asWidget(self: Self) Widget {
    return Widget.init(@as(*c.GtkWidget, @ptrCast(self.toRaw())));
}

/// Add a given `Widget` to this `Container`.
pub fn add(self: Self, widget: Widget) void {
    c.gtk_container_add(self.toRaw(), widget.toRaw());
}

const c = @import("./c.zig");
const utils = @import("./utils.zig");

const Self = @This();

ptr: *c.GtkWidget,

/// Creates a new Widget instance from an already existent `*c.GtkWidget`.
pub fn init(widget: *c.GtkWidget) Self {
    return Self{
        .ptr = widget,
    };
}

/// Connects the widget to the given signal by passing a callback and
/// an user_data value.
///
/// see: `utils.castGCallback` for passing your callback
/// see: `utils.castFromGPointer` to receive your data from a gpointer
/// see: `utils.castGPointer` to pass your data as a gpointer
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

/// Converts this `Widget` instance into a raw `*c.GtkWidget` ptr.
pub inline fn toRaw(self: Self) *c.GtkWidget {
    return self.ptr;
}

/// Destroys this widget.
pub fn destroy(self: Self) void {
    c.gtk_widget_destroy(self.toRaw());
}

/// Shows all the widgets inside this widget.
pub fn showAll(self: Self) void {
    c.gtk_widget_show_all(self.toRaw());
}

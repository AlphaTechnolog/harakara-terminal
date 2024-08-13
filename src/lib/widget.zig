const c = @import("./c.zig");
const utils = @import("./utils.zig");
const enums = @import("./enums.zig");

const Self = @This();

ptr: *c.GtkWidget,

/// Creates a new Widget instance from an already existent `*c.GtkWidget`.
pub fn init(widget: *c.GtkWidget) Self {
    return Self{
        .ptr = widget,
    };
}

/// Sets the horizontal alignment of widget. See the GtkWidget:halign property.
pub fn setHAlign(self: Self, halign: enums.GtkAlign) void {
    c.gtk_widget_set_halign(self.toRaw(), @intFromEnum(halign));
}

/// Sets the vertical alignment of widget. See the GtkWidget:valign property.
pub fn setVAlign(self: Self, valign: enums.GtkAlign) void {
    c.gtk_widget_set_valign(self.toRaw(), @intFromEnum(valign));
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

/// Convenience function that just given a boolean, calls either show() or hide() in this widget
pub fn setVisible(self: Self, visibility: bool) void {
    c.gtk_widget_set_visible(
        self.toRaw(),
        utils.boolToCInt(visibility),
    );
}

/// Determines whether the widget is visible. If you want to take into account whether the widget’s parent is also marked as visible, use gtk_widget_is_visible() instead.
///
/// This function does not check if the widget is obscured in any way.
pub fn getVisible(self: Self) bool {
    return utils.gboolToBool(
        c.gtk_widget_get_visible(self.toRaw()),
    );
}

/// Determines whether the widget and all its parents are marked as visible.
///
/// This function does not check if the widget is obscured in any way.
pub fn isVisible(self: Self) bool {
    return utils.gboolToBool(
        c.gtk_widget_is_visible(self.toRaw()),
    );
}

/// Shows the current widget.
pub fn show(self: Self) void {
    c.gtk_widget_show(self.toRaw());
}

/// Hides the current widget
pub fn hide(self: Self) void {
    c.gtk_widget_hide(self.toRaw());
}

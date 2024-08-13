const std = @import("std");
const c = @import("./c.zig");
const Widget = @import("./widget.zig");

const Self = @This();

ptr: [*c]c.GtkLabel,

pub fn init(str: [:0]const u8) Self {
    return Self{
        .ptr = @as(*c.GtkLabel, @ptrCast(c.gtk_label_new(
            str.ptr,
        ))),
    };
}

pub inline fn toRaw(self: Self) *c.GtkLabel {
    return self.ptr;
}

pub inline fn asWidget(self: Self) Widget {
    return Widget.init(@as(*c.GtkWidget, @ptrCast(self.toRaw())));
}

pub fn setText(self: Self, str: []const u8) void {
    c.gtk_label_set_text(self.toRaw(), str.ptr);
}

pub fn getText(self: Self) []const u8 {
    return std.mem.span(
        c.gtk_label_get_text(self.toRaw()),
    );
}

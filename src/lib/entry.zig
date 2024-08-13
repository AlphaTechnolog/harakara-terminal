const std = @import("std");
const c = @import("./c.zig");
const Widget = @import("./widget.zig");

const Self = @This();

ptr: [*c]c.GtkEntry,

pub fn init() Self {
    return Self{
        .ptr = @as(*c.GtkEntry, @ptrCast(c.gtk_entry_new())),
    };
}

pub inline fn toRaw(self: Self) *c.GtkEntry {
    return self.ptr;
}

pub inline fn asWidget(self: Self) Widget {
    return Widget.init(@as(*c.GtkWidget, @ptrCast(self.toRaw())));
}

pub fn setPlaceholderText(self: Self, text: [:0]const u8) void {
    c.gtk_entry_set_placeholder_text(self.toRaw(), text.ptr);
}

pub fn getPlaceholderText(self: Self) []const u8 {
    return std.mem.span(
        c.gtk_entry_get_placeholder_text(self.toRaw()),
    );
}

pub fn getText(self: Self) []const u8 {
    return std.mem.span(
        c.gtk_entry_get_text(self.toRaw()),
    );
}

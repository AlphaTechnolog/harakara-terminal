const std = @import("std");
const c = @import("./c.zig");

const Self = @This();

ptr: ?*c.GtkClipboard,

pub fn init(display: ?*c.GdkDisplay) Self {
    return Self{
        .ptr = c.gtk_clipboard_get_for_display(
            display,
            c.GDK_SELECTION_CLIPBOARD,
        ),
    };
}

pub inline fn toRaw(self: Self) *c.GtkClipboard {
    return self.ptr orelse @panic("invalid ptr");
}

pub fn setText(self: Self, text: []const u8) void {
    c.gtk_clipboard_set_text(
        self.toRaw(),
        @as([:0]const u8, @ptrCast(text)).ptr,
        @intCast(text.len),
    );
}

pub fn requestText(
    self: Self,
    c_handler: anytype,
    user_data: ?c.gpointer,
) void {
    c.gtk_clipboard_request_text(
        self.toRaw(),
        @as(
            c.GtkClipboardTextReceivedFunc,
            @constCast(
                @ptrCast(c_handler),
            ),
        ),
        user_data orelse null,
    );
}

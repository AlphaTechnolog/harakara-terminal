const c = @import("./c.zig");

const Self = @This();

ptr: *c.PangoFontDescription,

/// Creates a new `PangoFontDescription` from the given `format` string.
pub fn fromString(format: [:0]const u8) Self {
    return Self{
        .ptr = c.pango_font_description_from_string(format.ptr) orelse {
            @panic("pango_font_description_from_string() failed");
        },
    };
}

/// Returns the raw `?*c.PangoFontDescription` ptr.
pub inline fn toRaw(self: Self) ?*c.PangoFontDescription {
    return self.ptr;
}

/// Frees the allocated data for this `PangoFontDescription` object.
pub fn free(self: Self) void {
    c.pango_font_description_free(self.toRaw());
}

const c = @import("./c.zig");

const Self = @This();

ptr: *c.PangoFontDescription,

pub fn fromString(format: [:0]const u8) Self {
    return Self{
        .ptr = c.pango_font_description_from_string(format.ptr) orelse {
            @panic("pango_font_description_from_string() failed");
        },
    };
}

pub inline fn toRaw(self: Self) ?*c.PangoFontDescription {
    return self.ptr;
}

pub fn free(self: Self) void {
    c.pango_font_description_free(self.toRaw());
}

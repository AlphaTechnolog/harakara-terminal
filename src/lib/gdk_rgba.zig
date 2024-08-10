const std = @import("std");
const c = @import("./c.zig");
const utils = @import("./utils.zig");

const Self = @This();

value: c.GdkRGBA,

/// Initialiases an empty `c.GdkRGBA` value.
pub fn init() Self {
    return .{ .value = undefined };
}

/// From the given format, we fill the values of the current
/// `c.GdkRGBA` struct pointer. format is a hexagecimal value.
pub fn fromFormat(format: [:0]const u8) !Self {
    var instance = Self.init();
    try instance.parse(format);
    return instance;
}

/// Returns the raw `c.GdkRGBA` ptr.
pub inline fn toRaw(self: *Self) c.GdkRGBA {
    return self.value;
}

/// Parse a hexagecimal value and fill the current `c.GdkRGBA` struct ptr.
pub fn parse(self: *Self, format: [:0]const u8) !void {
    if (!utils.gboolToBool(c.gdk_rgba_parse(&self.value, format.ptr))) {
        return error.RGBAParseFailed;
    }
}

const std = @import("std");
const c = @import("./c.zig");
const utils = @import("./utils.zig");

const Self = @This();

value: c.GdkRGBA,

pub fn init() Self {
    return .{ .value = undefined };
}

pub fn fromFormat(format: [:0]const u8) !Self {
    var instance = Self.init();
    try instance.parse(format);
    return instance;
}

pub inline fn toRaw(self: *Self) c.GdkRGBA {
    return self.value;
}

pub fn parse(self: *Self, format: [:0]const u8) !void {
    if (!utils.gboolToBool(c.gdk_rgba_parse(&self.value, format.ptr))) {
        return error.RGBAParseFailed;
    }
}

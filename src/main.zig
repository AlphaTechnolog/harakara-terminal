pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("hello world\n", .{});
}

const std = @import("std");
const c = @import("./lib/c.zig");

pub fn main() !u8 {
    const app = Application.init("es.alphatechnolog.harakara-terminal", .default);

    var dba = std.heap.DebugAllocator(.{}){};
    defer if (dba.deinit() == .leak) std.debug.print("memleak detected\n", .{});
    const allocator = dba.allocator();

    var flag: i32 = 12;
    try app.connect(i32, allocator, .activate, struct {
        fn handler(_: *c.GtkApplication, data: ?i32) !void {
            const stdout = std.io.getStdOut().writer();
            try stdout.print("hello world from handler, flag is {d}\n", .{
                data orelse 0,
            });
        }
    }.handler, &flag);

    return app.toGApplication().runNoArgs();
}

const std = @import("std");
const c = @import("./lib/c.zig");
const Application = @import("./lib/application.zig");

const std = @import("std");

const c = @import("./lib/c.zig");
const Application = @import("./lib/application.zig");
const Terminal = @import("./terminal/init.zig");

fn activate(_: *c.GtkApplication, user_data: c.gpointer) void {
    const app = @as(*Application, @constCast(@alignCast(@ptrCast(user_data))));

    var terminal = Terminal.init(std.heap.page_allocator, app) catch unreachable;
    terminal.setup();
    terminal.window.asWidget().showAll();
}

pub fn main() u8 {
    const app = Application.init("es.alphatechnolog.harakara", .default);
    defer app.toGObject().unref();

    _ = app.connect(
        "activate",
        @as(c.GCallback, @constCast(@ptrCast(@alignCast(&activate)))),
        @as(c.gpointer, @constCast(@ptrCast(&app))),
    );

    return @intCast(app.toGApplication().run(0, null));
}

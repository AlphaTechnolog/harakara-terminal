const std = @import("std");

const c = @import("./lib/c.zig");
const utils = @import("./lib/utils.zig");
const Application = @import("./lib/application.zig");
const Terminal = @import("./terminal/init.zig");

fn activate(_: *c.GtkApplication, user_data: c.gpointer) void {
    const app = utils.castFromGPointer(Application, user_data);
    var terminal = Terminal.init(std.heap.page_allocator, app) catch unreachable;
    terminal.setup();
    terminal.window.asWidget().showAll();
}

pub fn main() u8 {
    const app = Application.init("es.alphatechnolog.harakara", .default);
    defer app.toGObject().unref();

    _ = app.connect(
        "activate",
        utils.castGCallback(activate),
        utils.castGPointer(&app),
    );

    return @intCast(app.toGApplication().run(0, null));
}

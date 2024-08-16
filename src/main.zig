const std = @import("std");
const builtin = @import("builtin");

const c = @import("./lib/c.zig");
const utils = @import("./lib/utils.zig");
const Application = @import("./lib/application.zig");
const Terminal = @import("./terminal/init.zig");

const isDevMode = @import("./terminal/utils.zig").isDevMode;
const allocator = std.heap.page_allocator;

fn activate(_: *c.GtkApplication, user_data: c.gpointer) void {
    const app = utils.castFromGPointer(Application, user_data);
    var terminal = Terminal.init(allocator, app) catch unreachable;
    terminal.setup();
    terminal.arrive();
}

pub fn main() u8 {
    const app = Application.init(
        if (isDevMode()) "dev.alphatechnolog.harakara" else "es.alphatechnolog.harakara",
        .non_unique,
    );

    defer app.toGObject().unref();

    _ = app.connect(
        "activate",
        utils.castGCallback(activate),
        utils.castGPointer(&app),
    );

    return @intCast(app.toGApplication().run(0, null));
}

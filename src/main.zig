const std = @import("std");
const builtin = @import("builtin");

const c = @import("./lib/c.zig");
const utils = @import("./lib/utils.zig");
const Application = @import("./lib/application.zig");
const Terminal = @import("./terminal/init.zig");

const isDevMode = @import("./terminal/utils.zig").isDevMode;
const allocator = std.heap.page_allocator;

pub fn main() u8 {
    const app = Application.init(
        if (isDevMode()) "dev.alphatechnolog.harakara" else "es.alphatechnolog.harakara",
        .non_unique,
    );

    defer app.toGObject().unref();

    const ConnectHandlers = struct {
        pub fn onActivate(_: *c.GtkApplication, data: c.gpointer) callconv(.C) void {
            const self = utils.castFromGPointer(Application, data);
            var terminal = Terminal.init(allocator, self) catch @panic("Unable to create terminal instance");
            terminal.setup().arrive();
        }
    };

    app.connect(
        "activate",
        utils.castGCallback(ConnectHandlers.onActivate),
        utils.castGPointer(&app),
    );

    return @intCast(app.toGApplication().run(0, null));
}

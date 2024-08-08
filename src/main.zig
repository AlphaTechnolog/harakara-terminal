const std = @import("std");

const c = @import("./lib/c.zig");
const Application = @import("./lib/application.zig");
const Window = @import("./lib/window.zig");
const VteTerminal = @import("./lib/vte.zig");

const Gui = struct {
    allocator: std.mem.Allocator,
    window: Window.ApplicationWindow,
    term: VteTerminal,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, app: *Application) !*Self {
        var instance = try allocator.create(Self);
        instance.allocator = allocator;
        instance.window = Window.ApplicationWindow.init(app.*);
        instance.term = VteTerminal.init();
        return instance;
    }

    pub fn setup(self: *Self) void {
        self.window.asWindow().setTitle("Harakara");
        self.window.asContainer().add(self.term.asWidget());
        self.term.spawnAsync(.default, null, "/bin/sh", null, .default, null, -1, null);

        self.term.connectChildExited(
            @as(c.GCallback, @constCast(@ptrCast(@alignCast(&onChildExited)))),
            @as(c.gpointer, @constCast(@ptrCast(self))),
        );
    }

    pub fn deinit(self: *Self) void {
        self.term.asWidget().destroy();
        self.window.asWindow().close();
        self.window.asWidget().destroy();
        self.allocator.destroy(self);
    }
};

fn onChildExited(_: *c.VteTerminal, _: c.gint, data: c.gpointer) void {
    var gui = @as(*Gui, @ptrCast(@alignCast(data)));
    gui.deinit();
}

fn activate(_: *c.GtkApplication, user_data: c.gpointer) void {
    const app = @as(*Application, @constCast(@alignCast(@ptrCast(user_data))));

    var gui = Gui.init(std.heap.page_allocator, app) catch unreachable;
    gui.setup();
    gui.window.asWidget().showAll();
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

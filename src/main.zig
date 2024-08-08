const std = @import("std");

const c = @import("./lib/c.zig");
const Application = @import("./lib/application.zig");
const Window = @import("./lib/window.zig");
const VteTerminal = @import("./lib/vte.zig");

var gapp: ?Application = null;
var gui: ?Gui = null;

const Gui = struct {
    window: Window.ApplicationWindow,
    term: VteTerminal,

    const Self = @This();

    pub fn init(app: Application) Self {
        return Self{
            .window = Window.ApplicationWindow.init(app),
            .term = VteTerminal.init(),
        };
    }

    pub fn setup(self: Self) void {
        self.window.asWindow().setTitle("Harakara");
        self.window.asContainer().add(self.term.asWidget());
        self.term.spawnAsync(.default, null, "/bin/sh", null, .default, null, -1, null);
        self.term.connectChildExited(&onChildExited, null);
    }
};

fn onChildExited(_: *c.VteTerminal, _: c.gpointer) void {
    if (gui) |self| {
        self.term.asWidget().destroy();
        self.window.asWidget().destroy();
    }
}

fn activate(_: *c.GtkApplication, _: c.gpointer) void {
    gui = Gui.init(gapp orelse @panic("invalid app instance!"));

    if (gui) |self| {
        self.setup();
        self.window.asWidget().showAll();
    }
}

pub fn main() u8 {
    gapp = Application.init("es.alphatechnolog.harakara", .default);
    defer gapp.?.toGObject().unref();

    if (gapp) |app| {
        _ = app.connect("activate", &activate, null);
    }

    return @intCast(gapp.?.toGApplication().run(0, null));
}

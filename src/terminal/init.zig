const std = @import("std");

const c = @import("../lib/c.zig");
const Window = @import("../lib/window.zig");
const Application = @import("../lib/application.zig");
const VteTerminal = @import("../lib/vte.zig");

const Colorscheme = @import("./colorscheme.zig");

const mem = std.mem;
const posix = std.posix;

const Self = @This();

allocator: mem.Allocator,
window: Window.ApplicationWindow,
terminal: VteTerminal,
colorscheme: Colorscheme,

pub fn init(allocator: mem.Allocator, app: *Application) !*Self {
    var instance = try allocator.create(Self);
    instance.allocator = allocator;
    instance.window = Window.ApplicationWindow.init(app.*);
    instance.terminal = VteTerminal.init();
    instance.colorscheme = Colorscheme.init(allocator, instance);
    return instance;
}

fn setupTerminal(self: Self) void {
    self.terminal.spawnAsync(
        .default,
        null,
        @as([:0]const u8, (posix.getenv("SHELL") orelse "/bin/bash")),
        null,
        .default,
        null,
        -1,
        null,
    );
}

fn onChildExited(_: *c.VteTerminal, _: c.gint, data: c.gpointer) void {
    var self = @as(*Self, @ptrCast(@alignCast(data)));
    self.deinit();
}

pub fn setup(self: *Self) void {
    self.window.asWindow().setTitle("Harakara");
    self.window.asContainer().add(self.terminal.asWidget());

    self.colorscheme.setup() catch @panic("Unable to load colorscheme");
    self.setupTerminal();

    self.terminal.connectChildExited(
        @as(c.GCallback, @constCast(@ptrCast(@alignCast(&Self.onChildExited)))),
        @as(c.gpointer, @constCast(@ptrCast(self))),
    );
}

pub fn deinit(self: *Self) void {
    self.terminal.asWidget().destroy();
    self.window.asWindow().close();
    self.window.asWidget().destroy();
    self.allocator.destroy(self);
}

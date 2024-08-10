const std = @import("std");

const c = @import("../lib/c.zig");
const Window = @import("../lib/window.zig");
const Application = @import("../lib/application.zig");
const VteTerminal = @import("../lib/vte.zig");
const utils = @import("../lib/utils.zig");
const types = @import("../lib/types.zig");

const AppearanceController = @import("./appearance.zig");

const mem = std.mem;
const posix = std.posix;

const Self = @This();

allocator: mem.Allocator,
window: Window.ApplicationWindow,
terminal: VteTerminal,
appearance: AppearanceController,

pub fn init(allocator: mem.Allocator, app: *Application) !*Self {
    var instance = try allocator.create(Self);
    instance.allocator = allocator;
    instance.window = Window.ApplicationWindow.init(app.*);
    instance.terminal = VteTerminal.init();
    instance.appearance = try AppearanceController.init(allocator, instance);
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
    var self = utils.castFromGPointer(Self, data);
    self.deinit();
}

fn onKeyPress(
    _: *c.GtkWidget,
    arg_event: *c.GdkEventKey,
    data: c.gpointer,
) c.gboolean {
    const self = utils.castFromGPointer(Self, data);
    const event = types.intoGdkEventKey(arg_event);

    const has_control = event.*.state & @as(c.guint, c.GDK_CONTROL_MASK) != 0;
    const has_c = event.keyval == @as(c.guint, c.GDK_KEY_c);
    const has_v = event.keyval == @as(c.guint, c.GDK_KEY_v);

    // TODO: For some reason if we wanna use ctrl + shift + c
    // and ctrl + shift + v, when we do something like:
    // const has_shift = event.*.state & @as(c.guint, c.GDK_SHIFT_MASK) != 0;
    // and then check for all of three has_control and has_shift and has_c
    // it fails to retrieve value for has_c and always keeps it as false
    // prolly help is gonna be needed here and further investigation aswell.

    if (has_control and has_c) {
        self.terminal.copyClipboardFormat(.text);
        return utils.boolToCInt(true);
    }

    if (has_control and has_v) {
        self.terminal.pastePrimary();
        return utils.boolToCInt(true);
    }

    return utils.boolToCInt(false);
}

pub fn setup(self: *Self) void {
    self.window.asWindow().setTitle("Harakara");
    self.window.asContainer().add(self.terminal.asWidget());

    self.appearance.setup(&self.terminal) catch {
        @panic("Unable to load appearance settings");
    };

    self.setupTerminal();

    // handles terminal resources cleanups.
    self.terminal.connectChildExited(
        utils.castGCallback(Self.onChildExited),
        utils.castGPointer(self),
    );

    // handles keybindings.
    self.window.asWindow().connectKeyPress(
        utils.castGCallback(Self.onKeyPress),
        utils.castGPointer(self),
    );
}

pub fn deinit(self: *Self) void {
    self.appearance.deinit();
    self.terminal.asWidget().destroy();
    self.window.asWindow().close();
    self.window.asWidget().destroy();
    self.allocator.destroy(self);
}

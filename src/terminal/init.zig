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

    instance.appearance = try AppearanceController.init(
        allocator,
        &instance.terminal,
    );

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
    var self = utils.castFromGPointer(Self, data);
    const event = types.intoGdkEventKey(arg_event);

    const control_mask: c.guint = c.GDK_CONTROL_MASK;
    const shift_mask: c.guint = c.GDK_CONTROL_MASK;

    const state = event.*.state;

    const has_modifiers = (state & control_mask != 0) and (state & shift_mask != 0);
    const has_c = (event.*.keyval == c.GDK_KEY_C);
    const has_v = (event.*.keyval == c.GDK_KEY_V);

    if (has_modifiers and has_c) {
        self.terminal.copyClipboardFormat(.text);
        return utils.boolToCInt(true);
    }

    if (has_modifiers and has_v) {
        self.terminal.pastePrimary();
        return utils.boolToCInt(true);
    }

    return utils.boolToCInt(false);
}

pub fn setup(self: *Self) void {
    self.window.asWindow().setTitle("Harakara");
    self.window.asContainer().add(self.terminal.asWidget());

    self.appearance.setup() catch {
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

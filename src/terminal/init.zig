const std = @import("std");

const c = @import("../lib/c.zig");
const Window = @import("../lib/window.zig");
const Application = @import("../lib/application.zig");
const VteTerminal = @import("../lib/vte.zig");
const Label = @import("../lib/label.zig");
const Overlay = @import("../lib/overlay.zig");
const Box = @import("../lib/box.zig");
const Clipboard = @import("../lib/clipboard.zig");
const utils = @import("../lib/utils.zig");
const types = @import("../lib/types.zig");

const TermUtils = @import("./utils.zig");
const AppearanceController = @import("./appearance.zig");
const CSSTemplate = @import("./utils/css_template.zig");

const mem = std.mem;
const posix = std.posix;

const Self = @This();

allocator: mem.Allocator,
window: Window.ApplicationWindow,
terminal: VteTerminal,
main_overlay: Overlay,
status_text: Label,
status_box: Box,
appearance: AppearanceController,
clipboard: Clipboard,

pub fn init(allocator: mem.Allocator, app: *Application) !*Self {
    var instance = try allocator.create(Self);

    instance.allocator = allocator;
    instance.window = Window.ApplicationWindow.init(app.*);
    instance.terminal = VteTerminal.init();
    instance.main_overlay = Overlay.init();
    instance.clipboard = Clipboard.init(c.gdk_display_get_default());

    instance.status_text = Label.init("12px");

    instance.status_box = Box.init(.{
        .orientation = .horizontal,
        .spacing = 0,
    });

    instance.appearance = try AppearanceController.init(
        allocator,
        &instance.terminal,
        &instance.status_text,
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

    self.terminal.setBoldIsBright(true);
}

fn onChildExited(_: *c.VteTerminal, _: c.gint, data: c.gpointer) void {
    var self = utils.castFromGPointer(Self, data);
    self.deinit();
}

fn handleClipboardRequest(
    _: *c.GtkClipboard,
    arg_text: [*c]const c.gchar,
    user_data: c.gpointer,
) void {
    const self = utils.castFromGPointer(Self, user_data);

    if (arg_text != null and mem.len(arg_text) > 0) {
        const text: [:0]const u8 = mem.span(arg_text);
        self.terminal.pasteText(text);
    }
}

fn handleCopyPaste(
    self: *Self,
    opts: struct {
        has_modifiers: bool,
        has_c: bool,
        has_v: bool,
    },
) bool {
    if (opts.has_modifiers and opts.has_c) {
        const text = self.terminal.getTextSelected(.text);
        self.clipboard.setText(text);
        return true;
    }

    if (opts.has_modifiers and opts.has_v) {
        self.clipboard.requestText(
            &Self.handleClipboardRequest,
            utils.castGPointer(self),
        );

        return true;
    }

    return false;
}

fn handleTermZoom(
    self: *Self,
    opts: struct {
        has_ctrl: bool,
        has_equal: bool,
        has_minus: bool,
        has_zero: bool,
    },
) !bool {
    const has_ctrl = opts.has_ctrl;
    const has_equal = opts.has_equal;
    const has_minus = opts.has_minus;
    const has_zero = opts.has_zero;

    // TODO: This should be in the config file.
    const ZOOM_STEP: i64 = 1;

    if (has_ctrl and has_equal) {
        try self.appearance.applyFontZoom(ZOOM_STEP);
        return true;
    }

    if (has_ctrl and has_minus) {
        try self.appearance.applyFontZoom(-ZOOM_STEP);
        return true;
    }

    if (has_ctrl and has_zero) {
        try self.appearance.restoreFontSize();
        return true;
    }

    return false;
}

fn onKeyPress(
    _: *c.GtkWidget,
    arg_event: *c.GdkEventKey,
    data: c.gpointer,
) c.gboolean {
    var self = utils.castFromGPointer(Self, data);
    const event = types.intoGdkEventKey(arg_event);

    const control_mask: c.guint = c.GDK_CONTROL_MASK;
    const shift_mask: c.guint = c.GDK_SHIFT_MASK;

    const state = event.*.state;

    const holding_ctrl = (state & control_mask != 0);
    const holding_shift = (state & shift_mask != 0);

    const has_modifiers = holding_ctrl and holding_shift;
    const has_c = (event.*.keyval == c.GDK_KEY_C);
    const has_v = (event.*.keyval == c.GDK_KEY_V);
    const has_equal = (event.*.keyval == c.GDK_KEY_equal);
    const has_minus = (event.*.keyval == c.GDK_KEY_minus);
    const has_zero = (event.*.keyval == c.GDK_KEY_0);

    const copy_paste = self.handleCopyPaste(.{
        .has_modifiers = has_modifiers,
        .has_c = has_c,
        .has_v = has_v,
    });

    if (copy_paste) {
        return utils.boolToCInt(true);
    }

    const zoom_action = self.handleTermZoom(.{
        .has_ctrl = holding_ctrl,
        .has_equal = has_equal,
        .has_minus = has_minus,
        .has_zero = has_zero,
    }) catch @panic("Unable to zoom in/out terminal");

    if (zoom_action) {
        return utils.boolToCInt(true);
    }

    return utils.boolToCInt(false);
}

pub fn setup(self: *Self) void {
    const title = if (TermUtils.isDevMode()) "Harakara (Dev Build)" else "Harakara";

    self.window.asWindow().setTitle(title);

    self.status_box.asWidget().setHAlign(.center);
    self.status_box.asWidget().setVAlign(.center);

    self.status_box.packStart(
        self.status_text.asWidget(),
        true,
        true,
        0,
    );

    self.status_box.asWidget().setName("information-container");

    self.main_overlay.addOverlay(self.status_box.asWidget());
    self.main_overlay.asContainer().add(self.terminal.asWidget());
    self.main_overlay.asWidget().setVExpand(true);

    const content_box = Box.init(.{
        .orientation = .vertical,
        .spacing = 0,
    });

    content_box.asContainer().add(self.main_overlay.asWidget());
    content_box.asWidget().setName("main-container");

    self.window.asContainer().add(content_box.asWidget());

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

/// This method is gonna be called after .setup()
pub fn arrive(self: Self) void {
    self.window.asWidget().showAll();
    self.status_text.asWidget().hide();
}

/// Frees all the allocated resources previously.
pub fn deinit(self: *Self) void {
    self.appearance.deinit();
    self.terminal.asWidget().destroy();
    self.window.asWindow().close();
    self.window.asWidget().destroy();
    self.allocator.destroy(self);
}

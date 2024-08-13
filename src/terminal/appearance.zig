const std = @import("std");
const Config = @import("./config.zig");
const c = @import("../lib/c.zig");
const utils = @import("../lib/utils.zig");
const enums = @import("../lib/enums.zig");
const VteTerminal = @import("../lib/vte.zig");
const Label = @import("../lib/label.zig");
const Timeout = @import("../lib/timeout.zig");
const GdkRGBA = @import("../lib/gdk_rgba.zig");

const mem = std.mem;
const fmt = std.fmt;

const Self = @This();

/// The used memory allocator object.
allocator: mem.Allocator,

/// The current terminal pointer instance.
terminal: *VteTerminal,

/// The configuration parser result ptr object.
config: *Config.Parser.Result,

/// Current font size used by the terminal.
current_font_size: i64,

/// The status text overlay which will print the font size.
status_text: *Label,

/// Time manager for hiding the status text properly, there's prolly a far
/// better way, but this is what i could have figured out in my own...
timeout_current_id: u32,

/// Payload which is gonna be passed from timer to timer.
const HideTimerState = struct {
    id: u32,
    self: *Self,
};

/// Initialiases the appearance component
pub fn init(allocator: mem.Allocator, terminal: *VteTerminal, status_text: *Label) !Self {
    const config = Config.init(allocator);
    const parsed_config = try config.parse();

    const initial_format = try fmt.allocPrint(allocator, "{d}px", .{parsed_config.font.size});
    defer allocator.free(initial_format);

    status_text.*.setText(@ptrCast(initial_format));

    return Self{
        .terminal = terminal,
        .allocator = allocator,
        .status_text = status_text,
        .config = parsed_config,
        .timeout_current_id = 0,
        .current_font_size = parsed_config.font.size,
    };
}

/// Setups the terminal font by using the parsed configuration file.
fn setupFont(self: Self) !void {
    const font_format = try fmt.allocPrint(self.allocator, "{s} {d}", .{
        self.config.font.family orelse "monospace",
        self.current_font_size,
    });

    defer self.allocator.free(font_format);

    self.terminal.setFontFromString(@ptrCast(font_format));
}

fn onTimeoutImpl(self: *Self, timer_id: u32) bool {
    // here we check if we're the last timer, if not, we will just not hide the widget
    // again, since the last timer is the only one which has the rights to do this.
    if (self.timeout_current_id != timer_id) {
        return false;
    }

    const status_widget = self.status_text.asWidget();

    if (status_widget.isVisible()) {
        status_widget.hide();
    }

    return false;
}

fn onTimeout(user_data: c.gpointer) c.gboolean {
    const data = utils.castFromGPointer(HideTimerState, user_data);
    var self = data.*.self;

    const value = utils.boolToCInt(self.onTimeoutImpl(data.id));
    self.allocator.destroy(data);

    return value;
}

/// Updates the font size indicator in the screen.
fn updateFontSizeIndicator(self: *Self) !void {
    const new_indicator_text = try fmt.allocPrint(
        self.allocator,
        "{d}px",
        .{self.current_font_size},
    );

    defer self.allocator.free(new_indicator_text);

    self.status_text.setText(@ptrCast(new_indicator_text));

    const status_label = self.status_text.asWidget();
    status_label.show();

    self.timeout_current_id += 1;

    const hide_timer_state = try self.allocator.create(HideTimerState);
    hide_timer_state.* = HideTimerState{
        .id = self.timeout_current_id,
        .self = self,
    };

    _ = Timeout.add(
        1000,
        utils.castGSourceFunc(onTimeout),
        utils.castGPointer(hide_timer_state),
    );

    // reset the timeout current id if it exceeds 100.
    self.timeout_current_id = if (self.timeout_current_id == 100) 0 else self.timeout_current_id;
}

/// Functions to run after the current_font_size attribute has been modified
inline fn afterFontSizeModify(self: *Self) !void {
    try self.updateFontSizeIndicator();
    try self.setupFont();
}

/// Applies a zoom of n pixels to the current font size
pub fn applyFontZoom(self: *Self, n: i64) !void {
    self.current_font_size += n;
    try self.afterFontSizeModify();
}

/// Restores the original font size of the terminal.
pub fn restoreFontSize(self: *Self) !void {
    self.current_font_size = self.config.font.size;
    try self.afterFontSizeModify();
}

/// Setups the cursor style of the terminal.
fn setupCursor(self: Self) void {
    const cursor_value = self.config.cursor.shape;

    var cursor: enums.CursorShape = .block;

    if (cursor_value) |value| {
        if (std.mem.eql(u8, value, "block")) {
            cursor = .block;
        }

        if (std.mem.eql(u8, value, "ibeam")) {
            cursor = .ibeam;
        }

        if (std.mem.eql(u8, value, "underline")) {
            cursor = .underline;
        }
    }

    self.terminal.setCursorShape(cursor);

    self.terminal.setCursorBlinkMode(
        if (self.config.cursor.blinking) .on else .off,
    );
}

/// Setups the colorscheme of the terminal by using the parsed configuration file.
fn setupColorscheme(self: Self) !void {
    const background_color: [:0]const u8 = @ptrCast(self.config.colors.background orelse "#141414");
    const foreground_color: [:0]const u8 = @ptrCast(self.config.colors.foreground orelse "#ffffff");

    var background_rgba = try GdkRGBA.fromFormat(background_color);
    var foreground_rgba = try GdkRGBA.fromFormat(foreground_color);

    try self.terminal.setColors(
        &foreground_rgba,
        &background_rgba,
        VteTerminal.TerminalColorPalette.fromConfig(self.config),
    );
}

/// This function will start the process of applying the appearance-related
/// configurations to the terminal.
pub fn setup(self: Self) !void {
    try self.setupFont();
    self.setupCursor();
    try self.setupColorscheme();
}

/// Releases allocated memory from the config file.
pub fn deinit(self: *Self) void {
    self.config.deinit();
}

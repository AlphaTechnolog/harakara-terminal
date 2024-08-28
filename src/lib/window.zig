const std = @import("std");
const c = @import("./c.zig");
const utils = @import("./utils.zig");

const Application = @import("./application.zig");
const Widget = @import("./widget.zig");
const Container = @import("./container.zig");

/// Serves as any window interface.
pub const Window = struct {
    ptr: *c.GtkWindow,

    const Self = @This();

    /// Initialiases a new `Window` instance.
    pub fn init(instance: *c.GtkWindow) Self {
        return Self{
            .ptr = instance,
        };
    }

    /// Converts a given `Window` into a `*c.GtkWindow` ptr.
    pub inline fn toRaw(self: Self) *c.GtkWindow {
        return self.ptr;
    }

    /// Converts a given `Window` into a `Widget` instance.
    pub inline fn asWidget(self: Self) Widget {
        return Widget.init(@as(*c.GtkWidget, @ptrCast(self.toRaw())));
    }

    /// Converts a given `Window` into a `Container` instance.
    pub inline fn asContainer(self: Self) Container {
        return Container.init(@as(*c.GtkContainer, @ptrCast(
            self.toRaw(),
        )));
    }

    /// Set a title of the current window instance.
    pub fn setTitle(self: Self, title: [:0]const u8) void {
        c.gtk_window_set_title(self.toRaw(), title.ptr);
    }

    /// Set a default size of the current window instance.
    pub fn setDefaultSize(self: Self, hsize: c_int, vsize: c_int) void {
        c.gtk_window_set_default_size(self.toRaw(), hsize, vsize);
    }

    /// Set if the window should be decorated or not.
    pub fn setDecorated(self: Self, value: bool) void {
        c.gtk_window_set_decorated(self.toRaw, utils.boolToCInt(value));
    }

    /// Close the current window instance.
    pub fn close(self: Self) void {
        c.gtk_window_close(self.toRaw());
    }

    /// Indicates to the window manager that this is a transient dialog
    /// associated with the application window parent.
    ///
    /// This allows the window manager to do things like center this on
    /// parent and keep this above parent.
    pub fn setTransientFor(self: Self, parent: Self) void {
        c.gtk_window_set_transient_for(self.toRaw(), parent.toRaw());
    }

    /// Connect the current window instance to a given detailed_signal
    /// with a callback and passing a gpointer as a data to that callback
    ///
    /// see: `utils.castGCallback` for passing your callback
    /// see: `utils.castFromGPointer` to receive your data from a gpointer
    /// see: `utils.castGPointer` to pass your data as a gpointer
    pub inline fn connect(
        self: Self,
        detailed_signal: [:0]const u8,
        callback: c.GCallback,
        data: ?c.gpointer,
    ) void {
        self.asWidget().connect(
            detailed_signal,
            callback,
            data,
        );
    }

    /// Connects this window instance to the `'key-press-event'` event.
    pub fn connectKeyPress(
        self: Self,
        callback: c.GCallback,
        data: ?c.gpointer,
    ) void {
        self.connect(
            "key-press-event",
            callback,
            data,
        );
    }

    pub fn isInstance(gtype: u64) bool {
        // TODO: Prolly need to check for Dialog aswell.
        return (gtype == c.gtk_window_get_type() or ApplicationWindow.isInstance(gtype));
    }
};

/// The main `Window` of a `Application` object.
pub const ApplicationWindow = struct {
    ptr: *c.GtkApplicationWindow,

    const Self = @This();

    /// Initialises a new `ApplicationWindow`.
    pub fn init(app: Application) Self {
        return Self{
            .ptr = @as(*c.GtkApplicationWindow, @ptrCast(
                c.gtk_application_window_new(app.toRaw()),
            )),
        };
    }

    /// Converts the current `ApplicationWindow` instance into a
    /// `*c.GtkApplicationWindow` ptr.
    pub inline fn toRaw(self: Self) *c.GtkApplicationWindow {
        return self.ptr;
    }

    /// Converts the current `ApplicationWindow` into a `Window` which
    /// helps us to connect to signals, close the window, etc.
    pub inline fn asWindow(self: Self) Window {
        return Window.init(@as(*c.GtkWindow, @ptrCast(
            self.toRaw(),
        )));
    }

    /// Converts the `ApplicationWindow` into a `Widget` element.
    pub inline fn asWidget(self: Self) Widget {
        return Widget.init(@as(*c.GtkWidget, @ptrCast(self.toRaw())));
    }

    /// Converts the `ApplicationWindow` into a `Container` element.
    pub inline fn asContainer(self: Self) Container {
        return Container.init(@as(*c.GtkContainer, @ptrCast(
            self.toRaw(),
        )));
    }

    pub fn isInstance(gtype: u64) bool {
        return (gtype == c.gtk_application_window_get_type());
    }
};

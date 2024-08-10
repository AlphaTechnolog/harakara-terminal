const c = @import("./c.zig");
const utils = @import("./utils.zig");

const Application = @import("./application.zig");
const Widget = @import("./widget.zig");
const Container = @import("./container.zig");

pub const Window = struct {
    ptr: *c.GtkWindow,

    const Self = @This();

    pub fn init(instance: *c.GtkWindow) Self {
        return Self{
            .ptr = instance,
        };
    }

    pub inline fn toRaw(self: Self) *c.GtkWindow {
        return self.ptr;
    }

    pub inline fn asWidget(self: Self) Widget {
        return Widget.init(@as(*c.GtkWidget, @ptrCast(self.toRaw())));
    }

    pub inline fn asContainer(self: Self) Container {
        return Container.init(@as(*c.GtkContainer, @ptrCast(
            self.toRaw(),
        )));
    }

    pub fn setTitle(self: Self, title: [:0]const u8) void {
        c.gtk_window_set_title(self.toRaw(), title.ptr);
    }

    pub fn setDefaultSize(self: Self, hsize: c_int, vsize: c_int) void {
        c.gtk_window_set_default_size(self.toRaw, hsize, vsize);
    }

    pub fn setDecorated(self: Self, value: bool) void {
        c.gtk_window_set_decorated(self.toRaw, utils.boolToCInt(value));
    }

    pub fn close(self: Self) void {
        c.gtk_window_close(self.toRaw());
    }

    pub fn setTransientFor(self: Self, parent: Self) void {
        c.gtk_window_set_transient_for(self.toRaw(), parent.toRaw());
    }

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

    // TODO: Prolly need to check for Dialog aswell.
    pub fn isInstance(gtype: u64) bool {
        return (gtype == c.gtk_window_get_type() or ApplicationWindow.isInstance(gtype));
    }
};

pub const ApplicationWindow = struct {
    ptr: *c.GtkApplicationWindow,

    const Self = @This();

    pub fn init(app: Application) Self {
        return Self{
            .ptr = @as(*c.GtkApplicationWindow, @ptrCast(
                c.gtk_application_window_new(app.toRaw()),
            )),
        };
    }

    pub inline fn toRaw(self: Self) *c.GtkApplicationWindow {
        return self.ptr;
    }

    pub inline fn asWindow(self: Self) Window {
        return Window.init(@as(*c.GtkWindow, @ptrCast(
            self.toRaw(),
        )));
    }

    pub inline fn asWidget(self: Self) Widget {
        return Widget.init(@as(*c.GtkWidget, @ptrCast(self.toRaw())));
    }

    pub inline fn asContainer(self: Self) Container {
        return Container.init(@as(*c.GtkContainer, @ptrCast(
            self.toRaw(),
        )));
    }

    pub fn isInstance(gtype: u64) bool {
        return (gtype == c.gtk_application_window_get_type());
    }
};

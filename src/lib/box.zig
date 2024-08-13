const c = @import("./c.zig");
const Container = @import("./container.zig");
const Widget = @import("./widget.zig");
const utils = @import("./utils.zig");
const enums = @import("./enums.zig");

const Self = @This();

ptr: [*c]c.GtkBox,

pub fn init(
    args: struct {
        orientation: enums.GtkOrientation,
        spacing: i32,
    },
) Self {
    return Self{
        .ptr = @as(*c.GtkBox, @ptrCast(c.gtk_box_new(
            @intFromEnum(args.orientation),
            @intCast(args.spacing),
        ))),
    };
}

pub inline fn toRaw(self: Self) *c.GtkBox {
    return self.ptr;
}

pub inline fn asWidget(self: Self) Widget {
    return Widget.init(@as(*c.GtkWidget, @ptrCast(self.toRaw())));
}

pub inline fn asContainer(self: Self) Container {
    return Container.init(@as(*c.GtkContainer, @ptrCast(self.toRaw())));
}

pub fn packStart(
    self: Self,
    child: Widget,
    expand: bool,
    fill: bool,
    padding: c.guint,
) void {
    c.gtk_box_pack_start(
        self.toRaw(),
        child.toRaw(),
        utils.boolToCInt(expand),
        utils.boolToCInt(fill),
        padding,
    );
}

pub fn packEnd(
    self: Self,
    child: Widget,
    expand: bool,
    fill: bool,
    padding: c.guint,
) void {
    c.gtk_box_pack_end(
        self.toRaw(),
        child.toRaw(),
        utils.boolToCInt(expand),
        utils.boolToCInt(fill),
        padding,
    );
}

pub fn setSpacing(self: Self, spacing: i32) void {
    c.gtk_box_set_spacing(self.toRaw(), @ptrCast(spacing));
}

pub fn getSpacing(self: Self) i32 {
    return @ptrCast(c.gtk_box_get_spacing(self.toRaw()));
}

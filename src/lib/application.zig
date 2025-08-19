const Application = @This();

pub const GApplicationFlags = enum(c_uint) {
    default = c.G_APPLICATION_FLAGS_NONE,
    is_service = c.G_APPLICATION_IS_SERVICE,
    is_launcher = c.G_APPLICATION_IS_LAUNCHER,
    handles_command_line = c.G_APPLICATION_HANDLES_COMMAND_LINE,
    send_environment = c.G_APPLICATION_SEND_ENVIRONMENT,
    non_unique = c.G_APPLICATION_NON_UNIQUE,
    can_override_app_id = c.G_APPLICATION_CAN_OVERRIDE_APP_ID,
    allow_replacement = c.G_APPLICATION_ALLOW_REPLACEMENT,
    replace = c.G_APPLICATION_REPLACE,
};

ptr: *c.GtkApplication,

pub fn init(id: [:0]const u8, flags: GApplicationFlags) Application {
    const app = c.gtk_application_new(id.ptr, @intFromEnum(flags)) orelse @panic("invalid app!");
    return Application{ .ptr = app };
}

pub inline fn toRaw(self: Application) *c.GtkApplication {
    return self.ptr;
}

pub inline fn toGPointer(self: Application) c.gpointer {
    return @ptrCast(self.toRaw());
}

pub inline fn toGApplication(self: Application) GApplication {
    return .init(@ptrCast(self.toRaw()));
}

fn _connect(
    self: Application,
    comptime T: type,
    signal: [:0]const u8,
    callback: anytype,
    data: ?*T,
) void {
    var zero: u32 = 0;
    const flags: *c.GConnectFlags = @ptrCast(&zero);

    _ = c.g_signal_connect_data(
        self.toGPointer(),
        signal.ptr,
        @constCast(@ptrCast(@alignCast(&callback))),
        if (data) |d| @constCast(@ptrCast(d)) else null,
        null,
        flags.*,
    );
}

// TODO: Map more signals.
const Signals = enum {
    activate,

    fn toCallback(self: @This(), comptime T: type) type {
        return switch (self) {
            .activate => fn (app: *c.GtkApplication, data: ?T) anyerror!void,
        };
    }
};

pub fn connect(
    self: Application,
    comptime T: type,
    allocator: std.mem.Allocator,
    signal: Signals,
    callback: *const signal.toCallback(T),
    data: ?*T,
) !void {
    const ClosureData = struct {
        real_payload: ?*T = null,
        signal: Signals,
        callback: *const signal.toCallback(T),
        allocator: std.mem.Allocator,

        pub fn deinit(ptr: *@This()) void {
            ptr.allocator.destroy(ptr);
        }
    };

    var closure_data = try allocator.create(ClosureData);
    closure_data.real_payload = data;
    closure_data.signal = signal;
    closure_data.callback = callback;
    closure_data.allocator = allocator;

    self._connect(ClosureData, @tagName(signal), struct {
        fn handler(instance: c.gpointer, payload: c.gpointer) callconv(.C) void {
            var recvrd_closure: *ClosureData = @ptrCast(@alignCast(payload));
            defer recvrd_closure.deinit();
            recvrd_closure.callback(
                @ptrCast(@alignCast(instance)),
                if (recvrd_closure.real_payload) |p| p.* else null,
            ) catch |err| {
                const stderr = std.io.getStdErr().writer();
                stderr.print("Unable to call callback for signal {s}: {s}\n", .{
                    @tagName(recvrd_closure.signal),
                    @errorName(err),
                }) catch unreachable;
            };
        }
    }.handler, closure_data);
}

const std = @import("std");
const c = @import("./c.zig");
const GApplication = @import("./gapplication.zig");

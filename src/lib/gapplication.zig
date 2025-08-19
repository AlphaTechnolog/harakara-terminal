const GApplication = @This();

ptr: *c.GApplication,

pub fn init(instance: *c.GApplication) GApplication {
    return GApplication{ .ptr = instance };
}

pub inline fn toRaw(self: GApplication) *c.GApplication {
    return self.ptr;
}

fn _run(self: GApplication, argc: c_int, argv: [*c][*c]u8) c_int {
    return c.g_application_run(self.toRaw(), argc, argv);
}

pub fn runNoArgs(self: GApplication) u8 {
    return @intCast(self._run(0, null));
}

const c = @import("./c.zig");

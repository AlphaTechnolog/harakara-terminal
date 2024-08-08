const c = @import("./c.zig");

const Self = @This();

ptr: *c.GApplication,

pub fn init(instance: *c.GApplication) Self {
    return Self{
        .ptr = instance,
    };
}

pub inline fn toRaw(self: Self) *c.GApplication {
    return self.ptr;
}

pub fn run(self: Self, argc: c_int, argv: [*c][*c]u8) c_int {
    return c.g_application_run(self.toRaw(), argc, argv);
}

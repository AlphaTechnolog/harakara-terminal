const c = @import("./c.zig");

const Self = @This();

ptr: *c.GApplication,

/// Initialiases a new `GApplication` instance from an already existent
/// `*c.GApplication` pointer.
pub fn init(instance: *c.GApplication) Self {
    return Self{
        .ptr = instance,
    };
}

/// Returns the raw `*c.GApplication` ptr.
pub inline fn toRaw(self: Self) *c.GApplication {
    return self.ptr;
}

/// Run the current `GApplication` instance.
pub fn run(self: Self, argc: c_int, argv: [*c][*c]u8) c_int {
    return c.g_application_run(self.toRaw(), argc, argv);
}

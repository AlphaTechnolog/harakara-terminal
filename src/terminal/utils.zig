const builtin = @import("builtin");

pub inline fn isDevMode() bool {
    return builtin.mode == .Debug;
}

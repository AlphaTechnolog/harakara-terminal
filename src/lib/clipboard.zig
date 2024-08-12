// Abstraction class for clipboard management
// NOTE: Expects wl-clipboard to be present in wayland systems and
// xclip to be available on X11

const std = @import("std");

const fmt = std.fmt;
const mem = std.mem;
const process = std.process;
const posix = std.posix;

allocator: mem.Allocator,

const Self = @This();

pub fn init(allocator: mem.Allocator) Self {
    return Self{ .allocator = allocator };
}

inline fn isWaylandDisplay() bool {
    const wayland_display = posix.getenv("WAYLAND_DISPLAY");
    return wayland_display != null;
}

fn runExternalCommand(
    self: Self,
    command: []const u8,
) !void {
    const argv = [_][]const u8{ "bash", "-c", command };

    var child = process.Child.init(
        &argv,
        self.allocator,
    );

    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Ignore;

    try child.spawn();

    defer {
        _ = child.wait() catch unreachable;
    }
}

fn copyTextWayland(self: Self, text: []const u8) !void {
    const command = fmt.allocPrint(self.allocator, "wl-copy '{s}'", .{
        text,
    }) catch @panic("oom when concatening strings");

    defer self.allocator.free(command);

    try self.runExternalCommand(command);
}

fn copyTextX11(self: Self, text: []const u8) !void {
    const command = fmt.allocPrint(self.allocator, "echo '{s}' | xclip -sel c", .{
        text,
    }) catch @panic("oom when concatening strings");

    defer self.allocator.free(command);

    try self.runExternalCommand(command);
}

pub fn copyText(self: Self, text: []const u8) void {
    const is_wayland_display = isWaylandDisplay();

    if (is_wayland_display) {
        self.copyTextWayland(text) catch @panic("unable to copy in wayland (wl-copy)");
    } else {
        self.copyTextX11(text) catch @panic("unable to copy in X11 (xclip)");
    }
}

fn retrieveWayland(self: Self) !?[]const u8 {
    const argv = [_][]const u8{ "bash", "-c", "wl-paste 2>/dev/null" };

    const result = try process.Child.run(.{
        .allocator = self.allocator,
        .argv = &argv,
    });

    defer {
        self.allocator.free(result.stderr);
        self.allocator.free(result.stdout);
    }

    const output = try self.allocator.dupe(u8, mem.trim(u8, result.stdout, "\n"));

    if (mem.eql(u8, output, "")) {
        self.allocator.free(output);
        return null;
    }

    return output;
}

fn retrieveX11(self: Self) !?[]const u8 {
    const argv = [_][]const u8{ "bash", "-c", "xclip -o 2>/dev/null" };

    const result = try process.Child.run(.{
        .allocator = self.allocator,
        .argv = &argv,
    });

    defer {
        self.allocator.free(result.stderr);
        self.allocator.free(result.stdout);
    }

    const output = try self.allocator.dupe(u8, mem.trim(u8, result.stdout, "\n"));

    if (mem.eql(u8, output, "")) {
        self.allocator.free(output);
        return null;
    }

    return output;
}

pub fn retrieve(self: Self) ?[]const u8 {
    const is_wayland_display = isWaylandDisplay();

    if (is_wayland_display) {
        return self.retrieveWayland() catch @panic("unable to paste in wayland (wl-paste)");
    } else {
        return self.retrieveX11() catch @panic("unable to paste in X11 (xclip)");
    }
}

const std = @import("std");
const c = @import("../../lib/c.zig");

const mem = std.mem;

const Self = @This();

allocator: mem.Allocator,
css_template: []const u8,
css_provider: [*c]c.GtkCssProvider,
final_css: ?[:0]u8,

pub fn init(allocator: mem.Allocator, css_template: []const u8) !Self {
    return .{
        .allocator = allocator,
        .css_template = try allocator.dupe(u8, css_template),
        .css_provider = c.gtk_css_provider_new(),
        .final_css = null,
    };
}

const ParsingError = anyerror || error{
    AlreadyParsedError,
    UnableToProduceCSSError,
    InvalidExpansionSyntaxError,
};

const PARSING_REPLACEMENT_INDICATOR = '^';

pub fn parseTemplate(self: *Self, context: *std.StringHashMap([]const u8)) ParsingError!void {
    if (self.final_css != null) {
        return error.AlreadyParsedError;
    }

    var result_string = std.ArrayList(u8).init(self.allocator);
    defer result_string.deinit();

    var buf_stream = std.io.fixedBufferStream(self.css_template);
    var reader = buf_stream.reader();
    var line: [1024]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(line[0..], '\n')) |cursor| {
        var is_expansion_opened = false;
        var expansion_occurred = false;
        var replacement_key: ?std.ArrayList(u8) = null;

        defer {
            if (replacement_key) |arraylist| {
                arraylist.deinit();
            }
        }

        for (cursor) |cur_ch| {
            if (cur_ch == PARSING_REPLACEMENT_INDICATOR and !is_expansion_opened) {
                is_expansion_opened = true;
                replacement_key = std.ArrayList(u8).init(self.allocator);
            } else if (cur_ch == PARSING_REPLACEMENT_INDICATOR and is_expansion_opened) {
                is_expansion_opened = false;
                expansion_occurred = true;

                if (replacement_key) |*arraylist| {
                    try arraylist.append(PARSING_REPLACEMENT_INDICATOR);
                }
            }

            if (is_expansion_opened) {
                if (replacement_key) |*arraylist| {
                    try arraylist.append(cur_ch);
                }
            }
        }

        if (is_expansion_opened) {
            return error.InvalidExpansionSyntaxError;
        }

        if (!expansion_occurred) {
            try result_string.appendSlice(cursor);
            try result_string.append('\n');
            continue;
        }

        if (replacement_key) |arraylist| {
            const needle = arraylist.items;

            var replacement_buffer: [100]u8 = undefined;
            var context_iterator = context.iterator();

            while (context_iterator.next()) |context_element| {
                if (std.mem.eql(u8, needle[1 .. needle.len - 1], context_element.key_ptr.*)) {
                    _ = std.mem.replace(
                        u8,
                        cursor,
                        needle,
                        context_element.value_ptr.*,
                        replacement_buffer[0..],
                    );

                    const real_size = std.mem.replacementSize(
                        u8,
                        cursor,
                        needle,
                        context_element.value_ptr.*,
                    );

                    try result_string.appendSlice(replacement_buffer[0..real_size]);
                    try result_string.append('\n');
                }
            }
        }
    }

    // dupeZ() creates a sentinel terminated string similar to doing something like this:
    // var raw_data = try self.allocator.alloc(u8, string_list.items.len + 1);
    // raw_data[string_list.items.len] = 0;
    // self.final_css = raw_data[0..string_list.items.len :0];
    self.final_css = try self.allocator.dupeZ(u8, result_string.items);
}

const LoadError = anyerror || error{
    NonParsedCSSError,
};

pub fn loadForDisplay(self: Self) LoadError!void {
    if (self.final_css == null) {
        return error.NonParsedCSSError;
    }

    if (self.final_css) |final_css| {
        _ = c.gtk_css_provider_load_from_data(
            self.css_provider,
            final_css.ptr,
            @intCast(final_css.len),
            null,
        );

        c.gtk_style_context_add_provider_for_screen(
            c.gdk_screen_get_default(),
            @as(*c.GtkStyleProvider, @ptrCast(self.css_provider)),
            c.GTK_STYLE_PROVIDER_PRIORITY_APPLICATION,
        );
    }
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.css_template);

    if (self.final_css) |value| {
        self.allocator.free(value);
    }
}

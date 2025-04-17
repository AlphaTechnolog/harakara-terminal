const std = @import("std");

const Config = @This();

pub const Attribute = struct {
    pub const Value = union(enum) {
        string: []u8,
        int: i64,
        float: f64,
        boolean: bool,
    };

    allocator: std.mem.Allocator,
    key: []const u8,
    value: Value,

    fn valueFromStr(allocator: std.mem.Allocator, str: []const u8) !Value {
        var lowercase_buf: [1024]u8 = undefined;
        const lowercased = std.ascii.lowerString(&lowercase_buf, str);

        if (lowercased[0] == '"' and lowercased[lowercased.len - 1] == '"') {
            return Value{ .string = try allocator.dupe(u8, str[1 .. lowercased.len - 1]) };
        }

        if (std.mem.eql(u8, lowercased, "yes") or std.mem.eql(u8, lowercased, "true") or std.mem.eql(u8, lowercased, "on")) {
            return Value{ .boolean = true };
        } else if (std.mem.eql(u8, lowercased, "no") or std.mem.eql(u8, lowercased, "false") or std.mem.eql(u8, lowercased, "off")) {
            return Value{ .boolean = false };
        }

        if (std.mem.containsAtLeast(u8, lowercased, 1, ".")) {
            return Value{ .float = try std.fmt.parseFloat(f64, lowercased) };
        } else {
            return Value{ .int = try std.fmt.parseInt(i64, lowercased, 10) };
        }
    }

    pub fn init(allocator: std.mem.Allocator, key: []const u8, value_str: []const u8) !Attribute {
        return Attribute{
            .allocator = allocator,
            .key = try allocator.dupe(u8, key),
            .value = try valueFromStr(allocator, value_str),
        };
    }

    pub inline fn debugShow(self: Attribute) void {
        std.debug.print("{s}: {s} = {s}\n", .{
            self.key,
            @tagName(self.value),

            switch (self.value) {
                .string => |str| str,
                .boolean => |b| if (b) "true" else "false",
                .int => |number| formatted: {
                    var buf: [256]u8 = undefined;
                    break :formatted std.fmt.bufPrint(&buf, "{d}", .{number}) catch unreachable;
                },
                .float => |number| formatted: {
                    var buf: [256]u8 = undefined;
                    break :formatted std.fmt.bufPrint(&buf, "{d}", .{number}) catch unreachable;
                },
            },
        });
    }

    pub fn deinit(self: *Attribute) void {
        self.allocator.free(self.key);

        switch (self.value) {
            .string => |*ptr| self.allocator.free(ptr.*),
            else => {},
        }
    }
};

const Section = struct {
    allocator: std.mem.Allocator,
    name: []u8,
    attributes: std.ArrayList(Attribute),

    pub fn init(allocator: std.mem.Allocator, name: []const u8) Section {
        return Section{
            .allocator = allocator,
            .name = allocator.dupe(u8, name) catch unreachable,
            .attributes = std.ArrayList(Attribute).init(allocator),
        };
    }

    pub fn get(self: Section, name: []const u8) ?Attribute {
        for (self.attributes.items) |attr| {
            if (std.mem.eql(u8, attr.key, name)) {
                return attr;
            }
        }

        return null;
    }

    pub const ListAttributeIterator = struct {
        attributes: []Attribute,
        name: []const u8,
        index: usize = 0,

        pub fn next(self: *ListAttributeIterator) ?Attribute {
            const index = self.index;
            for (self.attributes[index..]) |element| {
                self.index += 1;
                if (std.mem.eql(u8, self.name, element.key)) {
                    return element;
                }
            }
            return null;
        }
    };

    pub fn iterate(self: Section, name: []const u8) ListAttributeIterator {
        return ListAttributeIterator{
            .attributes = self.attributes.items,
            .name = name,
        };
    }

    pub fn deinit(self: *Section) void {
        self.allocator.free(self.name);
        for (self.attributes.items) |*attr| attr.deinit();
        self.attributes.deinit();
    }
};

sections: std.ArrayList(Section),

pub fn init(allocator: std.mem.Allocator) Config {
    return Config{ .sections = std.ArrayList(Section).init(allocator) };
}

fn isSection(input: []const u8) ?[]const u8 {
    if (input[0] == '[' and input[input.len - 1] == ']') {
        return input[1 .. input.len - 1];
    }

    return null;
}

pub const InputPopulateError = anyerror || error{
    InputKeyNotFound,
    InputValueNotFound,
};

fn populateWithInput(allocator: std.mem.Allocator, config: *Config, current_section: *Section, input: []const u8) InputPopulateError!void {
    if (std.mem.eql(u8, input, "") or input[0] == '#') {
        return;
    }

    if (isSection(input)) |section_name| {
        try config.sections.append(current_section.*);
        current_section.* = Section.init(allocator, section_name);
        return;
    }

    var it = std.mem.tokenizeAny(u8, input, "=");

    const key = it.next() orelse return error.InputKeyNotFound;
    const value = it.next() orelse return error.InputValueNotFound;

    try current_section.attributes.append(try Attribute.init(
        allocator,
        key,
        value,
    ));
}

pub fn parseFile(allocator: std.mem.Allocator, filename: []const u8) !Config {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var br = std.io.bufferedReader(file.reader());
    const reader = br.reader();

    var line_buf: [1024]u8 = undefined;
    var current_section = Section.init(allocator, "root");
    var config = init(allocator);

    while (try reader.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        try populateWithInput(
            allocator,
            &config,
            &current_section,
            line,
        );
    }

    try config.sections.append(current_section);

    return config;
}

pub fn parseString(allocator: std.mem.Allocator, contents: []const u8) !Config {
    var it = std.mem.tokenizeAny(u8, contents, "\n");
    var current_section = Section.init(allocator, "root");
    var config = init(allocator);

    while (it.next()) |line| {
        try populateWithInput(
            allocator,
            &config,
            &current_section,
            line,
        );
    }

    try config.sections.append(current_section);

    return config;
}

pub fn get(self: Config, secname: []const u8) ?Section {
    for (self.sections.items) |section| {
        if (std.mem.eql(u8, section.name, secname)) {
            return section;
        }
    }

    return null;
}

pub fn deinit(self: *Config) void {
    for (self.sections.items) |*section| section.deinit();
    self.sections.deinit();
}

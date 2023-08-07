const std = @import("std");
const testing = std.testing;

const clapz = @import("clapz");

const Output = union(enum) {
    stdout: void,
    filename: []const u8,

    pub fn parse(arg: []const u8) ?Output {
        if (std.mem.eql(u8, arg, "-")) {
            return Output.stdout;
        } else {
            return Output{ .filename = arg };
        }
    }
};

const Opt = struct {
    out: Output,
};

const Parser = clapz.Parser(Opt, .{}, .{
    .out = .{
        .short = 'o',
        .long = "out",
        .doc = "output strategy",
    },
});

test "opt parser with custom union stdout" {
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();

    const args = try Parser.parse(&.{
        "git",
        "-o",
        "-",
    }, alloc.allocator());

    try testing.expectEqual(Output.stdout, args.out);
}

test "opt parser with custom union filename" {
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();

    const args = try Parser.parse(&.{
        "git",
        "-o",
        "xyz.log",
    }, alloc.allocator());

    switch (args.out) {
        .stdout => {
            try testing.expect(false);
        },

        .filename => |f| {
            try testing.expectEqualStrings("xyz.log", f);
        },
    }
}

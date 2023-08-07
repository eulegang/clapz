const std = @import("std");
const testing = std.testing;

const clapz = @import("clapz");

const Color = enum {
    auto,
    off,
    on,
};

const Opt = struct {
    color: Color,
};

const Parser = clapz.Parser(Opt, .{}, .{
    .color = .{
        .short = 'c',
        .long = "color",
        .doc = "color option",
    },
});

test "opt parser with enum" {
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();

    var parser = Parser.init(alloc.allocator());

    const basic = try parser.parse(&.{
        "git",
        "-c",
        "auto",
    });

    try testing.expectEqual(Color.auto, basic.color);
}

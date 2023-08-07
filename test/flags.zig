const std = @import("std");
const testing = std.testing;

const clapz = @import("clapz");

const Flag = struct {
    verbose: bool,
};

const Parser = clapz.Parser(Flag, .{}, .{
    .verbose = .{
        .short = 'v',
        .long = "verbose",
        .doc = "output more output",
    },
});

test "parse flag" {
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();

    const basic = try Parser.parse(&.{
        "dd",
        "-v",
    }, alloc.allocator());

    try testing.expectEqual(Flag{
        .verbose = true,
    }, basic);
}

test "parse flag default" {
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();

    const basic = try Parser.parse(&.{
        "dd",
    }, alloc.allocator());

    try testing.expectEqual(Flag{
        .verbose = false,
    }, basic);
}

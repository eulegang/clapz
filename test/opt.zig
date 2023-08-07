const std = @import("std");
const testing = std.testing;

const clapz = @import("clapz");

const Opt = struct {
    output: ?[]const u8,
};

const Parser = clapz.Parser(Opt, .{}, .{
    .output = .{
        .short = 'o',
        .long = "output",
        .doc = "output to file",
    },
});

test "opt parser with option" {
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();

    var parser = Parser.init(alloc.allocator());

    const basic = try parser.parse(&.{
        "dd",
        "-o",
        "out.txt",
    });

    try testing.expectEqual(Opt{
        .output = "out.txt",
    }, basic);
}

test "opt parser without option" {
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();

    var parser = Parser.init(alloc.allocator());

    const basic = try parser.parse(&.{
        "dd",
    });

    try testing.expectEqual(Opt{
        .output = null,
    }, basic);
}

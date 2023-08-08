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
    var parser = try Parser.init(testing.allocator);
    defer parser.deinit();

    const basic = try parser.parse(&.{
        "dd",
        "-v",
    });

    try testing.expectEqual(Flag{
        .verbose = true,
    }, basic);
}

test "parse flag default" {
    var parser = try Parser.init(testing.allocator);
    defer parser.deinit();

    const basic = try parser.parse(&.{
        "dd",
    });

    try testing.expectEqual(Flag{
        .verbose = false,
    }, basic);
}

const std = @import("std");
const testing = std.testing;

const clapz = @import("clapz");

const Basic = struct {
    input: []const u8,
    output: []const u8,
};

const BasicParser = clapz.Parser(Basic, .{}, .{
    .input = .{ .doc = "input to program" },
    .output = .{ .doc = "output from program" },
});

test "basic good case" {
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();

    const basic = try BasicParser.parse(&.{
        "dd",
        "-i",
        "xyz",
        "-o",
        "abc",
    }, alloc.allocator());

    try testing.expectEqual(Basic{
        .input = "xyz",
        .output = "abc",
    }, basic);
}

test "basic missing param" {
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();

    _ = BasicParser.parse(&.{
        "dd",
        "-i",
        "xyz",
    }, alloc.allocator()) catch |err| {
        try testing.expectEqual(clapz.Error.MissingArg, err);

        return;
    };

    try testing.expect(false);
}

test "basic incomplete param" {
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();

    _ = BasicParser.parse(&.{
        "dd",
        "-i",
    }, alloc.allocator()) catch |err| {
        try testing.expectEqual(clapz.Error.MissingArg, err);

        return;
    };

    try testing.expect(false);
}

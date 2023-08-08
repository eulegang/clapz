const std = @import("std");
const testing = std.testing;

const clapz = @import("clapz");

const Basic = struct {
    input: []const u8,
    output: []const u8,
};

const BasicParser = clapz.Parser(Basic, .{}, .{
    .input = .{
        .short = 'i',
        .long = "input",
        .doc = "input to program",
    },
    .output = .{
        .short = 'o',
        .long = "output",
        .doc = "output from program",
    },
});

test "basic good case" {
    var parser = try BasicParser.init(testing.allocator);
    defer parser.deinit();

    const basic = try parser.parse(&.{
        "dd",
        "-i",
        "xyz",
        "-o",
        "abc",
    });

    try testing.expectEqualStrings("xyz", basic.input);
    try testing.expectEqualStrings("abc", basic.output);
}

test "basic missing param" {
    var parser = try BasicParser.init(testing.allocator);
    defer parser.deinit();

    _ = parser.parse(&.{
        "dd",
        "-i",
        "xyz",
    }) catch |err| {
        try testing.expectEqual(clapz.Error.MissingArg, err);

        return;
    };

    try testing.expect(false);
}

test "basic incomplete param" {
    var parser = try BasicParser.init(testing.allocator);
    defer parser.deinit();

    _ = parser.parse(&.{
        "dd",
        "-i",
    }) catch |err| {
        try testing.expectEqual(clapz.Error.MissingArg, err);

        return;
    };

    try testing.expect(false);
}

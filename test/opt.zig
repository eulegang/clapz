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
    var parser = try Parser.init(testing.allocator);
    defer parser.deinit();

    const basic = try parser.parse(&.{
        "dd",
        "-o",
        "out.txt",
    });

    const out = basic.output orelse {
        try testing.expect(false);
        return;
    };
    try testing.expectEqualStrings("out.txt", out);
}

test "opt parser without option" {
    var parser = try Parser.init(testing.allocator);
    defer parser.deinit();

    const basic = try parser.parse(&.{
        "dd",
    });

    const out: ?[]const u8 = null;

    try testing.expectEqual(out, basic.output);
}

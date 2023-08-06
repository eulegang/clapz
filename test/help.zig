const std = @import("std");
const testing = std.testing;

const clapz = @import("clapz");

const Args = struct {
    output: ?[]const u8,
    input: ?[]const u8,
    verbose: bool,
};

const Parser = clapz.Parser(Args, .{
    .name = "saver",
    .version = "0.1.23",
    .desc = "saves some file type",
    .author = "xyz",
}, .{
    .input = .{ .doc = "read file" },
    .output = .{ .doc = "save output" },
    .verbose = .{ .doc = "say more" },
});

test "parse flag" {
    try testing.expectEqualStrings(Parser.Doc,
        \\saver - 0.1.23 - xyz - saves some file type
        \\  -o, --output : save output
        \\  -i, --input : read file
        \\  -v, --verbose : say more
        \\
    );
}

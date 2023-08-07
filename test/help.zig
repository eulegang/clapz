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
    .input = .{
        .short = 'i',
        .long = "input",
        .doc = "read file",
    },
    .output = .{
        .short = 'o',
        .long = "output",
        .doc = "save output",
    },
    .verbose = .{
        .short = 'v',
        .long = "verbose",
        .doc = "say more",
    },
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

test "parse does throw show help error" {
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();

    _ = Parser.parse(&.{
        "dd",
        "-h",
    }, alloc.allocator()) catch |err| {
        try testing.expectEqual(clapz.Error.ShowHelp, err);

        return;
    };

    try testing.expect(false);
}

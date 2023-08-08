const std = @import("std");
const testing = std.testing;

const clapz = @import("clapz");

const GitRange = struct {
    start: []const u8,
    end: []const u8,

    pub fn parse(arg: []const u8) ?GitRange {
        var i: usize = 0;

        while (i < arg.len) : (i += 1) {
            if (arg[i] == '.') {
                break;
            }
        }

        if (i == arg.len) {
            return null;
        }

        const start = arg[0..i];

        while (i < arg.len) : (i += 1) {
            if (arg[i] != '.') {
                break;
            }
        }

        if (i == arg.len) {
            return null;
        }

        const end = arg[i..];

        return GitRange{
            .start = start,
            .end = end,
        };
    }
};

const Opt = struct {
    range: GitRange,
};

const Parser = clapz.Parser(Opt, .{}, .{
    .range = .{
        .short = 'r',
        .long = "range",
        .doc = "git range",
    },
});

test "opt parser with custom" {
    var parser = try Parser.init(testing.allocator);
    defer parser.deinit();

    const basic = try parser.parse(&.{
        "git",
        "-r",
        "HEAD..master",
    });

    try testing.expectEqualStrings("HEAD", basic.range.start);
    try testing.expectEqualStrings("master", basic.range.end);
}

test "opt parser with failed custom" {
    var parser = try Parser.init(testing.allocator);
    defer parser.deinit();

    _ = parser.parse(&.{
        "git",
        "-r",
        "HEAD",
    }) catch |err| {
        try testing.expectEqual(clapz.Error.ArgParse, err);
        return;
    };

    try testing.expect(false);
}

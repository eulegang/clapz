const std = @import("std");
const testing = std.testing;

const clapz = @import("clapz");

const Output = union(enum) {
    stdout: void,
    filename: []const u8,

    pub fn parse(arg: []const u8) ?Output {
        if (std.mem.eql(u8, arg, "-")) {
            return Output.stdout;
        } else {
            return Output{ .filename = arg };
        }
    }
};

const Opt = struct {
    out: Output,
};

const Parser = clapz.Parser(Opt, .{}, .{
    .out = .{
        .short = 'o',
        .long = "out",
        .doc = "output strategy",
    },
});

test "opt parser with custom union stdout" {
    var parser = try Parser.init(testing.allocator);
    defer parser.deinit();

    const args = try parser.parse(&.{
        "git",
        "-o",
        "-",
    });

    try testing.expectEqual(Output.stdout, args.out);
}

test "opt parser with custom union filename" {
    var parser = try Parser.init(testing.allocator);
    defer parser.deinit();

    const args = try parser.parse(&.{
        "git",
        "-o",
        "xyz.log",
    });

    switch (args.out) {
        .stdout => {
            try testing.expect(false);
        },

        .filename => |f| {
            try testing.expectEqualStrings("xyz.log", f);
        },
    }
}

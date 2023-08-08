const std = @import("std");
const testing = std.testing;

const clapz = @import("clapz");

const Opt = struct {
    user: []const u8,
};

const Parser = clapz.Parser(Opt, .{}, .{
    .user = .{
        .short = 'u',
        .long = "user",
        .doc = "user to login with",
        .env = "USER",
    },
});

test "opt parser with env" {
    var parser = try Parser.init(testing.allocator);
    defer parser.deinit();

    const user: []const u8 = try std.process.getEnvVarOwned(testing.allocator, "USER");
    defer testing.allocator.free(user);

    var args: Opt = try parser.parse(&.{
        "git",
    });

    try testing.expectEqualStrings(user, args.user);
}

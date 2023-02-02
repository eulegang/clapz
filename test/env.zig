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
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();
    var parser = Parser.init(alloc.allocator());

    const user: []const u8 = try std.process.getEnvVarOwned(alloc.allocator(), "USER");

    var args: Opt = try parser.parse(&.{
        "git",
    });

    try testing.expectEqualStrings(user, args.user);
}

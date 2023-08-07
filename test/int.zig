const std = @import("std");
const testing = std.testing;

const clapz = @import("clapz");

const Opt = struct {
    jobs: u32,
};

const Parser = clapz.Parser(Opt, .{}, .{
    .jobs = .{
        .short = 'j',
        .long = "jobs",
        .doc = "how many threads to run",
    },
});

test "opt parser with enum" {
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();

    var args: Opt = try Parser.parse(&.{
        "make",
        "-j",
        "5",
    }, alloc.allocator());

    var out: u32 = 5;

    try testing.expectEqual(out, args.jobs);
}

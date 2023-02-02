const std = @import("std");
const builder = @import("builder.zig");
const conf = @import("conf.zig");

const Type = std.builtin.Type;
const Opt = conf.Opt;

pub const Error = builder.Error;
pub const Meta = conf.Meta;

pub fn Parser(comptime T: type, comptime meta: Meta, comptime opts: Opt(T)) type {
    const Builder = builder.Builder(T, opts);
    return struct {
        const Self = @This();
        pub const Doc = conf.gen_help(T, meta, opts);

        alloc: std.mem.Allocator,

        pub fn init(alloc: std.mem.Allocator) Self {
            return Self{
                .alloc = alloc,
            };
        }

        pub fn parse(self: *Self, args: []const []const u8) Error!T {
            var b = Builder.init(self.alloc);

            try b.bootstrap_env();

            for (args[1..]) |arg| {
                try b.visit(arg);
            }

            return b.finalize();
        }

        pub fn parse_args(self: *Self) T {
            var acc = std.ArrayList([]const u8).init(self.alloc);
            // intentionally leaked

            var args = std.process.args();
            while (args.next()) |arg| {
                try acc.append(arg);
            }

            const res = self.parse(acc.items) catch |err| {
                if (err == Error.ShowHelp) {
                    const stdout = std.io.getStdOut();

                    stdout.print("{}", Doc);
                    std.os.exit(0);
                }

                std.os.exit(1);
            };

            return res;
        }
    };
}

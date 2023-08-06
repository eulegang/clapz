const std = @import("std");
const builder = @import("builder.zig");
const conf = @import("conf.zig");
const help = @import("help.zig");

const Type = std.builtin.Type;
const Opt = conf.Opt;

pub const Error = builder.Error;
pub const Meta = help.Meta;

pub fn Parser(comptime T: type, comptime meta: Meta, comptime opts: Opt(T)) type {
    const Builder = builder.Builder(T, opts);
    return struct {
        pub const Doc = help.gen_help(T, meta, opts);

        pub fn parse(args: []const []const u8, alloc: std.mem.Allocator) Error!T {
            var b = Builder.init(alloc);

            for (args) |arg| {
                try b.visit(arg);
            }

            return b.finalize();
        }

        pub fn parse_args() T {
            const res = parse(.{}) catch {
                std.os.exit(1);
            };

            return res;
        }
    };
}

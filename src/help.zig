const conf = @import("conf.zig");

const Opt = conf.Opt;

pub const Meta = struct {
    name: []const u8 = "name",
    version: []const u8 = "0.1.0",
    desc: []const u8 = "basic description",
    author: []const u8 = "yourname",
};

pub fn gen_help(comptime T: type, comptime meta: Meta, comptime opt: Opt(T)) []const u8 {
    comptime var buf: [4096]u8 = undefined;
    comptime var i = 0;

    const struct_def = @typeInfo(@TypeOf(opt)).Struct;

    inline for (struct_def.fields) |field| {
        const o = @field(opt, field.name);

        const line = "  -" ++ [1]u8{o.short} ++ ", --" ++ o.long ++ " : " ++ o.doc ++ "\n";

        @memcpy(buf[i..][0..line.len], line);
        i += line.len;
    }

    return meta.name ++ " - " ++ meta.version ++ " - " ++ meta.author ++ " - " ++ meta.desc ++ "\n" ++ buf[0..i];
}

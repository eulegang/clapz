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
    comptime var opt_buf: [4096]u8 = undefined;
    comptime var i = 0;

    const struct_def = @typeInfo(@TypeOf(opt)).Struct;

    inline for (struct_def.fields) |field| {
        comptime var j = 0;
        const o = @field(opt, field.name);

        @memcpy(opt_buf[0..2], "  ");
        j = 2;

        if (o.short) |short| {
            opt_buf[j] = '-';
            opt_buf[j + 1] = short;
            j += 2;
        }

        if (o.long) |long| {
            if (j != 2) {
                @memcpy(opt_buf[j..][0..2], ", ");
                j += 2;
            }

            @memcpy(opt_buf[j..][0..2], "--");
            j += 2;

            @memcpy(opt_buf[j..][0..long.len], long);
            j += long.len;
        }

        if (o.doc) |doc| {
            if (j != 2) {
                @memcpy(opt_buf[j..][0..3], " : ");
                j += 3;
            }

            @memcpy(opt_buf[j..][0..doc.len], doc);
            j += doc.len;
        }

        if (j != 2) {
            opt_buf[j] = '\n';
            j += 1;

            @memcpy(buf[i..][0..j], opt_buf[0..j]);
            i += j;
        }
    }

    return meta.name ++ " - " ++ meta.version ++ " - " ++ meta.author ++ " - " ++ meta.desc ++ "\n" ++ buf[0..i];
}

const std = @import("std");

const Type = std.builtin.Type;

pub const Meta = struct {
    name: []const u8 = "name",
    version: []const u8 = "0.1.0",
    desc: []const u8 = "basic description",
    author: []const u8 = "yourname",
};

pub const OptMeta = struct {
    long: ?[]const u8 = null,
    short: ?u8 = null,
    doc: ?[]const u8 = null,
};

pub fn Conf(comptime T: type, comptime State: type) type {
    return struct {
        fn short_lookup(flag: u8) ?State {
            const struct_def = @typeInfo(T).Struct;

            inline for (struct_def.fields, 1..) |field, i| {
                if (@field(opt, field.name).short) |short| {
                    if (short == flag) {
                        return @enumFromInt(i);
                    }
                }
            }

            return null;
        }

        fn long_lookup(flag: []const u8) ?State {
            const struct_def = @typeInfo(@TypeOf(opt)).Struct;

            inline for (struct_def.fields, 0..) |field, i| {
                if (std.mem.eql(u8, @field(opt, field.name).long, flag)) {
                    return @enumFromInt(i + 1);
                }
            }

            return null;
        }
    };
}

pub fn Opt(comptime T: type) type {
    switch (@typeInfo(T)) {
        .Struct => |s| {
            comptime var fields: [s.fields.len]Type.StructField = undefined;
            for (s.fields, 0..) |field, i| {
                fields[i] = Type.StructField{
                    .default_value = null,
                    .alignment = 8,
                    .is_comptime = false,
                    .name = field.name,
                    .type = OptMeta,
                };
            }

            return @Type(Type{ .Struct = Type.Struct{
                .layout = .Auto,
                .decls = &.{},
                .fields = &fields,
                .is_tuple = false,
            } });
        },

        else => @compileError("Cannot support options for type `" ++ @typeName(T) ++ "`"),
    }
}

const opt = struct {
    ty: type,

    fn gen(comptime field: Type.StructField) @This() {
        var long = Type.StructField{
            .name = "long",
            .type = []const u8,
            .is_comptime = true,
            .alignment = 8,
            .default_value = @ptrCast(&field.name),
        };

        var short = Type.StructField{
            .name = "short",
            .type = u8,
            .is_comptime = true,
            .alignment = 1,
            .default_value = &field.name[0],
        };

        var bare = Type.StructField{
            .name = "bare",
            .type = bool,
            .is_comptime = true,
            .alignment = 1,
            .default_value = &false,
        };

        var doc = Type.StructField{
            .name = "doc",
            .type = []const u8,
            .is_comptime = false,
            .alignment = 8,
            .default_value = null,
        };

        var ty = @Type(Type{
            .Struct = Type.Struct{
                .layout = .Auto,
                .decls = &.{},
                .fields = &.{
                    long,
                    short,
                    bare,
                    doc,
                },
                .is_tuple = false,
            },
        });

        return opt{
            .ty = ty,
        };
    }
};

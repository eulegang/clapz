const std = @import("std");

const Type = std.builtin.Type;

pub fn Opt(comptime T: type) type {
    switch (@typeInfo(T)) {
        .Struct => |s| {
            comptime var fields: [s.fields.len]Type.StructField = undefined;

            for (s.fields, 0..) |field, i| {
                const o = opt.gen(field);
                const ty = o.ty;

                fields[i] = Type.StructField{
                    .default_value = null,
                    .alignment = 8,
                    .is_comptime = false,
                    .name = field.name,
                    .type = ty,
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

        var ty = @Type(Type{
            .Struct = Type.Struct{
                .layout = .Auto,
                .decls = &.{},
                .fields = &.{
                    long,
                    short,
                    bare,
                },
                .is_tuple = false,
            },
        });

        return opt{
            .ty = ty,
        };
    }
};

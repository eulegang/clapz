const std = @import("std");

const Type = std.builtin.Type;
const ArrayList = std.ArrayList;

pub const Error = error{
    MissingArg,
    InvalidArg,
} || std.mem.Allocator.Error;

pub fn Builder(comptime T: type, comptime opt: anytype) type {
    const State = StateOf(opt);
    const Acc = accumulator(T, State);

    const blank: State = @enumFromInt(0);

    return struct {
        const Self = @This();

        acc: Acc,
        state: State,
        fused: bool,
        bare: ArrayList([]const u8),

        pub fn init(alloc: std.mem.Allocator) Self {
            return Self{
                .acc = Acc.init(),
                .state = blank,
                .fused = false,
                .bare = ArrayList([]const u8).init(alloc),
            };
        }

        pub fn visit(self: *Self, arg: []const u8) Error!void {
            if (!self.fused) {
                if (self.state != blank) {
                    self.acc.set(self.state, arg);
                    self.state = blank;
                } else if (std.mem.eql(u8, arg, "--")) {
                    self.fused = true;
                } else if (arg.len > 0 and arg[0] == '-') {
                    try self.accept_arg(arg);
                } else {
                    try self.bare.append(arg);
                }
            } else {
                try self.bare.append(arg);
            }
        }

        pub fn finalize(self: *Self) Error!T {
            if (self.state != blank) {
                return Error.MissingArg;
            }

            return self.acc.finalize();
        }

        fn accept_arg(self: *Self, arg: []const u8) Error!void {
            if (arg.len < 2) return Error.InvalidArg;
            var long = arg[1] == '-';

            if (!long) {
                self.state = state_short_lookup(opt, State, arg[1]) orelse {
                    return Error.InvalidArg;
                };
            } else {
                self.state = state_long_lookup(opt, State, arg[2..]) orelse {
                    return Error.InvalidArg;
                };
            }
        }
    };
}

fn accumulator(comptime T: type, comptime State: type) type {
    const struct_def = @typeInfo(T).Struct;

    comptime var fields: [struct_def.fields.len]Type.StructField = undefined;

    for (struct_def.fields, 0..) |field, i| {
        switch (@typeInfo(field.type)) {
            .Optional => {
                fields[i] = field;
            },

            else => {
                fields[i] = Type.StructField{
                    .name = field.name,
                    .type = @Type(Type{ .Optional = Type.Optional{ .child = field.type } }),
                    .alignment = field.alignment,
                    .is_comptime = field.is_comptime,
                    .default_value = null,
                };
            },
        }
    }

    const Inner = @Type(Type{
        .Struct = Type.Struct{
            .decls = &.{},
            .layout = .Auto,
            .is_tuple = false,
            .fields = &fields,
        },
    });

    return struct {
        const Self = @This();

        inner: Inner,

        pub fn init() Self {
            return Self{ .inner = nulledOut(Inner) };
        }

        pub fn set(self: *Self, state: State, arg: []const u8) void {
            if (@intFromEnum(state) == 0) unreachable;

            inline for (struct_def.fields, 1..) |field, i| {
                if (@intFromEnum(state) == i) {
                    @field(self.inner, field.name) = arg;
                }
            }
        }

        pub fn finalize(self: *Self) Error!T {
            var res: T = undefined;

            inline for (struct_def.fields) |field| {
                const val = @field(self.inner, field.name);
                switch (@typeInfo(field.type)) {
                    .Optional => {
                        @field(res, field.name) = val;
                    },

                    else => {
                        if (val) |v| {
                            @field(res, field.name) = v;
                        } else {
                            return Error.MissingArg;
                        }
                    },
                }
            }

            return res;
        }
    };
}

fn StateOf(comptime opt: anytype) type {
    const struct_def = @typeInfo(@TypeOf(opt)).Struct;

    comptime var states: [struct_def.fields.len + 1]Type.EnumField = undefined;
    states[0] = Type.EnumField{
        .name = "_blank",
        .value = 0,
    };

    for (struct_def.fields, 0..) |field, i| {
        states[i + 1] = Type.EnumField{
            .name = field.name,
            .value = i + 1,
        };
    }

    return @Type(Type{
        .Enum = Type.Enum{
            .tag_type = u8, // more than 255? really
            .decls = &.{},
            .is_exhaustive = true,
            .fields = &states,
        },
    });
}

fn state_short_lookup(comptime opt: anytype, comptime State: type, arg: u8) ?State {
    const struct_def = @typeInfo(@TypeOf(opt)).Struct;

    inline for (struct_def.fields, 0..) |field, i| {
        if (@field(opt, field.name).short == arg) {
            return @enumFromInt(i + 1);
        }
    }

    return null;
}

fn state_long_lookup(comptime opt: anytype, comptime State: type, arg: []const u8) ?State {
    const struct_def = @typeInfo(@TypeOf(opt)).Struct;

    inline for (struct_def.fields, 0..) |field, i| {
        if (std.mem.eql(u8, @field(opt, field.name).long, arg)) {
            return @enumFromInt(i + 1);
        }
    }

    return null;
}

fn nulledOut(comptime T: type) T {
    var res: T = undefined;

    inline for (@typeInfo(T).Struct.fields) |field| {
        @field(res, field.name) = null;
    }

    return res;
}
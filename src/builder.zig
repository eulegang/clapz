const std = @import("std");
const Bank = @import("bank.zig").Bank;

const Type = std.builtin.Type;
const ArrayList = std.ArrayList;

pub const Error = error{
    MissingArg,
    InvalidArg,
    ArgParse,
    ShowHelp,
} || std.mem.Allocator.Error || Bank.Error;

pub fn Builder(comptime T: type, comptime opt: anytype) type {
    const struct_def = @typeInfo(T).Struct;
    const State = StateOf(opt);
    const Acc = accumulator(T, State);
    const C = Conf(@TypeOf(opt), State);

    const blank: State = @enumFromInt(0);

    return struct {
        const Self = @This();

        acc: Acc,
        state: State,
        fused: bool,
        alloc: std.mem.Allocator,
        bare: ArrayList([]const u8),
        conf: C,
        bank: Bank,

        pub fn init(alloc: std.mem.Allocator) !Self {
            var bank = try Bank.init(alloc);

            return Self{
                .acc = Acc.init(bank),
                .state = blank,
                .fused = false,
                .bare = ArrayList([]const u8).init(alloc),
                .conf = C.init(opt),
                .alloc = alloc,
                .bank = bank,
            };
        }

        pub fn deinit(self: *Self) void {
            self.bank.deinit();
        }

        pub fn bootstrap_env(self: *Self) Error!void {
            var env_map = try std.process.getEnvMap(self.alloc);
            defer env_map.deinit();

            inline for (@typeInfo(@TypeOf(opt)).Struct.fields, 1..) |field, i| {
                if (@field(opt, field.name).env) |env| {
                    if (env_map.get(env)) |value| {
                        const state: State = @enumFromInt(i);

                        try self.acc.set(state, value);
                    }
                }
            }
        }

        pub fn visit(self: *Self, arg: []const u8) Error!void {
            if (!self.fused) {
                if (self.state != blank) {
                    try self.acc.set(self.state, arg);
                    self.state = blank;
                } else if (std.mem.eql(u8, arg, "--")) {
                    self.fused = true;
                } else if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                    return Error.ShowHelp;
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

            var state = blank;

            if (!long) {
                state = self.conf.short_lookup(arg[1]) orelse {
                    std.debug.print("invalid arg found {s}\n", .{arg});
                    return Error.InvalidArg;
                };
            } else {
                state = self.conf.long_lookup(arg[2..]) orelse {
                    return Error.InvalidArg;
                };
            }

            if (!is_bool(state)) {
                self.state = state;
            } else {
                self.acc.set_flag(state);
            }
        }

        fn is_bool(state: State) bool {
            const st_val = @intFromEnum(state);
            if (st_val == 0)
                return false;

            inline for (struct_def.fields, 1..) |field, i| {
                if (st_val == i) {
                    return field.type == bool;
                }
            }
            return false;
        }
    };
}

fn store_type(comptime T: type) type {
    switch (@typeInfo(T)) {
        .Optional => |o| {
            return store_type(o.child);
        },

        .Bool => {
            return @Type(Type.Bool);
        },

        .Pointer => |ti| {
            if (ti.size == .Slice and ti.child == u8) {
                return Bank.Entry;
            } else {
                return @Type(Type{ .Optional = Type.Optional{ .child = T } });
            }
        },

        else => {
            return @Type(Type{ .Optional = Type.Optional{ .child = T } });
        },
    }
}

fn accumulator(comptime T: type, comptime State: type) type {
    const struct_def = @typeInfo(T).Struct;

    comptime var fields: [struct_def.fields.len]Type.StructField = undefined;

    for (struct_def.fields, 0..) |field, i| {
        switch (@typeInfo(field.type)) {
            .Optional => {
                fields[i] = Type.StructField{
                    .name = field.name,
                    .type = store_type(field.type),
                    .is_comptime = false,
                    .default_value = null,
                    .alignment = 8,
                };
            },

            .Bool => {
                fields[i] = Type.StructField{
                    .name = field.name,
                    .type = bool,
                    .is_comptime = false,
                    .default_value = &false,
                    .alignment = 8,
                };
            },

            .Pointer => |p| {
                if (p.size == .Slice and p.child == u8) {
                    fields[i] = Type.StructField{
                        .name = field.name,
                        .type = store_type(field.type),
                        .alignment = 8,
                        .is_comptime = false,
                        .default_value = &Bank.Entry.default(),
                    };
                } else {
                    fields[i] = Type.StructField{
                        .name = field.name,
                        .type = store_type(field.type),
                        .alignment = field.alignment,
                        .is_comptime = false,
                        .default_value = null,
                    };
                }
            },

            else => {
                fields[i] = Type.StructField{
                    .name = field.name,
                    .type = store_type(field.type),
                    .alignment = field.alignment,
                    .is_comptime = false,
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
        bank: Bank,

        pub fn init(bank: Bank) Self {
            var inner: Inner = undefined;

            inline for (@typeInfo(T).Struct.fields) |field| {
                if (field.type == bool) {
                    @field(inner, field.name) = false;
                } else if (@TypeOf(@field(inner, field.name)) == Bank.Entry) {
                    @field(inner, field.name) = Bank.Entry.default();
                } else {
                    @field(inner, field.name) = null;
                }
            }

            return Self{
                .inner = inner,
                .bank = bank,
            };
        }

        pub fn set(self: *Self, state: State, arg: []const u8) !void {
            if (@intFromEnum(state) == 0) unreachable;

            inline for (struct_def.fields, 1..) |field, i| {
                if (@intFromEnum(state) == i) {
                    switch (@typeInfo(field.type)) {
                        .Bool => {},
                        .Enum => |e| {
                            if (@hasDecl(field.type, "parse")) {
                                if (field.type.parse(arg)) |val| {
                                    @field(self.inner, field.name) = val;
                                } else {
                                    return Error.ArgParse;
                                }
                            } else {
                                inline for (e.fields) |ef| {
                                    if (std.mem.eql(u8, ef.name, arg)) {
                                        @field(self.inner, field.name) = @enumFromInt(ef.value);

                                        break;
                                    }
                                }
                            }
                        },

                        .Int => {
                            const val = std.fmt.parseInt(field.type, arg, 10) catch {
                                return Error.ArgParse;
                            };

                            @field(self.inner, field.name) = val;
                        },

                        .Union => {
                            if (@hasDecl(field.type, "parse")) {
                                if (field.type.parse(arg)) |val| {
                                    @field(self.inner, field.name) = val;
                                } else {
                                    return Error.ArgParse;
                                }
                            } else {
                                @compileError("expected `" ++ @typeName(field.type) ++ "` to implement `parse`");
                            }
                        },

                        .Struct => {
                            if (@hasDecl(field.type, "parse")) {
                                if (field.type.parse(arg)) |val| {
                                    @field(self.inner, field.name) = val;
                                } else {
                                    return Error.ArgParse;
                                }
                            } else {
                                @compileError("expected `" ++ @typeName(field.type) ++ "` to implement `parse`");
                            }
                        },

                        else => {
                            if (@TypeOf(@field(self.inner, field.name)) == Bank.Entry) {
                                @field(self.inner, field.name) = try self.bank.record(arg);
                            } else {
                                @field(self.inner, field.name) = arg;
                            }
                        },
                    }
                }
            }
        }

        pub fn set_flag(self: *Self, state: State) void {
            if (@intFromEnum(state) == 0) unreachable;

            inline for (struct_def.fields, 1..) |field, i| {
                if (@intFromEnum(state) == i) {
                    switch (@typeInfo(field.type)) {
                        .Bool => {
                            @field(self.inner, field.name) = true;
                        },

                        else => {},
                    }
                }
            }
        }

        pub fn finalize(self: *Self) Error!T {
            var res: T = undefined;

            inline for (struct_def.fields) |field| {
                const val = @field(self.inner, field.name);

                if (@TypeOf(val) == Bank.Entry) {
                    const nullable = switch (@typeInfo(field.type)) {
                        .Optional => true,
                        else => false,
                    };

                    if (val.is_empty()) {
                        if (nullable) {
                            @field(res, field.name) = null;
                        } else {
                            return Error.MissingArg;
                        }
                    } else {
                        @field(res, field.name) = try self.bank.retrieve(val);
                    }
                } else {
                    switch (@typeInfo(field.type)) {
                        .Optional => {
                            @field(res, field.name) = val;
                        },

                        .Bool => {
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

    for (struct_def.fields, 1..) |field, i| {
        states[i] = Type.EnumField{
            .name = field.name,
            .value = i,
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

pub fn Conf(comptime T: type, comptime State: type) type {
    return struct {
        const Self = @This();
        const struct_def = @typeInfo(T).Struct;

        opt: T,

        fn init(opt: T) Self {
            return Self{ .opt = opt };
        }

        fn short_lookup(self: Self, flag: u8) ?State {
            inline for (struct_def.fields, 1..) |field, i| {
                if (@field(self.opt, field.name).short) |short| {
                    if (short == flag) {
                        return @enumFromInt(i);
                    }
                }
            }

            return null;
        }

        fn long_lookup(self: Self, flag: []const u8) ?State {
            inline for (struct_def.fields, 1..) |field, i| {
                if (@field(self.opt, field.name).long) |long| {
                    if (std.mem.eql(u8, long, flag)) {
                        return @enumFromInt(i);
                    }
                }
            }

            return null;
        }
    };
}

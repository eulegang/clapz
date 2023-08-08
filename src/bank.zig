const std = @import("std");

const List = std.ArrayList;

pub const Bank = struct {
    const Self = @This();

    pub const Error = std.mem.Allocator.Error || error{InvalidEntry};

    pub const Entry = packed struct {
        offset: u32,
        len: u32,

        pub fn default() Entry {
            return Entry{
                .offset = 0,
                .len = 0,
            };
        }

        pub fn is_empty(self: Entry) bool {
            return self.offset == 0 and self.len == 0;
        }
    };

    buf: *List(u8),

    pub fn init(alloc: std.mem.Allocator) !Self {
        var buf = try alloc.create(List(u8));
        buf.* = List(u8).init(alloc);
        return Self{
            .buf = buf,
        };
    }

    pub fn deinit(self: *Self) void {
        const alloc = self.buf.allocator;
        self.buf.deinit();

        alloc.destroy(self.buf);
    }

    pub fn record(self: *Self, rec: []const u8) Error!Entry {
        const offset: u32 = @truncate(self.buf.items.len);
        const len: u32 = @truncate(rec.len);
        try self.buf.appendSlice(rec);

        const entry = Entry{
            .offset = offset,
            .len = len,
        };

        return entry;
    }

    pub fn retrieve(self: *Self, entry: Entry) Error![]const u8 {
        if (entry.offset + entry.len > self.buf.items.len)
            return Error.InvalidEntry;

        return self.buf.items[entry.offset..][0..entry.len];
    }
};

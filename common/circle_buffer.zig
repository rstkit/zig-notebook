const std = @import("std");

pub fn CircBuf(comptime T: type, S: comptime_int) type {
    return struct {
        const Self = @This();

        head: usize = 0,
        tail: usize = 0,
        size: usize = 0,

        items: [S]T align(64),

        // init, initializes the circular buffer by filling it with zeroes.
        pub fn init(self: *Self) void {
            for (0..S) |_| {
                self.push(0);
            }
        }

        // Push a new value onto the circular array
        pub inline fn push(self: *Self, value: T) void {
            if (self.size == S) {
                // The array is full, overwrite the oldest value
                self.head = (self.head + 1) % S;
            } else {
                self.size += 1;
            }
            self.items[self.tail] = value;
            self.tail = (self.tail + 1) % S;
        }

        pub fn debug(self: *const Self) void {
            std.log.debug(
                "self.size: {d}, self.head: {d}, self.tail: {d}",
                .{
                    self.size,
                    self.head,
                    self.tail,
                },
            );
        }

        pub inline fn atIndex(self: *const Self, val: usize) T {
            const idx = (self.head + val) % S;
            return self.items[idx];
        }

        // Function to iterate over the circular array from the oldest value
        pub fn print(self: *Self) void {
            std.log.debug("Start:--------", .{});
            for (0..self.size) |i| {
                const idx = (self.head + i) % S;
                std.log.debug("val => {d}", .{self.items[idx]});
            }
            std.log.debug("End:--------", .{});
        }
    };
}

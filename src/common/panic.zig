const print = @import("print.zig").print;

pub fn PANIC(comptime file: []const u8, comptime line: usize, comptime fmt: []const u8, args: anytype) noreturn {
    print("PANIC: {s}:{d}: ", .{ file, line });
    print(fmt ++ "\n", args);

    while (true) {}
}

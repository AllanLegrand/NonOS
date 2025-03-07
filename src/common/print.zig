const putchar = @import("putchar.zig").putchar;

pub fn print(comptime fmt: []const u8, args: anytype) void {
    const ArgsType = @TypeOf(args);

    if (@typeInfo(ArgsType) != .Struct)
        @compileError("Expected tuple or struct argument, found " ++ @typeName(ArgsType));

    comptime var expected_args: usize = 0;
    comptime var fmt_j: usize = 0;
    inline while (fmt_j < fmt.len) : (fmt_j += 1) {
        if (fmt[fmt_j] == '{') {
            if (fmt_j + 1 < fmt.len and fmt[fmt_j + 1] == '{') {
                fmt_j += 1;
                continue;
            }

            fmt_j += 1;

            if (fmt_j >= fmt.len or fmt[fmt_j] != 's' and fmt[fmt_j] != 'd' and fmt[fmt_j] != 'x')
                @compileError("Invalid or unterminated format specifier");

            fmt_j += 1;

            if (fmt_j >= fmt.len or fmt[fmt_j] != '}')
                @compileError("Unterminated format specifier");

            expected_args += 1;
        } else if (fmt[fmt_j] == '}') {
            if (fmt_j + 1 >= fmt.len or fmt[fmt_j + 1] != '}')
                @compileError("Lone '}' without matching '}}'");

            fmt_j += 1;
        }
    }

    comptime {
        if (args.len < expected_args)
            @compileError("Too few arguments provided for format string: expected " ++
                @typeName(@TypeOf(expected_args)) ++ " got " ++ @typeName(@TypeOf(args.len)));
        if (args.len > expected_args)
            @compileError("Too many arguments provided for format string: expected " ++
                @typeName(@TypeOf(expected_args)) ++ " got " ++ @typeName(@TypeOf(args.len)));
    }

    comptime var arg_i: usize = 0;
    comptime var fmt_i: usize = 0;

    inline while (fmt_i < fmt.len) : (fmt_i += 1) {
        if (fmt[fmt_i] == '}') {
            if (fmt_i + 1 < fmt.len and fmt[fmt_i + 1] == '}') {
                putchar('}');
                fmt_i += 1;
                continue;
            }
            unreachable;
        }

        if (fmt[fmt_i] != '{') {
            putchar(fmt[fmt_i]);
            continue;
        }

        fmt_i += 1;

        if (fmt[fmt_i] == '{') {
            putchar('{');
            continue;
        }

        const argument = args[arg_i];
        const T = @TypeOf(argument);

        switch (fmt[fmt_i]) {
            's' => {
                if (@typeInfo(T) != .Pointer)
                    @compileError("Format specifier 's' expects an string, got " ++ @typeName(T));

                for (argument) |c|
                    putchar(c);
            },
            'd' => {
                if (@typeInfo(T) != .Int and @typeInfo(T) != .ComptimeInt)
                    @compileError("Format specifier 'd' expects an integer, got " ++ @typeName(T));

                comptime var magnitude = argument;

                if (magnitude < 0) {
                    putchar('-');
                    magnitude = -magnitude;
                }

                comptime var divisor = 1;
                inline while (magnitude / divisor > 9)
                    divisor *= 10;

                inline while (divisor > 0) {
                    putchar('0' + magnitude / divisor);
                    magnitude %= divisor;
                    divisor /= 10;
                }
            },
            'x' => {
                if (@typeInfo(T) != .Int and @typeInfo(T) != .ComptimeInt)
                    @compileError("Format specifier 'x' expects an integer, got " ++ @typeName(T));

                comptime var i = 7;
                inline while (i >= 0) : (i -= 1) {
                    const nibble: usize = (argument >> (i * 4)) & 0xf;
                    putchar("0123456789abcdef"[nibble]);
                }
            },
            else => unreachable,
        }

        fmt_i += 1;
        arg_i += 1;
    }
}

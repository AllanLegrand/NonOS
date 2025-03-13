// common/io.zig

const sbiret = struct {
    err: usize,
    value: usize,
};

fn sbi_call(arg0: usize, arg1: usize, arg2: usize, arg3: usize, arg4: usize, arg5: usize, fid: usize, eid: usize) sbiret {
    var a0: usize = arg0;
    var a1: usize = arg1;
    const a2: usize = arg2;
    const a3: usize = arg3;
    const a4: usize = arg4;
    const a5: usize = arg5;
    const a6: usize = fid;
    const a7: usize = eid;

    asm volatile ("ecall"
        : [err] "={a0}" (a0),
          [value] "={a1}" (a1),
        : [a0] "{a0}" (a0),
          [a1] "{a1}" (a1),
          [a2] "{a2}" (a2),
          [a3] "{a3}" (a3),
          [a4] "{a4}" (a4),
          [a5] "{a5}" (a5),
          [a6] "{a6}" (a6),
          [a7] "{a7}" (a7),
        : "memory"
    );

    return sbiret{ .err = a0, .value = a1 };
}

pub export fn putchar(ch: u8) void {
    _ = sbi_call(ch, 0, 0, 0, 0, 0, 0, 1);
}

pub fn print(comptime fmt: []const u8, args: anytype) void {
    const ArgsType = @TypeOf(args);

    if (@typeInfo(ArgsType) != .@"struct")
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
                if (@typeInfo(T) != .pointer)
                    @compileError("Format specifier 's' expects an string, got " ++ @typeName(T));

                for (argument) |c|
                    putchar(c);
            },
            'd' => {
                if (@typeInfo(T) != .int and @typeInfo(T) != .comptime_int)
                    @compileError("Format specifier 'd' expects an integer, got " ++ @typeName(T));

                var magnitude = argument;

                if (magnitude < 0) {
                    putchar('-');
                    magnitude = -magnitude;
                }

                var divisor: @TypeOf(magnitude) = 1;
                while (magnitude / divisor > 9)
                    divisor *= 10;

                while (divisor > 0) {
                    const digit: u8 = @intCast(magnitude / divisor);
                    putchar('0' + digit);
                    magnitude %= divisor;
                    divisor /= 10;
                }
            },
            'x' => {
                if (@typeInfo(T) != .int and @typeInfo(T) != .comptime_int)
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

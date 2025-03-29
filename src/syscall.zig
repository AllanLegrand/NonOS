// syscall.zig

pub const SYSCALL = enum(usize) {
    PUTCHAR = 1,
    GETCHAR = 2,
    EXIT = 3,
    _,
};

pub fn syscall(sysno: usize, arg0: usize, arg1: usize, arg2: usize) usize {
    var a0: usize = arg0;
    const a1: usize = arg1;
    const a2: usize = arg2;
    const a3: usize = sysno;

    asm volatile ("ecall"
        : [sys] "={a0}" (a0),
        : [a0] "{a0}" (a0),
          [a1] "{a1}" (a1),
          [a2] "{a2}" (a2),
          [a3] "{a3}" (a3),
        : "memory"
    );

    return a0;
}

pub fn putchar(ch: u8) callconv(.c) void {
    _ = syscall(@intFromEnum(SYSCALL.PUTCHAR), ch, 0, 0);
}

pub fn getchar() u8 {
    return @intCast(syscall(@intFromEnum(SYSCALL.GETCHAR), 0, 0, 0));
}

pub export fn exit() void {
    _ = syscall(@intFromEnum(SYSCALL.EXIT), 0, 0, 0);
}

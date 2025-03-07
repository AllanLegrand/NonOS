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

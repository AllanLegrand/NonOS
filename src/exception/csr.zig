// exception/csr.zig

pub inline fn READ_CSR(comptime reg: []const u8) usize {
    return asm volatile ("csrr %[out], " ++ reg
        : [out] "=r" (-> usize),
    );
}

pub inline fn WRITE_CSR(comptime reg: []const u8, value: usize) void {
    asm volatile ("csrw " ++ reg ++ ", %[val]"
        :
        : [val] "r" (value),
    );
}

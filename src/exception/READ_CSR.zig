pub inline fn READ_CSR(comptime reg: []const u8) usize {
    return asm volatile ("csrr %[out], " ++ reg
        : [out] "=r" (-> usize),
    );
}

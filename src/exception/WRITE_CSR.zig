pub inline fn WRITE_CSR(comptime reg: []const u8, value: usize) void {
    asm volatile ("csrw " ++ reg ++ ", %[val]"
        :
        : [val] "r" (value),
    );
}

pub noinline fn switch_context(prev_sp: *usize, next_sp: *usize) callconv(.C) void {
    asm volatile (
    // Save callee-saved registers onto the current process's stack.
        \\addi sp, sp, -4 * 13 //Allocate stack space for 13 4-byte registers
        \\sw ra,  0  * 4(sp) // Save callee-saved registers only
        \\sw s0,  1  * 4(sp)
        \\sw s1,  2  * 4(sp)
        \\sw s2,  3  * 4(sp)
        \\sw s3,  4  * 4(sp)
        \\sw s4,  5  * 4(sp)
        \\sw s5,  6  * 4(sp)
        \\sw s6,  7  * 4(sp)
        \\sw s7,  8  * 4(sp)
        \\sw s8,  9  * 4(sp)
        \\sw s9,  10 * 4(sp)
        \\sw s10, 11 * 4(sp)
        \\sw s11, 12 * 4(sp)

        // Switch the stack pointer.
        \\sw sp, (a0) // *prev_sp = sp;
        \\lw sp, (a1) // Switch stack pointer (sp) here

        // Restore callee-saved registers from the next process's stack.
        \\lw ra,  0  * 4(sp) // Restore callee-saved registers only
        \\lw s0,  1  * 4(sp)
        \\lw s1,  2  * 4(sp)
        \\lw s2,  3  * 4(sp)
        \\lw s3,  4  * 4(sp)
        \\lw s4,  5  * 4(sp)
        \\lw s5,  6  * 4(sp)
        \\lw s6,  7  * 4(sp)
        \\lw s7,  8  * 4(sp)
        \\lw s8,  9  * 4(sp)
        \\lw s9,  10 * 4(sp)
        \\lw s10, 11 * 4(sp)
        \\lw s11, 12 * 4(sp)
        \\addi sp, sp, 13 * 4 // We've popped 13 4-byte registers from the stack
        \\ret
        :
        : [prev_sp] "r" (prev_sp),
          [next_sp] "r" (next_sp),
        : "memory"
    );
}

const common = @import("common.zig");

const __bss = @extern([*]u8, .{ .name = "__bss" });
const __bss_end = @extern([*]u8, .{ .name = "__bss_end" });
const __stack_top = @extern([*]u8, .{ .name = "__stack_top" });

const __free_ram = @extern([*]u8, .{ .name = "__free_ram" });
const __free_ram_end = @extern([*]u8, .{ .name = "__free_ram_end" });

const PAGE_SIZE = 4096;

const PROCS_MAX = 8; // Maximum number of processes

const process = struct {
    pid: usize, // Process ID
    state: enum { PROC_UNUSED, PROC_RUNNABLE },
    sp: usize, // Stack pointer
    stack: [8192]u8, // Kernel stack
};

var procs: [PROCS_MAX]process = undefined;

pub fn create_process(pc: usize) *process {
    var proc: ?*process = null;

    var i: usize = 0;
    while (i < PROCS_MAX) : (i += 1) {
        if (procs[i].state == .PROC_UNUSED) {
            proc = &procs[i];
            break;
        }
    }

    if (proc == null) {
        const src = @src();
        common.PANIC(src.file, src.line, "no free process slots", .{});
    }

    const unwrapped_proc = proc.?;

    const stack_top = @intFromPtr(&unwrapped_proc.stack) + unwrapped_proc.stack.len;
    const aligned_top: usize = stack_top & ~@as(usize, 0xF);
    var sp: [*]usize = @ptrFromInt(aligned_top - 13 * @sizeOf(usize));

    sp[0] = pc; // ra

    inline for (1..13) |reg|
        sp[reg] = 0;

    unwrapped_proc.pid = i + 1;
    unwrapped_proc.state = .PROC_RUNNABLE;
    unwrapped_proc.sp = @intFromPtr(sp);

    return unwrapped_proc;
}

noinline fn switch_context(prev_sp: *usize, next_sp: *usize) callconv(.C) void {
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

fn delay() void {
    for (0..30000000) |_| {
        asm volatile ("nop");
    }
}

var proc_a: *process = undefined;
var proc_b: *process = undefined;

fn proc_a_entry() void {
    common.print("starting process A\n", .{});

    while (true) {
        common.putchar('A');
        common.print("A switching to B: prev_sp={x}, next_sp={x}\n", .{ proc_a.sp, proc_b.sp });
        switch_context(&proc_a.sp, &proc_b.sp);
        common.putchar('C');
        delay();
    }
}

fn proc_b_entry() void {
    common.print("starting process B\n", .{});

    while (true) {
        common.putchar('B');
        common.print("B switching to A: prev_sp={x}, next_sp={x}\n", .{ proc_b.sp, proc_a.sp });
        switch_context(&proc_b.sp, &proc_a.sp);
        common.putchar('D');
        delay();
    }
}

export fn alloc_pages(n: usize) usize {
    var next_paddr: usize = @intFromPtr(__free_ram);
    const paddr = next_paddr;

    const size = n * PAGE_SIZE;
    next_paddr += size;

    if (next_paddr > @intFromPtr(__free_ram_end)) {
        const src = @src();
        common.PANIC(src.file, src.line, "out of memory", .{});
    }

    const ptr = @as([*]u8, @ptrFromInt(paddr));
    common.memset(ptr[0..size], 0);

    return paddr;
}

export fn kernel_main() void {
    const __bss_len = @intFromPtr(__bss_end) - @intFromPtr(__bss);

    common.memset(__bss[0..__bss_len], 0);

    WRITE_CSR("stvec", @intFromPtr(&kernel_entry));

    common.print("Hello {s}\n", .{"world"});

    proc_a = create_process(@intFromPtr(&proc_a_entry));
    proc_b = create_process(@intFromPtr(&proc_b_entry));

    proc_a_entry();

    const src = @src();
    common.PANIC(src.file, src.line, "unreachable here!", .{});

    while (true) {}
}

export fn boot() linksection(".text.boot") callconv(.Naked) void {
    asm volatile (
        \\mv sp, %[stack_top] // Set the stack pointer
        \\j kernel_main       // Jump to the kernel main function
        :
        : [stack_top] "r" (__stack_top),
    );
}

export fn kernel_entry() align(4) callconv(.Naked) void {
    asm volatile (
        \\ csrw sscratch, sp
        \\ addi sp, sp, -4 * 31
        \\ sw ra,  4 * 0(sp)
        \\ sw gp,  4 * 1(sp)
        \\ sw tp,  4 * 2(sp)
        \\ sw t0,  4 * 3(sp)
        \\ sw t1,  4 * 4(sp)
        \\ sw t2,  4 * 5(sp)
        \\ sw t3,  4 * 6(sp)
        \\ sw t4,  4 * 7(sp)
        \\ sw t5,  4 * 8(sp)
        \\ sw t6,  4 * 9(sp)
        \\ sw a0,  4 * 10(sp)
        \\ sw a1,  4 * 11(sp)
        \\ sw a2,  4 * 12(sp)
        \\ sw a3,  4 * 13(sp)
        \\ sw a4,  4 * 14(sp)
        \\ sw a5,  4 * 15(sp)
        \\ sw a6,  4 * 16(sp)
        \\ sw a7,  4 * 17(sp)
        \\ sw s0,  4 * 18(sp)
        \\ sw s1,  4 * 19(sp)
        \\ sw s2,  4 * 20(sp)
        \\ sw s3,  4 * 21(sp)
        \\ sw s4,  4 * 22(sp)
        \\ sw s5,  4 * 23(sp)
        \\ sw s6,  4 * 24(sp)
        \\ sw s7,  4 * 25(sp)
        \\ sw s8,  4 * 26(sp)
        \\ sw s9,  4 * 27(sp)
        \\ sw s10, 4 * 28(sp)
        \\ sw s11, 4 * 29(sp)
        \\ csrr a0, sscratch
        \\ sw a0, 4 * 30(sp)
        \\ mv a0, sp
        \\ call handle_trap
        \\ lw ra,  4 * 0(sp)
        \\ lw gp,  4 * 1(sp)
        \\ lw tp,  4 * 2(sp)
        \\ lw t0,  4 * 3(sp)
        \\ lw t1,  4 * 4(sp)
        \\ lw t2,  4 * 5(sp)
        \\ lw t3,  4 * 6(sp)
        \\ lw t4,  4 * 7(sp)
        \\ lw t5,  4 * 8(sp)
        \\ lw t6,  4 * 9(sp)
        \\ lw a0,  4 * 10(sp)
        \\ lw a1,  4 * 11(sp)
        \\ lw a2,  4 * 12(sp)
        \\ lw a3,  4 * 13(sp)
        \\ lw a4,  4 * 14(sp)
        \\ lw a5,  4 * 15(sp)
        \\ lw a6,  4 * 16(sp)
        \\ lw a7,  4 * 17(sp)
        \\ lw s0,  4 * 18(sp)
        \\ lw s1,  4 * 19(sp)
        \\ lw s2,  4 * 20(sp)
        \\ lw s3,  4 * 21(sp)
        \\ lw s4,  4 * 22(sp)
        \\ lw s5,  4 * 23(sp)
        \\ lw s6,  4 * 24(sp)
        \\ lw s7,  4 * 25(sp)
        \\ lw s8,  4 * 26(sp)
        \\ lw s9,  4 * 27(sp)
        \\ lw s10, 4 * 28(sp)
        \\ lw s11, 4 * 29(sp)
        \\ lw sp,  4 * 30(sp)
        \\ sret
    );
}

const trap_frame = packed struct {
    ra: usize,
    gp: usize,
    tp: usize,
    t0: usize,
    t1: usize,
    t2: usize,
    t3: usize,
    t4: usize,
    t5: usize,
    t6: usize,
    a0: usize,
    a1: usize,
    a2: usize,
    a3: usize,
    a4: usize,
    a5: usize,
    a6: usize,
    a7: usize,
    s0: usize,
    s1: usize,
    s2: usize,
    s3: usize,
    s4: usize,
    s5: usize,
    s6: usize,
    s7: usize,
    s8: usize,
    s9: usize,
    s10: usize,
    s11: usize,
    sp: usize,
};

export fn handle_trap(f: *trap_frame) void {
    _ = f;

    const scause = READ_CSR("scause");
    const stval = READ_CSR("stval");
    const user_pc = READ_CSR("sepc");

    const src = @src();
    common.PANIC(src.file, src.line, "unexpected trap scause={x}, stval={x}, sepc={x}", .{ scause, stval, user_pc });
}

inline fn READ_CSR(comptime reg: []const u8) usize {
    return asm volatile ("csrr %[out], " ++ reg
        : [out] "=r" (-> usize),
    );
}

inline fn WRITE_CSR(comptime reg: []const u8, value: usize) void {
    asm volatile ("csrw " ++ reg ++ ", %[val]"
        :
        : [val] "r" (value),
    );
}

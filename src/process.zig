// process.zig

const common = @import("common.zig");
const __kernel_base = @import("kernel.zig").__kernel_base;
const __free_ram_end = @import("kernel.zig").__free_ram_end;
const page = @import("page.zig");
const USER_BASE = @import("kernel.zig").USER_BASE;
const SSTATUS_SPIE = @import("kernel.zig").SSTATUS_SPIE;

pub const PROCS_MAX = 8; // Maximum number of processes

pub const process = struct {
    pid: usize, // Process ID
    state: enum { PROC_UNUSED, PROC_RUNNABLE, PROC_EXITED },
    sp: usize, // Stack pointer
    page_table: [*]usize,
    stack: [8192]u8, // Kernel stack

    pub fn create_process(image: []const u8) *process {
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

        sp[0] = @intFromPtr(&user_entry); // ra

        inline for (1..13) |reg|
            sp[reg] = 0;

        const page_table = @as([*]usize, @alignCast(@ptrCast(page.alloc_pages(1))));
        var paddr: usize = @intFromPtr(__kernel_base);
        const end_addr: usize = @intFromPtr(__free_ram_end);

        // Map kernel pages.
        while (paddr < end_addr) : (paddr += page.PAGE_SIZE)
            page.map_page(page_table, paddr, paddr, page.PAGE_R | page.PAGE_W | page.PAGE_X);

        // Map user pages.
        var off: usize = 0;
        while (off < image.len) : (off += page.PAGE_SIZE) {
            const page_addr = page.alloc_pages(1);
            const remaining = image.len - off;
            const copy_size = if (page.PAGE_SIZE <= remaining) page.PAGE_SIZE else remaining;

            common.memcpy(page_addr[0..copy_size], image[off..][0..copy_size], copy_size);
            page.map_page(page_table, USER_BASE + off, @intFromPtr(page_addr), page.PAGE_U | page.PAGE_R | page.PAGE_W | page.PAGE_X);
        }

        unwrapped_proc.pid = i + 1;
        unwrapped_proc.state = .PROC_RUNNABLE;
        unwrapped_proc.sp = @intFromPtr(sp);
        unwrapped_proc.page_table = page_table;

        return unwrapped_proc;
    }

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
};

pub var procs: [PROCS_MAX]process = undefined;

pub var current_proc: *process = undefined;
pub var idle_proc: *process = undefined;

pub noinline fn yield() void {
    var next: *process = idle_proc;

    var i: usize = 0;
    while (i < PROCS_MAX) : (i += 1) {
        const index = (current_proc.pid + i) % PROCS_MAX;
        const proc = &procs[index];
        if (proc.state == .PROC_RUNNABLE and proc.pid > 0) {
            next = proc;
            break;
        }
    }

    if (next == current_proc)
        return;

    const prev = current_proc;
    current_proc = next;

    asm volatile (
        \\ sfence.vma
        \\ csrw satp, %[satp]
        \\ sfence.vma
        \\ csrw sscratch, %[sscratch]
        :
        : [satp] "r" (page.SATP_SV32 | (@intFromPtr(next.page_table) / page.PAGE_SIZE)),
          [sscratch] "r" (@intFromPtr(&next.stack) + next.stack.len),
    );

    process.switch_context(&prev.sp, &next.sp);
}

fn user_entry() callconv(.Naked) void {
    asm volatile (
        \\ csrw sepc, %[sepc]
        \\ csrw sstatus, %[sstatus]
        \\ sret
        :
        : [sepc] "r" (USER_BASE),
          [sstatus] "r" (SSTATUS_SPIE),
    );
}

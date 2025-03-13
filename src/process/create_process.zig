// process/create_process.zig

const common = @import("../common.zig");
const process_mod = @import("process.zig");
const process = process_mod.process;
const PROCS_MAX = process_mod.PROCS_MAX;
const __kernel_base = @import("../kernel.zig").__kernel_base;
const __free_ram_end = @import("../kernel.zig").__free_ram_end;
const page = @import("../page.zig");

pub fn create_process(pc: usize) *process {
    var proc: ?*process = null;

    var i: usize = 0;
    while (i < PROCS_MAX) : (i += 1) {
        if (process_mod.procs[i].state == .PROC_UNUSED) {
            proc = &process_mod.procs[i];
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

    const page_table = @as([*]usize, @alignCast(@ptrCast(page.alloc_pages(1))));
    var paddr: usize = @intFromPtr(__kernel_base);
    const end_addr: usize = @intFromPtr(__free_ram_end);
    while (paddr < end_addr) : (paddr += page.PAGE_SIZE)
        page.map_page(page_table, paddr, paddr, page.PAGE_R | page.PAGE_W | page.PAGE_X);

    unwrapped_proc.pid = i + 1;
    unwrapped_proc.state = .PROC_RUNNABLE;
    unwrapped_proc.sp = @intFromPtr(sp);
    unwrapped_proc.page_table = page_table;

    return unwrapped_proc;
}

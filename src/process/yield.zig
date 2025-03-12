// process/yield.zig

const process_mod = @import("process.zig");
const process = process_mod.process;
const PROCS_MAX = process_mod.PROCS_MAX;
const switch_context = @import("switch_context.zig").switch_context;
const common = @import("../common.zig");

pub noinline fn yield() void {
    var next: *process = process_mod.idle_proc;

    var i: usize = 0;
    while (i < PROCS_MAX) : (i += 1) {
        const index = (process_mod.current_proc.pid + i) % PROCS_MAX;
        const proc = &process_mod.procs[index];
        if (proc.state == .PROC_RUNNABLE and proc.pid > 0) {
            next = proc;
            break;
        }
    }

    if (next == process_mod.current_proc)
        return;

    asm volatile (
        \\ csrw sscratch, %[sscratch]
        :
        : [sscratch] "r" (@intFromPtr(&next.stack) + next.stack.len),
    );

    const prev = process_mod.current_proc;
    process_mod.current_proc = next;

    switch_context(&prev.sp, &next.sp);
}

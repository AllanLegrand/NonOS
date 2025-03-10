// process/create_process.zig

const common = @import("../common.zig");
const process_mod = @import("process.zig");
const process = process_mod.process;
const PROCS_MAX = process_mod.PROCS_MAX;

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

    unwrapped_proc.pid = i + 1;
    unwrapped_proc.state = .PROC_RUNNABLE;
    unwrapped_proc.sp = @intFromPtr(sp);

    return unwrapped_proc;
}

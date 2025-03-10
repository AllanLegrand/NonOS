pub const switch_context = @import("process/switch_context.zig").switch_context;
pub const create_process = @import("process/create_process.zig").create_process;
pub const process = @import("process/process.zig").process;
pub const procs = @import("process/process.zig").procs;
pub const PROCS_MAX = @import("process/process.zig").PROCS_MAX;

const common = @import("common.zig");

fn delay() void {
    for (0..30000000) |_| {
        asm volatile ("nop");
    }
}

pub var proc_a: *process = undefined;
pub var proc_b: *process = undefined;

pub fn proc_a_entry() void {
    common.print("starting process A\n", .{});

    while (true) {
        common.putchar('A');
        switch_context(&proc_a.sp, &proc_b.sp);
        delay();
    }
}

pub fn proc_b_entry() void {
    common.print("starting process B\n", .{});

    while (true) {
        common.putchar('B');
        switch_context(&proc_b.sp, &proc_a.sp);
        delay();
    }
}

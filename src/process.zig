// process.zig

pub const switch_context = @import("process/switch_context.zig").switch_context;
pub const create_process = @import("process/create_process.zig").create_process;
pub const process_mod = @import("process/process.zig");
pub const process = process_mod.process;
pub const PROCS_MAX = process_mod.PROCS_MAX;
pub const yield = @import("process/yield.zig").yield;

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
        yield();
        delay();
    }
}

pub fn proc_b_entry() void {
    common.print("starting process B\n", .{});

    while (true) {
        common.putchar('B');
        yield();
        delay();
    }
}

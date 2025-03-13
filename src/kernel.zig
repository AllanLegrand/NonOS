// kernel.zig

const common = @import("common.zig");
const process = @import("process.zig");
const exception = @import("exception.zig");
const page = @import("page.zig");

const __bss = @extern([*]u8, .{ .name = "__bss" });
const __bss_end = @extern([*]u8, .{ .name = "__bss_end" });
const __stack_top = @extern([*]u8, .{ .name = "__stack_top" });

const __free_ram = @extern([*]u8, .{ .name = "__free_ram" });
pub const __free_ram_end = @extern([*]u8, .{ .name = "__free_ram_end" });

pub const __kernel_base = @extern([*]u8, .{ .name = "__kernel_base" });

export fn kernel_main() void {
    const __bss_len = @intFromPtr(__bss_end) - @intFromPtr(__bss);

    common.memset(__bss[0..__bss_len], 0);

    exception.WRITE_CSR("stvec", @intFromPtr(&exception.kernel_entry));

    page.next_paddr = @intFromPtr(__free_ram);

    common.print("Hello {s}\n", .{"world"});

    process.proc_a = process.process.create_process(@intFromPtr(&process.proc_a_entry));
    process.proc_b = process.process.create_process(@intFromPtr(&process.proc_b_entry));

    process.idle_proc = process.process.create_process(undefined);
    process.idle_proc.pid = 0;
    process.current_proc = process.idle_proc;

    process.yield();

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

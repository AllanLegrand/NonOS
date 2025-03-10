const common = @import("common.zig");
const process = @import("process.zig");
const exception = @import("exception.zig");

const __bss = @extern([*]u8, .{ .name = "__bss" });
const __bss_end = @extern([*]u8, .{ .name = "__bss_end" });
const __stack_top = @extern([*]u8, .{ .name = "__stack_top" });

const __free_ram = @extern([*]u8, .{ .name = "__free_ram" });
const __free_ram_end = @extern([*]u8, .{ .name = "__free_ram_end" });

const PAGE_SIZE = 4096;

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

    exception.WRITE_CSR("stvec", @intFromPtr(&exception.kernel_entry));

    common.print("Hello {s}\n", .{"world"});

    process.proc_a = process.create_process(@intFromPtr(&process.proc_a_entry));
    process.proc_b = process.create_process(@intFromPtr(&process.proc_b_entry));

    process.proc_a_entry();

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

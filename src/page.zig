const __free_ram_end = @import("kernel.zig").__free_ram_end;
const common = @import("common.zig");

pub const SATP_SV32 = (1 << 31);
pub const PAGE_V = (1 << 0); // "Valid" bit (entry is enabled)
pub const PAGE_R = (1 << 1); // Readable
pub const PAGE_W = (1 << 2); // Writable
pub const PAGE_X = (1 << 3); // Executable
pub const PAGE_U = (1 << 4); // User (accessible in user mode)

pub const PAGE_SIZE = 4096;

pub var next_paddr: usize = undefined;

pub fn alloc_pages(n: usize) [*]u8 {
    const paddr = next_paddr;

    const size = n * PAGE_SIZE;
    next_paddr += size;

    if (next_paddr > @intFromPtr(__free_ram_end)) {
        const src = @src();
        common.PANIC(src.file, src.line, "out of memory", .{});
    }

    const ptr = @as([*]u8, @ptrFromInt(paddr));
    common.memset(ptr[0..size], 0);

    return ptr;
}

fn is_aligned(addr: usize, size: usize) bool {
    return addr & (size - 1) == 0;
}

pub fn map_page(table1: [*]usize, vaddr: usize, paddr: usize, flags: usize) void {
    if (!is_aligned(vaddr, PAGE_SIZE)) {
        const src = @src();
        common.PANIC(src.file, src.line, "unaligned vaddr {x}", .{vaddr});
    }

    if (!is_aligned(paddr, PAGE_SIZE)) {
        const src = @src();
        common.PANIC(src.file, src.line, "unaligned paddr {x}", .{paddr});
    }

    const vpn1 = (vaddr >> 22) & 0x3ff;
    if ((table1[vpn1] & PAGE_V) == 0) {
        // Create the non-existent 2nd level page table.
        const pt_paddr = @intFromPtr(alloc_pages(1));
        table1[vpn1] = ((pt_paddr / PAGE_SIZE) << 10) | PAGE_V;
    }

    // Set the 2nd level page table entry to map the physical page.
    const vpn0 = (vaddr >> 12) & 0x3ff;
    const table0: [*]usize = @ptrFromInt((table1[vpn1] >> 10) * PAGE_SIZE);
    table0[vpn0] = ((paddr / PAGE_SIZE) << 10) | flags | PAGE_V;
}

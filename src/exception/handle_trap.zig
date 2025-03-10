const common = @import("../common.zig");
const trap_frame = @import("trap_frame.zig").trap_frame;
const READ_CSR = @import("READ_CSR.zig").READ_CSR;

pub export fn handle_trap(f: *trap_frame) void {
    _ = f;

    const scause = READ_CSR("scause");
    const stval = READ_CSR("stval");
    const user_pc = READ_CSR("sepc");

    const src = @src();
    common.PANIC(src.file, src.line, "unexpected trap scause={x}, stval={x}, sepc={x}", .{ scause, stval, user_pc });
}

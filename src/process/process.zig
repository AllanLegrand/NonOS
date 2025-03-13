// process/process.zig

pub const PROCS_MAX = 8; // Maximum number of processes

pub const process = struct {
    pid: usize, // Process ID
    state: enum { PROC_UNUSED, PROC_RUNNABLE },
    sp: usize, // Stack pointer
    page_table: [*]usize,
    stack: [8192]u8, // Kernel stack
};

pub var procs: [PROCS_MAX]process = undefined;

pub var current_proc: *process = undefined;
pub var idle_proc: *process = undefined;

// common.zig

pub const print = @import("common/io.zig").print_user;
pub const print_kernel = @import("common/io.zig").print_kernel;
pub const putchar = @import("common/io.zig").putchar;
pub const getchar = @import("common/io.zig").getchar;
pub const memset = @import("common/memory.zig").memset;
pub const memcpy = @import("common/memory.zig").memcpy;
pub const strcpy = @import("common/string.zig").strcpy;
pub const strcmp = @import("common/string.zig").strcmp;
pub const PANIC = @import("common/panic.zig").PANIC;

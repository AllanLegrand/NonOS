// common.zig

pub const print = @import("common/io.zig").print;
pub const putchar = @import("common/io.zig").putchar;
pub const memset = @import("common/memory.zig").memset;
pub const memcpy = @import("common/memory.zig").memcpy;
pub const strcpy = @import("common/string.zig").strcpy;
pub const eql = @import("common/eql.zig").eql;
pub const PANIC = @import("common/panic.zig").PANIC;

// common/memory.zig

pub fn memcopy(dst: []u8, src: []u8, n: usize) void {
    var i: usize = 0;
    while (i < n) : (i += 1)
        dst[i] = src[i];
}

pub fn memset(buffer: []u8, c: u8) void {
    var i: usize = 0;
    while (i < buffer.len) : (i += 1)
        buffer[i] = c;
}

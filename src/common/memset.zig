pub fn memset(buffer: []u8, c: u8) void {
    var i: usize = 0;
    while (i < buffer.len) : (i += 1)
        buffer[i] = c;
}

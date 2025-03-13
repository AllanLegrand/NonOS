// common/string.zig

fn strcpy(dst: []u8, src: []u8) !void {
    if (dst.len < src.len + 1)
        return error.BufferTooSmall;

    for (src, 0..) |c, i|
        dst[i] = c;

    dst[src.len] = 0;
}

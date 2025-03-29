// common/string.zig

pub fn strcpy(dst: []u8, src: []const u8) !void {
    if (dst.len < src.len + 1)
        return error.BufferTooSmall;

    for (src, 0..) |c, i|
        dst[i] = c;

    dst[src.len] = 0;
}

pub fn strcmp(s1: []const u8, s2: []const u8) bool {
    var i: usize = 0;
    while (i < s1.len and i < s2.len) : (i += 1)
        if (s1[i] != s2[i])
            return false;

    return true;
}

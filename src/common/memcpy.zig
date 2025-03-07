fn memcopy(dst: []u8, src: []u8, n: usize) void {
    var i: usize = 0;
    while (i < n) : (i += 1)
        dst[i] = src[i];
}

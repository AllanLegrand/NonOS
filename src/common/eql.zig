pub fn eql(comptime T: type, a: []const T, b: []const T) bool {
    if (a.len != b.len) return false;
    if (a.ptr == b.ptr) return true;
    for (a, 0..a.len) |item, index| {
        if (b[index] != item) return false;
    }
    return true;
}

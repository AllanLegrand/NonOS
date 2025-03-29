const __stack_top = @extern([*]u8, .{ .name = "__stack_top" });

const syscall = @import("syscall.zig");
const common = @import("common.zig");
const print = common.print;
const exit = syscall.exit;

pub export fn start() linksection(".text.start") callconv(.Naked) void {
    asm volatile (
        \\ mv sp, %[stack_top] // Set the stack pointer
        \\ call main
        \\ call exit
        :
        : [stack_top] "r" (__stack_top),
    );
}

export fn main() void {
    while (true) {
        print("> ", .{});
        var cmd_line = [_]u8{0} ** 128;
        var i: usize = 0;
        while (true) : (i += 1) {
            const ch = syscall.getchar();
            syscall.putchar(ch);
            if (i == cmd_line.len - 1) {
                print("command line too long\n", .{});
                continue;
            } else if (ch == '\r') {
                syscall.putchar('\n');
                cmd_line[i] = 0;
                break;
            } else {
                cmd_line[i] = ch;
            }
        }

        if (common.strcmp(cmd_line[0..i], "hello"))
            print("Hello world from shell!\n", .{})
        else if (common.strcmp(cmd_line[0..i], "exit"))
            break
        else
            print("unknown command: {s}\n", .{cmd_line});
    }
}

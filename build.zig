const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{ .cpu_arch = .riscv32, .os_tag = .freestanding, .abi = .none });

    const kernel_exe = b.addExecutable(.{
        .name = "kernel.elf",
        .root_source_file = b.path("src/kernel.zig"),
        .target = target,
        .optimize = .ReleaseSmall,
        .strip = false,
    });

    kernel_exe.setLinkerScript(b.path("src/kernel.ld"));
    kernel_exe.entry = .disabled;

    b.installArtifact(kernel_exe);

    const run_cmd = b.addSystemCommand(&.{
        "qemu-system-riscv32",
    });

    const debug_cmd = b.addSystemCommand(&.{
        "qemu-system-riscv32",
    });

    run_cmd.addArgs(&.{
        "-machine",
        "virt",
        "-bios",
        "default",
        "--no-reboot",
        "-nographic",
        "-kernel",
    });

    debug_cmd.addArgs(&.{
        "-machine",
        "virt",
        "-bios",
        "default",
        "--no-reboot",
        "-nographic",
        "-d",
        "in_asm,cpu",
        "-D",
        "debug.log",
        "-s",
        "-S",
        "-kernel",
    });

    run_cmd.addArtifactArg(kernel_exe);
    debug_cmd.addArtifactArg(kernel_exe);

    const run = b.step("run", "Run QEMU");
    run.dependOn(&run_cmd.step);

    const debug = b.step("debug", "Debug QEMU");
    debug.dependOn(&debug_cmd.step);
}

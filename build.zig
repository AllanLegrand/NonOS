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

    const shell_exe = b.addExecutable(.{
        .name = "shell.elf",
        .root_source_file = b.path("src/user.zig"),
        .target = target,
        .optimize = .ReleaseSmall,
        .strip = false,
    });

    shell_exe.setLinkerScript(b.path("src/user.ld"));
    shell_exe.entry = .disabled;

    b.installArtifact(shell_exe);

    const shell_elf = b.addSystemCommand(&.{
        "llvm-objcopy",
        "-O",
        "binary",
        "--set-section-flags",
        ".bss=alloc,contents",
    });

    shell_elf.addArtifactArg(shell_exe);
    const shell_bin = shell_elf.addOutputFileArg("shell.bin");

    const install_shell_bin = b.addInstallFile(shell_bin, "bin/shell.bin");
    b.getInstallStep().dependOn(&install_shell_bin.step);

    kernel_exe.root_module.addAnonymousImport("shell.bin", .{
        .root_source_file = shell_bin,
    });

    const run_cmd = b.addSystemCommand(&.{
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

    run_cmd.addArtifactArg(kernel_exe);

    const run = b.step("run", "Run QEMU");
    run.dependOn(&run_cmd.step);

    const debug_cmd = b.addSystemCommand(&.{
        "qemu-system-riscv32",
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

    debug_cmd.addArtifactArg(kernel_exe);

    const debug = b.step("debug", "Debug QEMU");
    debug.dependOn(&debug_cmd.step);
}

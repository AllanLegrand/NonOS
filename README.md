# NonOs

## Compile

```bash
zig build
```

## Run

```bash
zig build run
```

## Compile and debug

```bash
zig build && zig build debug 
```

In another terminal :

```bash
riscv64-elf-gdb zig-out/bin/kernel.elf -ex 'target remote localhost:1234' -ex 'b kernel_main' -ex 'c'
```

You can also debug via Qemu with <kbd>Ctrl</kbd>+<kbd>A</kbd> and C

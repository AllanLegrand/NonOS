# NonOs

## Compile

```bash
zig build
```

## Compile and run

```bash
zig build run
```

## Compile and debug

```bash
zig build debug 
```

In another terminal :

```bash
riscv64-elf-gdb zig-out/bin/kernel.elf -ex 'target remote localhost:1234' -ex 'b 0x80200000' -ex 'c'
```



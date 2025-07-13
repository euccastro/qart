# Linux x86-64 System Call ABI Reference

## System Call Invocation

Use the `syscall` instruction (not `int 0x80` which is 32-bit legacy).

## Register Usage

### Input Registers
- **RAX**: System call number
- **RDI**: First argument
- **RSI**: Second argument  
- **RDX**: Third argument
- **R10**: Fourth argument (note: NOT RCX!)
- **R8**: Fifth argument
- **R9**: Sixth argument

### Return Value
- **RAX**: Return value or -errno on error

### Preserved Registers (will NOT be modified)
- RBX, RBP, RSP, R12, R13, R14, R15

### Clobbered Registers (may be DESTROYED)
- RAX (return value)
- RCX, R11 (used by syscall instruction itself)
- RDI, RSI, RDX, R10, R8, R9 (argument registers)

## Why RCX and R11 are Clobbered

The `syscall` instruction itself uses these:
- RCX ← RIP (saves the return address)
- R11 ← RFLAGS (saves the flags register)

## System Calls We've Used

### sys_write (1)
```asm
mov rax, 1          ; System call number
mov rdi, 1          ; File descriptor (1 = stdout)
mov rsi, buffer     ; Pointer to data
mov rdx, length     ; Number of bytes
syscall
; Returns: number of bytes written in RAX, or negative error
```

### sys_exit (60)
```asm
mov rax, 60         ; System call number
mov rdi, 0          ; Exit status code
syscall
; Does not return
```

## Important Notes

1. **Always reload arguments between syscalls** - The previous syscall may have modified RDI, RSI, RDX, etc.

2. **Save important values** - If you need a value after a syscall, save it in a preserved register (like RBX, R12-R15) or on the stack.

3. **Check return values** - Negative RAX means error (the negated errno value).

4. **R10 not RCX** - The 4th argument uses R10, breaking the normal calling convention pattern. This is because syscall uses RCX internally.

## Example: Multiple Syscalls
```asm
; First write
mov rax, 1
mov rdi, 1
mov rsi, msg1
mov rdx, len1
syscall

; MUST reload all arguments for second write!
mov rax, 1          ; Required - RAX now has return value
mov rdi, 1          ; Required - RDI may be modified  
mov rsi, msg2       ; Required - RSI may be modified
mov rdx, len2       ; Required - RDX may be modified
syscall
```

## Common Syscall Numbers
- read: 0
- write: 1
- open: 2
- close: 3
- mmap: 9
- munmap: 11
- exit: 60

See `/usr/include/asm/unistd_64.h` for complete list.
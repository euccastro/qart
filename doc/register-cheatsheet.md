# x86_64 Register Cheatsheet

## Register Name Meanings

The register names are historical abbreviations from the 8086 processor:

| Register | Full Name | Original Purpose |
|----------|-----------|------------------|
| RAX | Accumulator | Math operations, especially with immediate values |
| RBX | Base | Base pointer for data structures |
| RCX | Counter | Loop counter, repeat counts |
| RDX | Data | Data register, I/O operations |
| RSI | Source Index | Source pointer for string operations |
| RDI | Destination Index | Destination pointer for string operations |
| RBP | Base Pointer | Stack frame base pointer |
| RSP | Stack Pointer | Current stack position |
| RIP | Instruction Pointer | Next instruction to execute |

Register prefixes through history:
- **No prefix** (8086): 16-bit registers (AX, SI, etc.)
- **E prefix** (80386): **E**xtended to 32-bit (EAX, ESI, etc.)
- **R prefix** (x86-64): **R**EX-prefix 64-bit registers (RAX, RSI, etc.)

The 'R' refers to the REX (Register Extension) instruction prefix needed to access 64-bit registers:
- RSI (64-bit) → ESI (32-bit) → SI (16-bit)
- RAX (64-bit) → EAX (32-bit) → AX (16-bit) → AL/AH (8-bit)

R8-R15 are new registers added in x86_64 with no historical baggage.

## General Purpose Registers

### Used in Our Forth Implementation

| Register | Special Features | Our Usage | Why This Choice? |
|----------|-----------------|-----------|------------------|
| RAX | • Syscall number & return<br>• Division dividend (low)<br>• Multiplication result<br>• Shorter encodings | • Syscall numbers<br>• Math operations<br>• General computation | Required for syscalls and div/mul |
| RBX | • Callee-saved<br>• General purpose | • Forth instruction pointer (IP) | Arbitrary - needs to be preserved |
| R15 | • Callee-saved<br>• No special meaning | • Forth data stack pointer (DSP) | Better than RBP for C interop |
| R14 | • Callee-saved<br>• No special meaning | • Forth return stack pointer | Callee-saved, no conflicts |
| RDI | • Syscall arg 1<br>• Function arg 1<br>• String destination | • Syscall parameter 1<br>• String operations | Required for syscalls |
| RSI | • Syscall arg 2<br>• Function arg 2<br>• String source | • Syscall parameter 2 | Required for syscalls |
| RDX | • Syscall arg 3<br>• Function arg 3<br>• Division dividend (high)<br>• Multiplication result (high) | • Syscall parameter 3<br>• Division operations<br>• Dictionary entry for DOCOL | Required for syscalls and div |
| RCX | • Syscall arg 4 (not used in Linux)<br>• Function arg 4<br>• Loop counter<br>• REP count | • Divisor in conversions | Arbitrary choice |

### Reserved for Future Use

| Register | Special Features | Planned Usage |
|----------|-----------------|---------------|
| RSP | • Hardware stack pointer | System stack (must not change) |
| RBP | • Traditional frame pointer<br>• Callee-saved | Available - good for C interop |
| R12-R13 | • Callee-saved | TBD - Good for Forth VM registers |
| R8-R11 | • Caller-saved<br>• Function args 5-6 (R8-R9) | TBD - Temporary values |

## Register Categories

### Caller-Saved (Volatile)
RAX, RCX, RDX, RSI, RDI, R8-R11
- Can be destroyed by function calls
- Don't need to preserve

### Callee-Saved (Non-volatile)  
RBX, RBP, RSP, R12-R15
- Must preserve across calls
- Good for Forth VM state

## String Instruction Examples

These show why RSI/RDI are called "Source/Destination Index":

```asm
; Copy memory (like memcpy)
mov rsi, source_addr    ; Source Index points to source
mov rdi, dest_addr      ; Destination Index points to destination  
mov rcx, count          ; Counter holds number of bytes
rep movsb               ; Repeat: copy byte from [RSI] to [RDI], increment both

; Fill memory (like memset)
mov rdi, buffer         ; Destination Index
mov al, 0               ; Value to fill
mov rcx, 1024           ; Counter
rep stosb               ; Repeat: store AL at [RDI], increment RDI

; Search memory (like strchr)
mov rdi, string         ; Destination Index (yes, for searching too!)
mov al, 'X'             ; Character to find
mov rcx, length         ; Counter
repne scasb             ; Repeat while not equal: compare AL with [RDI], increment RDI
```

## Special Uses in Instructions

### Division (DIV)
- Dividend: RDX:RAX (128-bit)
- Divisor: Operand
- Quotient: RAX
- Remainder: RDX

### Multiplication (MUL)
- Multiplicand: RAX
- Multiplier: Operand
- Result: RDX:RAX (128-bit)

### String Operations
- RDI: Destination pointer
- RSI: Source pointer
- RCX: Count (with REP prefix)

### System Calls (Linux x86_64)
- RAX: System call number
- RDI: First argument
- RSI: Second argument
- RDX: Third argument
- R10: Fourth argument (not RCX!)
- R8: Fifth argument
- R9: Sixth argument

## Notes
- Lower portions accessible as 32-bit (EAX), 16-bit (AX), 8-bit (AL/AH)
- R8-R15 have 8-bit access with REX prefix (R8B-R15B)
- RSP must always be 16-byte aligned before calls
; lock-demo.asm - Demonstrates LOCK prefix behavior

%define SYS_write   1
%define SYS_exit    60

section .data
    counter: dq 0
    msg1: db "Without LOCK prefix:", 10
    msg1_len equ $ - msg1
    msg2: db "With LOCK prefix:", 10  
    msg2_len equ $ - msg2

section .text
global _start

_start:
    ; Example 1: INC without LOCK (NOT atomic on SMP)
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, msg1
    mov rdx, msg1_len
    syscall
    
    inc qword [counter]         ; NOT atomic on multiprocessor
    
    ; Example 2: INC with LOCK (atomic)
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, msg2
    mov rdx, msg2_len
    syscall
    
    lock inc qword [counter]    ; Atomic on multiprocessor
    
    ; LOCK can be used with:
    ; - ADD, SUB, INC, DEC
    ; - AND, OR, XOR, NOT, NEG
    ; - BTC, BTR, BTS (bit operations)
    ; - XCHG (always atomic, LOCK not needed)
    ; - CMPXCHG, CMPXCHG8B
    ; - XADD
    
    ; Example: atomic compare-and-swap
    mov rax, 2                  ; Expected value
    mov rbx, 3                  ; New value
    lock cmpxchg [counter], rbx ; If [counter]==rax, set [counter]=rbx
    
    ; Example: atomic add
    lock add qword [counter], 5
    
    ; Example: atomic bit test and set
    lock bts qword [counter], 0 ; Set bit 0
    
    mov rax, SYS_exit
    xor rdi, rdi
    syscall
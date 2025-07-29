; futex-simple.asm - Simple futex wait/wake demo

%define CLONE_VM        0x00000100
%define FUTEX_WAIT      0
%define FUTEX_WAKE      1
%define SYS_write       1
%define SYS_clone       56
%define SYS_exit        60
%define SYS_futex       202

section .data
    align 4
    futex: dd 0             ; 0 = wait, 1 = go
    
    msg1: db "Child: Waiting on futex...", 10
    msg1_len equ $ - msg1
    
    msg2: db "Parent: Waking child...", 10
    msg2_len equ $ - msg2
    
    msg3: db "Child: Woken up!", 10
    msg3_len equ $ - msg3

section .text
global _start

child:
    ; Print waiting message
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, msg1
    mov rdx, msg1_len
    syscall
    
    ; Wait on futex (expecting value 0)
    mov rax, SYS_futex
    lea rdi, [futex]
    mov rsi, FUTEX_WAIT
    mov rdx, 0              ; Expected value
    xor r10, r10            ; No timeout
    syscall
    
    ; Print woken message
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, msg3
    mov rdx, msg3_len
    syscall
    
    ; Exit
    mov rax, SYS_exit
    xor rdi, rdi
    syscall

_start:
    ; Stack for child
    sub rsp, 8192
    mov r12, rsp
    add rsp, 8192
    
    ; Clone child
    mov rax, SYS_clone
    mov rdi, CLONE_VM
    mov rsi, r12
    xor rdx, rdx
    xor r10, r10
    xor r8, r8
    syscall
    
    test rax, rax
    jz child
    
    ; Parent: wait a bit
    mov rcx, 100000000
.delay:
    dec rcx
    jnz .delay
    
    ; Print waking message
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, msg2
    mov rdx, msg2_len
    syscall
    
    ; Wake the child
    mov dword [futex], 1    ; Change value
    mov rax, SYS_futex
    lea rdi, [futex]
    mov rsi, FUTEX_WAKE
    mov rdx, 1              ; Wake 1 thread
    syscall
    
    ; Wait for child to finish
    mov rcx, 100000000
.wait:
    dec rcx
    jnz .wait
    
    ; Exit
    mov rax, SYS_exit
    xor rdi, rdi
    syscall
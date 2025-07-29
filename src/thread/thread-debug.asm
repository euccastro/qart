; thread-debug.asm - Debug clone issues

%define CLONE_VM        0x00000100
%define CLONE_THREAD    0x00010000
%define SYS_write       1
%define SYS_clone       56
%define SYS_exit        60
%define STDOUT          1

section .data
    msg_parent: db "Parent here", 10
    msg_parent_len equ $ - msg_parent
    
    msg_child: db "Child here", 10
    msg_child_len equ $ - msg_child
    
    msg_error: db "Clone failed", 10
    msg_error_len equ $ - msg_error

section .bss
    stack: resb 8192

section .text
global _start

child_func:
    ; Print child message
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, msg_child
    mov rdx, msg_child_len
    syscall
    
    ; Exit
    mov rax, SYS_exit
    xor rdi, rdi
    syscall

_start:
    ; Try simple clone
    mov rax, SYS_clone
    mov rdi, CLONE_VM | CLONE_THREAD
    lea rsi, [stack + 8192]  ; Stack top
    xor rdx, rdx
    xor r10, r10
    xor r8, r8
    syscall
    
    ; Check for error
    cmp rax, -1
    je .error
    
    ; Check if parent or child
    test rax, rax
    jz child_func
    
    ; Parent
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, msg_parent
    mov rdx, msg_parent_len
    syscall
    
    ; Small delay
    mov rcx, 10000000
.delay:
    dec rcx
    jnz .delay
    
    ; Exit
    mov rax, SYS_exit
    xor rdi, rdi
    syscall
    
.error:
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, msg_error
    mov rdx, msg_error_len
    syscall
    
    mov rax, SYS_exit
    mov rdi, 1
    syscall
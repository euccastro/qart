; thread-test.asm - Simplest possible test

%define CLONE_VM        0x00000100
%define SYS_write       1
%define SYS_clone       56
%define SYS_exit        60

section .data
    shared: dq 0
    msg: db "Shared value: "
    msg_len equ $ - msg
    digit: db '0', 10

section .text
global _start

child:
    inc qword [shared]      ; Child increments
    mov rax, SYS_exit
    xor rdi, rdi
    syscall

_start:
    ; Simple stack
    sub rsp, 8192
    mov rsi, rsp
    add rsp, 8192
    
    ; Clone
    mov rax, SYS_clone
    mov rdi, CLONE_VM
    xor rdx, rdx
    xor r10, r10
    xor r8, r8
    syscall
    
    test rax, rax
    jz child
    
    ; Parent increments too
    inc qword [shared]
    
    ; Wait a bit
    mov rcx, 10000000
.wait:
    dec rcx
    jnz .wait
    
    ; Print message
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, msg
    mov rdx, msg_len
    syscall
    
    ; Convert shared value to digit
    mov rax, [shared]
    add al, '0'
    mov [digit], al
    
    ; Print digit
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, digit
    mov rdx, 2
    syscall
    
    mov rax, SYS_exit
    xor rdi, rdi
    syscall
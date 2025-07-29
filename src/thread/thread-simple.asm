; thread-simple.asm - Simplest possible working thread example

%define CLONE_VM        0x00000100
%define SYS_write       1
%define SYS_mmap        9
%define SYS_clone       56
%define SYS_exit        60
%define SYS_nanosleep   35

section .data
    msg1: db "Thread 1 working", 10
    msg1_len equ $ - msg1
    
    msg2: db "Thread 2 working", 10
    msg2_len equ $ - msg2
    
    msg_done: db "Both threads done!", 10
    msg_done_len equ $ - msg_done
    
    ; For nanosleep
    timespec:
        dq 0    ; seconds
        dq 100000000    ; nanoseconds (0.1 sec)
    
    ; Shared completion flags
    align 8
    thread1_done: dq 0
    thread2_done: dq 0

section .text
global _start

thread_func:
    ; Print message 3 times with delays
    mov r12, 3
.loop:
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, msg2
    mov rdx, msg2_len
    syscall
    
    ; Sleep 0.1 sec
    mov rax, SYS_nanosleep
    mov rdi, timespec
    xor rsi, rsi
    syscall
    
    dec r12
    jnz .loop
    
    ; Mark done
    mov qword [thread2_done], 1
    
    ; Exit thread
    mov rax, SYS_exit
    xor rdi, rdi
    syscall

_start:
    ; Allocate stack for thread
    mov rax, SYS_mmap
    xor rdi, rdi
    mov rsi, 8192
    mov rdx, 3          ; PROT_READ|PROT_WRITE
    mov r10, 0x22       ; MAP_PRIVATE|MAP_ANONYMOUS
    mov r8, -1
    xor r9, r9
    syscall
    add rax, 8192       ; Stack top
    
    ; Create thread (without CLONE_THREAD flag)
    mov rsi, rax
    mov rax, SYS_clone
    mov rdi, CLONE_VM   ; Share memory only
    xor rdx, rdx
    xor r10, r10
    xor r8, r8
    syscall
    
    test rax, rax
    jz thread_func      ; Child
    
    ; Parent: print message 3 times
    mov r12, 3
.loop:
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, msg1
    mov rdx, msg1_len
    syscall
    
    ; Sleep 0.1 sec
    mov rax, SYS_nanosleep
    mov rdi, timespec
    xor rsi, rsi
    syscall
    
    dec r12
    jnz .loop
    
    ; Mark done
    mov qword [thread1_done], 1
    
    ; Wait for other thread
.wait:
    cmp qword [thread2_done], 1
    jne .wait
    
    ; Print completion
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, msg_done
    mov rdx, msg_done_len
    syscall
    
    ; Exit
    mov rax, SYS_exit
    xor rdi, rdi
    syscall
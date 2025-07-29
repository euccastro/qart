; futex-mutex.asm - Working futex-based mutex

%define CLONE_VM        0x00000100
%define FUTEX_WAIT      0
%define FUTEX_WAKE      1
%define SYS_write       1
%define SYS_clone       56
%define SYS_exit        60
%define SYS_futex       202

section .data
    align 8
    counter: dq 0
    
    align 4
    mutex: dd 0             ; 0=free, 1=locked
    
    msg: db "Final counter: "
    msg_len equ $ - msg
    nl: db 10

section .text
global _start

; Lock mutex
lock_mutex:
    mov eax, 1
    xchg dword [mutex], eax ; Atomic swap
    test eax, eax
    jz .done                ; Got it
    
    ; Contended - wait
.retry:
    mov rax, SYS_futex
    lea rdi, [mutex]
    mov rsi, FUTEX_WAIT
    mov rdx, 1              ; Wait while mutex=1
    xor r10, r10
    syscall
    
    ; Try again
    mov eax, 1
    xchg dword [mutex], eax
    test eax, eax
    jnz .retry
.done:
    ret

; Unlock mutex
unlock_mutex:
    mov dword [mutex], 0
    
    ; Wake one waiter
    mov rax, SYS_futex
    lea rdi, [mutex]
    mov rsi, FUTEX_WAKE
    mov rdx, 1
    syscall
    ret

; Worker - increment 5000 times
worker:
    mov r12, 5000
.loop:
    call lock_mutex
    inc qword [counter]
    call unlock_mutex
    dec r12
    jnz .loop
    ret

; Thread entry
thread:
    call worker
    mov rax, SYS_exit
    xor rdi, rdi
    syscall

; Print decimal number in rax
print_dec:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov rdi, rbp
    mov rbx, 10
.digit:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rdi
    mov [rdi], dl
    test rax, rax
    jnz .digit
    
    mov rax, SYS_write
    mov rdx, rbp
    sub rdx, rdi        ; Length
    mov rsi, rdi        ; Start
    mov rdi, 1          ; stdout
    syscall
    
    leave
    ret

_start:
    ; Create thread stack
    sub rsp, 8192
    mov rsi, rsp
    add rsp, 8192
    
    ; Clone thread
    mov rax, SYS_clone
    mov rdi, CLONE_VM
    xor rdx, rdx
    xor r10, r10
    xor r8, r8
    syscall
    
    test rax, rax
    jz thread
    
    ; Parent work
    call worker
    
    ; Wait for child (crude)
    mov rcx, 500000000
.wait:
    dec rcx
    jnz .wait
    
    ; Print result
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, msg
    mov rdx, msg_len
    syscall
    
    mov rax, [counter]
    call print_dec
    
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, nl
    mov rdx, 1
    syscall
    
    ; Exit
    mov rax, SYS_exit
    xor rdi, rdi
    syscall
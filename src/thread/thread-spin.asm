; thread-spin.asm - Simple spinlock version

%define CLONE_VM        0x00000100
%define CLONE_THREAD    0x00010000
%define SYS_write       1
%define SYS_mmap        9
%define SYS_clone       56
%define SYS_exit        60
%define STDOUT          1

section .data
    align 8
    counter: dq 0
    done_count: dq 0
    
    align 4
    spinlock: dd 0
    
    msg_result: db "Counter = "
    msg_result_len equ $ - msg_result
    newline: db 10

section .text
global _start

; Simple spinlock acquire
spin_lock:
.retry:
    mov eax, 1
    xchg [spinlock], eax    ; Atomic exchange
    test eax, eax
    jnz .retry              ; Spin if was already locked
    ret

; Simple spinlock release  
spin_unlock:
    mov dword [spinlock], 0
    ret

; Print number in rax
print_num:
    push rbx
    push rcx
    push rdx
    mov rbx, 10
    mov rcx, rsp
    sub rsp, 32
.loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rcx
    mov [rcx], dl
    test rax, rax
    jnz .loop
    mov rax, 1              ; write
    mov rdi, 1              ; stdout
    mov rsi, rcx
    mov rdx, rsp
    sub rdx, rcx
    syscall
    add rsp, 32
    pop rdx
    pop rcx
    pop rbx
    ret

; Worker increments counter 100000 times
worker:
    mov r12, 100000
.loop:
    call spin_lock
    inc qword [counter]
    call spin_unlock
    dec r12
    jnz .loop
    lock inc qword [done_count]
    ret

; Thread entry
thread_entry:
    call worker
    mov rax, SYS_exit
    xor rdi, rdi
    syscall

_start:
    ; Create thread stack
    mov rax, SYS_mmap
    xor rdi, rdi
    mov rsi, 8192
    mov rdx, 3              ; RW
    mov r10, 0x22           ; PRIVATE|ANON
    mov r8, -1
    xor r9, r9
    syscall
    add rax, 8192
    
    ; Create thread
    mov rsi, rax
    mov rax, SYS_clone
    mov rdi, CLONE_VM | CLONE_THREAD
    xor rdx, rdx
    xor r10, r10
    xor r8, r8
    syscall
    
    test rax, rax
    jz thread_entry
    
    ; Parent also works
    call worker
    
    ; Wait for completion
.wait:
    pause
    cmp qword [done_count], 2
    jne .wait
    
    ; Print result
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, msg_result
    mov rdx, msg_result_len
    syscall
    
    mov rax, [counter]
    call print_num
    
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, newline
    mov rdx, 1
    syscall
    
    ; Exit
    mov rax, SYS_exit
    xor rdi, rdi
    syscall
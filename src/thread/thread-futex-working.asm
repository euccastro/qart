; thread-futex-working.asm - Working futex example with clone

%define CLONE_VM        0x00000100
%define FUTEX_WAIT      0
%define FUTEX_WAKE      1
%define SYS_write       1
%define SYS_mmap        9  
%define SYS_clone       56
%define SYS_exit        60
%define SYS_futex       202

section .data
    align 8
    counter: dq 0
    done: dq 0
    
    align 4
    mutex: dd 0             ; 0=unlocked, 1=locked
    
    msg: db "Final count: "
    msg_len equ $ - msg
    newline: db 10
    
    msg_child: db "Child starting", 10
    msg_child_len equ $ - msg_child
    
    msg_parent: db "Parent starting", 10  
    msg_parent_len equ $ - msg_parent

section .text
global _start

; Acquire lock with futex
get_lock:
    mov eax, 1
    xchg [mutex], eax       ; Try to acquire
    test eax, eax
    jz .got_it              ; Was 0, we got it
    
.wait:
    mov eax, [mutex]        ; Re-check before waiting
    test eax, eax
    jz get_lock             ; Unlocked now, retry
    
    ; Wait on futex
    mov rax, SYS_futex
    lea rdi, [mutex]
    mov rsi, FUTEX_WAIT
    mov rdx, 1              ; Expected value
    xor r10, r10
    syscall
    jmp get_lock            ; Try again
    
.got_it:
    ret

; Release lock
put_lock:
    mov dword [mutex], 0
    
    ; Wake one waiter
    mov rax, SYS_futex
    lea rdi, [mutex]
    mov rsi, FUTEX_WAKE
    mov rdx, 1
    syscall
    ret

; Print number
print_num:
    push rbx
    push rcx
    push rdx
    mov rbx, 10
    mov rcx, rsp
    sub rsp, 32
.conv:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rcx
    mov [rcx], dl
    test rax, rax
    jnz .conv
    mov rax, 1
    mov rdi, 1
    mov rsi, rcx
    mov rdx, rsp
    sub rdx, rcx
    syscall
    add rsp, 32
    pop rdx
    pop rcx
    pop rbx
    ret

; Thread work
do_work:
    mov r12, 10000          ; iterations
.loop:
    call get_lock
    inc qword [counter]
    call put_lock
    dec r12
    jnz .loop
    lock inc qword [done]
    ret

; Thread entry  
thread_start:
    ; Print child message
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, msg_child
    mov rdx, msg_child_len
    syscall
    
    call do_work
    mov rax, SYS_exit
    xor rdi, rdi
    syscall

_start:
    ; Create thread stack
    mov rax, SYS_mmap
    xor rdi, rdi
    mov rsi, 8192
    mov rdx, 3
    mov r10, 0x22
    mov r8, -1
    xor r9, r9
    syscall
    add rax, 8192
    
    ; Clone thread
    mov rsi, rax
    mov rax, SYS_clone
    mov rdi, CLONE_VM       ; Just share memory
    xor rdx, rdx
    xor r10, r10
    xor r8, r8
    syscall
    
    test rax, rax
    jz thread_start         ; Child
    
    ; Parent - print message
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, msg_parent
    mov rdx, msg_parent_len
    syscall
    
    ; Parent work
    call do_work
    
    ; Wait for child
.wait:
    cmp qword [done], 2
    jne .wait
    
    ; Print result
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, msg
    mov rdx, msg_len
    syscall
    
    mov rax, [counter]
    test rax, rax           ; Check if counter is 0
    jnz .print_it
    ; Counter is 0, print '0'
    push '0'
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, rsp
    mov rdx, 1
    syscall
    pop rax
    jmp .skip_print
.print_it:
    call print_num
.skip_print:
    
    mov rax, SYS_write
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    mov rax, SYS_exit
    xor rdi, rdi
    syscall
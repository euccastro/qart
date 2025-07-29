; thread-example.asm - Minimal clone+futex threading example
; Shows thread creation and synchronization with futex

%define CLONE_VM        0x00000100  ; Share memory space
%define CLONE_FS        0x00000200  ; Share filesystem info
%define CLONE_FILES     0x00000400  ; Share file descriptors
%define CLONE_SIGHAND   0x00000800  ; Share signal handlers
%define CLONE_THREAD    0x00010000  ; Same thread group
%define CLONE_SYSVSEM   0x00040000  ; Share SysV semaphores
%define CLONE_SETTLS    0x00080000  ; Create new TLS
%define CLONE_PARENT_SETTID 0x00100000
%define CLONE_CHILD_CLEARTID 0x00200000

%define FUTEX_WAIT      0
%define FUTEX_WAKE      1

%define SYS_write       1
%define SYS_mmap        9
%define SYS_clone       56
%define SYS_exit        60
%define SYS_futex       202

%define STDOUT          1
%define PROT_READ       0x1
%define PROT_WRITE      0x2
%define MAP_PRIVATE     0x02
%define MAP_ANONYMOUS   0x20

section .data
    msg1: db "Thread 1: Starting", 10
    msg1_len equ $ - msg1
    
    msg2: db "Thread 2: Starting", 10
    msg2_len equ $ - msg2
    
    msg3: db "Thread 1: Waiting on futex", 10
    msg3_len equ $ - msg3
    
    msg4: db "Thread 2: Waking futex", 10
    msg4_len equ $ - msg4
    
    msg5: db "Thread 1: Woken up!", 10
    msg5_len equ $ - msg5
    
    msg6: db "Main: All done", 10
    msg6_len equ $ - msg6

section .bss
    ; Futex variable (must be 32-bit aligned)
    alignb 4
    futex_var: resd 1
    
    ; Thread stack size
    STACK_SIZE equ 8192

section .text
global _start

; Thread 1 function - waits on futex
thread1_func:
    ; Print starting message
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, msg1
    mov rdx, msg1_len
    syscall
    
    ; Print waiting message
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, msg3
    mov rdx, msg3_len
    syscall
    
    ; Wait on futex (will block until woken)
    mov rax, SYS_futex
    mov rdi, futex_var      ; futex address
    mov rsi, FUTEX_WAIT     ; operation
    mov rdx, 0              ; expected value
    xor r10, r10            ; timeout (NULL = infinite)
    syscall
    
    ; Print woken message
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, msg5
    mov rdx, msg5_len
    syscall
    
    ; Exit thread
    mov rax, SYS_exit
    xor rdi, rdi
    syscall

; Thread 2 function - wakes futex
thread2_func:
    ; Print starting message
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, msg2
    mov rdx, msg2_len
    syscall
    
    ; Sleep a bit (busy wait for demo)
    mov rcx, 100000000
.delay:
    dec rcx
    jnz .delay
    
    ; Print waking message
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, msg4
    mov rdx, msg4_len
    syscall
    
    ; Wake one waiter on futex
    mov rax, SYS_futex
    mov rdi, futex_var      ; futex address
    mov rsi, FUTEX_WAKE     ; operation
    mov rdx, 1              ; wake 1 thread
    syscall
    
    ; Exit thread
    mov rax, SYS_exit
    xor rdi, rdi
    syscall

_start:
    ; Initialize futex to 0
    mov dword [futex_var], 0
    
    ; Allocate stack for thread 1
    mov rax, SYS_mmap
    xor rdi, rdi            ; addr = NULL
    mov rsi, STACK_SIZE     ; length
    mov rdx, PROT_READ | PROT_WRITE
    mov r10, MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1              ; fd = -1
    xor r9, r9              ; offset = 0
    syscall
    mov r12, rax            ; Save thread 1 stack base
    add r12, STACK_SIZE     ; Stack grows down
    
    ; Allocate stack for thread 2
    mov rax, SYS_mmap
    xor rdi, rdi
    mov rsi, STACK_SIZE
    mov rdx, PROT_READ | PROT_WRITE
    mov r10, MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1
    xor r9, r9
    syscall
    mov r13, rax            ; Save thread 2 stack base
    add r13, STACK_SIZE
    
    ; Create thread 1
    mov rax, SYS_clone
    mov rdi, CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND | CLONE_THREAD
    mov rsi, r12            ; child stack
    xor rdx, rdx            ; parent_tid
    xor r10, r10            ; child_tid
    xor r8, r8              ; tls
    syscall
    
    test rax, rax
    jz thread1_func         ; Child jumps to thread function
    
    ; Parent continues, create thread 2
    mov rax, SYS_clone
    mov rdi, CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND | CLONE_THREAD
    mov rsi, r13            ; child stack
    xor rdx, rdx
    xor r10, r10
    xor r8, r8
    syscall
    
    test rax, rax
    jz thread2_func         ; Child jumps to thread function
    
    ; Parent waits a bit for threads to finish
    mov rcx, 200000000
.wait:
    dec rcx
    jnz .wait
    
    ; Print completion message
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, msg6
    mov rdx, msg6_len
    syscall
    
    ; Exit main thread
    mov rax, SYS_exit
    xor rdi, rdi
    syscall
;; thread.asm - Threading primitives for Forth
;; Provides THREAD, WAIT, WAKE

%include "forth.inc"

%define SYS_mmap        9
%define SYS_munmap      11
%define SYS_clone       56
%define SYS_exit        60
%define SYS_futex       202

%define CLONE_VM        0x00000100
%define FUTEX_WAIT      0
%define FUTEX_WAKE      1

section .data

;; Anonymous dictionary entry for thread cleanup
dict_THREAD_CLEANUP:
    dq 0                    ; No link - internal use only
    db 0                    ; Name length 0 (anonymous)
    times 7 db 0            ; Padding to 8 bytes
    dq THREAD_CLEANUP       ; Code field

section .text

;; THREAD ( xt -- error )
;; Execute xt in a new thread with shared memory
;; Thread gets fresh data and return stacks
;; Returns 0 on success, non-zero on error
global THREAD
THREAD:
    ; Save execution token
    mov r12, [DSP]          ; Get xt from stack (don't pop yet)
    
    ; Allocate 8KB for child's stacks
    mov rax, SYS_mmap
    xor rdi, rdi            ; NULL - let kernel choose address
    mov rsi, 8192           ; 8KB total
    mov rdx, 3              ; PROT_READ|PROT_WRITE
    mov r10, 0x22           ; MAP_PRIVATE|MAP_ANONYMOUS
    mov r8, -1              ; No file
    xor r9, r9
    syscall
    
    ; Check for mmap error
    test rax, rax
    js .mmap_error          ; Negative means error
    
    ; Set up stack layout:
    ; Bottom 4KB: Return stack (grows down from +4096)
    ; Top 4KB: Data stack (grows down from +8192)
    lea r13, [rax + 8192]   ; Top of allocated space (for clone)
    mov r11, rax            ; Save base address for child
    
    ; Create thread
    mov rax, SYS_clone
    mov rdi, CLONE_VM       ; Share memory space only
    mov rsi, r13            ; Stack pointer for child
    xor rdx, rdx            ; No parent tid pointer
    xor r10, r10            ; No child tid pointer
    xor r8, r8              ; No tls
    syscall
    
    test rax, rax
    jz .child               ; rax=0 means we're the child
    js .clone_error         ; Negative means error
    
    ; Parent: success - set rax to 0 and fall through
    xor rax, rax
    
.mmap_error:
    ; Store result (0 on success, error code on failure)
    mov [DSP], rax          ; Replace xt with result
    jmp NEXT
    
.clone_error:
    ; clone failed - need to unmap memory first
    push rax                ; Save error code
    mov rdi, r11            ; Base address to unmap
    mov rsi, 8192
    mov rax, SYS_munmap
    syscall
    pop rax                 ; Restore error code
    mov [DSP], rax          ; Replace xt with error code
    jmp NEXT
    
.child:
    ; Child thread initialization
    ; r11 = base of our allocated memory
    ; r12 = execution token to run
    
    ; Set up return stack (bottom 4KB)
    lea RSTACK, [r11 + 4096]
    
    ; Set up data stack (top 4KB) 
    lea DSP, [r11 + 8192]
    
    ; Push cleanup dictionary entry onto return stack
    sub RSTACK, 8
    mov qword [RSTACK], dict_THREAD_CLEANUP
    
    ; Push mmap base address onto data stack
    sub DSP, 8
    mov [DSP], r11
    
    ; Execute the provided xt
    mov rdx, r12            ; xt into rdx for EXECUTE semantics
    mov rax, [rdx + 16]     ; Get code field
    jmp rax                 ; Jump to code

;; THREAD_CLEANUP - Internal cleanup routine for threads
;; ( mmap-base -- )
;; Unmaps thread stacks and exits thread
THREAD_CLEANUP:
    ; When thread's word returns, we end up here
    ; Data stack has mmap base address
    mov rdi, [DSP]          ; Get base address
    mov rsi, 8192           ; Size we allocated
    mov rax, SYS_munmap
    syscall
    
    ; Exit thread
    mov rax, SYS_exit
    xor rdi, rdi            ; Exit code 0
    syscall

;; WAIT ( addr expected -- )
;; Atomically check if *addr == expected, and if so, sleep
;; Uses futex FUTEX_WAIT operation
global WAIT
WAIT:
    mov rdx, [DSP]          ; expected value
    mov rdi, [DSP+8]        ; futex address
    add DSP, 16             ; Pop both args
    
    ; futex(addr, FUTEX_WAIT, expected, NULL, NULL, 0)
    mov rax, SYS_futex
    mov rsi, FUTEX_WAIT
    ; rdx already has expected value
    xor r10, r10            ; No timeout
    xor r8, r8
    xor r9, r9
    syscall
    
    ; We don't check return value - could be:
    ; 0 = woken up normally
    ; -EAGAIN = value didn't match expected
    ; -EINTR = interrupted by signal
    ; All cases just continue execution
    
    jmp NEXT

;; WAKE ( addr n -- n' )
;; Wake up to n threads waiting on addr
;; Returns number of threads actually woken
global WAKE
WAKE:
    mov rdx, [DSP]          ; Number to wake
    mov rdi, [DSP+8]        ; futex address
    add DSP, 8              ; Pop address, leave n on stack for return
    
    ; futex(addr, FUTEX_WAKE, n, NULL, NULL, 0)
    mov rax, SYS_futex
    mov rsi, FUTEX_WAKE
    ; rdx already has number to wake
    xor r10, r10
    xor r8, r8
    xor r9, r9
    syscall
    
    ; Return value is number actually woken
    ; Replace n with actual count
    mov [DSP], rax
    
    jmp NEXT

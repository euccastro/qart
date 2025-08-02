;; thread.asm - Threading primitives for Forth
;; Provides THREAD, FWAIT, WAKE

%include "forth.inc"

extern NEXT

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
    
    ; Basic validation - execution tokens must be 8-byte aligned
    test r12, 7             ; Check low 3 bits
    jnz .invalid_xt         ; Not aligned = invalid
    
    ; Check if address is in kernel space (negative when viewed as signed)
    test r12, r12
    js .invalid_xt          ; Negative = kernel space = invalid
    
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
    
    ; Use RBP for mmap base (it's callee-saved, no need to protect it)
    mov rbp, rax            ; RBP = base address
    
    ; Create thread
    mov rax, SYS_clone
    mov rdi, CLONE_VM       ; Share memory space only
    lea rsi, [rbp + 8192]   ; Stack pointer for child (top of allocation)
    xor rdx, rdx            ; No parent tid pointer
    xor r10, r10            ; No child tid pointer
    xor r8, r8              ; No tls
    syscall
    
    test rax, rax
    jz .child               ; rax=0 means we're the child
    js .clone_error         ; Negative means error
    
    ; Parent: success - return 0
    mov qword [DSP], 0      ; Replace xt with 0 (success)
    jmp NEXT
    
.mmap_error:
    ; mmap failed - return error code
    mov [DSP], rax          ; Replace xt with error code
    jmp NEXT
    
.clone_error:
    ; clone failed - need to unmap memory first
    ; rbp has mmap base (callee-saved, still valid)
    push rax                ; Save error code
    mov rdi, rbp            ; Base address to unmap
    mov rsi, 8192
    mov rax, SYS_munmap
    syscall
    pop rax                 ; Restore error code
    mov [DSP], rax          ; Replace xt with error code
    jmp NEXT
    
.invalid_xt:
    mov qword [DSP], -22    ; -EINVAL  
    jmp NEXT
    
.child:
    ; Child thread initialization
    ; RSP points to top of mmap region (set by clone)
    ; rbp = mmap base (inherited from parent - it's callee-saved!)
    ; r12 = execution token to run
    ; r13 = parent's flags, inherited
    
    ; Set up stacks with proper separation:
    ; Bottom 3KB: Return stack (grows down from +3072)
    ; Middle 4KB: Data stack (grows down from +7168)  
    ; Top 1KB: System stack (grows down from +8192, set by clone)
    lea RSTACK, [rbp + 3072]    ; 3KB mark
    lea DSP, [rbp + 7168]       ; 7KB mark (leaving 1KB for system stack)
    
    ; Push mmap base address onto data stack
    sub DSP, 8
    mov [DSP], rbp
    
    ; Build a mini "program" at the start of our allocated memory:
    ; - User's xt
    ; - THREAD_CLEANUP
    ; We'll point IP at this and jump to NEXT
    
    mov [rbp], r12          ; User's xt at offset 0
    mov rax, dict_THREAD_CLEANUP
    mov [rbp+8], rax        ; Cleanup word at offset 8
    
    ; Point IP at our program
    mov IP, rbp
    
    ; Start execution via NEXT
    jmp NEXT

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

;; FWAIT ( addr expected -- )
;; Atomically check if *addr == expected, and if so, sleep
;; Uses futex FUTEX_WAIT operation
global FWAIT
FWAIT:
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

;; time.asm - Time-related primitives for Forth
;; Provides CLOCK@ for getting nanosecond-precision timestamps

%include "forth.inc"

extern NEXT

%define SYS_clock_gettime   228
%define CLOCK_MONOTONIC     1

section .bss
    align 8
timespec_buffer:
    resq 2                  ; seconds and nanoseconds

section .text

;; CLOCK@ ( -- seconds nanoseconds )
;; Get current monotonic clock time
;; Returns seconds and nanoseconds as two values on stack
global CLOCK_FETCH
CLOCK_FETCH:
    ; clock_gettime(CLOCK_MONOTONIC, &timespec)
    mov rax, SYS_clock_gettime
    mov rdi, CLOCK_MONOTONIC
    lea rsi, [timespec_buffer]
    syscall
    
    ; Check for error
    test rax, rax
    jnz .error
    
    ; Push seconds
    sub DSP, 8
    mov rax, [timespec_buffer]
    mov [DSP], rax
    
    ; Push nanoseconds
    sub DSP, 8
    mov rax, [timespec_buffer + 8]
    mov [DSP], rax
    
    jmp NEXT
    
.error:
    ; On error, push 0 0
    sub DSP, 16
    mov qword [DSP+8], 0
    mov qword [DSP], 0
    jmp NEXT
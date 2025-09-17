;; time.asm - Time-related primitives for Forth
;; Provides CLOCK@ for getting nanosecond-precision timestamps

%include "forth.inc"

extern NEXT

%define SYS_clock_gettime   228
%define SYS_nanosleep       35
%define CLOCK_MONOTONIC     1

section .bss
    align 8
timespec_buffer:
    resq 2                  ; seconds and nanoseconds

section .text

;; CLOCK@ ( -- seconds nanoseconds )
;; Get current monotonic clock time
;; Returns seconds and nanoseconds as two values on stack
global IMPL_CLOCK_FETCH
IMPL_CLOCK_FETCH:
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

;; SLEEP ( nanoseconds -- )
;; Sleep for specified nanoseconds
;; Handles values > 1 second by converting to seconds + nanoseconds
;; Note: actual precision depends on system timer (typically ~1ms minimum)
global IMPL_SLEEP
IMPL_SLEEP:
    ; Get nanoseconds from stack
    mov rax, [DSP]
    add DSP, 8                          ; pop stack
    
    ; Divide by 1 billion to get seconds and remainder
    mov rdx, 0                          ; clear high part for division
    mov rcx, 1000000000                 ; 1 billion
    div rcx                             ; rax = seconds, rdx = nanoseconds
    
    ; Store in timespec buffer
    mov [timespec_buffer], rax          ; seconds
    mov [timespec_buffer + 8], rdx      ; nanoseconds (remainder)
    
    ; nanosleep(&timespec, NULL)
    mov rax, SYS_nanosleep
    lea rdi, [timespec_buffer]
    xor rsi, rsi                        ; no remainder buffer
    syscall
    
    ; Ignore return value (0 on success, -EINTR if interrupted)
    jmp NEXT
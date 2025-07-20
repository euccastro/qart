; input.asm - Input buffer management primitives

%include "forth.inc"

section .text
global REFILL

extern input_buffer
extern input_length
extern input_position
extern NEXT

; REFILL ( -- flag )
; Read a line of input into the input buffer
; Returns -1 (true) on success, 0 (false) on EOF
REFILL:
    ; Reset position to start of buffer
    mov qword [input_position], 0
    
    ; Read from stdin (fd=0) into input_buffer
    mov rax, 0                  ; sys_read
    mov rdi, 0                  ; stdin
    mov rsi, input_buffer       ; buffer
    mov rdx, INPUT_BUFFER_SIZE
    syscall
    
    sub DSP, 8
    ; Check for error or EOF
    cmp rax, 0
    jle .eof
    
    ; Store actual length read
    mov [input_length], rax
    
    ; Push true (-1) for success
    mov qword [DSP], -1
    jmp NEXT
    
.eof:
    mov qword [DSP], 0
    jmp NEXT

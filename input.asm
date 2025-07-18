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
    mov rdx, INPUT_BUFFER_SIZE-1 ; max bytes (leave room for null)
    syscall
    
    ; Check for error or EOF
    cmp rax, 0
    jle .eof
    
    ; Store actual length read
    mov [input_length], rax
    
    ; Null-terminate (optional but helpful for debugging)
    mov rdx, input_buffer
    add rdx, rax
    mov byte [rdx], 0
    
    ; Find and remove newline if present
    mov rcx, rax               ; length
    mov rsi, input_buffer      ; start of buffer
.find_newline:
    cmp rcx, 0
    je .no_newline
    dec rcx
    mov al, [rsi + rcx]
    cmp al, 10                 ; newline
    je .found_newline
    jmp .find_newline
    
.found_newline:
    ; Replace newline with null and adjust length
    mov byte [rsi + rcx], 0
    mov [input_length], rcx
    
.no_newline:
    ; Push true (-1) for success
    sub DSP, 8
    mov qword [DSP], -1
    jmp NEXT
    
.eof:
    ; Push false (0) for EOF/error
    sub DSP, 8
    mov qword [DSP], 0
    jmp NEXT
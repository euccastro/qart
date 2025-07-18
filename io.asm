; io.asm - Input/Output operations

%include "forth.inc"  

section .text

global DOT
global NUMBER
global EMIT
global KEY

extern NEXT
extern buffer
extern minus_sign
extern space

; DOT ( n -- ) Pop and print number with trailing space
DOT:
    mov rax, [DSP]          ; Get number
    add DSP, 8              ; Drop it
    
    ; Handle negative numbers
    test rax, rax
    jns .positive
    neg rax                 ; Make positive
    push rax                ; Save number
    
    ; Print minus sign
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, minus_sign
    mov rdx, 1
    syscall
    
    pop rax                 ; Restore number
    
.positive:
    ; Convert to decimal string
    mov rdi, buffer + 19
    mov rcx, 10
    
.convert_loop:
    xor rdx, rdx
    div rcx
    add dl, '0'
    dec rdi
    mov [rdi], dl
    test rax, rax
    jnz .convert_loop
    
    ; Print the number
    mov rax, 1              ; sys_write
    mov rsi, rdi
    mov rdx, buffer + 19
    sub rdx, rdi
    mov rdi, 1              ; stdout
    syscall
    
    ; Print space (Forth convention)
    mov rax, 1
    mov rdi, 1
    mov rsi, space
    mov rdx, 1
    syscall
    
    jmp NEXT

; EMIT ( c -- ) Output character
EMIT:
    ; Write directly from stack (low byte contains the character)
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, DSP            ; Address of character on stack
    mov rdx, 1              ; One byte (just the low byte)
    syscall
    
    add DSP, 8              ; Drop from stack
    jmp NEXT

; KEY ( -- c ) Read one character from stdin
KEY:
    ; Make room on stack and zero it
    sub DSP, 8
    mov qword [DSP], 0      ; Clear all 8 bytes
    
    ; Read one character directly into stack
    mov rax, 0              ; sys_read
    mov rdi, 0              ; stdin
    mov rsi, DSP            ; Read into low byte of stack entry
    mov rdx, 1              ; Read 1 byte
    syscall
    
    ; Check for EOF or error
    test rax, rax
    jle .eof
    
    ; Character is already on stack (zero-extended)
    jmp NEXT
    
.eof:
    ; Replace with -1 for EOF
    mov qword [DSP], -1
    jmp NEXT

; NUMBER ( c-addr u -- n ) Parse string as signed integer
NUMBER:
    ; Get parameters (u is on top, c-addr below)
    mov rcx, [DSP]          ; Length (u)
    add DSP, 8              ; Drop it
    mov rsi, [DSP]          ; String pointer (c-addr) - leave on stack for now
    
    xor rax, rax            ; Initialize result
    xor r8, r8              ; Sign flag (0 = positive)
    xor r9, r9              ; Digit counter
    
    ; Check for empty string
    test rcx, rcx
    jz .error
    
    ; Check for negative sign
    mov dl, [rsi]
    cmp dl, '-'
    jne .parse_digits
    mov r8, 1               ; Set negative flag
    inc rsi                 ; Skip minus sign
    dec rcx                 ; Decrease length
    jz .error               ; Error if just "-"
    
.parse_digits:
    movzx rdx, byte [rsi]   ; Get character (zero-extended)
    sub dl, '0'             ; Convert to digit
    cmp dl, 9               ; Check if valid digit
    ja .error               ; Not a digit
    
    ; Multiply current result by 10 and add digit
    push rdx                ; Save digit
    mov r9, 10
    mul r9                  ; rax = rax * 10, result in rax
    pop rdx                 ; Restore digit
    add rax, rdx            ; Add new digit
    
    inc rsi                 ; Next character
    dec rcx                 ; Decrease count
    jnz .parse_digits
    
    ; Apply sign if negative
    test r8, r8
    jz .done
    neg rax
    
.done:
    mov [DSP], rax          ; Store result over string pointer
    jmp NEXT
    
.error:
    ; For now, just return 0 on error
    xor rax, rax
    jmp .done
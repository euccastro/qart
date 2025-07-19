; stack.asm - Stack manipulation primitives

%include "forth.inc"

section .text

global LIT
global DUP
global DROP
global OVER
global SWAP

extern NEXT

; LIT ( -- n ) Push following cell as literal
LIT:
    mov rax, [IP]           ; Get literal value
    add IP, 8               ; Skip it
    sub DSP, 8              ; Make room
    mov [DSP], rax          ; Push value
    jmp NEXT

; DUP ( n -- n n ) Duplicate top of stack
DUP:
    mov rax, [DSP]          ; Get top
    sub DSP, 8              ; Make room
    mov [DSP], rax          ; Push copy
    jmp NEXT

; DROP ( n -- ) Remove top of stack
DROP:
    add DSP, 8              ; Drop top item
    jmp NEXT

; OVER ( n m -- n m n ) Push next-to-last to top
OVER:
    mov rax, [DSP+8]
    sub DSP, 8
    mov [DSP], rax
    jmp NEXT

; SWAP ( n m -- m n ) Swap two topmost stack values
SWAP:
    mov rax, [DSP]
    mov rsi, [DSP+8]
    mov [DSP+8], rax
    mov [DSP], rsi
    jmp NEXT

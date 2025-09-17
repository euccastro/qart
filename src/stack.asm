; stack.asm - Stack manipulation primitives

%include "forth.inc"

section .text

global IMPL_LIT
global IMPL_DUP
global IMPL_DROP
global IMPL_OVER
global IMPL_SWAP
global IMPL_ROT
global IMPL_TWO_DUP
global IMPL_TWO_DROP
global IMPL_SP_FETCH

extern NEXT

; LIT ( -- n ) Push following cell as literal
IMPL_LIT:
    mov rax, [NEXTIP]           ; Get literal value
    add NEXTIP, 8               ; Skip it
    sub DSP, 8              ; Make room
    mov [DSP], rax          ; Push value
    jmp NEXT

; DUP ( n -- n n ) Duplicate top of stack
IMPL_DUP:
    mov rax, [DSP]          ; Get top
    sub DSP, 8              ; Make room
    mov [DSP], rax          ; Push copy
    jmp NEXT

; DROP ( n -- ) Remove top of stack
IMPL_DROP:
    add DSP, 8              ; Drop top item
    jmp NEXT

; OVER ( n m -- n m n ) Push next-to-last to top
IMPL_OVER:
    mov rax, [DSP+8]
    sub DSP, 8
    mov [DSP], rax
    jmp NEXT

; SWAP ( n m -- m n ) Swap two topmost stack values
IMPL_SWAP:
    mov rax, [DSP]
    mov rsi, [DSP+8]
    mov [DSP+8], rax
    mov [DSP], rsi
    jmp NEXT

; ROT ( a b c -- b c a ) Rotate third item to top
IMPL_ROT:
    mov rax, [DSP]          ; c
    mov rdx, [DSP+8]        ; b
    mov rcx, [DSP+16]       ; a
    mov [DSP+16], rdx       ; b
    mov [DSP+8], rax        ; c
    mov [DSP], rcx          ; a
    jmp NEXT

; 2DUP ( x1 x2 -- x1 x2 x1 x2 ) Duplicate top two cells
IMPL_TWO_DUP:
    mov rax, [DSP+8]        ; Get second item
    mov rdx, [DSP]          ; Get top item
    sub DSP, 16             ; Make room for two cells
    mov [DSP+8], rax        ; Push copy of second
    mov [DSP], rdx          ; Push copy of top
    jmp NEXT

; 2DROP ( x1 x2 -- ) Drop top two cells
IMPL_TWO_DROP:
    add DSP, 16             ; Drop two items
    jmp NEXT

; SP@ ( -- addr ) Push current stack pointer (points to TOS)
IMPL_SP_FETCH:
    mov rax, DSP            ; Save current stack pointer
    sub DSP, 8              ; Make room
    mov [DSP], rax          ; Push the saved pointer
    jmp NEXT

; arithmetic.asm - Arithmetic operations

%include "forth.inc"  

section .text

global ADD

extern NEXT

; ADD ( n1 n2 -- n3 ) Add top two stack items
ADD:
    mov rax, [DSP]          ; Get top (n2)
    add DSP, 8              ; Drop it
    add [DSP], rax          ; Add to new top (n1)
    jmp NEXT
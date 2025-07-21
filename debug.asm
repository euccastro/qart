; debug.asm - Debugging primitives

%include "forth.inc"

section .text
global LINE_NUMBER_FETCH

extern line_number
extern NEXT

; LINE# ( -- n )
; Push current line number
LINE_NUMBER_FETCH:
    sub DSP, 8
    mov rax, [line_number]
    mov [DSP], rax
    jmp NEXT
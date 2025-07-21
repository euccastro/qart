; debug.asm - Debugging primitives

%include "forth.inc"

section .text
global LINE_NUMBER_FETCH
global COLUMN_NUMBER_FETCH

extern line_number
extern line_start_position
extern input_position
extern NEXT

; LINE# ( -- n )
; Push current line number
LINE_NUMBER_FETCH:
    sub DSP, 8
    mov rax, [line_number]
    mov [DSP], rax
    jmp NEXT

; COL# ( -- n )
; Push current column number (0-based position after word)
COLUMN_NUMBER_FETCH:
    mov rax, [input_position]
    sub rax, [line_start_position]
    sub DSP, 8
    mov [DSP], rax
    jmp NEXT
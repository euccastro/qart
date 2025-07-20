; memory.asm - Memory access primitives

%include "forth.inc"

section .text

global TO_R
global R_FROM
global R_FETCH
global FETCH
global STORE
global C_FETCH
global C_STORE
global STATE_word
global OUTPUT_word
global FLAGS_word

extern NEXT
extern STATE
extern OUTPUT
extern FLAGS

; >R ( n -- ) (R: -- n) Move from data stack to return stack
TO_R:
    mov rax, [DSP]          ; Get value from data stack
    add DSP, 8              ; Drop from data stack
    sub RSTACK, 8           ; Make room on return stack
    mov [RSTACK], rax       ; Push to return stack
    jmp NEXT

; R> ( -- n) (R: n -- ) Move from return stack to data stack
R_FROM:
    mov rax, [RSTACK]       ; Get value from return stack
    add RSTACK, 8           ; Drop from return stack
    sub DSP, 8              ; Make room on data stack
    mov [DSP], rax          ; Push to data stack
    jmp NEXT

; R@ ( -- n) (R: n -- n) Copy top of return stack to data stack
R_FETCH:
    mov rax, [RSTACK]       ; Peek at return stack top
    sub DSP, 8              ; Make room on data stack
    mov [DSP], rax          ; Push copy to data stack
    jmp NEXT

; @ ( addr -- n ) Fetch 64-bit value from address
FETCH:
    mov rax, [DSP]          ; Get address
    mov rax, [rax]          ; Fetch value from that address
    mov [DSP], rax          ; Replace address with value
    jmp NEXT

; ! ( n addr -- ) Store 64-bit value to address
STORE:
    mov rax, [DSP]          ; Get address
    add DSP, 8              ; Drop it
    mov rdx, [DSP]          ; Get value
    add DSP, 8              ; Drop it
    mov [rax], rdx          ; Store value at address
    jmp NEXT

; C@ ( addr -- c ) Fetch byte from address
C_FETCH:
    mov rax, [DSP]          ; Get address
    movzx rax, byte [rax]   ; Fetch byte, zero-extended
    mov [DSP], rax          ; Replace address with byte value
    jmp NEXT

; C! ( c addr -- ) Store byte to address
C_STORE:
    mov rax, [DSP]          ; Get address
    add DSP, 8              ; Drop it
    mov dl, [DSP]           ; Get byte value (low 8 bits)
    add DSP, 8              ; Drop it
    mov [rax], dl           ; Store byte at address
    jmp NEXT

; STATE ( -- addr ) Push address of STATE variable
STATE_word:
    sub DSP, 8              ; Make room
    mov qword [DSP], STATE  ; Push address
    jmp NEXT

; OUTPUT ( -- addr ) Push address of OUTPUT variable
OUTPUT_word:
    sub DSP, 8              ; Make room
    mov qword [DSP], OUTPUT ; Push address
    jmp NEXT

; FLAGS ( -- addr ) Push address of FLAGS variable
FLAGS_word:
    sub DSP, 8              ; Make room
    mov qword [DSP], FLAGS  ; Push address
    jmp NEXT
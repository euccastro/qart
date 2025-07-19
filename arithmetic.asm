;;; arithmetic.asm - Arithmetic operations

  %include "forth.inc"  

  section .text

  global ADD
  global ZEROEQ

  extern NEXT

  ;; ADD ( n1 n2 -- n3 ) Add top two stack items
ADD:
  mov rax, [DSP]          ; Get top (n2)
  add DSP, 8              ; Drop it
  add [DSP], rax          ; Add to new top (n1)
  jmp NEXT

  ;; 0= ( n -- b ) b := -1 if n=0, 0 otherwise
ZEROEQ:
  mov rax, [DSP]
  test rax, rax
  setz al
  movzx rax, al
  neg rax
  mov [DSP], rax
  jmp NEXT

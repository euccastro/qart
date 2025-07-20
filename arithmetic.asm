;;; arithmetic.asm - Arithmetic operations

  %include "forth.inc"  

  section .text

  global ADD
  global ZEROEQ
  global EQUAL

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

  ;; = ( n1 n2 -- flag ) flag := -1 if n1=n2, 0 otherwise
EQUAL:
  mov rax, [DSP]          ; Get n2
  add DSP, 8              ; Drop it
  cmp [DSP], rax          ; Compare with n1
  sete al                 ; Set AL to 1 if equal
  movzx rax, al           ; Zero-extend to 64 bits
  neg rax                 ; Convert 1 to -1, 0 stays 0
  mov [DSP], rax          ; Store result
  jmp NEXT

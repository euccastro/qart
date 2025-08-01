;;; arithmetic.asm - Arithmetic operations

  %include "forth.inc"  

  section .text

  global ADD
  global ZEROEQ
  global EQUAL
  global AND
  global SUB
  global LSHIFT
  global OR
  global LESS_THAN

  extern NEXT

  ;; ADD ( n1 n2 -- n3 ) Add top two stack items
ADD:
  mov rax, [DSP]          ; Get top (n2)
  add DSP, 8              ; Drop it
  add [DSP], rax          ; Add to new top (n1)
  jmp NEXT

  ;; SUB ( n1 n2 -- n3 ) Subtract TOS from second stack item
SUB:
  mov rax, [DSP]          ; Get top (n2)
  add DSP, 8              ; Drop it
  sub [DSP], rax          ; Add to new top (n1)
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

  ;; AND ( n1 n2 -- n3 ) Bitwise AND
AND:
  mov rax, [DSP]          ; Get n2
  add DSP, 8              ; Drop it
  and [DSP], rax          ; AND with n1
  jmp NEXT

  ;; LSHIFT ( x1 u -- x2 ) Logical left shift
LSHIFT:
  mov rcx, [DSP]          ; shift count
  add DSP, 8
  mov rax, [DSP]          ; value to shift
  shl rax, cl             ; shift left (only uses low 6 bits of rcx)
  mov [DSP], rax
  jmp NEXT

  ;; OR ( x1 x2 -- x3 ) Bitwise OR
OR:
  mov rax, [DSP]          ; second operand
  add DSP, 8
  or [DSP], rax           ; OR with first operand
  jmp NEXT

  ;; < ( n1 n2 -- flag ) flag := -1 if n1 < n2, 0 otherwise
LESS_THAN:
  mov rax, [DSP]          ; Get n2
  add DSP, 8              ; Drop it
  cmp [DSP], rax          ; Compare n1 with n2
  setl al                 ; Set AL to 1 if n1 < n2 (signed)
  movzx rax, al           ; Zero-extend to 64 bits
  neg rax                 ; Convert 1 to -1, 0 stays 0
  mov [DSP], rax          ; Store result
  jmp NEXT

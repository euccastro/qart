;;; arithmetic.asm - Arithmetic operations

  %include "forth.inc"  

  section .text

  global IMPL_ADD
  global IMPL_ZEROEQ
  global IMPL_EQUAL
  global IMPL_AND
  global IMPL_SUB
  global IMPL_LSHIFT
  global IMPL_OR
  global IMPL_LESS_THAN
  global IMPL_RSHIFT

  extern NEXT

  ;; ADD ( n1 n2 -- n3 ) Add top two stack items
IMPL_ADD:
  mov rax, [DSP]          ; Get top (n2)
  add DSP, 8              ; Drop it
  add [DSP], rax          ; Add to new top (n1)
  jmp NEXT

  ;; SUB ( n1 n2 -- n3 ) Subtract TOS from second stack item
IMPL_SUB:
  mov rax, [DSP]          ; Get top (n2)
  add DSP, 8              ; Drop it
  sub [DSP], rax          ; Add to new top (n1)
  jmp NEXT

  ;; 0= ( n -- b ) b := -1 if n=0, 0 otherwise
IMPL_ZEROEQ:
  mov rax, [DSP]
  test rax, rax
  setz al
  movzx rax, al
  neg rax
  mov [DSP], rax
  jmp NEXT

  ;; = ( n1 n2 -- flag ) flag := -1 if n1=n2, 0 otherwise
IMPL_EQUAL:
  mov rax, [DSP]          ; Get n2
  add DSP, 8              ; Drop it
  cmp [DSP], rax          ; Compare with n1
  sete al                 ; Set AL to 1 if equal
  movzx rax, al           ; Zero-extend to 64 bits
  neg rax                 ; Convert 1 to -1, 0 stays 0
  mov [DSP], rax          ; Store result
  jmp NEXT

  ;; AND ( n1 n2 -- n3 ) Bitwise AND
IMPL_AND:
  mov rax, [DSP]          ; Get n2
  add DSP, 8              ; Drop it
  and [DSP], rax          ; AND with n1
  jmp NEXT

  ;; LSHIFT ( x1 u -- x2 ) Logical left shift
IMPL_LSHIFT:
  mov rcx, [DSP]          ; shift count
  add DSP, 8
  mov rax, [DSP]          ; value to shift
  shl rax, cl             ; shift left (only uses low 6 bits of rcx)
  mov [DSP], rax
  jmp NEXT

  ;; OR ( x1 x2 -- x3 ) Bitwise OR
IMPL_OR:
  mov rax, [DSP]          ; second operand
  add DSP, 8
  or [DSP], rax           ; OR with first operand
  jmp NEXT

  ;; < ( n1 n2 -- flag ) flag := -1 if n1 < n2, 0 otherwise
IMPL_LESS_THAN:
  mov rax, [DSP]          ; Get n2
  add DSP, 8              ; Drop it
  cmp [DSP], rax          ; Compare n1 with n2
  setl al                 ; Set AL to 1 if n1 < n2 (signed)
  movzx rax, al           ; Zero-extend to 64 bits
  neg rax                 ; Convert 1 to -1, 0 stays 0
  mov [DSP], rax          ; Store result
  jmp NEXT

  ;; RSHIFT ( x1 u -- x2 ) Arithmetic right shift
IMPL_RSHIFT:
  mov rcx, [DSP]          ; shift count
  add DSP, 8
  mov rax, [DSP]          ; value to shift
  sar rax, cl             ; arithmetic shift right (preserves sign)
  mov [DSP], rax
  jmp NEXT

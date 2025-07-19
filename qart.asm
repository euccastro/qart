  ;; qart.asm - Main file for Forth-like language implementation
  ;; Includes all the other modules and contains data section and entry point

  %include "forth.inc"

  section .data
buffer: times 20 db 0
newline: db 10
  
  ;; Input buffer and tracking variables
input_buffer: times INPUT_BUFFER_SIZE db 0  ; Input line buffer
input_length: dq 0                          ; Number of chars in buffer
input_position: dq 0                        ; Current parse position
  
  ;; Test variables for memory access
test_var: dq 0              ; 64-bit test variable
test_byte: db 0             ; Byte test variable
  
  ;; Test strings for FIND
test_dup: db "DUP"
  test_dup_len equ 3
test_plus: db "+"
  test_plus_len equ 1
test_bad: db "BADWORD"
  test_bad_len equ 7
  
  ;; Dictionary structure
  ;; Format per entry:
  ;;   +0: Link to previous word (8 bytes)
  ;;   +8: Length (1 byte) + Name (up to 7 bytes) = 8 bytes total
  ;;  +16: Code field address (8 bytes)
  
  align 8
  ;; Start with last word and work backwards
dict_EXIT:
  dq 0                        ; Link (null - last word in dictionary)
  db 4, "EXIT", 0, 0, 0       ; Length + name (padded to 8)
  dq EXIT                     ; Code field

dict_DOT:
  dq dict_EXIT
  db 1, ".", 0, 0, 0, 0, 0, 0
  dq DOT

dict_EMIT:
  dq dict_DOT
  db 4, "EMIT", 0, 0, 0
  dq EMIT

dict_KEY:
  dq dict_EMIT
  db 3, "KEY", 0, 0, 0, 0
  dq KEY

dict_C_STORE:
  dq dict_KEY
  db 2, "C!", 0, 0, 0, 0, 0
  dq C_STORE

dict_C_FETCH:
  dq dict_C_STORE
  db 2, "C@", 0, 0, 0, 0, 0
  dq C_FETCH

dict_STORE:
  dq dict_C_FETCH
  db 1, "!", 0, 0, 0, 0, 0, 0
  dq STORE

dict_FETCH:
  dq dict_STORE
  db 1, "@", 0, 0, 0, 0, 0, 0
  dq FETCH

dict_R_FETCH:
  dq dict_FETCH
  db 2, "R@", 0, 0, 0, 0, 0
  dq R_FETCH

dict_R_FROM:
  dq dict_R_FETCH
  db 2, "R>", 0, 0, 0, 0, 0
  dq R_FROM

dict_TO_R:
  dq dict_R_FROM
  db 2, ">R", 0, 0, 0, 0, 0
  dq TO_R

dict_ADD:
  dq dict_TO_R
  db 1, "+", 0, 0, 0, 0, 0, 0
  dq ADD

dict_ZEROEQ:
  dq dict_ADD
  db 2, "0=", 0, 0, 0, 0, 0
  dq ZEROEQ

dict_DROP:
  dq dict_ZEROEQ
  db 4, "DROP", 0, 0, 0
  dq DROP

dict_SWAP:
  dq dict_DROP
  db 4, "SWAP", 0, 0, 0
  dq SWAP

dict_OVER:
  dq dict_SWAP
  db 4, "OVER", 0, 0, 0
  dq OVER

dict_DUP:
  dq dict_OVER
  db 3, "DUP", 0, 0, 0, 0
  dq DUP

dict_LIT:
  dq dict_DUP
  db 3, "LIT", 0, 0, 0, 0
  dq LIT

  ;; Test colon definition: DOUBLE ( n -- n*2 ) 
  ;; Equivalent to : DOUBLE DUP + ;
dict_DOUBLE:
  dq dict_LIT             ; Link to previous
  db 6, "DOUBLE", 0       ; Name
  dq DOCOL                ; Code field points to DOCOL
  ;; Body starts here:
  dq dict_DUP             ; DUP
  dq dict_ADD             ; +
  dq dict_EXIT            ; EXIT (;)

dict_EXECUTE:
  dq dict_DOUBLE          ; Link to previous
  db 7, "EXECUTE"         ; Name (7 chars exactly)
  dq EXECUTE              ; Code field

dict_ZBRANCH:
  dq dict_EXECUTE
  db 7, "0BRANCH"
  dq ZBRANCH

dict_REFILL:
  dq dict_ZBRANCH         ; Link to previous
  db 6, "REFILL", 0       ; Name
  dq REFILL               ; Code field

dict_WORD:
  dq dict_REFILL          ; Link to previous
  db 4, "WORD", 0, 0, 0   ; Name
  dq PARSE_WORD           ; Code field
  
  ;; LATEST points to the most recent word
LATEST: dq dict_WORD
  
  
  ;; Test program: Use dictionary entries throughout
  align 8
test_program:
  dq dict_LIT, 42
  dq dict_LIT, 0
  dq dict_ZBRANCH, 2
  dq dict_LIT, 99
  dq dict_DOT
  dq dict_EXIT

minus_sign: db '-'
space: db ' '

  section .bss
  align 8
stack_base: resq 1024
stack_top:
  
return_stack_base: resq 512   ; Return stack (smaller than data stack)
return_stack_top:

  section .text
  global _start
  global buffer
  global minus_sign
  global space
  global LATEST
  global input_buffer
  global input_length
  global input_position

  ;; Import all the primitives from other files
  extern NEXT
  extern DOCOL
  extern EXIT
  extern EXECUTE
  extern ZBRANCH
  extern LIT
  extern DUP
  extern DROP
  extern OVER
  extern SWAP
  extern ADD
  extern ZEROEQ
  extern TO_R
  extern R_FROM
  extern R_FETCH
  extern FETCH
  extern STORE
  extern C_FETCH
  extern C_STORE
  extern DOT
  extern EMIT
  extern KEY
  extern NUMBER
  extern FIND
  extern REFILL
  extern PARSE_WORD

  ;; ---- Main Program ----

_start:
  ;; Initialize stacks
  mov DSP, stack_top          ; Data stack grows down
  mov RSTACK, return_stack_top ; Return stack grows down
  
  ;; Push 0 to return stack to mark top-level
  sub RSTACK, 8
  mov qword [RSTACK], 0
  
  ;; Start interpreting
  mov IP, test_program
  jmp NEXT

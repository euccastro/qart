  ;; memory.asm - Memory access primitives

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
  global HERE_word
  global LATEST_word
  global COMMA
  global IMMED_TEST
  global IMMED
  global STATE_FETCH
  global STATE_STORE
  global OUTPUT_FETCH
  global OUTPUT_STORE
  global DEBUG_FETCH
  global DEBUG_STORE

  extern NEXT
  extern STATE
  extern OUTPUT
  extern FLAGS
  extern HERE
  extern LATEST

  ;; >R ( n -- ) (R: -- n) Move from data stack to return stack
TO_R:
  mov rax, [DSP]          ; Get value from data stack
  add DSP, 8              ; Drop from data stack
  sub RSTACK, 8           ; Make room on return stack
  mov [RSTACK], rax       ; Push to return stack
  jmp NEXT

  ;; R> ( -- n) (R: n -- ) Move from return stack to data stack
R_FROM:
  mov rax, [RSTACK]       ; Get value from return stack
  add RSTACK, 8           ; Drop from return stack
  sub DSP, 8              ; Make room on data stack
  mov [DSP], rax          ; Push to data stack
  jmp NEXT

  ;; R@ ( -- n) (R: n -- n) Copy top of return stack to data stack
R_FETCH:
  mov rax, [RSTACK]       ; Peek at return stack top
  sub DSP, 8              ; Make room on data stack
  mov [DSP], rax          ; Push copy to data stack
  jmp NEXT

  ;; @ ( addr -- n ) Fetch 64-bit value from address
FETCH:
  mov rax, [DSP]          ; Get address
  mov rax, [rax]          ; Fetch value from that address
  mov [DSP], rax          ; Replace address with value
  jmp NEXT

  ;; ! ( n addr -- ) Store 64-bit value to address
STORE:
  mov rax, [DSP]          ; Get address
  add DSP, 8              ; Drop it
  mov rdx, [DSP]          ; Get value
  add DSP, 8              ; Drop it
  mov [rax], rdx          ; Store value at address
  jmp NEXT

  ;; C@ ( addr -- c ) Fetch byte from address
C_FETCH:
  mov rax, [DSP]          ; Get address
  movzx rax, byte [rax]   ; Fetch byte, zero-extended
  mov [DSP], rax          ; Replace address with byte value
  jmp NEXT

  ;; C! ( c addr -- ) Store byte to address
C_STORE:
  mov rax, [DSP]          ; Get address
  add DSP, 8              ; Drop it
  mov dl, [DSP]           ; Get byte value (low 8 bits)
  add DSP, 8              ; Drop it
  mov [rax], dl           ; Store byte at address
  jmp NEXT

  ;; STATE ( -- addr ) Push address of STATE variable
STATE_word:
  sub DSP, 8              ; Make room
  mov qword [DSP], STATE  ; Push address
  jmp NEXT

  ;; OUTPUT ( -- addr ) Push address of OUTPUT variable
OUTPUT_word:
  sub DSP, 8              ; Make room
  mov qword [DSP], OUTPUT ; Push address
  jmp NEXT

  ;; FLAGS ( -- addr ) Push address of FLAGS variable
FLAGS_word:
  sub DSP, 8              ; Make room
  mov qword [DSP], FLAGS  ; Push address
  jmp NEXT

  ;; HERE ( -- addr ) Push address of HERE variable
HERE_word:
  sub DSP, 8              ; Make room
  mov qword [DSP], HERE  ; Push address
  jmp NEXT

  ;; LATEST ( -- addr ) Push address of LATEST variable
LATEST_word:
  sub DSP, 8              ; Make room
  mov qword [DSP], LATEST  ; Push address
  jmp NEXT

COMMA:
  mov rax, [DSP]
  add DSP, 8
  mov rdx, [HERE]      ; get current dictionary pointer
  mov [rdx], rax       ; store value at dictionary pointer
  add qword [HERE], 8  ; advance HERE
  jmp NEXT

  ;; IMMED? ( xt -- flag ) Test if word is immediate
IMMED_TEST:
  mov rax, [DSP]      ; get xt (dictionary pointer)
  movzx rax, byte [rax+8]     ; get length/flags byte
  test rax, 0x80      ; test bit 7
  setnz al            ; set AL to 1 if immediate
  movzx rax, al
  neg rax             ; convert to -1/0
  mov [DSP], rax
  jmp NEXT

  ;; IMMED ( -- ) Make LATEST word immediate
IMMED:
  mov rax, [LATEST]   ; get latest word
  or byte [rax+8], 0x80       ; set immediate bit
  jmp NEXT

  ;; Thread-local flags using R13
  ;; R13 bit layout:
  ;; Bit 0: STATE (0 = interpret, 1 = compile)
  ;; Bits 1-2: OUTPUT (0 = stdin, 1 = stdout, 2 = stderr)
  ;; Bit 3: DEBUG (verbose ASSERT output)
  ;; Bits 4-63: Reserved

  ;; STATE@ ( -- n )
  ;; Get current STATE (bit 0 of R13)
STATE_FETCH:
  sub DSP, 8              ; Make room
  mov rax, r13            ; Get R13
  and rax, 1              ; Isolate bit 0
  mov [DSP], rax          ; Push result
  jmp NEXT

  ;; STATE! ( n -- )
  ;; Set STATE (bit 0 of R13)
STATE_STORE:
  mov rax, [DSP]          ; Get new state
  add DSP, 8              ; Pop it
  and rax, 1              ; Ensure only bit 0
  and r13, ~1             ; Clear bit 0
  or r13, rax             ; Set new bit 0
  jmp NEXT

  ;; OUTPUT@ ( -- n )
  ;; Get current OUTPUT (bits 1-2 of R13)
OUTPUT_FETCH:
  sub DSP, 8              ; Make room
  mov rax, r13            ; Get R13
  shr rax, 1              ; Shift right to get bits 1-2
  and rax, 3              ; Isolate 2 bits
  mov [DSP], rax          ; Push result
  jmp NEXT

  ;; OUTPUT! ( n -- )
  ;; Set OUTPUT (bits 1-2 of R13)
OUTPUT_STORE:
  mov rax, [DSP]          ; Get new output
  add DSP, 8              ; Pop it
  and rax, 3              ; Ensure only 2 bits
  shl rax, 1              ; Shift to bits 1-2 position
  and r13, ~6             ; Clear bits 1-2 (6 = 110b)
  or r13, rax             ; Set new bits 1-2
  jmp NEXT

  ;; DEBUG@ ( -- n )
  ;; Get DEBUG flag (bit 3 of R13)
DEBUG_FETCH:
  sub DSP, 8              ; Make room
  mov rax, r13            ; Get R13
  shr rax, 3              ; Shift right to get bit 3
  and rax, 1              ; Isolate 1 bit
  mov [DSP], rax          ; Push result
  jmp NEXT

  ;; DEBUG! ( n -- )
  ;; Set DEBUG flag (bit 3 of R13)
DEBUG_STORE:
  mov rax, [DSP]          ; Get new debug flag
  add DSP, 8              ; Pop it
  and rax, 1              ; Ensure only 1 bit
  shl rax, 3              ; Shift to bit 3 position
  and r13, ~8             ; Clear bit 3 (8 = 1000b)
  or r13, rax             ; Set new bit 3
  jmp NEXT

  ;; memory.asm - Memory access primitives

  %include "forth.inc"

  section .text

  global IMPL_TO_R
  global IMPL_R_FROM
  global IMPL_R_FETCH
  global IMPL_FETCH
  global IMPL_STORE
  global IMPL_C_FETCH
  global IMPL_C_STORE
  global IMPL_STATE_word
  global IMPL_OUTPUT_word
  global IMPL_FLAGS_word
  global IMPL_HERE_word
  global IMPL_LATEST_word
  global IMPL_COMMA
  global IMPL_ALLOT
  global IMPL_IMMED_TEST
  global IMPL_IMMED
  global IMPL_STATE_FETCH
  global IMPL_STATE_STORE
  global IMPL_OUTPUT_FETCH
  global IMPL_OUTPUT_STORE
  global IMPL_DEBUG_FETCH
  global IMPL_DEBUG_STORE

  extern NEXT
  extern STATE
  extern OUTPUT
  extern FLAGS
  extern HERE
  extern LATEST

  ;; >R ( n -- ) (R: -- n) Move from data stack to return stack
IMPL_TO_R:
  mov rax, [DSP]          ; Get value from data stack
  add DSP, 8              ; Drop from data stack
  sub RSTACK, 8           ; Make room on return stack
  mov [RSTACK], rax       ; Push to return stack
  jmp NEXT

  ;; R> ( -- n) (R: n -- ) Move from return stack to data stack
IMPL_R_FROM:
  mov rax, [RSTACK]       ; Get value from return stack
  add RSTACK, 8           ; Drop from return stack
  sub DSP, 8              ; Make room on data stack
  mov [DSP], rax          ; Push to data stack
  jmp NEXT

  ;; R@ ( -- n) (R: n -- n) Copy top of return stack to data stack
IMPL_R_FETCH:
  mov rax, [RSTACK]       ; Peek at return stack top
  sub DSP, 8              ; Make room on data stack
  mov [DSP], rax          ; Push copy to data stack
  jmp NEXT

  ;; @ ( addr -- n ) Fetch 64-bit value from address
IMPL_FETCH:
  mov rax, [DSP]          ; Get address
  mov rax, [rax]          ; Fetch value from that address
  mov [DSP], rax          ; Replace address with value
  jmp NEXT

  ;; ! ( n addr -- ) Store 64-bit value to address
IMPL_STORE:
  mov rax, [DSP]          ; Get address
  add DSP, 8              ; Drop it
  mov rdx, [DSP]          ; Get value
  add DSP, 8              ; Drop it
  mov [rax], rdx          ; Store value at address
  jmp NEXT

  ;; C@ ( addr -- c ) Fetch byte from address
IMPL_C_FETCH:
  mov rax, [DSP]          ; Get address
  movzx rax, byte [rax]   ; Fetch byte, zero-extended
  mov [DSP], rax          ; Replace address with byte value
  jmp NEXT

  ;; C! ( c addr -- ) Store byte to address
IMPL_C_STORE:
  mov rax, [DSP]          ; Get address
  add DSP, 8              ; Drop it
  mov dl, [DSP]           ; Get byte value (low 8 bits)
  add DSP, 8              ; Drop it
  mov [rax], dl           ; Store byte at address
  jmp NEXT

  ;; STATE ( -- addr ) Push address of STATE variable
IMPL_STATE_word:
  sub DSP, 8              ; Make room
  mov qword [DSP], STATE  ; Push address
  jmp NEXT

  ;; OUTPUT ( -- addr ) Push address of OUTPUT variable
IMPL_OUTPUT_word:
  sub DSP, 8              ; Make room
  mov qword [DSP], OUTPUT ; Push address
  jmp NEXT

  ;; FLAGS ( -- addr ) Push address of FLAGS variable
IMPL_FLAGS_word:
  sub DSP, 8              ; Make room
  mov qword [DSP], FLAGS  ; Push address
  jmp NEXT

  ;; HERE ( -- addr ) Push address of HERE variable
IMPL_HERE_word:
  sub DSP, 8              ; Make room
  mov qword [DSP], HERE  ; Push address
  jmp NEXT

  ;; LATEST ( -- addr ) Push address of LATEST variable
IMPL_LATEST_word:
  sub DSP, 8              ; Make room
  mov qword [DSP], LATEST  ; Push address
  jmp NEXT

IMPL_COMMA:
  mov rax, [DSP]
  add DSP, 8
  mov rdx, [HERE]      ; get current dictionary pointer
  mov [rdx], rax       ; store value at dictionary pointer
  add qword [HERE], 8  ; advance HERE
  jmp NEXT

  ;; ALLOT ( n -- ) Allocate n bytes in dictionary
IMPL_ALLOT:
  mov rax, [DSP]          ; Get number of bytes to allocate
  add DSP, 8              ; Drop it
  add [HERE], rax         ; Advance HERE by n bytes
  jmp NEXT

  ;; IMMED? ( xt -- flag ) Test if word is immediate
IMPL_IMMED_TEST:
  mov rax, [DSP]      ; get xt (dictionary pointer)
  movzx rax, byte [rax+8]     ; get length/flags byte
  test rax, 0x80      ; test bit 7
  setnz al            ; set AL to 1 if immediate
  movzx rax, al
  neg rax             ; convert to -1/0
  mov [DSP], rax
  jmp NEXT

  ;; IMMED ( -- ) Make LATEST word immediate
IMPL_IMMED:
  mov rax, [LATEST]   ; get latest word
  or byte [rax+8], 0x80       ; set immediate bit
  jmp NEXT

  ;; Thread-local flags using R13
  ;; R13 bit layout:
  ;; Bit 0: STATE (0 = interpret, 1 = compile)
  ;; Bits 1-2: OUTPUT (0 = stdin, 1 = stdout, 2 = stderr)
  ;; Bit 3: DEBUG (verbose ASSERT output)
  ;; Bit 4: INTERACTIVE (prompts and bye message)
  ;; Bits 5-63: Reserved

  ;; STATE@ ( -- n )
  ;; Get current STATE (bit 0 of TLS->flags)
IMPL_STATE_FETCH:
  sub DSP, 8              ; Make room
  mov rax, [TLS+TLS_FLAGS] ; Get flags from descriptor
  and rax, 1              ; Isolate bit 0
  mov [DSP], rax          ; Push result
  jmp NEXT

  ;; STATE! ( n -- )
  ;; Set STATE (bit 0 of TLS->flags)
IMPL_STATE_STORE:
  mov rax, [DSP]          ; Get new state
  add DSP, 8              ; Pop it
  and rax, 1              ; Ensure only bit 0
  mov rdx, [TLS+TLS_FLAGS] ; Get current flags
  and rdx, ~1             ; Clear bit 0
  or rdx, rax             ; Set new bit 0
  mov [TLS+TLS_FLAGS], rdx ; Store back
  jmp NEXT

  ;; OUTPUT@ ( -- n )
  ;; Get current OUTPUT (bits 1-2 of R13)
IMPL_OUTPUT_FETCH:
  sub DSP, 8              ; Make room
  mov rax, [TLS+TLS_FLAGS] ; Get flags from descriptor
  shr rax, 1              ; Shift right to get bits 1-2
  and rax, 3              ; Isolate 2 bits
  mov [DSP], rax          ; Push result
  jmp NEXT

  ;; OUTPUT! ( n -- )
  ;; Set OUTPUT (bits 1-2 of TLS->flags)
IMPL_OUTPUT_STORE:
  mov rax, [DSP]          ; Get new output
  add DSP, 8              ; Pop it
  and rax, 3              ; Ensure only 2 bits
  shl rax, 1              ; Shift to bits 1-2 position
  mov rdx, [TLS+TLS_FLAGS] ; Get current flags
  and rdx, ~6             ; Clear bits 1-2 (6 = 110b)
  or rdx, rax             ; Set new bits 1-2
  mov [TLS+TLS_FLAGS], rdx ; Store back
  jmp NEXT

  ;; DEBUG@ ( -- n )
  ;; Get DEBUG flag (bit 3 of TLS->flags)
IMPL_DEBUG_FETCH:
  sub DSP, 8              ; Make room
  mov rax, [TLS+TLS_FLAGS] ; Get flags from descriptor
  shr rax, 3              ; Shift right to get bit 3
  and rax, 1              ; Isolate 1 bit
  mov [DSP], rax          ; Push result
  jmp NEXT

  ;; DEBUG! ( n -- )
  ;; Set DEBUG flag (bit 3 of TLS->flags)
IMPL_DEBUG_STORE:
  mov rax, [DSP]          ; Get new debug flag
  add DSP, 8              ; Pop it
  and rax, 1              ; Ensure only 1 bit
  shl rax, 3              ; Shift to bit 3 position
  mov rdx, [TLS+TLS_FLAGS] ; Get current flags
  and rdx, ~8             ; Clear bit 3 (8 = 1000b)
  or rdx, rax             ; Set new bit 3
  mov [TLS+TLS_FLAGS], rdx ; Store back
  jmp NEXT

  ;; INTERACT ( -- ) Enable interactive mode (bit 4 of TLS->flags)
  global IMPL_INTERACT
IMPL_INTERACT:
  or qword [TLS+TLS_FLAGS], 16  ; Set bit 4 (16 = 10000b)
  jmp NEXT

  ;; PROMPT ( -- ) Show prompt if interactive (bit 4 of TLS->flags)
  global IMPL_PROMPT
IMPL_PROMPT:
  test qword [TLS+TLS_FLAGS], 16  ; Test bit 4 (interactive mode)
  jz .skip                         ; Skip if not interactive
  ; Print "> " to stdout
  mov rax, 1              ; sys_write
  mov rdi, 1              ; stdout
  mov rsi, prompt_text
  mov rdx, 2              ; length
  syscall
.skip:
  jmp NEXT

prompt_text: db "> "

  ;; BYE_MSG ( -- ) Show bye message if interactive (bit 4 of TLS->flags)
  global IMPL_BYE_MSG
IMPL_BYE_MSG:
  test qword [TLS+TLS_FLAGS], 16  ; Test bit 4 (interactive mode)
  jz .skip                         ; Skip if not interactive
  ; Print "\nbye.\n" to stdout
  mov rax, 1              ; sys_write
  mov rdi, 1              ; stdout
  mov rsi, bye_text
  mov rdx, 6              ; length
  syscall
.skip:
  jmp NEXT

bye_text: db 10, "bye.", 10  ; newline, "bye.", newline

  ;; IACR ( -- ) Output CR only if interactive (bit 4 of TLS->flags)
  global IMPL_IACR
IMPL_IACR:
  test qword [TLS+TLS_FLAGS], 16  ; Test bit 4 (interactive mode)
  jz .skip                         ; Skip if not interactive
  ; Print newline to stdout
  mov rax, 1              ; sys_write
  mov rdi, 1              ; stdout
  mov rsi, iacr_newline
  mov rdx, 1              ; length
  syscall
.skip:
  jmp NEXT

iacr_newline: db 10      ; just a newline

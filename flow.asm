  ;; flow.asm - Control flow for the Forth interpreter
  ;; Contains NEXT, DOCOL, EXIT and other flow control primitives

  %include "forth.inc"

  section .text

  global NEXT
  global DOCOL
  global EXIT
  global EXECUTE
  global BRANCH
  global ZBRANCH
  global ABORT_word

  extern stack_top
  extern return_stack_top
  extern STATE
  extern dict_QUIT

  ;; NEXT - The inner interpreter
  ;; Dictionary-based execution: IP points to dictionary entry addresses
NEXT:
  mov rdx, [IP]           ; Get dictionary entry address
  add IP, 8               ; Advance IP
  mov rax, [rdx+16]       ; Get code field from dict entry (link=8 + name=8)
  jmp rax                 ; Execute the code

  ;; DOCOL - Runtime for colon definitions
  ;; Expects RDX = dictionary entry address
  ;; Dictionary structure: link(8) + name(8) + code(8) + body...
DOCOL:
  sub RSTACK, 8           ; Make room on return stack
  mov [RSTACK], IP        ; Save current IP
  lea IP, [rdx+24]        ; IP = start of body (after 16-byte header and pointer to DOCOL)
  jmp NEXT                ; Start executing the body

  ;; EXIT ( -- ) Return from colon definition
  ;; For top-level, return stack will be empty and we'll exit
EXIT:
  mov rax, [RSTACK]       ; Get saved IP
  test rax, rax           ; Was it 0 (top-level)?
  jz .exit_program
  add RSTACK, 8           ; Drop from return stack
  mov IP, rax             ; Restore IP
  jmp NEXT                ; Continue in caller
  
  .exit_program:
  mov rax, 60             ; sys_exit
  xor rdi, rdi
  syscall

  ;; EXECUTE ( xt -- ) Execute word given execution token
  ;; Execution token is a dictionary pointer
EXECUTE:
  mov rdx, [DSP]          ; Get dictionary pointer from stack
  add DSP, 8              ; Drop from stack
  mov rax, [rdx+16]       ; Load code address from dict entry
  jmp rax                 ; Jump to the code

  ;; BRANCH ( -- ) Skip next n words unconditionally
BRANCH:
  mov rdx, [IP]
  lea IP, [IP + (rdx+1)*8]
  jmp NEXT

  ;; ZBRANCH ( n -- ) Skip next n words if zero in TOS
ZBRANCH:
  mov rdx, [IP]
  add IP, 8
  mov rax, [DSP]
  add DSP, 8
  xor rcx, rcx
  test rax, rax
  cmovz rcx, rdx
  lea IP, [IP + rcx*8]
  jmp NEXT

  ;; ABORT ( -- ) Clear stacks and jump to QUIT
ABORT_word:
  ; Clear data stack
  mov DSP, stack_top       ; stack_top is a label, not a variable
  
  ; Clear return stack and add sentinel
  mov RSTACK, return_stack_top  ; return_stack_top is a label, not a variable
  sub RSTACK, 8
  mov qword [RSTACK], 0    ; Sentinel for EXIT
  
  ; Set STATE = 0 (interpreter mode)
  mov qword [STATE], 0
  
  ; Jump into QUIT colon definition
  mov rdx, dict_QUIT       ; DOCOL expects dictionary pointer in RDX
  lea IP, [dict_QUIT + 24] ; Point IP to first word after header
  jmp NEXT                 ; Start executing QUIT

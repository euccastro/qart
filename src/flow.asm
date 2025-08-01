  ;; flow.asm - Control flow for the Forth interpreter
  ;; Contains NEXT, DOCOL, EXIT and other flow control primitives

  %include "forth.inc"

  section .data

  ;; Anonymous dictionary entry for SYSEXIT
  ;; Used by ABORT to terminate the program
dict_SYSEXIT:
  dq 0                    ; No link - internal use only
  db 0                    ; Name length 0 (anonymous)
  times 7 db 0            ; Padding to 8 bytes
  dq SYSEXIT              ; Code field

  ;; Main program executed by ABORT: QUIT followed by SYSEXIT
  extern dict_QUIT
abort_program:
  dq dict_QUIT            ; Call QUIT
  dq dict_SYSEXIT         ; Call SYSEXIT (exits program)

  section .text

  global NEXT
  global DOCOL
  global DOCREATE
  global EXIT
  global EXECUTE
  global BRANCH
  global ZBRANCH
  global ABORT_word
  global CC_SIZE
  global dict_SYSEXIT

  extern stack_top
  extern return_stack_top
  extern STATE

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

  ;; DOCREATE - Runtime for CREATE'd words
  ;; Expects RDX = dictionary entry address
  ;; Pushes address of data field (right after code field)
DOCREATE:
  sub DSP, 8              ; Make room on data stack
  lea rax, [rdx+24]       ; Address after link(8) + name(8) + code(8)
  mov [DSP], rax          ; Push data field address
  jmp NEXT

  ;; EXIT ( -- ) Return from colon definition
EXIT:
  mov rax, [RSTACK]       ; Get saved IP
  add RSTACK, 8           ; Drop from return stack
  mov IP, rax             ; Restore IP
  jmp NEXT                ; Continue in caller

  ;; SYSEXIT ( -- ) Exit the program
  ;; This is placed on the return stack by ABORT as the "bottom" return address
SYSEXIT:
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

  ;; ABORT ( -- ) Clear stacks and execute RUN
ABORT_word:
  ;; Clear data stack
  mov DSP, stack_top       ; stack_top is a label, not a variable
  
  ;; Clear return stack (completely empty)
  mov RSTACK, return_stack_top  ; return_stack_top is a label, not a variable
  
  ;; Initialize R13 with default flags:
  ;; Bit 0 = 0 (STATE = interpret)
  ;; Bits 1-2 = 01 (OUTPUT = stdout)
  ;; Bit 3 = 0 (DEBUG = off)  
  mov r13, 2               ; Binary: 0010 = stdout in bits 1-2
  
  ;; Point IP to abort_program and let NEXT execute it
  mov IP, abort_program    ; IP points to QUIT/SYSEXIT program
  jmp NEXT                 ; NEXT will execute QUIT then SYSEXIT

  ;; CC-SIZE - Calculate size needed for a continuation
  ;; ( -- n )
  ;; Returns bytes needed to capture current continuation state
CC_SIZE:
  ;; Fixed header size: 32 bytes
  ;; +0:  Code pointer (8 bytes)
  ;; +8:  Data stack depth in cells (8 bytes)
  ;; +16: Return stack depth in cells (8 bytes)
  ;; +24: Saved IP (8 bytes)
  mov rax, 32               ; Start with header size

  ;; Calculate data stack depth
  mov rdx, stack_top
  sub rdx, DSP              ; Distance from base to current
  add rax, rdx              ; Add data stack bytes

  ;; Calculate return stack depth
  mov rdx, return_stack_top
  sub rdx, RSTACK           ; Distance from base to current
  add rax, rdx              ; Add return stack bytes

  ;; Push total size to data stack
  sub DSP, 8
  mov [DSP], rax
  jmp NEXT

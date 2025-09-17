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

  ;; Anonymous dictionary entry for THREAD-EXIT
  ;; Calls the thread-local cleanup function
dict_THREAD_EXIT:
  dq 0                    ; No link - internal use only
  db 0                    ; Name length 0 (anonymous)
  times 7 db 0            ; Padding to 8 bytes
  dq THREAD_EXIT          ; Code field

  ;; Main program executed by ABORT: QUIT followed by thread-local cleanup
  extern dict_QUIT
abort_program:
  dq dict_QUIT            ; Call QUIT
  dq dict_THREAD_EXIT     ; Call thread-local cleanup

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
  global CALL_CC
  global dict_SYSEXIT
  global dict_THREAD_EXIT
  global RESTORE_CONT

  extern data_stack_base
  extern return_stack_base
  extern STATE

  ;; NEXT - The inner interpreter
  ;; Dictionary-based execution: NEXTIP points to dictionary entry addresses
NEXT:
  mov CURRIP, [NEXTIP]           ; Get dictionary entry address
  add NEXTIP, 8               ; Advance NEXTIP
  mov rax, [CURRIP+16]       ; Get code field from dict entry (link=8 + name=8)
  jmp rax                 ; Execute the code

  ;; DOCOL - Runtime for colon definitions
  ;; Expects RDX = dictionary entry address
  ;; Dictionary structure: link(8) + name(8) + code(8) + body...
DOCOL:
  sub RSTACK, 8           ; Make room on return stack
  mov [RSTACK], NEXTIP        ; Save current NEXTIP
  lea NEXTIP, [CURRIP+24]        ; NEXTIP = start of body (after 16-byte header and pointer to DOCOL)
  jmp NEXT                ; Start executing the body

  ;; DOCREATE - Runtime for CREATE'd words
  ;; Expects RDX = dictionary entry address
  ;; Pushes address of data field (right after code field)
DOCREATE:
  sub DSP, 8              ; Make room on data stack
  lea rax, [CURRIP+24]       ; Address after link(8) + name(8) + code(8)
  mov [DSP], rax          ; Push data field address
  jmp NEXT

  ;; EXIT ( -- ) Return from colon definition
EXIT:
  mov rax, [RSTACK]       ; Get saved NEXTIP
  add RSTACK, 8           ; Drop from return stack
  mov NEXTIP, rax             ; Restore NEXTIP
  jmp NEXT                ; Continue in caller

  ;; SYSEXIT ( -- ) Exit the entire process
  ;; Used as cleanup for main thread
SYSEXIT:
  mov rax, 60             ; sys_exit
  xor rdi, rdi
  syscall

  ;; THREAD_EXIT ( -- ) Call thread-local cleanup
  ;; Loads cleanup function from TLS and executes via NEXT
THREAD_EXIT:
  lea NEXTIP, [TLS+TLS_CLEANUP] ; Point NEXTIP to cleanup field in descriptor
  jmp NEXT                  ; NEXT will load and execute it

  ;; EXECUTE ( xt -- ) Execute word given execution token
  ;; Execution token is a dictionary pointer
EXECUTE:
  mov CURRIP, [DSP]          ; Get dictionary pointer from stack
  add DSP, 8              ; Drop from stack
  mov rax, [CURRIP+16]       ; Load code address from dict entry
  jmp rax                 ; Jump to the code

  ;; BRANCH ( -- ) Jump to absolute address
BRANCH:
  mov NEXTIP, [NEXTIP]            ; Load absolute address from next cell
  jmp NEXT

  ;; ZBRANCH ( n -- ) Jump to absolute address if TOS is zero
ZBRANCH:
  mov rdx, [NEXTIP]           ; Get absolute address
  add NEXTIP, 8               ; Skip past the address
  mov rax, [DSP]          ; Get flag
  add DSP, 8              ; Drop flag
  test rax, rax           ; Test flag
  cmovz NEXTIP, rdx           ; If zero, jump to absolute address
  jmp NEXT

  ;; ABORT ( -- ) Clear stacks and execute RUN
ABORT_word:
  ;; Clear data stack
  mov DSP, data_stack_base ; data_stack_base is a label, not a variable
  
  ;; Clear return stack (completely empty)
  mov RSTACK, return_stack_base  ; return_stack_base is a label, not a variable
  
  ;; Initialize TLS (R13) to point to main thread descriptor
  extern main_thread_descriptor
  mov TLS, main_thread_descriptor
  
  ;; Point NEXTIP to abort_program and let NEXT execute it
  mov NEXTIP, abort_program    ; NEXTIP points to QUIT/SYSEXIT program
  jmp NEXT                 ; NEXT will execute QUIT then SYSEXIT

  ;; CC-SIZE - Calculate size needed for a continuation
  ;; ( -- n )
  ;; Returns bytes needed to capture current continuation state
CC_SIZE:
  ;; Fixed header size: CONT_HEADER_SIZE bytes
  ;; +CONT_CODE:        Code pointer (8 bytes)
  ;; +CONT_DATA_SIZE:   Data stack depth in bytes (8 bytes)
  ;; +CONT_RETURN_SIZE: Return stack depth in bytes (8 bytes)
  ;; +CONT_SAVED_IP:    Saved NEXTIP (8 bytes)
  mov rax, CONT_HEADER_SIZE      ; Start with header size

  ;; Calculate data stack depth
  mov rdx, [TLS+TLS_DATA_BASE]   ; Get data stack base from descriptor
  sub rdx, DSP                   ; Distance from base to current
  add rax, rdx                   ; Add data stack bytes

  ;; Calculate return stack depth
  mov rdx, [TLS+TLS_RETURN_BASE] ; Get return stack base from descriptor
  sub rdx, RSTACK                ; Distance from base to current
  add rax, rdx                   ; Add return stack bytes

  ;; Push total size to data stack
  sub DSP, 8
  mov [DSP], rax
  jmp NEXT

  ;; CALL/CC - Call with current continuation
  ;; ( cont-addr xt -- cont-addr )
  ;; Captures current continuation into buffer at cont-addr,
  ;; then calls xt with cont-addr on stack
CALL_CC:
  ;; Stack has: cont-addr xt
  mov r11, [DSP]          ; r11 = xt to call
  mov rdi, [DSP+8]        ; RDI = buffer for continuation
  
  ;; Fill in continuation header
  mov rax, RESTORE_CONT
  mov [rdi+CONT_CODE], rax        ; Code pointer
  
  ;; Calculate and store data stack depth (excluding cont-addr and xt)
  mov rax, [TLS+TLS_DATA_BASE]
  sub rax, DSP
  sub rax, 16                      ; Exclude the two args
  mov [rdi+CONT_DATA_SIZE], rax   ; Store data stack size
  
  ;; Calculate and store return stack depth
  mov rax, [TLS+TLS_RETURN_BASE]
  sub rax, RSTACK
  mov [rdi+CONT_RETURN_SIZE], rax ; Store return stack size
  
  ;; Store NEXTIP (pointing to instruction AFTER CALL/CC)
  mov [rdi+CONT_SAVED_IP], NEXTIP     ; Save where to continue
  
  ;; Copy data stack (excluding cont-addr and xt)
  mov rcx, [rdi+CONT_DATA_SIZE]
  lea rsi, [DSP+16]                ; Source: skip cont-addr and xt
  push rdi                          ; Save continuation pointer
  lea rdi, [rdi+CONT_HEADER_SIZE]  ; Destination in continuation
  shr rcx, 3                        ; Convert bytes to qwords (0 if empty)
  rep movsq                         ; Copy the data (no-op if RCX=0)
  
  ;; Copy return stack (always has something - at least cleanup)
  pop rdi                           ; Restore continuation pointer
  mov rcx, [rdi+CONT_RETURN_SIZE]
  mov rsi, RSTACK                   ; Source
  lea rdx, [rdi+CONT_HEADER_SIZE]  ; Start of data area
  add rdx, [rdi+CONT_DATA_SIZE]    ; Skip past data stack contents
  mov rdi, rdx                      ; Destination for return stack
  shr rcx, 3                        ; Convert bytes to qwords
  rep movsq                         ; Copy the data
  
  ;; Now execute the function with cont-addr on stack
  ;; Stack currently has: cont-addr xt
  ;; EXECUTE will pop xt and execute it, leaving cont-addr
  jmp EXECUTE

  ;; RESTORE-CONT - Restore a continuation
  ;; This is called when a continuation is executed
  ;; NEXTIP points to the continuation object when this runs
  ;; Continuation layout:
  ;;   [NEXTIP+CONT_CODE]:        Code pointer to RESTORE-CONT (this code)
  ;;   [NEXTIP+CONT_DATA_SIZE]:   Data stack depth in bytes
  ;;   [NEXTIP+CONT_RETURN_SIZE]: Return stack depth in bytes
  ;;   [NEXTIP+CONT_SAVED_IP]:    Saved NEXTIP
  ;;   [NEXTIP+CONT_HEADER_SIZE]: Data stack contents
  ;;   [NEXTIP+CONT_HEADER_SIZE+data_bytes]: Return stack contents
RESTORE_CONT:
  ;; This IS the continuation - directly executable like any word
  ;; NEXTIP points to our continuation object structure
  ;; Stack has value to pass (user error if empty, like . on empty stack)
  
  ;; Save the value to pass to the continuation
  mov r11, [DSP]          ; r11 = value to pass
  
  ;; Load data stack depth (already in bytes)
  mov rdx, [NEXTIP+CONT_DATA_SIZE]   ; RDX = data stack size in bytes
  
  ;; Restore data stack
  mov DSP, [TLS+TLS_DATA_BASE] ; Get base from descriptor
  sub DSP, rdx              ; Make room on data stack
  
  ;; Copy data stack contents
  mov rcx, rdx              ; RCX = byte count
  mov rdi, DSP              ; Destination
  lea rsi, [NEXTIP+CONT_HEADER_SIZE] ; Source (skip header)
  shr rcx, 3                ; Convert to qwords (0 if empty)
  rep movsq                 ; Copy the data (no-op if RCX=0)
  
  ;; Push the passed value onto restored stack
  sub DSP, 8
  mov [DSP], r11          ; Push the value
  
  ;; Load return stack depth and restore
  mov rdx, [NEXTIP+CONT_RETURN_SIZE] ; RDX = return stack size in bytes
  mov RSTACK, [TLS+TLS_RETURN_BASE] ; Get base from descriptor
  
  ;; Adjust RSTACK (rdx has size in bytes, always non-zero)
  sub RSTACK, rdx           ; Make room on return stack
  
  ;; Calculate source offset (header + data stack bytes)
  mov rax, [NEXTIP+CONT_DATA_SIZE]   ; Data stack size in bytes
  add rax, CONT_HEADER_SIZE      ; Add header size
  
  ;; Copy return stack contents
  mov rcx, rdx              ; RCX = byte count
  mov rdi, RSTACK           ; Destination
  lea rsi, [NEXTIP+rax]         ; Source (NEXTIP + offset in rax)
  shr rcx, 3                ; Convert to qwords
  rep movsq                 ; Copy the data
  
  ;; Restore NEXTIP and continue
  mov NEXTIP, [NEXTIP+CONT_SAVED_IP]     ; Load saved NEXTIP from continuation
  jmp NEXT                  ; Continue execution

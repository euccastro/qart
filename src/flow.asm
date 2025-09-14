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
  global JMP2IP
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
  ;; Dictionary-based execution: IP points to dictionary entry addresses
NEXT:
  add IP, 8               ; Advance IP to next instruction
JMP2IP:                   ; Jump to execution token at IP without advancing
  mov rax, [IP]           ; Get dictionary entry address
  mov rax, [rax+16]       ; Get code field from dict entry (link=8 + name=8)
  jmp rax                 ; Execute the code

  ;; DOCOL - Runtime for colon definitions
  ;; IP points to current dictionary entry when this executes
DOCOL:
  sub RSTACK, 8           ; Make room on return stack
  mov [RSTACK], IP        ; Save current IP (return address in calling sequence)
  mov rax, [IP]           ; Get dictionary entry address
  lea IP, [rax+24]        ; IP = start of body (after link+name+code = 24 bytes)
  jmp JMP2IP              ; Start executing the body

  ;; DOCREATE - Runtime for CREATE'd words
  ;; IP points to current dictionary entry when this executes
  ;; Pushes address of data field (right after code field)
DOCREATE:
  sub DSP, 8              ; Make room on data stack
  mov rax, [IP]           ; Get dictionary entry address
  lea rax, [rax+24]       ; Address after link(8) + name(8) + code(8)
  mov [DSP], rax          ; Push data field address
  jmp NEXT

  ;; EXIT ( -- ) Return from colon definition
EXIT:
  mov rax, [RSTACK]       ; Get saved IP
  add RSTACK, 8           ; Drop from return stack
  mov IP, rax             ; Restore IP
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
  lea IP, [TLS+TLS_CLEANUP] ; Point IP to cleanup field in descriptor
  jmp JMP2IP

  ;; EXECUTE ( xt -- ) Execute word given execution token
  ;; Execution token is a dictionary pointer
EXECUTE:
  sub RSTACK, 8                    ; Make room in return stack
  mov [RSTACK], IP                 ; Save return address
  mov rax, [DSP]                   ; Get dictionary pointer from stack
  add DSP, 8                       ; Drop from stack
  mov [TLS+TLS_EXECUTE_BUFFER], rax ; Store in execute buffer
  lea IP, [TLS+TLS_EXECUTE_BUFFER] ; Set IP to buffer address
  jmp JMP2IP                       ; Execute at IP without advancing

  ;; BRANCH ( -- ) Jump to absolute address
BRANCH:
  mov IP, [IP+8]            ; Load absolute address
  jmp JMP2IP              ; Execute at new IP without advancing

  ;; ZBRANCH ( n -- ) Jump to absolute address if TOS is zero
ZBRANCH:
  mov rdx, [IP+8]           ; Get absolute address
  add IP, 16               ; Advance past address (+1 because we'll be using JMP2IP not NEXT)
  mov rax, [DSP]          ; Get flag
  add DSP, 8              ; Drop flag
  test rax, rax           ; Test flag
  cmovz IP, rdx           ; If zero, jump to absolute address
  jmp JMP2IP              ; Execute at IP without advancing

  ;; ABORT ( -- ) Clear stacks and execute RUN
ABORT_word:
  ;; Clear data stack
  mov DSP, data_stack_base ; data_stack_base is a label, not a variable
  
  ;; Clear return stack (completely empty)
  mov RSTACK, return_stack_base  ; return_stack_base is a label, not a variable
  
  ;; Initialize TLS (R13) to point to main thread descriptor
  extern main_thread_descriptor
  mov TLS, main_thread_descriptor
  
  ;; Execute abort_program directly
  mov IP, abort_program    ; IP points to QUIT/SYSEXIT program  
  jmp JMP2IP               ; Execute first word in program

  ;; CC-SIZE - Calculate size needed for a continuation
  ;; ( -- n )
  ;; Returns bytes needed to capture current continuation state
CC_SIZE:
  ;; Fixed header size: CONT_HEADER_SIZE bytes
  ;; +CONT_CODE:        Code pointer (8 bytes)
  ;; +CONT_DATA_SIZE:   Data stack depth in bytes (8 bytes)
  ;; +CONT_RETURN_SIZE: Return stack depth in bytes (8 bytes)
  ;; +CONT_SAVED_IP:    Saved IP (8 bytes)
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
  mov rbx, [DSP]          ; RBX = xt to call
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
  
  ;; Store IP (pointing to instruction AFTER CALL/CC)
  mov [rdi+CONT_SAVED_IP], IP     ; Save where to continue
  
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
  ;; IP points to the continuation object when this runs
  ;; Continuation layout:
  ;;   [IP+CONT_CODE]:        Code pointer to RESTORE-CONT (this code)
  ;;   [IP+CONT_DATA_SIZE]:   Data stack depth in bytes
  ;;   [IP+CONT_RETURN_SIZE]: Return stack depth in bytes
  ;;   [IP+CONT_SAVED_IP]:    Saved IP
  ;;   [IP+CONT_HEADER_SIZE]: Data stack contents
  ;;   [IP+CONT_HEADER_SIZE+data_bytes]: Return stack contents
RESTORE_CONT:
  ;; This IS the continuation - directly executable like any word
  ;; IP points to our continuation object structure
  ;; Stack has value to pass (user error if empty, like . on empty stack)
  
  ;; Save the value to pass to the continuation
  mov rbx, [DSP]          ; RBX = value to pass
  
  ;; Load data stack depth (already in bytes)
  mov rdx, [IP+CONT_DATA_SIZE]   ; RDX = data stack size in bytes
  
  ;; Restore data stack
  mov DSP, [TLS+TLS_DATA_BASE] ; Get base from descriptor
  sub DSP, rdx              ; Make room on data stack
  
  ;; Copy data stack contents
  mov rcx, rdx              ; RCX = byte count
  mov rdi, DSP              ; Destination
  lea rsi, [IP+CONT_HEADER_SIZE] ; Source (skip header)
  shr rcx, 3                ; Convert to qwords (0 if empty)
  rep movsq                 ; Copy the data (no-op if RCX=0)
  
  ;; Push the passed value onto restored stack
  sub DSP, 8
  mov [DSP], rbx          ; Push the value
  
  ;; Load return stack depth and restore
  mov rdx, [IP+CONT_RETURN_SIZE] ; RDX = return stack size in bytes
  mov RSTACK, [TLS+TLS_RETURN_BASE] ; Get base from descriptor
  
  ;; Adjust RSTACK (rdx has size in bytes, always non-zero)
  sub RSTACK, rdx           ; Make room on return stack
  
  ;; Calculate source offset (header + data stack bytes)
  mov rax, [IP+CONT_DATA_SIZE]   ; Data stack size in bytes
  add rax, CONT_HEADER_SIZE      ; Add header size
  
  ;; Copy return stack contents
  mov rcx, rdx              ; RCX = byte count
  mov rdi, RSTACK           ; Destination
  lea rsi, [IP+rax]         ; Source (IP + offset in rax)
  shr rcx, 3                ; Convert to qwords
  rep movsq                 ; Copy the data
  
  ;; Restore IP and continue
  mov IP, [IP+CONT_SAVED_IP]     ; Load saved IP from continuation
  jmp NEXT                  ; Continue execution

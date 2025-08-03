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
  jmp NEXT                  ; NEXT will load and execute it

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
  mov DSP, data_stack_base ; data_stack_base is a label, not a variable
  
  ;; Clear return stack (completely empty)
  mov RSTACK, return_stack_base  ; return_stack_base is a label, not a variable
  
  ;; Initialize TLS (R13) to point to main thread descriptor
  extern main_thread_descriptor
  mov TLS, main_thread_descriptor
  
  ;; Point IP to abort_program and let NEXT execute it
  mov IP, abort_program    ; IP points to QUIT/SYSEXIT program
  jmp NEXT                 ; NEXT will execute QUIT then SYSEXIT

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
  
  ;; Copy data stack (if any, excluding cont-addr and xt)
  mov rcx, [rdi+CONT_DATA_SIZE]
  test rcx, rcx
  jz .copy_return_stack
  
  ;; Copy data stack contents
  lea rsi, [DSP+16]                ; Source: skip cont-addr and xt
  lea rdx, [rdi+CONT_HEADER_SIZE]  ; Destination in continuation
  shr rcx, 3                        ; Convert bytes to qwords
  rep movsq                         ; Copy the data
  
.copy_return_stack:
  ;; Copy return stack (always has something - at least cleanup)
  mov rcx, [rdi+CONT_RETURN_SIZE]
  mov rsi, RSTACK                   ; Source
  lea rdx, [rdi+CONT_HEADER_SIZE]  ; Start of data area
  add rdx, [rdi+CONT_DATA_SIZE]    ; Skip past data stack contents
  mov rdi, rdx                      ; Destination for return stack
  shr rcx, 3                        ; Convert bytes to qwords
  rep movsq                         ; Copy the data
  
  ;; Now execute the function with cont-addr on stack
  ;; Stack currently has: cont-addr xt
  ;; We want: cont-addr (and execute xt)
  add DSP, 8              ; Drop xt, leave cont-addr
  mov rdx, rbx            ; RDX = dictionary pointer (xt)
  mov rax, [rdx+16]       ; Get code field from dict entry
  jmp rax                 ; Execute the function

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
  ;; IP points to the continuation object
  ;; Stack has value to pass to continuation
  ;; We'll preserve IP and use it as our base pointer
  
  ;; Save the value to pass to the continuation
  mov rbx, [DSP]          ; RBX = value to pass
  
  ;; Load data stack depth (already in bytes)
  mov rdx, [IP+CONT_DATA_SIZE]   ; RDX = data stack size in bytes
  
  ;; Restore data stack
  mov DSP, [TLS+TLS_DATA_BASE] ; Get base from descriptor
  sub DSP, rdx              ; Make room on data stack
  
  ;; Copy data stack contents (if any)
  test rdx, rdx
  jz .push_value
  mov rdi, DSP              ; Destination
  lea rsi, [IP+CONT_HEADER_SIZE] ; Source (skip header)
  ;; rdx already has byte count
  call memcpy_forward       ; Copy the data
  
.push_value:
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
  mov rdi, RSTACK           ; Destination
  lea rsi, [IP+rax]         ; Source (IP + offset in rax)
  ;; rdx already has byte count
  call memcpy_forward       ; Copy the data
  
  ;; Restore IP and continue
  mov IP, [IP+CONT_SAVED_IP]     ; Load saved IP from continuation
  jmp NEXT                  ; Continue execution

  ;; Simple forward memcpy (used by RESTORE_CONT)
  ;; RDI = dest, RSI = source, RDX = count
  ;; Modifies: RCX, RDI, RSI (rep movsq increments RDI/RSI)
memcpy_forward:
  test rdx, rdx
  jz .done
  mov rcx, rdx
  shr rcx, 3                ; Count of qwords
  rep movsq                 ; Copy qwords
.done:
  ret

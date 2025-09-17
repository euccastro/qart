;;; io.asm - Input/Output operations

  %include "forth.inc"  

  section .text

  global IMPL_DOT
  global IMPL_NUMBER
  global IMPL_EMIT
  global IMPL_TYPE
  global IMPL_KEY

  extern NEXT
  extern buffer
  extern minus_sign
  extern space

  ;; Helper macro to load output FD from TLS->flags bits 1-2 into RDI
%macro LOAD_OUTPUT_FD_RDI 0
  mov rdi, [TLS+TLS_FLAGS] ; Get flags from descriptor
  shr rdi, 1              ; Get bits 1-2
  and rdi, 3              ; Isolate 2 bits (0=stdin, 1=stdout, 2=stderr)
%endmacro

  ;; DOT ( n -- ) Pop and print number with trailing space
IMPL_DOT:
  mov rax, [DSP]          ; Get number
  add DSP, 8              ; Drop it
  
  ;; Handle negative numbers
  test rax, rax
  jns .positive
  neg rax                 ; Make positive
  push rax                ; Save number
  
  ;; Print minus sign
  mov rax, 1              ; sys_write
  LOAD_OUTPUT_FD_RDI
  mov rsi, minus_sign
  mov rdx, 1
  syscall
  
  pop rax                 ; Restore number
  
  .positive:
  ;; Convert to decimal string
  mov rdi, buffer + 19
  mov rcx, 10
  
  .convert_loop:
  xor rdx, rdx
  div rcx
  add dl, '0'
  dec rdi
  mov [rdi], dl
  test rax, rax
  jnz .convert_loop
  
  ;; Print the number
  mov rax, 1              ; sys_write
  mov rsi, rdi            ; Move buffer pointer to rsi
  mov rdx, buffer + 19
  sub rdx, rdi
  LOAD_OUTPUT_FD_RDI
  syscall
  
  ;; Print space (Forth convention)
  mov rax, 1
  LOAD_OUTPUT_FD_RDI
  mov rsi, space
  mov rdx, 1
  syscall
  
  jmp NEXT

  ;; EMIT ( c -- ) Output character
IMPL_EMIT:
  ;; Write directly from stack (low byte contains the character)
  mov rax, 1              ; sys_write
  LOAD_OUTPUT_FD_RDI
  mov rsi, DSP            ; Address of character on stack
  mov rdx, 1              ; One byte (just the low byte)
  syscall
  
  add DSP, 8              ; Drop from stack
  jmp NEXT

  ;; TYPE ( c-addr u -- ) Output string
IMPL_TYPE:
  mov rax, 1              ; sys_write
  LOAD_OUTPUT_FD_RDI
  mov rsi, [DSP+8]        ; String address
  mov rdx, [DSP]          ; Length
  syscall

  add DSP, 16
  jmp NEXT

  ;; KEY ( -- c ) Read one character from stdin
IMPL_KEY:
  ;; Make room on stack and zero it
  sub DSP, 8
  mov qword [DSP], 0      ; Clear all 8 bytes
  
  ;; Read one character directly into stack
  mov rax, 0              ; sys_read
  mov rdi, 0              ; stdin
  mov rsi, DSP            ; Read into low byte of stack entry
  mov rdx, 1              ; Read 1 byte
  syscall
  
  ;; Check for EOF or error
  test rax, rax
  jle .eof
  
  ;; Character is already on stack (zero-extended)
  jmp NEXT
  .eof:
  ;; Replace with -1 for EOF
  mov qword [DSP], -1
  jmp NEXT

  ;; NUMBER ( c-addr u -- n -1 | c-addr u 0 ) Parse string as signed integer
IMPL_NUMBER:
  ;; Save original values for possible error return
  mov rax, [DSP]          ; Length (u)
  push rax
  mov rax, [DSP+8]        ; String pointer (c-addr)
  push rax
  
  ;; Get parameters for parsing
  mov rcx, [DSP]          ; Length (u) 
  mov rsi, [DSP+8]        ; String pointer (c-addr)
  
  xor rax, rax            ; Initialize result
  xor r8, r8              ; Sign flag (0 = positive)
  
  ;; Check for empty string
  test rcx, rcx
  jz .error
  
  ;; Check for negative sign
  mov dl, [rsi]
  cmp dl, '-'
  jne .parse_digits
  mov r8, 1               ; Set negative flag
  inc rsi                 ; Skip minus sign
  dec rcx                 ; Decrease length
  jz .error               ; Error if just "-"
  
  .parse_digits:
  movzx rdx, byte [rsi]   ; Get character (zero-extended)
  sub dl, '0'             ; Convert to digit
  cmp dl, 9               ; Check if valid digit
  ja .error               ; Not a digit
  
  ;; Multiply current result by 10 and add digit
  push rdx                ; Save digit
  mov r9, 10
  mul r9                  ; rax = rax * 10, result in rax
  pop rdx                 ; Restore digit
  add rax, rdx            ; Add new digit
  
  inc rsi                 ; Next character
  dec rcx                 ; Decrease count
  jnz .parse_digits
  
  ;; Apply sign if negative
  test r8, r8
  jz .success
  neg rax
  
  .success:
  ;; Drop saved values
  add rsp, 16
  ;; Replace string with number and true
  mov [DSP+8], rax        ; Store result over c-addr
  mov qword [DSP], -1     ; Store true (-1 for standard Forth) over u
  jmp NEXT
  
  .error:
  ;; Restore original values
  pop rax
  mov [DSP+8], rax        ; Keep c-addr
  pop rax
  mov [DSP], rax          ; Keep u
  ;; Push false
  sub DSP, 8
  mov qword [DSP], 0
  jmp NEXT


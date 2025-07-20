;;; io.asm - Input/Output operations

  %include "forth.inc"  

  section .text

  global DOT
  global NUMBER
  global EMIT
  global TYPE
  global ERRTYPE
  global KEY
  global ASSERT

  extern NEXT
  extern buffer
  extern minus_sign
  extern space

  ;; DOT ( n -- ) Pop and print number with trailing space
DOT:
  mov rax, [DSP]          ; Get number
  add DSP, 8              ; Drop it
  
  ;; Handle negative numbers
  test rax, rax
  jns .positive
  neg rax                 ; Make positive
  push rax                ; Save number
  
  ;; Print minus sign
  mov rax, 1              ; sys_write
  mov rdi, 1              ; stdout
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
  mov rsi, rdi
  mov rdx, buffer + 19
  sub rdx, rdi
  mov rdi, 1              ; stdout
  syscall
  
  ;; Print space (Forth convention)
  mov rax, 1
  mov rdi, 1
  mov rsi, space
  mov rdx, 1
  syscall
  
  jmp NEXT

  ;; EMIT ( c -- ) Output character
EMIT:
  ;; Write directly from stack (low byte contains the character)
  mov rax, 1              ; sys_write
  mov rdi, 1              ; stdout
  mov rsi, DSP            ; Address of character on stack
  mov rdx, 1              ; One byte (just the low byte)
  syscall
  
  add DSP, 8              ; Drop from stack
  jmp NEXT

  ;; TYPE ( c-addr u -- ) Output string to stdout
TYPE:
  mov rax, 1              ; sys_write
  mov rdi, 1              ; stdout
  mov rsi, [DSP+8]        ; String address
  mov rdx, [DSP]          ; Length
  syscall

  add DSP, 16
  jmp NEXT

  ;; ERRTYPE ( c-addr u -- ) Output string to stderr
ERRTYPE:
  mov rax, 1              ; sys_write
  mov rdi, 2              ; stderr
  mov rsi, [DSP+8]        ; String address
  mov rdx, [DSP]          ; Length
  syscall

  add DSP, 16
  jmp NEXT

  ;; KEY ( -- c ) Read one character from stdin
KEY:
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

  ;; NUMBER ( c-addr u -- n true | c-addr u false ) Parse string as signed integer
NUMBER:
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
  mov qword [DSP], 1      ; Store true over u
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

  ;; ASSERT ( flag id -- ) Print "FAIL: <id>" to stderr if flag is false
ASSERT:
  mov rax, [DSP]          ; Get id
  add DSP, 8
  mov rdx, [DSP]          ; Get flag
  add DSP, 8
  test rdx, rdx
  jnz .ok                 ; Non-zero = true = pass
  
  ;; Print "FAIL: " to stderr
  push rax                ; Save id
  mov rax, 1              ; sys_write
  mov rdi, 2              ; stderr
  mov rsi, .fail_msg
  mov rdx, 6              ; "FAIL: " length
  syscall
  
  ;; Print the test ID number
  pop rax                 ; Restore id
  
  ;; Handle negative numbers
  test rax, rax
  jns .print_positive
  neg rax                 ; Make positive
  push rax                ; Save number
  
  ;; Print minus sign
  mov rax, 1              ; sys_write
  mov rdi, 2              ; stderr
  mov rsi, minus_sign
  mov rdx, 1
  syscall
  
  pop rax                 ; Restore number
  
.print_positive:
  ;; Convert to decimal string (reuse DOT's logic)
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
  mov rsi, rdi
  mov rdx, buffer + 19
  sub rdx, rdi
  mov rdi, 2              ; stderr
  syscall
  
  ;; Print newline
  mov rax, 1
  mov rdi, 2              ; stderr
  mov rsi, .newline_char
  mov rdx, 1
  syscall
  
.ok:
  jmp NEXT

.fail_msg: db "FAIL: "
.newline_char: db NEWLINE

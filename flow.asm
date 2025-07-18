; flow.asm - Control flow for the Forth interpreter
; Contains NEXT, DOCOL, EXIT and other flow control primitives

%include "forth.inc"

section .text

global NEXT
global DOCOL
global EXIT
global EXECUTE

; NEXT - The inner interpreter
; Dictionary-based execution: IP points to dictionary entry addresses
NEXT:
    mov rdx, [IP]           ; Get dictionary entry address
    add IP, 8               ; Advance IP
    mov rax, [rdx+16]       ; Get code field from dict entry (link=8 + name=8)
    jmp rax                 ; Execute the code

; DOCOL - Runtime for colon definitions
; Expects RDX = dictionary entry address
; Dictionary structure: link(8) + name(8) + code(8) + body...
DOCOL:
    sub RSTACK, 8           ; Make room on return stack
    mov [RSTACK], IP        ; Save current IP
    lea IP, [rdx+24]        ; IP = start of body (after 24-byte header)
    jmp NEXT                ; Start executing the body

; EXIT ( -- ) Return from colon definition
; For top-level, return stack will be empty and we'll exit
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

; EXECUTE ( xt -- ) Execute word given execution token
; Execution token is a dictionary entry address
EXECUTE:
    mov rdx, [DSP]          ; Get execution token from stack
    add DSP, 8              ; Drop from stack
    mov rax, [rdx+16]       ; Get code field from dict entry
    jmp rax                 ; Execute it (primitives will jmp NEXT themselves)
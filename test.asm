; test.asm - Testing and assertion primitives

%include "forth.inc"

section .text

global ASSERT

extern NEXT
extern OUTPUT
extern FLAGS

section .data
.fail_msg: db "FAIL: "
.pass_msg: db "PASS: "
.newline_char: db 10

section .text

; ASSERT ( flag id -- ) Check assertion, print FAIL: id if false
; If FLAGS bit 0 is set, also print PASS: id for successes
ASSERT:
    mov rax, [DSP]          ; Get id
    add DSP, 8
    mov rdx, [DSP]          ; Get flag
    add DSP, 8
    
    ; Check if assertion passed
    test rdx, rdx
    jnz .check_verbose      ; Non-zero = true = pass
    
    ; Failed - print error to stderr
    push rax                ; Save id
    push rbx                ; Save IP
    
    ; Print "FAIL: " to stderr
    mov rax, 1              ; sys_write
    mov rdi, 2              ; stderr
    mov rsi, .fail_msg
    mov rdx, 6              ; Length of "FAIL: "
    syscall
    
    pop rbx                 ; Restore IP
    pop rax                 ; Get id back
    
    ; Print the id number
    push rbx                ; Save IP again
    mov rbx, 10             ; Divisor
    mov rcx, buffer + 19    ; End of buffer
    mov rsi, rcx            ; Save end position
    mov rdi, 2              ; stderr for fail case
    
    ; Handle negative numbers
    test rax, rax
    jns .print_positive
    neg rax                 ; Make positive
    push rax
    
    ; Print minus sign
    push rcx
    push rsi
    mov rax, 1              ; sys_write
    mov rdi, 2              ; stderr
    mov rsi, minus_sign
    mov rdx, 1
    syscall
    pop rsi
    pop rcx
    
    pop rax
    
.print_positive:
    ; Convert to decimal (backwards)
.convert_loop:
    xor rdx, rdx
    div rbx                 ; Divide by 10
    add dl, '0'             ; Convert remainder to ASCII
    dec rcx
    mov [rcx], dl
    test rax, rax
    jnz .convert_loop
    
    ; Write the number
    mov rdx, rsi
    sub rdx, rcx            ; Length = end - start
    mov rax, 1              ; sys_write
    ; RDI should already be set to the appropriate stream
    mov rsi, rcx            ; Start of string
    syscall
    
    ; Print newline
    mov rax, 1              ; sys_write
    ; RDI still has the stream
    mov rsi, .newline_char
    mov rdx, 1
    syscall
    
    pop rbx                 ; Restore IP
    jmp NEXT
    
.check_verbose:
    ; Check if FLAGS bit 0 is set (verbose mode)
    push rax                ; Save id
    mov rax, [FLAGS]
    test rax, 1             ; Check bit 0
    pop rax                 ; Restore id
    jz .ok                  ; Not verbose, just return
    
    ; Verbose mode - print PASS message
    push rax                ; Save id
    push rbx                ; Save IP
    
    ; Print "PASS: " to stderr
    mov rax, 1              ; sys_write
    mov rdi, 2              ; stderr
    mov rsi, .pass_msg
    mov rdx, 6              ; Length of "PASS: "
    syscall
    
    pop rbx                 ; Restore IP
    pop rax                 ; Get id back
    
    ; Print the id number (reuse the positive number printing code)
    push rbx                ; Save IP again
    mov rbx, 10             ; Divisor
    mov rcx, buffer + 19    ; End of buffer
    mov rsi, rcx            ; Save end position
    mov rdi, 2              ; stderr for pass case too
    jmp .print_positive     ; Reuse number printing code
    
.ok:
    jmp NEXT

; External references needed
extern buffer
extern minus_sign
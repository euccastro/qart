; qart.asm - A Forth-like language implementation in x86_64 assembly
; Starting from basic ITC interpreter, building toward advanced features

%define IP rbx              ; Instruction Pointer
%define DSP rbp             ; Data Stack Pointer

section .data
    buffer: times 20 db 0
    newline: db 10
    
    ; Test program: 10 20 + 15 + . 
    ; Should print 45
    align 8
    test_program:
        dq LIT, 10          ; Push 10
        dq LIT, 20          ; Push 20
        dq ADD              ; 10 + 20 = 30
        dq LIT, 15          ; Push 15
        dq ADD              ; 30 + 15 = 45
        dq DOT              ; Print top of stack
        dq EXIT             ; Done

section .bss
    align 8
    stack_base: resq 1024
    stack_top:

section .text
global _start

; NEXT - The inner interpreter
NEXT:
    mov rax, [IP]           ; Fetch next word
    add IP, 8               ; Advance IP
    jmp rax                 ; Execute the word

; ---- Forth Primitives ----

; LIT ( -- n ) Push following cell as literal
LIT:
    mov rax, [IP]           ; Get literal value
    add IP, 8               ; Skip it
    sub DSP, 8              ; Make room
    mov [DSP], rax          ; Push value
    jmp NEXT

; ADD ( n1 n2 -- n3 ) Add top two stack items
ADD:
    mov rax, [DSP]          ; Get top (n2)
    add DSP, 8              ; Drop it
    add [DSP], rax          ; Add to new top (n1)
    jmp NEXT

; DOT ( n -- ) Pop and print number with trailing space
DOT:
    push rdi                ; Save registers
    push rsi
    push rdx
    push rcx
    
    mov rax, [DSP]          ; Get number
    add DSP, 8              ; Drop it
    
    ; Handle negative numbers
    test rax, rax
    jns .positive
    neg rax                 ; Make positive
    push rax                ; Save number
    
    ; Print minus sign
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, minus_sign
    mov rdx, 1
    syscall
    
    pop rax                 ; Restore number
    
.positive:
    ; Convert to decimal string
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
    
    ; Print the number
    mov rax, 1              ; sys_write
    mov rsi, rdi
    mov rdx, buffer + 19
    sub rdx, rdi
    mov rdi, 1              ; stdout
    syscall
    
    ; Print space (Forth convention)
    mov rax, 1
    mov rdi, 1
    mov rsi, space
    mov rdx, 1
    syscall
    
    pop rcx                 ; Restore registers
    pop rdx
    pop rsi
    pop rdi
    jmp NEXT

; EXIT ( -- ) Stop interpreting
EXIT:
    mov rax, 60             ; sys_exit
    xor rdi, rdi
    syscall

; ---- Main Program ----

_start:
    ; Initialize stacks
    mov DSP, stack_top      ; Data stack grows down
    
    ; Start interpreting
    mov IP, test_program
    jmp NEXT

; ---- Data that didn't fit in .data section ----
section .data
    minus_sign: db '-'
    space: db ' '
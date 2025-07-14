; step05_next_mechanism.asm - The NEXT inner interpreter
; Goal: Replace manual loop with proper NEXT mechanism

%define IP rbx              ; Instruction Pointer - points into thread
%define DSP rbp             ; Data Stack Pointer

section .data
    buffer: times 20 db 0
    newline: db 10
    
    ; Same program as before: push 42, push 17, add, print
    align 8
    thread:
        dq lit
        dq 42
        dq lit
        dq 17
        dq add_top_two
        dq print_pop
        dq exit_forth       ; New: proper exit instead of null

section .bss
    align 8
    stack_base: resq 1024
    stack_top:

section .text
global _start

; NEXT - The inner interpreter
; This is the heart of Forth!
NEXT:
    mov rax, [IP]           ; Load address from thread
    add IP, 8               ; Advance instruction pointer
    jmp rax                 ; Jump to the primitive (rax contains the address)
    ; Note: We never return here! Each primitive ends with jmp NEXT

; LIT - Push inline literal
lit:
    mov rax, [IP]           ; Get the literal value
    add IP, 8               ; Skip over it
    sub DSP, 8              ; Make room on stack
    mov [DSP], rax          ; Push the value
    jmp NEXT                ; Continue interpreting

; Add top two values
add_top_two:
    mov rax, [DSP]          ; Get top
    add rax, [DSP + 8]      ; Add second
    add DSP, 8              ; Drop top
    mov [DSP], rax          ; Replace with sum
    jmp NEXT                ; Continue interpreting

; Pop and print
print_pop:
    push rdi                ; Save registers (syscalls destroy them)
    push rsi
    push rdx
    push rcx
    
    mov rax, [DSP]          ; Get value
    add DSP, 8              ; Pop it
    
    ; Convert to string
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
    
    ; Print newline
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    pop rcx                 ; Restore registers
    pop rdx
    pop rsi
    pop rdi
    jmp NEXT                ; Continue interpreting

; Exit - Stop interpreting and return to system
exit_forth:
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; exit code 0
    syscall
    ; No jmp NEXT - we're done!

_start:
    ; Initialize data stack pointer
    mov DSP, stack_top
    
    ; Initialize instruction pointer to our thread
    mov IP, thread
    
    ; Start the interpreter!
    jmp NEXT
    
    ; We never get here - exit_forth terminates the program
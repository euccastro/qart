; step01_stack.asm - Basic stack in memory
; Goal: Allocate stack buffer, push one number, print it

section .data
    ; For printing numbers, we'll convert to ASCII
    buffer: times 20 db 0   ; Buffer for number->string conversion
    newline: db 10          ; Newline character

section .bss
    ; Our data stack - 1024 cells (8KB)
    align 8                 ; Align to 8 bytes for 64-bit values
    stack_base: resq 1024   ; Reserve quadwords (8 bytes each)
    stack_top:              ; Label marks end of stack space

section .text
global _start

_start:
    ; Initialize stack pointer to point to stack_top
    ; Stack grows downward (toward stack_base)
    mov rbp, stack_top      ; rbp will be our stack pointer
    
    ; Push the number 42 onto our stack
    sub rbp, 8              ; Move stack pointer down
    mov qword [rbp], 42     ; Store 42 at stack location
    
    ; Pop the number and print it
    mov rax, [rbp]          ; Load the value
    add rbp, 8              ; Move stack pointer back up
    
    ; Convert number to string for printing
    ; rax contains our number (42)
    mov rdi, buffer + 19    ; Start at end of buffer
    mov byte [rdi], 0       ; Null terminator
    dec rdi
    mov rcx, 10             ; Divisor for decimal conversion
    
.convert_loop:
    xor rdx, rdx            ; Clear rdx for division
    div rcx                 ; Divide rax by 10
    add dl, '0'             ; Convert remainder to ASCII
    mov [rdi], dl           ; Store digit
    dec rdi                 ; Move back in buffer
    test rax, rax           ; Check if quotient is 0
    jnz .convert_loop       ; If not, continue
    
    inc rdi                 ; Point to first digit
    
    ; Calculate string length
    mov rsi, rdi            ; String start
    mov rdx, buffer + 19    
    sub rdx, rdi            ; Length = end - start
    
    ; Write the number
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    syscall
    
    ; Write newline
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, newline
    mov rdx, 1
    syscall
    
    ; Exit
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; exit code 0
    syscall
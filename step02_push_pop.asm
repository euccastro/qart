; step02_push_pop.asm - Push and Pop subroutines
; Goal: Create reusable PUSH/POP functions, test with multiple values

section .data
    buffer: times 20 db 0
    newline: db 10
    space: db ' '

section .bss
    align 8
    stack_base: resq 1024
    stack_top:

section .text
global _start

; PUSH subroutine - pushes RAX onto our data stack
; Input: RAX = value to push
; Modifies: RBP (stack pointer)
push_value:
    sub rbp, 8              ; Move stack pointer down
    mov [rbp], rax          ; Store value
    ret

; POP subroutine - pops value from data stack into RAX
; Output: RAX = popped value
; Modifies: RBP (stack pointer)
pop_value:
    mov rax, [rbp]          ; Load value
    add rbp, 8              ; Move stack pointer up
    ret

; Print number in RAX
print_number:
    push rdi                ; Save registers we'll use
    push rsi
    push rdx
    push rcx
    
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
    mov rsi, rdi            ; String start
    mov rdx, buffer + 19
    sub rdx, rdi            ; Length
    mov rdi, 1              ; stdout
    syscall
    
    pop rcx                 ; Restore registers
    pop rdx
    pop rsi
    pop rdi
    ret

_start:
    ; Initialize stack pointer
    mov rbp, stack_top
    
    ; Push 3
    mov rax, 3
    call push_value
    
    ; Push 4
    mov rax, 4
    call push_value
    
    ; Pop first value (4) and print
    call pop_value
    call print_number
    
    ; Print space
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, space
    mov rdx, 1
    syscall
    
    ; Pop second value (3) and print
    call pop_value
    call print_number
    
    ; Print newline
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, newline
    mov rdx, 1
    syscall
    
    ; Exit
    mov rax, 60             ; sys_exit
    xor rdi, rdi
    syscall
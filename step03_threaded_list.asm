; step03_threaded_list.asm - Threaded list without interpreter
; Goal: Create array of addresses, manually walk and CALL each

section .data
    buffer: times 20 db 0
    newline: db 10
    
    ; Our "threaded code" - an array of addresses
    ; Each address points to a subroutine to call
    align 8
    thread:
        dq push_three       ; Address of push_three
        dq push_four        ; Address of push_four
        dq print_top        ; Address of print_top (prints without popping)
        dq swap_top_two     ; Address of swap_top_two
        dq print_top        ; Print again to see swap effect
        dq 0                ; Null terminator

section .bss
    align 8
    stack_base: resq 1024
    stack_top:

section .text
global _start

; Push 3 onto stack
push_three:
    sub rbp, 8
    mov qword [rbp], 3
    ret

; Push 4 onto stack
push_four:
    sub rbp, 8
    mov qword [rbp], 4
    ret

; Print top of stack without popping
print_top:
    push rax            ; Save registers
    push rdi
    push rsi
    push rdx
    push rcx
    
    mov rax, [rbp]      ; Get top value (don't pop)
    
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
    mov rax, 1          ; sys_write
    mov rsi, rdi        ; String start
    mov rdx, buffer + 19
    sub rdx, rdi        ; Length
    mov rdi, 1          ; stdout
    syscall
    
    ; Print newline
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    pop rcx             ; Restore registers
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Swap top two stack items
swap_top_two:
    mov rax, [rbp]      ; Get top
    mov rdx, [rbp + 8]  ; Get second
    mov [rbp], rdx      ; Put second on top
    mov [rbp + 8], rax  ; Put top in second
    ret

_start:
    ; Initialize stack pointer
    mov rbp, stack_top
    
    ; Walk through our thread manually
    ; RBX will point to current position in thread
    mov rbx, thread
    
.thread_loop:
    mov rax, [rbx]      ; Load address from thread
    test rax, rax       ; Check if null (end marker)
    jz .done            ; If null, we're done
    
    call rax            ; Call the subroutine
    add rbx, 8          ; Move to next address in thread
    jmp .thread_loop    ; Continue
    
.done:
    ; Exit
    mov rax, 60         ; sys_exit
    xor rdi, rdi
    syscall
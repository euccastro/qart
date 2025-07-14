; step04_lit_primitive.asm - Introduce LIT for inline data
; Goal: Mix code addresses and data in the thread

section .data
    buffer: times 20 db 0
    newline: db 10
    space: db ' '
    
    ; Our thread now mixes addresses (code) and values (data)
    ; LIT reads the next cell as data and pushes it
    align 8
    thread:
        dq lit              ; LIT will read next value
        dq 42               ; This is data, not an address!
        dq lit              ; Another LIT
        dq 17               ; More data
        dq add_top_two      ; Add them together
        dq print_pop        ; Print result
        dq 0                ; End marker

section .bss
    align 8
    stack_base: resq 1024
    stack_top:

section .text
global _start

; LIT - Push the next cell in thread as a literal value
; This is special: it needs to know where we are in the thread!
lit:
    ; RBX points to current position in thread (the LIT address)
    ; We need to:
    ; 1. Skip past LIT to get the data
    add rbx, 8          ; Move to next cell (the literal value)
    mov rax, [rbx]      ; Load the literal value
    
    ; 2. Push it on stack
    sub rbp, 8
    mov [rbp], rax
    
    ; Note: main loop will add 8 to RBX again, so we'll skip the data
    ret

; Add top two stack values
add_top_two:
    mov rax, [rbp]      ; Get top
    add rax, [rbp + 8]  ; Add second
    add rbp, 8          ; Drop top
    mov [rbp], rax      ; Replace new top with sum
    ret

; Pop and print a number
print_pop:
    push rdi            ; Save registers
    push rsi
    push rdx
    push rcx
    
    mov rax, [rbp]      ; Get value
    add rbp, 8          ; Pop it
    
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
    mov rsi, rdi
    mov rdx, buffer + 19
    sub rdx, rdi
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
    ret

_start:
    ; Initialize stack pointer
    mov rbp, stack_top
    
    ; Walk through thread - RBX is our "instruction pointer"
    mov rbx, thread
    
.thread_loop:
    mov rax, [rbx]      ; Load from thread
    test rax, rax       ; Check if null
    jz .done
    
    ; Here's the key: RBX tells primitives where we are!
    call rax            ; Call the primitive
    add rbx, 8          ; Move to next position
    jmp .thread_loop
    
.done:
    ; Exit
    mov rax, 60
    xor rdi, rdi
    syscall
; Hello World in x86_64 assembly using NASM (Intel syntax)
; Build: nasm -f elf64 hello_nasm.asm && ld hello_nasm.o -o hello_nasm

section .data
    msg db "Hello, World!", 0x0a    ; message with newline
    len equ $ - msg                  ; calculate message length

section .text
    global _start

_start:
    ; write(1, msg, len)
    mov rax, 1          ; syscall number for write
    mov rdi, 1          ; file descriptor 1 (stdout)
    mov rsi, msg        ; address of message
    mov rdx, len        ; message length
    syscall

    ; exit(0)
    mov rax, 60         ; syscall number for exit
    xor rdi, rdi        ; exit code 0
    syscall
; qart.asm - A Forth-like language implementation in x86_64 assembly
; Starting from basic ITC interpreter, building toward advanced features

%define IP rbx              ; Instruction Pointer
%define DSP r15             ; Data Stack Pointer  
%define RSTACK r14          ; Return Stack Pointer

section .data
    buffer: times 20 db 0
    newline: db 10
    
    ; Test variables for memory access
    test_var: dq 0              ; 64-bit test variable
    test_byte: db 0             ; Byte test variable
    
    ; Test strings for FIND
    test_dup: db "DUP"
    test_dup_len equ 3
    test_plus: db "+"
    test_plus_len equ 1
    test_bad: db "BADWORD"
    test_bad_len equ 7
    
    ; Dictionary structure
    ; Format per entry:
    ;   +0: Link to previous word (8 bytes)
    ;   +8: Length (1 byte) + Name (up to 7 bytes) = 8 bytes total
    ;  +16: Code field address (8 bytes)
    
    align 8
    ; Start with last word and work backwards
dict_EXIT:
    dq 0                        ; Link (null - last word in dictionary)
    db 4, "EXIT", 0, 0, 0       ; Length + name (padded to 8)
    dq EXIT                     ; Code field

dict_DOT:
    dq dict_EXIT
    db 1, ".", 0, 0, 0, 0, 0, 0
    dq DOT

dict_C_STORE:
    dq dict_DOT
    db 2, "C!", 0, 0, 0, 0, 0
    dq C_STORE

dict_C_FETCH:
    dq dict_C_STORE
    db 2, "C@", 0, 0, 0, 0, 0
    dq C_FETCH

dict_STORE:
    dq dict_C_FETCH
    db 1, "!", 0, 0, 0, 0, 0, 0
    dq STORE

dict_FETCH:
    dq dict_STORE
    db 1, "@", 0, 0, 0, 0, 0, 0
    dq FETCH

dict_R_FETCH:
    dq dict_FETCH
    db 2, "R@", 0, 0, 0, 0, 0
    dq R_FETCH

dict_R_FROM:
    dq dict_R_FETCH
    db 2, "R>", 0, 0, 0, 0, 0
    dq R_FROM

dict_TO_R:
    dq dict_R_FROM
    db 2, ">R", 0, 0, 0, 0, 0
    dq TO_R

dict_ADD:
    dq dict_TO_R
    db 1, "+", 0, 0, 0, 0, 0, 0
    dq ADD

dict_DROP:
    dq dict_ADD
    db 4, "DROP", 0, 0, 0
    dq DROP

dict_DUP:
    dq dict_DROP
    db 3, "DUP", 0, 0, 0, 0
    dq DUP

dict_LIT:
    dq dict_DUP
    db 3, "LIT", 0, 0, 0, 0
    dq LIT

    ; Test colon definition: DOUBLE ( n -- n*2 ) 
    ; Equivalent to : DOUBLE DUP + ;
dict_DOUBLE:
    dq dict_LIT             ; Link to previous
    db 6, "DOUBLE", 0       ; Name
    dq DOCOL                ; Code field points to DOCOL
    ; Body starts here:
    dq dict_DUP             ; DUP
    dq dict_ADD             ; +
    dq dict_EXIT            ; EXIT (;)
    
    ; LATEST points to the most recent word
    LATEST: dq dict_DOUBLE
    
    
    ; Test program: Use dictionary entries throughout
    align 8
    test_program:
        ; Test with primitives first
        dq dict_LIT, 21         ; Push 21
        dq dict_LIT, 21         ; Push 21 
        dq dict_ADD             ; Add them
        dq dict_DOT             ; Print result (should be 42)
        
        ; Now test colon definition
        dq dict_LIT, 10         ; Push 10
        dq dict_DOUBLE          ; Call DOUBLE (should double to 20)
        dq dict_DOT             ; Print result
        
        dq dict_EXIT            ; Done

section .bss
    align 8
    stack_base: resq 1024
    stack_top:
    
    return_stack_base: resq 512   ; Return stack (smaller than data stack)
    return_stack_top:

section .text
global _start

; NEXT - The inner interpreter
; Dictionary-based execution: IP points to dictionary entry addresses
NEXT:
    mov rdx, [IP]           ; Get dictionary entry address
    add IP, 8               ; Advance IP
    mov rax, [rdx+16]       ; Get code field from dict entry (link=8 + name=8)
    jmp rax                 ; Execute the code

; ---- Forth Primitives ----

; DOCOL - Runtime for colon definitions
; Expects RDX = dictionary entry address
; Dictionary structure: link(8) + name(8) + code(8) + body...
DOCOL:
    sub RSTACK, 8           ; Make room on return stack
    mov [RSTACK], IP        ; Save current IP
    lea IP, [rdx+24]        ; IP = start of body (after 24-byte header)
    jmp NEXT                ; Start executing the body

; LIT ( -- n ) Push following cell as literal
LIT:
    mov rax, [IP]           ; Get literal value
    add IP, 8               ; Skip it
    sub DSP, 8              ; Make room
    mov [DSP], rax          ; Push value
    jmp NEXT

; DUP ( n -- n n ) Duplicate top of stack
DUP:
    mov rax, [DSP]          ; Get top
    sub DSP, 8              ; Make room
    mov [DSP], rax          ; Push copy
    jmp NEXT

; DROP ( n -- ) Remove top of stack
DROP:
    add DSP, 8              ; Drop top item
    jmp NEXT

; ADD ( n1 n2 -- n3 ) Add top two stack items
ADD:
    mov rax, [DSP]          ; Get top (n2)
    add DSP, 8              ; Drop it
    add [DSP], rax          ; Add to new top (n1)
    jmp NEXT

; >R ( n -- ) (R: -- n) Move from data stack to return stack
TO_R:
    mov rax, [DSP]          ; Get value from data stack
    add DSP, 8              ; Drop from data stack
    sub RSTACK, 8           ; Make room on return stack
    mov [RSTACK], rax       ; Push to return stack
    jmp NEXT

; R> ( -- n) (R: n -- ) Move from return stack to data stack
R_FROM:
    mov rax, [RSTACK]       ; Get value from return stack
    add RSTACK, 8           ; Drop from return stack
    sub DSP, 8              ; Make room on data stack
    mov [DSP], rax          ; Push to data stack
    jmp NEXT

; R@ ( -- n) (R: n -- n) Copy top of return stack to data stack
R_FETCH:
    mov rax, [RSTACK]       ; Peek at return stack top
    sub DSP, 8              ; Make room on data stack
    mov [DSP], rax          ; Push copy to data stack
    jmp NEXT

; @ ( addr -- n ) Fetch 64-bit value from address
FETCH:
    mov rax, [DSP]          ; Get address
    mov rax, [rax]          ; Fetch value from that address
    mov [DSP], rax          ; Replace address with value
    jmp NEXT

; ! ( n addr -- ) Store 64-bit value to address
STORE:
    mov rax, [DSP]          ; Get address
    add DSP, 8              ; Drop it
    mov rdx, [DSP]          ; Get value
    add DSP, 8              ; Drop it
    mov [rax], rdx          ; Store value at address
    jmp NEXT

; C@ ( addr -- c ) Fetch byte from address
C_FETCH:
    mov rax, [DSP]          ; Get address
    movzx rax, byte [rax]   ; Fetch byte, zero-extended
    mov [DSP], rax          ; Replace address with byte value
    jmp NEXT

; C! ( c addr -- ) Store byte to address
C_STORE:
    mov rax, [DSP]          ; Get address
    add DSP, 8              ; Drop it
    mov dl, [DSP]           ; Get byte value (low 8 bits)
    add DSP, 8              ; Drop it
    mov [rax], dl           ; Store byte at address
    jmp NEXT

; DOT ( n -- ) Pop and print number with trailing space
DOT:
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
    
    jmp NEXT

; NUMBER ( c-addr u -- n ) Parse string as signed integer
NUMBER:
    ; Get parameters (u is on top, c-addr below)
    mov rcx, [DSP]          ; Length (u)
    add DSP, 8              ; Drop it
    mov rsi, [DSP]          ; String pointer (c-addr) - leave on stack for now
    
    xor rax, rax            ; Initialize result
    xor r8, r8              ; Sign flag (0 = positive)
    xor r9, r9              ; Digit counter
    
    ; Check for empty string
    test rcx, rcx
    jz .error
    
    ; Check for negative sign
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
    
    ; Multiply current result by 10 and add digit
    push rdx                ; Save digit
    mov r9, 10
    mul r9                  ; rax = rax * 10, result in rax
    pop rdx                 ; Restore digit
    add rax, rdx            ; Add new digit
    
    inc rsi                 ; Next character
    dec rcx                 ; Decrease count
    jnz .parse_digits
    
    ; Apply sign if negative
    test r8, r8
    jz .done
    neg rax
    
.done:
    mov [DSP], rax          ; Store result over string pointer
    jmp NEXT
    
.error:
    ; For now, just return 0 on error
    xor rax, rax
    jmp .done


; FIND ( c-addr u -- xt 1 | c-addr u 0 ) Look up word in dictionary
; If found: returns execution token and 1
; If not found: returns original string and 0
FIND:
    ; Save string for possible return
    mov rax, [DSP]          ; Length
    push rax
    mov rax, [DSP+8]        ; Address
    push rax
    
    ; Get search parameters
    mov rcx, [DSP]          ; Length in rcx
    mov rsi, [DSP+8]        ; String pointer in rsi
    
    ; Start at LATEST
    mov rdi, [LATEST]
    
.search_loop:
    test rdi, rdi           ; End of dictionary?
    jz .not_found
    
    ; Compare lengths first
    movzx rax, byte [rdi+8] ; Get word's length
    cmp rax, rcx
    jne .next_word
    
    ; Lengths match, compare names
    push rcx
    push rsi
    push rdi
    
    lea rdi, [rdi+9]        ; Point to name in dictionary
    ; rsi already points to search string
    ; rcx already has length
    repe cmpsb              ; Compare strings
    
    pop rdi
    pop rsi
    pop rcx
    
    je .found               ; If equal, we found it
    
.next_word:
    mov rdi, [rdi]          ; Follow link to next word
    jmp .search_loop
    
.found:
    ; Drop saved values
    add rsp, 16
    ; Replace string with xt
    mov rax, [rdi+16]       ; Get code field
    mov [DSP+8], rax        ; Replace c-addr with xt
    mov qword [DSP], 1      ; Replace length with true flag
    jmp NEXT
    
.not_found:
    ; Restore original values
    pop rax
    mov [DSP+8], rax        ; Keep c-addr
    pop rax
    mov [DSP], rax          ; Keep length
    ; Push false flag
    sub DSP, 8
    mov qword [DSP], 0
    jmp NEXT

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

; ---- Main Program ----

_start:
    ; Initialize stacks
    mov DSP, stack_top          ; Data stack grows down
    mov RSTACK, return_stack_top ; Return stack grows down
    
    ; Push 0 to return stack to mark top-level
    sub RSTACK, 8
    mov qword [RSTACK], 0
    
    ; Start interpreting
    mov IP, test_program
    jmp NEXT

; ---- Data that didn't fit in .data section ----
section .data
    minus_sign: db '-'
    space: db ' '
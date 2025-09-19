; dictionary.asm - Dictionary lookup and management

%include "forth.inc"  

section .text

global FIND

extern NEXT
extern LATEST

; FIND ( c-addr u -- xt -1 | c-addr u 0 ) Look up word in dictionary
; If found: returns execution token and -1 (true)
; If not found: returns original string and 0 (false)
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
    mov rax, [rdi+8]        ; Get descriptor pointer
    movzx rbx, byte [rax]   ; Get word's length from descriptor
    and rbx, NAME_LENGTH_MASK ; Mask off immediate and compile-only bits
    cmp rbx, rcx
    jne .next_word

    ; Lengths match, compare names
    push rcx
    push rsi
    push rdi

    lea rdi, [rax+1]        ; Point to name in descriptor (descriptor+1)
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
    ; Replace string with xt (dictionary pointer)
    mov [DSP+8], rdi        ; Replace c-addr with dict pointer
    mov qword [DSP], -1     ; Replace length with true flag (-1 for standard Forth)
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
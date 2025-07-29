; word.asm - Word parsing primitive

%include "forth.inc"

section .text
global PARSE_WORD

extern input_buffer
extern input_length
extern input_position
extern line_number
extern line_start_position
extern NEXT

; PARSE_WORD ( -- addr length )
; Parse next space-delimited word from input buffer
; Returns address and length on stack (0 0 if no more words)
PARSE_WORD:
    ; Get current position and length
    mov rsi, [input_position]   ; Current position
    mov rcx, [input_length]     ; Total length
    
    ; Check if we're at end
    cmp rsi, rcx
    jge .no_more_words
    
    ; Skip leading spaces and newlines
    mov rdi, input_buffer
    add rdi, rsi                ; Point to current position
.skip_spaces:
    cmp rsi, rcx
    jge .no_more_words
    mov al, [rdi]
    cmp al, ' '
    je .skip_this_char
    cmp al, NEWLINE         ; Also skip newlines
    jne .found_word_start
    ; Found newline - update line tracking
    inc qword [line_number]
    mov [line_start_position], rsi
    inc qword [line_start_position]  ; Line starts after the newline
.skip_this_char:
    inc rsi
    inc rdi
    jmp .skip_spaces
    
.found_word_start:
    ; Save start position
    mov rdx, rsi                ; Start of word
    mov r8, rdi                 ; Start address
    
    ; Find end of word (next space or newline or end of buffer)
.find_word_end:
    cmp rsi, rcx
    jge .found_word_end
    mov al, [rdi]
    cmp al, ' '
    je .found_word_end
    cmp al, NEWLINE         ; Also treat newline as whitespace
    je .found_word_end
    inc rsi
    inc rdi
    jmp .find_word_end
    
.found_word_end:
    ; Update position for next call
    mov [input_position], rsi
    
    ; Calculate word length
    mov rax, rsi
    sub rax, rdx                ; Length = end - start
    
    ; Push address and length
    sub DSP, 8
    mov qword [DSP], r8         ; Address (start of word in input_buffer)
    sub DSP, 8
    mov qword [DSP], rax        ; Length
    jmp NEXT
    
.no_more_words:
    ; Push 0 0 for no more words
    sub DSP, 8
    mov qword [DSP], 0          ; Address = 0
    sub DSP, 8
    mov qword [DSP], 0          ; Length = 0
    jmp NEXT

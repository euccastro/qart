; input_buffer.asm - Input buffer management and word parsing primitives
; Combines functionality from input.asm and word.asm

%include "forth.inc"

section .text
global REFILL
global BACKSLASH
global PARSE_WORD
global SCAN_CHAR
global SOURCE_FETCH

extern input_buffer
extern input_length
extern input_position
extern line_number
extern line_start_position
extern NEXT

; REFILL ( -- flag )
; Read a line of input into the input buffer
; Returns -1 (true) on success, 0 (false) on EOF
REFILL:
    ; Reset position to start of buffer
    mov qword [input_position], 0
    ; Reset line tracking
    mov qword [line_number], 1
    mov qword [line_start_position], 0
    
    ; Read from stdin (fd=0) into input_buffer
    mov rax, 0                  ; sys_read
    mov rdi, 0                  ; stdin
    mov rsi, input_buffer       ; buffer
    mov rdx, INPUT_BUFFER_SIZE
    syscall
    
    sub DSP, 8
    ; Check for error or EOF
    cmp rax, 0
    jle .eof
    
    ; Store actual length read
    mov [input_length], rax
    
    ; Push true (-1) for success
    mov qword [DSP], -1
    jmp NEXT
    
.eof:
    mov qword [DSP], 0
    jmp NEXT

; BACKSLASH ( -- )
; Skip to end of current line (rest-of-line comment)
BACKSLASH:
    ; Get current position and length
    mov rsi, [input_position]   ; Current position
    mov rcx, [input_length]     ; Total length
    
    ; Check if we're already at end
    cmp rsi, rcx
    jge .done
    
    ; Search for newline
    mov rdi, input_buffer
    add rdi, rsi                ; Point to current position
    
.find_newline:
    cmp rsi, rcx
    jge .at_end
    mov al, [rdi]
    cmp al, NEWLINE
    je .found_newline
    inc rsi
    inc rdi
    jmp .find_newline
    
.found_newline:
    ; Update line tracking
    inc qword [line_number]
    ; Skip past the newline
    inc rsi
    mov [line_start_position], rsi  ; Line starts after the newline
    
.at_end:
    ; Update position
    mov [input_position], rsi
    
.done:
    jmp NEXT

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

; SOURCE@ ( -- addr )
; Push address of current position in input buffer
SOURCE_FETCH:
    ; Calculate current position address
    mov rax, input_buffer
    add rax, [input_position]
    
    ; Push address onto stack
    sub DSP, 8
    mov [DSP], rax
    jmp NEXT

; SCAN_CHAR ( char -- n )
; Search for character in input buffer starting from current position
; If found: advance input_position to that character and return distance
; If not found: leave input_position unchanged and return -1
SCAN_CHAR:
    ; Get character to search for
    mov rax, [DSP]          ; Get the value from stack
    add DSP, 8              ; Pop the stack
    ; Character is in AL (low byte of RAX)
    
    ; Get current position and length
    mov rsi, [input_position]   ; Current position
    mov rcx, [input_length]     ; Total length
    
    ; Save starting position
    mov rdx, rsi                ; Save original position
    
    ; Set up pointer to current position
    mov rdi, input_buffer
    add rdi, rsi                ; Point to current position
    
.search_loop:
    cmp rsi, rcx
    jge .not_found              ; Reached end without finding
    
    cmp byte [rdi], al          ; Compare with target character
    je .found                   ; Found it!
    
    inc rsi                     ; Advance position
    inc rdi                     ; Advance pointer
    jmp .search_loop
    
.found:
    ; Calculate distance (found position - original position)
    ; Note: distance is to the character, not past it
    sub rsi, rdx
    sub DSP, 8              ; Make room on stack
    mov [DSP], rsi          ; Return distance

    ; Update input_position to AFTER found character
    inc rsi                 ; Move past the found character
    mov [input_position], rsi
    jmp NEXT
    
.not_found:
    ; Leave input_position unchanged (it's still at rdx value)
    ; Return -1
    sub DSP, 8              ; Make room on stack
    mov qword [DSP], -1
    jmp NEXT

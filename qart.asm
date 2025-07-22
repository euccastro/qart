  ;; qart.asm - Main file for Forth-like language implementation
  ;; Includes all the other modules and contains data section and entry point

  %include "forth.inc"

  ;; Macro for calculating branch offsets
  ;; Usage: BRANCH_OFFSET(target_label) or JUMP_TO(target_label)
  %define BRANCH_OFFSET(target) (((target - $) // 8) - 2)

  section .data
  align 8
buffer: times 20 db 0
newline: db NEWLINE
  
  ;; Input tracking variables
  align 8
input_length: dq 0                          ; Number of chars in buffer
input_position: dq 0                        ; Current parse position
line_number: dq 1                           ; Current line number (1-based)
line_start_position: dq 0                   ; Position where current line started

  ;; Compiler state
  align 8
STATE: dq 0                                  ; 0 = interpret, non-zero = compile

  ;; Output stream control
  align 8
OUTPUT: dq 1                                 ; 1 = stdout, 2 = stderr

  ;; Debug and behavior flags (bit 0 = verbose ASSERT)
  align 8
FLAGS: dq 0                                  ; Bit flags for various behaviors
HERE:  dq dict_space
  
  
bye_msg: db "bye."
  bye_msg_len equ 4
  
  ;; Dictionary structure
  ;; Format per entry:
  ;;   +0: Link to previous word (8 bytes)
  ;;   +8: Length (1 byte) + Name (up to 7 bytes) = 8 bytes total
  ;;  +16: Code field address (8 bytes)
  
  align 8
  ;; Start with last word and work backwards
dict_EXIT:
  dq 0                        ; Link (null - last word in dictionary)
  db 4, "EXIT", 0, 0, 0       ; Length + name (padded to 8)
  dq EXIT                     ; Code field

dict_DOT:
  dq dict_EXIT
  db 1, ".", 0, 0, 0, 0, 0, 0
  dq DOT

dict_EMIT:
  dq dict_DOT
  db 4, "EMIT", 0, 0, 0
  dq EMIT

dict_KEY:
  dq dict_EMIT
  db 3, "KEY", 0, 0, 0, 0
  dq KEY

dict_C_STORE:
  dq dict_KEY
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

dict_SUB:
  dq dict_ADD
  db 1, "-", 0, 0, 0, 0, 0, 0
  dq SUB

dict_ZEROEQ:
  dq dict_SUB
  db 2, "0=", 0, 0, 0, 0, 0
  dq ZEROEQ

dict_EQUAL:
  dq dict_ZEROEQ
  db 1, "=", 0, 0, 0, 0, 0, 0
  dq EQUAL

dict_AND:
  dq dict_EQUAL
  db 3, "AND", 0, 0, 0, 0
  dq AND

dict_DROP:
  dq dict_AND
  db 4, "DROP", 0, 0, 0
  dq DROP

dict_SWAP:
  dq dict_DROP
  db 4, "SWAP", 0, 0, 0
  dq SWAP

dict_TWO_DUP:
  dq dict_SWAP
  db 4, "2DUP", 0, 0, 0
  dq TWO_DUP

dict_TWO_DROP:
  dq dict_TWO_DUP
  db 5, "2DROP", 0, 0
  dq TWO_DROP

dict_OVER:
  dq dict_TWO_DROP
  db 4, "OVER", 0, 0, 0
  dq OVER

dict_DUP:
  dq dict_OVER
  db 3, "DUP", 0, 0, 0, 0
  dq DUP

dict_SP_FETCH:
  dq dict_DUP
  db 3, "SP@", 0, 0, 0, 0
  dq SP_FETCH

dict_LIT:
  dq dict_SP_FETCH
  db 3, "LIT", 0, 0, 0, 0
  dq LIT

  ;; Test colon definition: DOUBLE ( n -- n*2 ) 
  ;; Equivalent to : DOUBLE DUP + ;
dict_DOUBLE:
  dq dict_LIT             ; Link to previous
  db 6, "DOUBLE", 0       ; Name
  dq DOCOL                ; Code field points to DOCOL
  ;; Body starts here:
  dq dict_DUP             ; DUP
  dq dict_ADD             ; +
  dq dict_EXIT            ; EXIT (;)

dict_EXECUTE:
  dq dict_DOUBLE          ; Link to previous
  db 7, "EXECUTE"         ; Name (7 chars exactly)
  dq EXECUTE              ; Code field

dict_BRANCH:
  dq dict_EXECUTE
  db 6, "BRANCH", 0
  dq BRANCH

dict_ZBRANCH:
  dq dict_BRANCH
  db 7, "0BRANCH"
  dq ZBRANCH

dict_REFILL:
  dq dict_ZBRANCH         ; Link to previous
  db 6, "REFILL", 0       ; Name
  dq REFILL               ; Code field

dict_WORD:
  dq dict_REFILL          ; Link to previous
  db 4, "WORD", 0, 0, 0   ; Name
  dq PARSE_WORD           ; Code field

dict_BACKSLASH:
  dq dict_WORD            ; Link to previous
  db 1, 92, 0, 0, 0, 0, 0, 0 ; Name (ASCII code not to confuse emacs)
  dq BACKSLASH            ; Code field

dict_LINE_NUMBER_FETCH:
  dq dict_BACKSLASH       ; Link to previous
  db 5, "LINE#", 0, 0    ; Name
  dq LINE_NUMBER_FETCH   ; Code field

dict_COLUMN_NUMBER_FETCH:
  dq dict_LINE_NUMBER_FETCH ; Link to previous
  db 4, "COL#", 0, 0, 0  ; Name
  dq COLUMN_NUMBER_FETCH ; Code field

dict_FIND:
  dq dict_COLUMN_NUMBER_FETCH
  db 4, "FIND", 0, 0, 0
  dq FIND

dict_NUMBER:
  dq dict_FIND
  db 6, "NUMBER", 0
  dq NUMBER

dict_TYPE:
  dq dict_NUMBER
  db 4, "TYPE", 0, 0, 0
  dq TYPE

  ;; ERRTYPE ( c-addr u -- ) Output string to stderr
dict_ERRTYPE:
  dq dict_TYPE
  db 7, "ERRTYPE"
  dq DOCOL                ; Colon definition
  ;; Save current OUTPUT
  dq dict_OUTPUT          ; ( c-addr u OUTPUT )
  dq dict_FETCH           ; ( c-addr u old-output )
  dq dict_TO_R            ; ( c-addr u ) (R: old-output)
  ;; Set OUTPUT to stderr
  dq dict_LIT
  dq 2                    ; ( c-addr u 2 )
  dq dict_OUTPUT          ; ( c-addr u 2 OUTPUT )
  dq dict_STORE           ; ( c-addr u )
  ;; Output the string
  dq dict_TYPE            ; ( )
  ;; Restore OUTPUT
  dq dict_R_FROM          ; ( old-output )
  dq dict_OUTPUT          ; ( old-output OUTPUT )
  dq dict_STORE           ; ( )
  dq dict_EXIT

  ;; CR ( -- ) Output newline to stdout
  align 8
dict_CR:
  dq dict_ERRTYPE         ; Link to previous
  db 2, "CR", 0, 0, 0, 0, 0 ; Name must be exactly 8 bytes
  dq DOCOL                ; Colon definition
  ;; Body starts here at offset 24
  dq dict_LIT, NEWLINE    ; Push newline character
  dq dict_EMIT            ; Output it
  dq dict_EXIT

  ;; ERRCR ( -- ) Output newline to stderr  
dict_ERRCR:
  dq dict_CR              ; Link to previous
  db 5, "ERRCR", 0, 0
  dq DOCOL                ; Colon definition
  ;; Save current OUTPUT
  dq dict_OUTPUT          ; ( OUTPUT )
  dq dict_FETCH           ; ( old-output )
  dq dict_TO_R            ; ( ) (R: old-output)
  ;; Set OUTPUT to stderr
  dq dict_LIT
  dq 2                    ; ( 2 )
  dq dict_OUTPUT          ; ( 2 OUTPUT )
  dq dict_STORE           ; ( )
  ;; Output newline
  dq dict_CR              ; ( )
  ;; Restore OUTPUT
  dq dict_R_FROM          ; ( old-output )
  dq dict_OUTPUT          ; ( old-output OUTPUT )
  dq dict_STORE           ; ( )
  dq dict_EXIT

  ;; Error message for unknown word
unknown_word_msg: db "Unknown word: "
  unknown_word_msg_len equ 14

  ;; INTERPRET ( -- ) Process words from input buffer
  align 8
dict_INTERPRET:
  dq dict_ERRCR           ; Link to previous
  db 7, "INTERPR"
  dq DOCOL                ; Colon definition
  .loop:
  ;; Get next word
  dq dict_WORD            ; ( -- c-addr u )
  dq dict_DUP             ; ( c-addr u u )
  dq dict_ZBRANCH, BRANCH_OFFSET(.done)

  ;; Try to find in dictionary
  dq dict_FIND            ; ( xt 1 | c-addr u 0 )
  dq dict_ZBRANCH, BRANCH_OFFSET(.try_number)       ; If not found, skip to .try_number
  
  ;; Found - execute it
  dq dict_EXECUTE         ; Execute the word
  dq dict_BRANCH, BRANCH_OFFSET(.loop)

  .try_number:
  ;; Not in dictionary, try NUMBER
  dq dict_NUMBER          ; ( n 1 | c-addr u 0 )
  dq dict_ZEROEQ
  dq dict_ZBRANCH, BRANCH_OFFSET(.loop)      ; If not failed, number is in stack
  ;; Unknown word - print error
  dq dict_LIT, unknown_word_msg
  dq dict_LIT, unknown_word_msg_len
  dq dict_ERRTYPE         ; Print "Unknown word: "
  dq dict_ERRTYPE         ; Print the word itself
  dq dict_ERRCR           ; Print newline
  dq dict_EXIT
  
  .done:
  dq dict_TWO_DROP
  dq dict_EXIT

  ;; Error message for unknown word
missing_word_msg: db "Expected word, got EOF."
  missing_word_msg_len equ 23

  align 8
dict_TICK:
  dq dict_INTERPRET
  db 1, "'", 0, 0, 0, 0, 0, 0
  dq DOCOL                ; Colon definition
  dq dict_WORD            ; ( -- c-addr u )
  dq dict_DUP
  dq dict_ZBRANCH, BRANCH_OFFSET(.missing_word)
  dq dict_FIND            ; ( xt -1 | c-addr u 0 )
  dq dict_ZBRANCH, BRANCH_OFFSET(.unknown_word)
  dq dict_EXIT
  .missing_word:
  dq dict_LIT, missing_word_msg
  dq dict_LIT, missing_word_msg_len
  dq dict_BRANCH, BRANCH_OFFSET(.print_and_abort)
  .unknown_word:
  dq dict_LIT, unknown_word_msg
  dq dict_LIT, unknown_word_msg_len
  dq dict_ERRTYPE         ; Print "Unknown word: "
  .print_and_abort:
  dq dict_ERRTYPE         ; Print the word itself
  dq dict_ERRCR           ; Print newline
  dq dict_ABORT

  ;; STATE ( -- addr ) Push address of STATE variable
dict_STATE:
  dq dict_TICK       ; Link to previous
  db 5, "STATE", 0, 0     ; Name
  dq STATE_word           ; Code field

  ;; ASSERT ( flag -- ) Check assertion, print FAIL: line:col if false
dict_ASSERT:
  dq dict_STATE           ; Link to previous
  db 6, "ASSERT", 0       ; Name
  dq DOCOL                ; Colon definition
  ;; Check if assertion failed
  dq dict_ZBRANCH, BRANCH_OFFSET(.fail)
  ;; Passed - check if verbose mode
  dq dict_FLAGS           ; ( FLAGS )
  dq dict_FETCH           ; ( flags-value )
  dq dict_LIT, 1          ; ( flags-value 1 )
  dq dict_AND             ; ( flags&1 )
  dq dict_ZBRANCH, BRANCH_OFFSET(.done)
  ;; Verbose mode - push PASS message
  dq dict_LIT, pass_msg   ; ( pass_msg )
  dq dict_LIT, pass_msg_len ; ( pass_msg 6 )
  dq dict_BRANCH, BRANCH_OFFSET(.print)
  .fail:
  ;; Failed - push FAIL message
  dq dict_LIT, fail_msg   ; ( fail_msg )
  dq dict_LIT, fail_msg_len ; ( fail_msg 6 )
  .print:
  ;; Common print path - save OUTPUT and set to stderr
  dq dict_OUTPUT          ; ( msg len OUTPUT )
  dq dict_FETCH           ; ( msg len old-output )
  dq dict_TO_R            ; ( msg len ) (R: old-output)
  dq dict_LIT, 2          ; ( msg len 2 )
  dq dict_OUTPUT          ; ( msg len 2 OUTPUT )
  dq dict_STORE           ; ( msg len )
  ;; Print the message
  dq dict_TYPE            ; ( )
  ;; Print line:col
  dq dict_LINE_NUMBER_FETCH ; ( line )
  dq dict_DOT             ; ( ) - prints line to stderr
  dq dict_LIT, ':' ; ( ':' )
  dq dict_EMIT            ; ( )
  dq dict_COLUMN_NUMBER_FETCH ; ( col )
  dq dict_DOT             ; ( ) - prints col to stderr
  dq dict_CR              ; Print newline
  ;; Restore OUTPUT
  dq dict_R_FROM          ; ( old-output )
  dq dict_OUTPUT          ; ( old-output OUTPUT )
  dq dict_STORE           ; ( )
  .done:
  dq dict_EXIT

  ;; OUTPUT ( -- addr ) Push address of OUTPUT variable
dict_OUTPUT:
  dq dict_ASSERT          ; Link to previous
  db 6, "OUTPUT", 0       ; Name
  dq OUTPUT_word          ; Code field

  ;; FLAGS ( -- addr ) Push address of FLAGS variable
dict_FLAGS:
  dq dict_OUTPUT          ; Link to previous
  db 5, "FLAGS", 0, 0     ; Name
  dq FLAGS_word           ; Code field

  ;; HERE ( -- addr ) Push address of HERE variable
dict_HERE:
  dq dict_FLAGS          ; Link to previous
  db 4, "HERE", 0, 0, 0     ; Name
  dq HERE_word           ; Code field

  ;; QUIT ( -- ) Main interpreter loop
  align 8
dict_QUIT:
  dq dict_HERE           ; Link to previous
  db 4, "QUIT", 0, 0, 0   ; Name
  dq DOCOL                ; Colon definition
  .loop:
  dq dict_LIT, '>'
  dq dict_EMIT
  dq dict_LIT, ' '
  dq dict_EMIT
  dq dict_REFILL
  dq dict_ZBRANCH, BRANCH_OFFSET(.bye)
  dq dict_INTERPRET
  dq dict_CR
  dq dict_BRANCH, BRANCH_OFFSET(.loop)
  .bye:
  dq dict_CR
  dq dict_LIT, bye_msg
  dq dict_LIT, bye_msg_len
  dq dict_TYPE
  dq dict_CR
  dq dict_EXIT

  ;; ABORT ( -- ) Clear stacks and jump to QUIT
  align 8
dict_ABORT:
  dq dict_QUIT            ; Link to previous
  db 5, "ABORT", 0, 0     ; Name
  dq ABORT_word           ; Code field (primitive)

  ;; SHOWWORDS ( -- ) Debug word parsing by showing each word as bytes
dict_SHOWWORDS:
  dq dict_ABORT           ; Link to previous
  db 5, "SHOWW", 0, 0
  dq DOCOL                ; Colon definition
  .loop:
  ;; Get next word
  dq dict_WORD            ; ( -- c-addr u )
  dq dict_DUP             ; ( c-addr u u )
  dq dict_ZBRANCH, BRANCH_OFFSET(.done)
  
  ;; For each character in the word
  .byte_loop:
  dq dict_DUP             ; ( c-addr u u )
  dq dict_ZBRANCH, BRANCH_OFFSET(.end_word)
  
  ;; Print one byte
  dq dict_OVER            ; ( c-addr count c-addr )
  dq dict_C_FETCH         ; ( c-addr count byte )
  dq dict_DOT             ; ( c-addr count )
  dq dict_LIT, ' '
  dq dict_EMIT
  
  ;; Next byte
  dq dict_SWAP            ; ( count c-addr )
  dq dict_LIT, 1
  dq dict_ADD             ; ( count c-addr+1 )
  dq dict_SWAP            ; ( c-addr+1 count )
  dq dict_LIT, -1
  dq dict_ADD
  dq dict_BRANCH, BRANCH_OFFSET(.byte_loop)
  
  .end_word:
  ;; Clean up
  dq dict_TWO_DROP        ; ( c-addr u )
  dq dict_LIT, '.'
  dq dict_EMIT
  dq dict_LIT, ' '
  dq dict_EMIT            ; Double space
  dq dict_BRANCH, BRANCH_OFFSET(.loop)
  
  .done:
  dq dict_TWO_DROP
  dq dict_CR
  dq dict_EXIT

dict_COMMA:
  dq dict_SHOWWORDS
  db 1, ",", 0, 0, 0, 0, 0, 0
  dq COMMA

  ;; LATEST points to the most recent word
LATEST: dq dict_COMMA
  
  align 8


minus_sign: db '-'
space: db ' '
fail_msg: db "FAIL: "
fail_msg_len equ 6
pass_msg: db "PASS: "
pass_msg_len equ 6

  section .bss
  align 8
dict_space: resq 65536
stack_base: resq 1024
stack_top:
  
return_stack_base: resq 512   ; Return stack (smaller than data stack)
return_stack_top:

input_buffer: resb INPUT_BUFFER_SIZE  ; Input line buffer

  section .text
  global _start
  global buffer
  global minus_sign
  global space
  global LATEST
  global input_buffer
  global input_length
  global input_position
  global line_number
  global line_start_position
  global STATE
  global OUTPUT
  global FLAGS
  global stack_top
  global return_stack_top
  global dict_QUIT
  global HERE

  ;; Import all the primitives from other files
  extern NEXT
  extern DOCOL
  extern EXIT
  extern EXECUTE
  extern BRANCH
  extern ZBRANCH
  extern LIT
  extern DUP
  extern DROP
  extern OVER
  extern SWAP
  extern SP_FETCH
  extern TWO_DUP
  extern TWO_DROP
  extern ADD
  extern SUB
  extern ZEROEQ
  extern EQUAL
  extern AND
  extern TO_R
  extern R_FROM
  extern R_FETCH
  extern FETCH
  extern STORE
  extern C_FETCH
  extern C_STORE
  extern DOT
  extern EMIT
  extern KEY
  extern NUMBER
  extern FIND
  extern REFILL
  extern PARSE_WORD
  extern BACKSLASH
  extern LINE_NUMBER_FETCH
  extern COLUMN_NUMBER_FETCH
  extern TYPE
  extern STATE_word
  extern OUTPUT_word
  extern FLAGS_word
  extern HERE_word
  extern ABORT_word
  extern COMMA

  ;; ---- Main Program ----

_start:
  ;; Initialize stacks
  mov DSP, stack_top          ; Data stack grows down
  mov RSTACK, return_stack_top ; Return stack grows down
  
  ;; Push 0 to return stack to mark top-level
  sub RSTACK, 8
  mov qword [RSTACK], 0
  
  ;; Call ABORT to start the system
  ;; ABORT will clear stacks and jump to QUIT
  jmp ABORT_word

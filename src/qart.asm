  ;; qart.asm - Main file for Forth-like language implementation
  ;; Includes all the other modules and contains data section and entry point

  %include "forth.inc"

  section .data

  ;; Main thread descriptor
  ;; This is what TLS (R13) points to for the main thread
  align 8
main_thread_descriptor:
  dq 2                      ; +0: flags (STATE=0, OUTPUT=1 (stdout), DEBUG=0)
  dq data_stack_base        ; +8: data stack base address
  dq return_stack_base      ; +16: return stack base address
  extern SYSEXIT
  dq SYSEXIT              ; +24: cleanup function (exits entire process)
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

  ;; Legacy FLAGS variable - for backwards compatibility only
  ;; This is effectively the main thread's TLS->flags
  ;; See memory.asm for the bit layout (same as thread-local flags)
  align 8
FLAGS: dq 0                                  ; Legacy - use thread-local flags instead
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
EXIT:
  dq IMPL_EXIT

dict_DOT:
  dq dict_EXIT
  db 1, ".", 0, 0, 0, 0, 0, 0
DOT:                      ; Execution token points here
  dq IMPL_DOT

dict_EMIT:
  dq dict_DOT
  db 4, "EMIT", 0, 0, 0
EMIT:                     ; Execution token points here
  dq IMPL_EMIT

dict_KEY:
  dq dict_EMIT
  db 3, "KEY", 0, 0, 0, 0
KEY:                      ; Execution token points here
  dq IMPL_KEY

dict_C_STORE:
  dq dict_KEY
  db 2, "C!", 0, 0, 0, 0, 0
C_STORE:                  ; Execution token points here
  dq IMPL_C_STORE

dict_C_FETCH:
  dq dict_C_STORE
  db 2, "C@", 0, 0, 0, 0, 0
C_FETCH:                  ; Execution token points here
  dq IMPL_C_FETCH

dict_STORE:
  dq dict_C_FETCH
  db 1, "!", 0, 0, 0, 0, 0, 0
STORE:                    ; Execution token points here
  dq IMPL_STORE

dict_FETCH:
  dq dict_STORE
  db 1, "@", 0, 0, 0, 0, 0, 0
FETCH:                    ; Execution token points here
  dq IMPL_FETCH

dict_R_FETCH:
  dq dict_FETCH
  db 2, "R@", 0, 0, 0, 0, 0
R_FETCH:                  ; Execution token points here
  dq IMPL_R_FETCH

dict_R_FROM:
  dq dict_R_FETCH
  db 2, "R>", 0, 0, 0, 0, 0
R_FROM:                   ; Execution token points here
  dq IMPL_R_FROM

dict_TO_R:
  dq dict_R_FROM
  db 2, ">R", 0, 0, 0, 0, 0
TO_R:                     ; Execution token points here
  dq IMPL_TO_R

dict_ADD:
  dq dict_TO_R
  db 1, "+", 0, 0, 0, 0, 0, 0
ADD:                      ; Execution token points here
  dq IMPL_ADD

dict_SUB:
  dq dict_ADD
  db 1, "-", 0, 0, 0, 0, 0, 0
SUB:                      ; Execution token points here
  dq IMPL_SUB

dict_ZEROEQ:
  dq dict_SUB
  db 2, "0=", 0, 0, 0, 0, 0
ZEROEQ:                   ; Execution token points here
  dq IMPL_ZEROEQ

dict_EQUAL:
  dq dict_ZEROEQ
  db 1, "=", 0, 0, 0, 0, 0, 0
EQUAL:                    ; Execution token points here
  dq IMPL_EQUAL

dict_AND:
  dq dict_EQUAL
  db 3, "AND", 0, 0, 0, 0
AND:                      ; Execution token points here
  dq IMPL_AND

dict_LSHIFT:
  dq dict_AND
  db 6, "LSHIFT", 0
LSHIFT:                   ; Execution token points here
  dq IMPL_LSHIFT

dict_OR:
  dq dict_LSHIFT
  db 2, "OR", 0, 0, 0, 0, 0
OR:                       ; Execution token points here
  dq IMPL_OR

dict_LESS_THAN:
  dq dict_OR
  db 1, "<", 0, 0, 0, 0, 0, 0
LESS_THAN:                ; Execution token points here
  dq IMPL_LESS_THAN

dict_RSHIFT:
  dq dict_LESS_THAN
  db 6, "RSHIFT", 0
RSHIFT:                   ; Execution token points here
  dq IMPL_RSHIFT

dict_DROP:
  dq dict_RSHIFT
  db 4, "DROP", 0, 0, 0
DROP:                     ; Execution token points here
  dq IMPL_DROP

dict_SWAP:
  dq dict_DROP
  db 4, "SWAP", 0, 0, 0
SWAP:                     ; Execution token points here
  dq IMPL_SWAP

dict_ROT:
  dq dict_SWAP
  db 3, "ROT", 0, 0, 0, 0
ROT:                      ; Execution token points here
  dq IMPL_ROT

dict_TWO_DUP:
  dq dict_ROT
  db 4, "2DUP", 0, 0, 0
TWO_DUP:                  ; Execution token points here
  dq IMPL_TWO_DUP

dict_TWO_DROP:
  dq dict_TWO_DUP
  db 5, "2DROP", 0, 0
TWO_DROP:                 ; Execution token points here
  dq IMPL_TWO_DROP

dict_OVER:
  dq dict_TWO_DROP
  db 4, "OVER", 0, 0, 0
OVER:                     ; Execution token points here
  dq IMPL_OVER

dict_DUP:
  dq dict_OVER
  db 3, "DUP", 0, 0, 0, 0
DUP:                      ; Execution token points here
  dq IMPL_DUP

dict_SP_FETCH:
  dq dict_DUP
  db 3, "SP@", 0, 0, 0, 0
SP_FETCH:                 ; Execution token points here
  dq IMPL_SP_FETCH

dict_LIT:
  dq dict_SP_FETCH
  db 67, "LIT", 0, 0, 0, 0  ; 3 | COMPILE_ONLY_FLAG = 67
LIT:                      ; Execution token points here
  dq IMPL_LIT

  ;; Test colon definition: DOUBLE ( n -- n*2 )
  ;; Equivalent to : DOUBLE DUP + ;
dict_DOUBLE:
  dq dict_LIT             ; Link to previous
  db 6, "DOUBLE", 0       ; Name
DOUBLE:                   ; Execution token points here
  dq DOCOL                ; Code field points to DOCOL
  dq DUP                  ; DUP (primitive)
  dq ADD                  ; + (primitive)
  dq EXIT                 ; EXIT (primitive)

dict_EXECUTE:
  dq dict_DOUBLE          ; Link to previous
  db 7, "EXECUTE"         ; Name (7 chars exactly)
EXECUTE:                  ; Execution token points here
  dq IMPL_EXECUTE

dict_BRANCH:
  dq dict_EXECUTE
  db 70, "BRANCH", 0       ; 6 | COMPILE_ONLY_FLAG = 70
BRANCH:                   ; Execution token points here
  dq IMPL_BRANCH          ; Points to implementation

dict_ZBRANCH:
  dq dict_BRANCH
  db 71, "0BRANCH"         ; 7 | COMPILE_ONLY_FLAG = 71
ZBRANCH:                  ; Execution token points here
  dq IMPL_ZBRANCH         ; Points to implementation

dict_REFILL:
  dq dict_ZBRANCH         ; Link to previous
  db 6, "REFILL", 0       ; Name
REFILL:                   ; Execution token points here
  dq IMPL_REFILL

dict_WORD:
  dq dict_REFILL          ; Link to previous
  db 4, "WORD", 0, 0, 0   ; Name
PARSE_WORD:               ; Execution token points here
  dq IMPL_PARSE_WORD

dict_BACKSLASH:
  dq dict_WORD            ; Link to previous
  db 129, 92, 0, 0, 0, 0, 0, 0 ; Name (ASCII code not to confuse emacs) - IMMEDIATE (bit 7 set)
BACKSLASH:                ; Execution token points here
  dq IMPL_BACKSLASH

dict_SCANC:
  dq dict_BACKSLASH       ; Link to previous
  db 5, "SCANC", 0, 0    ; Name
SCAN_CHAR:                ; Execution token points here
  dq IMPL_SCAN_CHAR

dict_SOURCE_FETCH:
  dq dict_SCANC           ; Link to previous
  db 7, "SOURCE@"        ; Name (7 chars exactly)
SOURCE_FETCH:             ; Execution token points here
  dq IMPL_SOURCE_FETCH

dict_LINE_NUMBER_FETCH:
  dq dict_SOURCE_FETCH    ; Link to previous
  db 5, "LINE#", 0, 0    ; Name
LINE_NUMBER_FETCH:        ; Execution token points here
  dq IMPL_LINE_NUMBER_FETCH

dict_COLUMN_NUMBER_FETCH:
  dq dict_LINE_NUMBER_FETCH ; Link to previous
  db 4, "COL#", 0, 0, 0  ; Name
COLUMN_NUMBER_FETCH:      ; Execution token points here
  dq IMPL_COLUMN_NUMBER_FETCH

dict_FIND:
  dq dict_COLUMN_NUMBER_FETCH
  db 4, "FIND", 0, 0, 0
FIND:                     ; Execution token points here
  dq IMPL_FIND

dict_NUMBER:
  dq dict_FIND
  db 6, "NUMBER", 0
NUMBER:                   ; Execution token points here
  dq IMPL_NUMBER

dict_TYPE:
  dq dict_NUMBER
  db 4, "TYPE", 0, 0, 0
TYPE:                     ; Execution token points here
  dq IMPL_TYPE

  ;; ERRTYPE ( c-addr u -- ) Output string to stderr
dict_ERRTYPE:
  dq dict_TYPE
  db 7, "ERRTYPE"
ERRTYPE:                  ; Execution token points here
  dq DOCOL                ; Colon definition
  ;; Save current OUTPUT
  dq OUTPUT_word          ; ( c-addr u OUTPUT )
  dq FETCH                ; ( c-addr u old-output )
  dq TO_R                 ; ( c-addr u ) (R: old-output)
  ;; Set OUTPUT to stderr
  dq LIT
  dq 2                    ; ( c-addr u 2 )
  dq OUTPUT_word          ; ( c-addr u 2 OUTPUT )
  dq STORE                ; ( c-addr u )
  ;; Output the string
  dq TYPE                 ; ( )
  ;; Restore OUTPUT
  dq R_FROM               ; ( old-output )
  dq OUTPUT_word          ; ( old-output OUTPUT )
  dq STORE                ; ( )
  dq EXIT

  ;; CR ( -- ) Output newline to stdout
  align 8
dict_CR:
  dq dict_ERRTYPE         ; Link to previous
  db 2, "CR", 0, 0, 0, 0, 0 ; Name must be exactly 8 bytes
CR:                       ; Execution token points here
  dq DOCOL                ; Colon definition
  dq LIT
  dq NEWLINE              ; Push newline character
  dq EMIT                 ; Output it
  dq EXIT

  ;; ERRCR ( -- ) Output newline to stderr
dict_ERRCR:
  dq dict_CR              ; Link to previous
  db 5, "ERRCR", 0, 0
ERRCR:                    ; Execution token points here
  dq DOCOL                ; Colon definition
  ;; Save current OUTPUT
  dq OUTPUT_word          ; ( OUTPUT )
  dq FETCH                ; ( old-output )
  dq TO_R                 ; ( ) (R: old-output)
  ;; Set OUTPUT to stderr
  dq LIT
  dq 2                    ; ( 2 )
  dq OUTPUT_word          ; ( 2 OUTPUT )
  dq STORE                ; ( )
  ;; Output newline
  dq CR                   ; ( )
  ;; Restore OUTPUT
  dq R_FROM               ; ( old-output )
  dq OUTPUT_word          ; ( old-output OUTPUT )
  dq STORE                ; ( )
  dq EXIT

  ;; Error message for unknown word
unknown_word_msg: db "Unknown word: "
  unknown_word_msg_len equ 14

  ;; Error message for compile-only word
compile_only_msg: db "Interpreting compile-only word: "
  compile_only_msg_len equ 32

  ;; INTERPRET ( -- ) Process words from input buffer
  align 8
dict_INTERPRET:
  dq dict_ERRCR           ; Link to previous
  db 7, "INTERPR"
INTERPRET:                ; Execution token points here
  dq DOCOL                ; Colon definition
  .loop:
  ;; Get next word
  dq PARSE_WORD           ; ( -- c-addr u )
  dq DUP                  ; ( c-addr u u )
  dq ZBRANCH, .done

  ;; Try to find in dictionary
  dq FIND                 ; ( dict-ptr 1 | c-addr u 0 )
  dq ZBRANCH, .try_number ; If not found, skip to .try_number

  ;; Found - check what to do with it (dict-ptr is on stack)
  dq DUP                  ; ( dict-ptr dict-ptr )
  dq LIT
  dq 8                    ; ( dict-ptr dict-ptr 8 )
  dq ADD                  ; ( dict-ptr name-field-addr )
  dq C_FETCH              ; ( dict-ptr length-byte )

  ;; First check compile-only in interpret mode
  dq DUP                  ; ( dict-ptr length-byte length-byte )
  dq LIT
  dq COMPILE_ONLY_FLAG ; ( dict-ptr length-byte length-byte 0x40 )
  dq AND                  ; ( dict-ptr length-byte compile-only? )
  dq STATE_FETCH          ; ( dict-ptr length-byte compile-only? state )
  dq ZEROEQ               ; ( dict-ptr length-byte compile-only? interpreting? )
  dq AND                  ; ( dict-ptr length-byte error? )
  dq ZBRANCH, .no_compile_only_error

  ;; Compile-only error path
  dq DROP                 ; ( dict-ptr )
  dq BRANCH, .compile_only_error

  .no_compile_only_error: ; ( dict-ptr length-byte )
  ;; Check if we should execute (immediate or interpreting)
  dq LIT
  dq IMMED_FLAG       ; ( dict-ptr length-byte 0x80 )
  dq AND                  ; ( dict-ptr immediate? )
  dq STATE_FETCH          ; ( dict-ptr immediate? state )
  dq ZEROEQ               ; ( dict-ptr immediate? interpreting? )
  dq OR                   ; ( dict-ptr should-execute? )
  dq ZBRANCH, .compile_it

  ;; Execute the word - need to get execution token
  dq LIT                  ; ( dict-ptr 16 )
  dq 16
  dq ADD                  ; ( xt )
  dq EXECUTE              ; Execute the word
  dq BRANCH, .loop

  .compile_it:            ; ( dict-ptr )
  ;; Compile the word - need to get execution token
  dq LIT                  ; ( dict-ptr 16 )
  dq 16
  dq ADD                  ; ( xt )
  dq COMMA
  dq BRANCH, .loop

  .compile_only_error:
  ;; Print compile-only error
  dq LIT
  dq compile_only_msg
  dq LIT
  dq compile_only_msg_len
  dq ERRTYPE              ; Print "Interpreting compile-only word: "
  ;; Get word name from dictionary pointer (dict-ptr + 8 = name field)
  dq LIT
  dq 8
  dq ADD                  ; ( name-field-addr )
  dq DUP                  ; ( name-field-addr name-field-addr )
  dq C_FETCH              ; ( name-field-addr length-byte )
  dq LIT
  dq NAME_LENGTH_MASK
  dq AND                  ; ( name-field-addr length )
  dq SWAP                 ; ( length name-field-addr )
  dq LIT
  dq 1
  dq ADD                  ; ( length name-addr )
  dq SWAP                 ; ( name-addr length )
  dq ERRTYPE              ; Print the word name
  dq ERRCR                ; Print newline
  dq EXIT

  .try_number:
  ;; Not in dictionary, try NUMBER
  dq NUMBER               ; ( n 1 | c-addr u 0 )
  dq ZBRANCH, .unknown_word

  ;; Got a number - check if we should compile it
  dq STATE_FETCH          ; ( n state )
  dq ZBRANCH, .loop       ; If interpreting, leave on stack

  ;; Compile mode - compile as literal
  dq LIT
  dq LIT              ; ( n LIT )
  dq COMMA                ; ( n )
  dq COMMA                ; ( )
  dq BRANCH, .loop

  .unknown_word:
  ;; Unknown word - print error
  dq LIT
  dq unknown_word_msg
  dq LIT
  dq unknown_word_msg_len
  dq ERRTYPE              ; Print "Unknown word: "
  dq ERRTYPE              ; Print the word itself
  dq ERRCR                ; Print newline
  dq EXIT

  .done:
  dq TWO_DROP
  dq EXIT

  ;; Error message for unknown word
missing_word_msg: db "Expected word, got EOF."
  missing_word_msg_len equ 23

  ;; Error messages for CREATE
wrong_word_size_msg: db "Wrong word size (must be 1-7 chars): "
  wrong_word_size_msg_len equ 37

  align 8
print_and_abort:
  dq ERRTYPE              ; Print the word itself
  dq ERRCR                ; Print newline
  dq ABORT

dict_TICK:
  dq dict_INTERPRET
  db 1, "'", 0, 0, 0, 0, 0, 0
TICK:                     ; Execution token points here
  dq DOCOL                ; Colon definition
  dq PARSE_WORD           ; ( -- c-addr u )
  dq DUP
  dq ZBRANCH, .missing_word
  dq FIND                 ; ( dict-ptr -1 | c-addr u 0 )
  dq ZBRANCH, .unknown_word
  ;; Convert dictionary pointer to execution token
  dq LIT
  dq 16
  dq ADD                  ; ( xt )
  dq EXIT
  .missing_word:
  dq LIT
  dq missing_word_msg
  dq LIT
  dq missing_word_msg_len
  dq BRANCH, print_and_abort
  .unknown_word:
  dq LIT
  dq unknown_word_msg
  dq LIT
  dq unknown_word_msg_len
  dq ERRTYPE              ; Print "Unknown word: "
  dq BRANCH, print_and_abort

  ;; STATE ( -- addr ) Push address of STATE variable
dict_STATE:
  dq dict_TICK       ; Link to previous
  db 5, "STATE", 0, 0     ; Name
STATE_word:               ; Execution token points here
  dq IMPL_STATE_word

  ;; ASSERT ( flag -- ) Check assertion, print FAIL: line:col if false
dict_ASSERT:
  dq dict_STATE           ; Link to previous
  db 6, "ASSERT", 0       ; Name
ASSERT:                   ; Execution token points here
  dq DOCOL                ; Colon definition
  ;; Check if assertion failed
  dq ZBRANCH, .fail
  ;; Passed - check if verbose mode
  dq DEBUG_FETCH          ; ( debug-flag )
  dq ZBRANCH, .done
  ;; Verbose mode - push PASS message
  dq LIT
  dq pass_msg         ; ( pass_msg )
  dq LIT
  dq pass_msg_len     ; ( pass_msg 6 )
  dq BRANCH, .print
  .fail:
  ;; Failed - push FAIL message
  dq LIT
  dq fail_msg         ; ( fail_msg )
  dq LIT
  dq fail_msg_len     ; ( fail_msg 6 )
  .print:
  ;; Common print path - save OUTPUT and set to stderr
  dq OUTPUT_word          ; ( msg len OUTPUT )
  dq FETCH                ; ( msg len old-output )
  dq TO_R                 ; ( msg len ) (R: old-output)
  dq LIT
  dq 2                ; ( msg len 2 )
  dq OUTPUT_word          ; ( msg len 2 OUTPUT )
  dq STORE                ; ( msg len )
  ;; Print the message
  dq TYPE                 ; ( )
  ;; Print line:col
  dq LINE_NUMBER_FETCH    ; ( line )
  dq DOT                  ; ( ) - prints line to stderr
  dq LIT
  dq ':'              ; ( ':' )
  dq EMIT                 ; ( )
  dq COLUMN_NUMBER_FETCH  ; ( col )
  dq DOT                  ; ( ) - prints col to stderr
  dq CR                   ; Print newline
  ;; Restore OUTPUT
  dq R_FROM               ; ( old-output )
  dq OUTPUT_word          ; ( old-output OUTPUT )
  dq STORE                ; ( )
  .done:
  dq EXIT

  ;; OUTPUT ( -- addr ) Push address of OUTPUT variable
dict_OUTPUT:
  dq dict_ASSERT          ; Link to previous
  db 6, "OUTPUT", 0       ; Name
OUTPUT_word:              ; Execution token points here
  dq IMPL_OUTPUT_word

  ;; FLAGS ( -- addr ) Push address of FLAGS variable
dict_FLAGS:
  dq dict_OUTPUT          ; Link to previous
  db 5, "FLAGS", 0, 0     ; Name
FLAGS_word:               ; Execution token points here
  dq IMPL_FLAGS_word

  ;; HERE ( -- addr ) Push address of HERE variable
dict_HERE:
  dq dict_FLAGS          ; Link to previous
  db 4, "HERE", 0, 0, 0     ; Name
HERE_word:                ; Execution token points here
  dq IMPL_HERE_word

  ;; LATEST ( -- addr ) Push address of HERE variable
dict_LATEST:
  dq dict_HERE          ; Link to previous
  db 6, "LATEST", 0
LATEST_word:              ; Execution token points here
  dq IMPL_LATEST_word

  ;; PROMPT ( -- ) Show prompt if interactive
  align 8
dict_PROMPT:
  dq dict_LATEST
  db 6, "PROMPT", 0
PROMPT:                   ; Execution token points here
  dq IMPL_PROMPT

  ;; BYE_MSG ( -- ) Show bye message if interactive
  align 8
dict_BYE_MSG:
  dq dict_PROMPT
  db 7, "BYE-MSG"
BYE_MSG:                  ; Execution token points here
  dq IMPL_BYE_MSG

  ;; IACR ( -- ) Output CR only if interactive
  align 8
dict_IACR:
  dq dict_BYE_MSG
  db 4, "IACR", 0, 0, 0
IACR:                     ; Execution token points here
  dq IMPL_IACR

  ;; QUIT ( -- ) Main interpreter loop
  align 8
dict_QUIT:
  dq dict_IACR           ; Link to previous
  db 4, "QUIT", 0, 0, 0   ; Name
QUIT:                     ; Execution token points here
  dq DOCOL                ; Colon definition
  .loop:
  dq PROMPT               ; Show prompt if interactive
  dq REFILL
  dq ZBRANCH, .bye
  dq INTERPRET            ; Call INTERPRET
  dq IACR                 ; CR if interactive
  dq BRANCH, .loop
  .bye:
  dq BYE_MSG              ; Show bye message if interactive
  dq EXIT

  ;; ABORT ( -- ) Clear stacks and jump to QUIT
  align 8
dict_ABORT:
  dq dict_QUIT            ; Link to previous
  db 5, "ABORT", 0, 0     ; Name
ABORT:                    ; Execution token points here
  dq IMPL_ABORT           ; Points to implementation

  ;; SHOWWORDS ( -- ) Debug word parsing by showing each word as bytes
dict_SHOWWORDS:
  dq dict_ABORT           ; Link to previous
  db 5, "SHOWW", 0, 0
SHOWWORDS:                ; Execution token points here
  dq DOCOL                ; Colon definition
  .loop:
  ;; Get next word
  dq PARSE_WORD           ; ( -- c-addr u )
  dq DUP                  ; ( c-addr u u )
  dq ZBRANCH, .done

  ;; For each character in the word
  .byte_loop:
  dq DUP                  ; ( c-addr u u )
  dq ZBRANCH, .end_word

  ;; Print one byte
  dq OVER                 ; ( c-addr count c-addr )
  dq C_FETCH              ; ( c-addr count byte )
  dq DOT                  ; ( c-addr count )
  dq LIT
  dq ' '
  dq EMIT

  ;; Next byte
  dq SWAP                 ; ( count c-addr )
  dq LIT
  dq 1
  dq ADD                  ; ( count c-addr+1 )
  dq SWAP                 ; ( c-addr+1 count )
  dq LIT
  dq -1
  dq ADD
  dq BRANCH, .byte_loop

  .end_word:
  ;; Clean up
  dq TWO_DROP             ; ( c-addr u )
  dq LIT
  dq '.'
  dq EMIT
  dq LIT
  dq ' '
  dq EMIT                 ; Double space
  dq BRANCH, .loop

  .done:
  dq TWO_DROP
  dq CR
  dq EXIT

dict_COMMA:
  dq dict_SHOWWORDS
  db 1, ",", 0, 0, 0, 0, 0, 0
COMMA:                    ; Execution token points here
  dq IMPL_COMMA

dict_ALLOT:
  dq dict_COMMA
  db 5, "ALLOT", 0, 0
ALLOT:                    ; Execution token points here
  dq IMPL_ALLOT

dict_CREATE:
  dq dict_ALLOT
  db 6, "CREATE", 0
CREATE:                       ; Execution token points here
  dq DOCOL
  ;; Update linked list pointers
  dq HERE_word
  dq FETCH                    ; save original HERE before ,
  dq LATEST_word
  dq FETCH
  dq COMMA
  dq LATEST_word
  dq STORE

  dq PARSE_WORD               ; (c-addr u)

  ;; Check word length is 1-7
  dq DUP                      ; (c-addr u u)
  dq DUP                      ; (c-addr u u u)
  dq ZEROEQ                   ; (c-addr u u is-zero)
  dq SWAP                     ; (c-addr u is-zero u)
  dq LIT
  dq -8                   ; (c-addr u is-zero u -8)
  dq AND                      ; (c-addr u is-zero u&~7)
  dq OR                       ; (c-addr u invalid?)
  dq ZBRANCH, .size_ok

  ;; Size error - print message and abort
  dq LIT
  dq wrong_word_size_msg
  dq LIT
  dq wrong_word_size_msg_len
  dq ERRTYPE
  dq ERRTYPE                  ; Print the word
  dq ERRCR
  dq ABORT

  .size_ok:
  dq SWAP                     ; (u c-addr)
  dq FETCH
  dq LIT
  dq 8
  dq LSHIFT
  dq OR
  dq COMMA
  dq LIT
  dq DOCREATE
  dq COMMA
  dq EXIT

dict_IMMED_TEST:
  dq dict_CREATE
  db 6, "IMMED?", 0
IMMED_TEST:               ; Execution token points here
  dq IMPL_IMMED_TEST

dict_IMMED:
  dq dict_IMMED_TEST
  db 5, "IMMED", 0, 0
IMMED:                    ; Execution token points here
  dq IMPL_IMMED

dict_COLON:
  dq dict_IMMED
  db 1, ":", 0, 0, 0, 0, 0, 0
COLON:                        ; Execution token points here
  dq DOCOL
  dq CREATE

  ;; replace DOCREATE with DOCOL
  dq LIT
  dq DOCOL
  dq HERE_word
  dq FETCH                    ; Get HERE value, not address
  dq LIT
  dq 8
  dq SUB
  dq STORE

  ;; set compilation mode
  dq LIT
  dq 1
  dq STATE_STORE
  dq EXIT

dict_SEMICOLON:
  dq dict_COLON
  db 129, ";", 0, 0, 0, 0, 0, 0
SEMICOLON:                    ; Execution token points here
  dq DOCOL
  dq LIT
  dq EXIT
  dq COMMA
  dq LIT
  dq 0
  dq STATE_STORE
  dq EXIT

dict_THREAD:
  dq dict_SEMICOLON
  db 6, "THREAD", 0
THREAD:                   ; Execution token points here
  dq IMPL_THREAD

dict_WAIT:
  dq dict_THREAD
  db 4, "WAIT", 0, 0, 0
FWAIT:                    ; Execution token points here
  dq IMPL_FWAIT

dict_WAKE:
  dq dict_WAIT
  db 4, "WAKE", 0, 0, 0
WAKE:                     ; Execution token points here
  dq IMPL_WAKE

dict_CLOCK_FETCH:
  dq dict_WAKE
  db 6, "CLOCK@", 0
CLOCK_FETCH:              ; Execution token points here
  dq IMPL_CLOCK_FETCH

dict_SLEEP:
  dq dict_CLOCK_FETCH
  db 5, "SLEEP", 0, 0
SLEEP:                    ; Execution token points here
  dq IMPL_SLEEP

  ;; STATE@ ( -- n ) Get compile/interpret state
dict_STATE_FETCH:
  dq dict_SLEEP
  db 6, "STATE@", 0
STATE_FETCH:              ; Execution token points here
  dq IMPL_STATE_FETCH

  ;; STATE! ( n -- ) Set compile/interpret state
dict_STATE_STORE:
  dq dict_STATE_FETCH
  db 6, "STATE!", 0
STATE_STORE:              ; Execution token points here
  dq IMPL_STATE_STORE

  ;; OUTPUT@ ( -- n ) Get output stream
dict_OUTPUT_FETCH:
  dq dict_STATE_STORE
  db 7, "OUTPUT@"
OUTPUT_FETCH:             ; Execution token points here
  dq IMPL_OUTPUT_FETCH

  ;; OUTPUT! ( n -- ) Set output stream
dict_OUTPUT_STORE:
  dq dict_OUTPUT_FETCH
  db 7, "OUTPUT!"
OUTPUT_STORE:             ; Execution token points here
  dq IMPL_OUTPUT_STORE

  ;; DEBUG@ ( -- n ) Get debug flag
dict_DEBUG_FETCH:
  dq dict_OUTPUT_STORE
  db 6, "DEBUG@", 0
DEBUG_FETCH:              ; Execution token points here
  dq IMPL_DEBUG_FETCH

  ;; DEBUG! ( n -- ) Set debug flag
dict_DEBUG_STORE:
  dq dict_DEBUG_FETCH
  db 6, "DEBUG!", 0
DEBUG_STORE:              ; Execution token points here
  dq IMPL_DEBUG_STORE

dict_CC_SIZE:
  dq dict_DEBUG_STORE
  db 7, "CC-SIZE"
CC_SIZE:                  ; Execution token points here
  dq IMPL_CC_SIZE

extern IMPL_CALL_CC
dict_CALL_CC:
  dq dict_CC_SIZE
  db 7, "CALL/CC"
CALL_CC:                  ; Execution token points here
  dq IMPL_CALL_CC

  ;; INTERACT ( -- ) Enable interactive mode (prompts and bye message)
dict_INTERACT:
  dq dict_CALL_CC
  db 7, "INTERAC"
INTERACT:                 ; Execution token points here
  dq IMPL_INTERACT


  ;; LATEST points to the most recent word
LATEST: dq dict_INTERACT
  
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
data_stack: resq 1024
data_stack_base:          ; Base of data stack (high address, grows down)
  
return_stack: resq 512    ; Return stack (smaller than data stack)
return_stack_base:        ; Base of return stack (high address, grows down)

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
  global data_stack_base
  global return_stack_base
  global main_thread_descriptor
  global QUIT
  global ERRTYPE
  global ERRCR
  global HERE

  ;; Import all the primitives from other files
  extern NEXT
  extern DOCOL
  extern DOCREATE
  extern IMPL_EXIT
  extern IMPL_EXECUTE
  extern IMPL_ABORT
  extern IMPL_BRANCH
  extern IMPL_ZBRANCH
  extern IMPL_CC_SIZE
  extern IMPL_LIT
  extern IMPL_DUP
  extern IMPL_DROP
  extern IMPL_OVER
  extern IMPL_SWAP
  extern IMPL_ROT
  extern IMPL_SP_FETCH
  extern IMPL_TWO_DUP
  extern IMPL_TWO_DROP
  extern IMPL_ADD
  extern IMPL_SUB
  extern IMPL_ZEROEQ
  extern IMPL_EQUAL
  extern IMPL_AND
  extern IMPL_LSHIFT
  extern IMPL_OR
  extern IMPL_LESS_THAN
  extern IMPL_RSHIFT
  extern IMPL_TO_R
  extern IMPL_R_FROM
  extern IMPL_R_FETCH
  extern IMPL_FETCH
  extern IMPL_STORE
  extern IMPL_C_FETCH
  extern IMPL_C_STORE
  extern IMPL_DOT
  extern IMPL_EMIT
  extern IMPL_KEY
  extern IMPL_NUMBER
  extern IMPL_FIND
  extern IMPL_REFILL
  extern IMPL_PARSE_WORD
  extern IMPL_BACKSLASH
  extern IMPL_SCAN_CHAR
  extern IMPL_SOURCE_FETCH
  extern IMPL_LINE_NUMBER_FETCH
  extern IMPL_COLUMN_NUMBER_FETCH
  extern IMPL_TYPE
  extern IMPL_STATE_word
  extern IMPL_OUTPUT_word
  extern IMPL_FLAGS_word
  extern IMPL_HERE_word
  extern IMPL_LATEST_word
  extern IMPL_INTERACT
  extern IMPL_PROMPT
  extern IMPL_BYE_MSG
  extern IMPL_IACR
  extern IMPL_COMMA
  extern IMPL_ALLOT
  extern IMPL_IMMED_TEST
  extern IMPL_IMMED
  extern IMPL_STATE_FETCH
  extern IMPL_STATE_STORE
  extern IMPL_OUTPUT_FETCH
  extern IMPL_OUTPUT_STORE
  extern IMPL_DEBUG_FETCH
  extern IMPL_DEBUG_STORE
  extern IMPL_THREAD
  extern IMPL_FWAIT
  extern IMPL_WAKE
  extern IMPL_CLOCK_FETCH
  extern IMPL_SLEEP

  ;; ---- Main Program ----

_start:
  ;; Call ABORT to start the system
  ;; ABORT will clear stacks and jump to QUIT
  jmp IMPL_ABORT

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
  extern dict_SYSEXIT
  dq dict_SYSEXIT           ; +24: cleanup function (exits entire process)
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
  ;; New format: descriptor_data then dict_entry with pointer back to descriptor

EXIT_descriptor:
  db 4, "EXIT", 0, 0, 0       ; Length + name (padded to 8)
dict_EXIT:
  dq 0                        ; Link (null - last word in dictionary)
  dq EXIT_descriptor          ; Descriptor pointer
  dq EXIT                     ; Code field

DOT_descriptor:
  db 1, ".", 0, 0, 0, 0, 0, 0
dict_DOT:
  dq dict_EXIT
  dq DOT_descriptor
  dq DOT

EMIT_descriptor:
  db 4, "EMIT", 0, 0, 0
dict_EMIT:
  dq dict_DOT
  dq EMIT_descriptor
  dq EMIT

KEY_descriptor:
  db 3, "KEY", 0, 0, 0, 0
dict_KEY:
  dq dict_EMIT
  dq KEY_descriptor
  dq KEY

C_STORE_descriptor:
  db 2, "C!", 0, 0, 0, 0, 0
dict_C_STORE:
  dq dict_KEY
  dq C_STORE_descriptor
  dq C_STORE

C_FETCH_descriptor:
  db 2, "C@", 0, 0, 0, 0, 0
dict_C_FETCH:
  dq dict_C_STORE
  dq C_FETCH_descriptor
  dq C_FETCH

STORE_descriptor:
  db 1, "!", 0, 0, 0, 0, 0, 0
dict_STORE:
  dq dict_C_FETCH
  dq STORE_descriptor
  dq STORE

FETCH_descriptor:
  db 1, "@", 0, 0, 0, 0, 0, 0
dict_FETCH:
  dq dict_STORE
  dq FETCH_descriptor
  dq FETCH

R_FETCH_descriptor:
  db 2, "R@", 0, 0, 0, 0, 0
dict_R_FETCH:
  dq dict_FETCH
  dq R_FETCH_descriptor
  dq R_FETCH

R_FROM_descriptor:
  db 2, "R>", 0, 0, 0, 0, 0
dict_R_FROM:
  dq dict_R_FETCH
  dq R_FROM_descriptor
  dq R_FROM

TO_R_descriptor:
  db 2, ">R", 0, 0, 0, 0, 0
dict_TO_R:
  dq dict_R_FROM
  dq TO_R_descriptor
  dq TO_R

ADD_descriptor:
  db 1, "+", 0, 0, 0, 0, 0, 0
dict_ADD:
  dq dict_TO_R
  dq ADD_descriptor
  dq ADD

SUB_descriptor:
  db 1, "-", 0, 0, 0, 0, 0, 0
dict_SUB:
  dq dict_ADD
  dq SUB_descriptor
  dq SUB

ZEROEQ_descriptor:
  db 2, "0=", 0, 0, 0, 0, 0
dict_ZEROEQ:
  dq dict_SUB
  dq ZEROEQ_descriptor
  dq ZEROEQ

EQUAL_descriptor:
  db 1, "=", 0, 0, 0, 0, 0, 0
dict_EQUAL:
  dq dict_ZEROEQ
  dq EQUAL_descriptor
  dq EQUAL

AND_descriptor:
  db 3, "AND", 0, 0, 0, 0
dict_AND:
  dq dict_EQUAL
  dq AND_descriptor
  dq AND

LSHIFT_descriptor:
  db 6, "LSHIFT", 0
dict_LSHIFT:
  dq dict_AND
  dq LSHIFT_descriptor
  dq LSHIFT

OR_descriptor:
  db 2, "OR", 0, 0, 0, 0, 0
dict_OR:
  dq dict_LSHIFT
  dq OR_descriptor
  dq OR

LESS_THAN_descriptor:
  db 1, "<", 0, 0, 0, 0, 0, 0
dict_LESS_THAN:
  dq dict_OR
  dq LESS_THAN_descriptor
  dq LESS_THAN

RSHIFT_descriptor:
  db 6, "RSHIFT", 0
dict_RSHIFT:
  dq dict_LESS_THAN
  dq RSHIFT_descriptor
  dq RSHIFT

DROP_descriptor:
  db 4, "DROP", 0, 0, 0
dict_DROP:
  dq dict_RSHIFT
  dq DROP_descriptor
  dq DROP

SWAP_descriptor:
  db 4, "SWAP", 0, 0, 0
dict_SWAP:
  dq dict_DROP
  dq SWAP_descriptor
  dq SWAP

ROT_descriptor:
  db 3, "ROT", 0, 0, 0, 0
dict_ROT:
  dq dict_SWAP
  dq ROT_descriptor
  dq ROT

TWO_DUP_descriptor:
  db 4, "2DUP", 0, 0, 0
dict_TWO_DUP:
  dq dict_ROT
  dq TWO_DUP_descriptor
  dq TWO_DUP

TWO_DROP_descriptor:
  db 5, "2DROP", 0, 0
dict_TWO_DROP:
  dq dict_TWO_DUP
  dq TWO_DROP_descriptor
  dq TWO_DROP

OVER_descriptor:
  db 4, "OVER", 0, 0, 0
dict_OVER:
  dq dict_TWO_DROP
  dq OVER_descriptor
  dq OVER

DUP_descriptor:
  db 3, "DUP", 0, 0, 0, 0
dict_DUP:
  dq dict_OVER
  dq DUP_descriptor
  dq DUP

SP_FETCH_descriptor:
  db 3, "SP@", 0, 0, 0, 0
dict_SP_FETCH:
  dq dict_DUP
  dq SP_FETCH_descriptor
  dq SP_FETCH

LIT_descriptor:
  db 67, "LIT", 0, 0, 0, 0  ; 3 | COMPILE_ONLY_FLAG = 67
dict_LIT:
  dq dict_SP_FETCH
  dq LIT_descriptor
  dq LIT

  ;; Test colon definition: DOUBLE ( n -- n*2 )
  ;; Equivalent to : DOUBLE DUP + ;
DOUBLE_descriptor:
  db 6, "DOUBLE", 0       ; Name
dict_DOUBLE:
  dq dict_LIT             ; Link to previous
  dq DOUBLE_descriptor    ; Descriptor pointer
  dq DOCOL                ; Code field points to DOCOL
  ;; Body starts here:
  dq dict_DUP             ; DUP
  dq dict_ADD             ; +
  dq dict_EXIT            ; EXIT (;)

EXECUTE_descriptor:
  db 7, "EXECUTE"         ; Name (7 chars exactly)
dict_EXECUTE:
  dq dict_DOUBLE          ; Link to previous
  dq EXECUTE_descriptor   ; Descriptor pointer
  dq EXECUTE              ; Code field

BRANCH_descriptor:
  db 70, "BRANCH", 0       ; 6 | COMPILE_ONLY_FLAG = 70
dict_BRANCH:
  dq dict_EXECUTE
  dq BRANCH_descriptor
  dq BRANCH

ZBRANCH_descriptor:
  db 71, "0BRANCH"         ; 7 | COMPILE_ONLY_FLAG = 71
dict_ZBRANCH:
  dq dict_BRANCH
  dq ZBRANCH_descriptor
  dq ZBRANCH

REFILL_descriptor:
  db 6, "REFILL", 0       ; Name
dict_REFILL:
  dq dict_ZBRANCH         ; Link to previous
  dq REFILL_descriptor
  dq REFILL               ; Code field

WORD_descriptor:
  db 4, "WORD", 0, 0, 0   ; Name
dict_WORD:
  dq dict_REFILL          ; Link to previous
  dq WORD_descriptor
  dq PARSE_WORD           ; Code field

BACKSLASH_descriptor:
  db 129, 92, 0, 0, 0, 0, 0, 0 ; Name (ASCII code not to confuse emacs) - IMMEDIATE (bit 7 set)
dict_BACKSLASH:
  dq dict_WORD            ; Link to previous
  dq BACKSLASH_descriptor
  dq BACKSLASH            ; Code field

SCANC_descriptor:
  db 5, "SCANC", 0, 0    ; Name
dict_SCANC:
  dq dict_BACKSLASH       ; Link to previous
  dq SCANC_descriptor
  dq SCAN_CHAR            ; Code field

SOURCE_FETCH_descriptor:
  db 7, "SOURCE@"        ; Name (7 chars exactly)
dict_SOURCE_FETCH:
  dq dict_SCANC           ; Link to previous
  dq SOURCE_FETCH_descriptor
  dq SOURCE_FETCH         ; Code field

LINE_NUMBER_FETCH_descriptor:
  db 5, "LINE#", 0, 0    ; Name
dict_LINE_NUMBER_FETCH:
  dq dict_SOURCE_FETCH    ; Link to previous
  dq LINE_NUMBER_FETCH_descriptor
  dq LINE_NUMBER_FETCH   ; Code field

COLUMN_NUMBER_FETCH_descriptor:
  db 4, "COL#", 0, 0, 0  ; Name
dict_COLUMN_NUMBER_FETCH:
  dq dict_LINE_NUMBER_FETCH ; Link to previous
  dq COLUMN_NUMBER_FETCH_descriptor
  dq COLUMN_NUMBER_FETCH ; Code field

FIND_descriptor:
  db 4, "FIND", 0, 0, 0
dict_FIND:
  dq dict_COLUMN_NUMBER_FETCH
  dq FIND_descriptor
  dq FIND

NUMBER_descriptor:
  db 6, "NUMBER", 0
dict_NUMBER:
  dq dict_FIND
  dq NUMBER_descriptor
  dq NUMBER

TYPE_descriptor:
  db 4, "TYPE", 0, 0, 0
dict_TYPE:
  dq dict_NUMBER
  dq TYPE_descriptor
  dq TYPE

  ;; ERRTYPE ( c-addr u -- ) Output string to stderr
ERRTYPE_descriptor:
  db 7, "ERRTYPE"
dict_ERRTYPE:
  dq dict_TYPE
  dq ERRTYPE_descriptor
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
CR_descriptor:
  db 2, "CR", 0, 0, 0, 0, 0 ; Name must be exactly 8 bytes
dict_CR:
  dq dict_ERRTYPE         ; Link to previous
  dq CR_descriptor
  dq DOCOL                ; Colon definition
  ;; Body starts here at offset 24
  dq dict_LIT, NEWLINE    ; Push newline character
  dq dict_EMIT            ; Output it
  dq dict_EXIT

  ;; ERRCR ( -- ) Output newline to stderr
ERRCR_descriptor:
  db 5, "ERRCR", 0, 0
dict_ERRCR:
  dq dict_CR              ; Link to previous
  dq ERRCR_descriptor
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

  ;; Error message for compile-only word
compile_only_msg: db "Interpreting compile-only word: "
  compile_only_msg_len equ 32

  ;; INTERPRET ( -- ) Process words from input buffer
  align 8
INTERPRET_descriptor:
  db 7, "INTERPR"
dict_INTERPRET:
  dq dict_ERRCR           ; Link to previous
  dq INTERPRET_descriptor
  dq DOCOL                ; Colon definition
  .loop:
  ;; Get next word
  dq dict_WORD            ; ( -- c-addr u )
  dq dict_DUP             ; ( c-addr u u )
  dq dict_ZBRANCH, .done

  ;; Try to find in dictionary
  dq dict_FIND            ; ( xt 1 | c-addr u 0 )
  dq dict_ZBRANCH, .try_number       ; If not found, skip to .try_number
  
  ;; Found - check what to do with it
  dq dict_DUP             ; ( xt xt )
  dq dict_LIT, 8          ; ( xt xt 8 )
  dq dict_ADD             ; ( xt descriptor-ptr-addr )
  dq dict_FETCH           ; ( xt descriptor-ptr )
  dq dict_C_FETCH         ; ( xt length-byte )
  
  ;; First check compile-only in interpret mode
  dq dict_DUP             ; ( xt length-byte length-byte )
  dq dict_LIT, COMPILE_ONLY_FLAG ; ( xt length-byte length-byte 0x40 )
  dq dict_AND             ; ( xt length-byte compile-only? )
  dq dict_STATE_FETCH     ; ( xt length-byte compile-only? state )
  dq dict_ZEROEQ          ; ( xt length-byte compile-only? interpreting? )
  dq dict_AND             ; ( xt length-byte error? )
  dq dict_ZBRANCH, .no_compile_only_error
  
  ;; Compile-only error path
  dq dict_DROP            ; ( xt )
  dq dict_BRANCH, .compile_only_error
  
  .no_compile_only_error: ; ( xt length-byte )
  ;; Check if we should execute (immediate or interpreting)
  dq dict_LIT, IMMED_FLAG ; ( xt length-byte 0x80 )
  dq dict_AND             ; ( xt immediate? )
  dq dict_STATE_FETCH     ; ( xt immediate? state )
  dq dict_ZEROEQ          ; ( xt immediate? interpreting? )
  dq dict_OR              ; ( xt should-execute? )
  dq dict_ZBRANCH, .compile_it
  
  ;; Execute the word
  dq dict_EXECUTE         ; Execute the word
  dq dict_BRANCH, .loop
  
  .compile_it:            ; ( xt )
  ;; Compile the word
  dq dict_COMMA
  dq dict_BRANCH, .loop
  
  .compile_only_error:
  ;; Print compile-only error
  dq dict_LIT, compile_only_msg
  dq dict_LIT, compile_only_msg_len
  dq dict_ERRTYPE         ; Print "Interpreting compile-only word: "
  ;; Need to get the word name from the dictionary entry
  dq dict_LIT, 8
  dq dict_ADD             ; ( name-field-addr )
  dq dict_DUP             ; ( name-field-addr name-field-addr )
  dq dict_C_FETCH         ; ( name-field-addr length-byte )
  dq dict_LIT, NAME_LENGTH_MASK
  dq dict_AND             ; ( name-field-addr length )
  dq dict_SWAP            ; ( length name-field-addr )
  dq dict_LIT, 1
  dq dict_ADD             ; ( length name-addr )
  dq dict_SWAP            ; ( name-addr length )
  dq dict_ERRTYPE         ; Print the word name
  dq dict_ERRCR           ; Print newline
  dq dict_EXIT

  .try_number:
  ;; Not in dictionary, try NUMBER
  dq dict_NUMBER          ; ( n 1 | c-addr u 0 )
  dq dict_ZBRANCH, .unknown_word
  
  ;; Got a number - check if we should compile it
  dq dict_STATE_FETCH     ; ( n state )
  dq dict_ZBRANCH, .loop  ; If interpreting, leave on stack
  
  ;; Compile mode - compile as literal
  dq dict_LIT, dict_LIT   ; ( n dict_LIT )
  dq dict_COMMA           ; ( n )
  dq dict_COMMA           ; ( )
  dq dict_BRANCH, .loop
  
  .unknown_word:
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

  ;; Error messages for CREATE
create_zero_length_msg: db "CREATE: name cannot be empty", 10
  create_zero_length_msg_len equ $ - create_zero_length_msg
create_too_long_msg: db "CREATE: name too long (max 63 chars)", 10
  create_too_long_msg_len equ $ - create_too_long_msg

  align 8
print_and_abort:
  dq dict_ERRTYPE         ; Print the word itself
  dq dict_ERRCR           ; Print newline
  dq dict_ABORT

TICK_descriptor:
  db 1, "'", 0, 0, 0, 0, 0, 0
dict_TICK:
  dq dict_INTERPRET
  dq TICK_descriptor
  dq DOCOL                ; Colon definition
  dq dict_WORD            ; ( -- c-addr u )
  dq dict_DUP
  dq dict_ZBRANCH, .missing_word
  dq dict_FIND            ; ( xt -1 | c-addr u 0 )
  dq dict_ZBRANCH, .unknown_word
  dq dict_EXIT
  .missing_word:
  dq dict_LIT, missing_word_msg
  dq dict_LIT, missing_word_msg_len
  dq dict_BRANCH, print_and_abort
  .unknown_word:
  dq dict_LIT, unknown_word_msg
  dq dict_LIT, unknown_word_msg_len
  dq dict_ERRTYPE         ; Print "Unknown word: "
  dq dict_BRANCH, print_and_abort

  ;; STATE ( -- addr ) Push address of STATE variable
STATE_descriptor:
  db 5, "STATE", 0, 0     ; Name
dict_STATE:
  dq dict_TICK       ; Link to previous
  dq STATE_descriptor
  dq STATE_word           ; Code field

  ;; ASSERT ( flag -- ) Check assertion, print FAIL: line:col if false
ASSERT_descriptor:
  db 6, "ASSERT", 0       ; Name
dict_ASSERT:
  dq dict_STATE           ; Link to previous
  dq ASSERT_descriptor
  dq DOCOL                ; Colon definition
  ;; Check if assertion failed
  dq dict_ZBRANCH, .fail
  ;; Passed - check if verbose mode
  dq dict_DEBUG_FETCH     ; ( debug-flag )
  dq dict_ZBRANCH, .done
  ;; Verbose mode - push PASS message
  dq dict_LIT, pass_msg   ; ( pass_msg )
  dq dict_LIT, pass_msg_len ; ( pass_msg 6 )
  dq dict_BRANCH, .print
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
OUTPUT_descriptor:
  db 6, "OUTPUT", 0       ; Name
dict_OUTPUT:
  dq dict_ASSERT          ; Link to previous
  dq OUTPUT_descriptor
  dq OUTPUT_word          ; Code field

  ;; FLAGS ( -- addr ) Push address of FLAGS variable
FLAGS_descriptor:
  db 5, "FLAGS", 0, 0     ; Name
dict_FLAGS:
  dq dict_OUTPUT          ; Link to previous
  dq FLAGS_descriptor
  dq FLAGS_word           ; Code field

  ;; HERE ( -- addr ) Push address of HERE variable
HERE_descriptor:
  db 4, "HERE", 0, 0, 0     ; Name
dict_HERE:
  dq dict_FLAGS          ; Link to previous
  dq HERE_descriptor
  dq HERE_word           ; Code field

  ;; LATEST ( -- addr ) Push address of HERE variable
LATEST_descriptor:
  db 6, "LATEST", 0
dict_LATEST:
  dq dict_HERE          ; Link to previous
  dq LATEST_descriptor
  dq LATEST_word           ; Code field

  ;; PROMPT ( -- ) Show prompt if interactive
  align 8
PROMPT_descriptor:
  db 6, "PROMPT", 0
dict_PROMPT:
  dq dict_LATEST
  dq PROMPT_descriptor
  dq PROMPT

  ;; BYE_MSG ( -- ) Show bye message if interactive
  align 8
BYE_MSG_descriptor:
  db 7, "BYE-MSG"
dict_BYE_MSG:
  dq dict_PROMPT
  dq BYE_MSG_descriptor
  dq BYE_MSG

  ;; IACR ( -- ) Output CR only if interactive
  align 8
IACR_descriptor:
  db 4, "IACR", 0, 0, 0
dict_IACR:
  dq dict_BYE_MSG
  dq IACR_descriptor
  dq IACR

  ;; QUIT ( -- ) Main interpreter loop
  align 8
QUIT_descriptor:
  db 4, "QUIT", 0, 0, 0   ; Name
dict_QUIT:
  dq dict_IACR           ; Link to previous
  dq QUIT_descriptor
  dq DOCOL                ; Colon definition
  .loop:
  dq dict_PROMPT          ; Show prompt if interactive
  dq dict_REFILL
  dq dict_ZBRANCH, .bye
  dq dict_INTERPRET
  dq dict_IACR                  ; CR if interactive
  dq dict_BRANCH, .loop
  .bye:
  dq dict_BYE_MSG         ; Show bye message if interactive
  dq dict_EXIT

  ;; ABORT ( -- ) Clear stacks and jump to QUIT
  align 8
ABORT_descriptor:
  db 5, "ABORT", 0, 0     ; Name
dict_ABORT:
  dq dict_QUIT            ; Link to previous
  dq ABORT_descriptor
  dq ABORT_word           ; Code field (primitive)

  ;; SHOWWORDS ( -- ) Debug word parsing by showing each word as bytes
SHOWWORDS_descriptor:
  db 5, "SHOWW", 0, 0
dict_SHOWWORDS:
  dq dict_ABORT           ; Link to previous
  dq SHOWWORDS_descriptor
  dq DOCOL                ; Colon definition
  .loop:
  ;; Get next word
  dq dict_WORD            ; ( -- c-addr u )
  dq dict_DUP             ; ( c-addr u u )
  dq dict_ZBRANCH, .done
  
  ;; For each character in the word
  .byte_loop:
  dq dict_DUP             ; ( c-addr u u )
  dq dict_ZBRANCH, .end_word
  
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
  dq dict_BRANCH, .byte_loop
  
  .end_word:
  ;; Clean up
  dq dict_TWO_DROP        ; ( c-addr u )
  dq dict_LIT, '.'
  dq dict_EMIT
  dq dict_LIT, ' '
  dq dict_EMIT            ; Double space
  dq dict_BRANCH, .loop
  
  .done:
  dq dict_TWO_DROP
  dq dict_CR
  dq dict_EXIT

COMMA_descriptor:
  db 1, ",", 0, 0, 0, 0, 0, 0
dict_COMMA:
  dq dict_SHOWWORDS
  dq COMMA_descriptor
  dq COMMA

CMOVE_descriptor:
  db 5, "CMOVE", 0, 0
dict_CMOVE:
  dq dict_COMMA
  dq CMOVE_descriptor
  dq CMOVE

ALLOT_descriptor:
  db 5, "ALLOT", 0, 0
dict_ALLOT:
  dq dict_CMOVE
  dq ALLOT_descriptor
  dq ALLOT

CREATE_descriptor:
  db 6, "CREATE", 0
dict_CREATE:
  dq dict_ALLOT
  dq CREATE_descriptor
  dq DOCOL

  ;; Parse word name
  dq dict_WORD                  ; (c-addr u)

  ;; Check word length is 1-63
  dq dict_DUP                   ; (c-addr u u)
  dq dict_DUP                   ; (c-addr u u u)
  dq dict_ZEROEQ                ; (c-addr u u is-zero)
  dq dict_SWAP                  ; (c-addr u is-zero u)
  dq dict_LIT, -64              ; (c-addr u is-zero u -64)
  dq dict_AND                   ; (c-addr u is-zero u&~63)
  dq dict_OR                    ; (c-addr u invalid?)
  dq dict_ZBRANCH, .size_ok

  ;; Size error - print message and abort
  dq dict_LIT, create_too_long_msg
  dq dict_LIT, create_too_long_msg_len
  dq dict_ERRTYPE
  dq dict_ERRTYPE               ; Print the word
  dq dict_ERRCR
  dq dict_ABORT

  .size_ok:                     ; (c-addr u)
  ;; Store variable-length descriptor with 8-byte alignment
  ;; Save descriptor start position
  dq dict_HERE, dict_FETCH      ; (c-addr u desc-start)
  dq dict_TO_R                  ; (c-addr u) (R: desc-start)

  ;; First store length byte
  dq dict_DUP                   ; (c-addr u u)
  dq dict_HERE, dict_FETCH      ; (c-addr u u here)
  dq dict_C_STORE               ; (c-addr u) - store length
  dq dict_LIT, 1, dict_ALLOT    ; advance HERE by 1

  ;; Copy name bytes using CMOVE: (c-addr u)
  dq dict_HERE, dict_FETCH      ; (c-addr u dest)
  dq dict_SWAP                  ; (c-addr dest u)
  dq dict_DUP                   ; (c-addr dest u u)
  dq dict_ALLOT                 ; (c-addr dest u) - advance HERE by u
  dq dict_CMOVE                 ; Copy u bytes from c-addr to dest

  ;; Align HERE to 8-byte boundary
  dq dict_HERE, dict_FETCH      ; (here)
  dq dict_LIT, 7, dict_ADD      ; (here+7)
  dq dict_LIT, -8, dict_AND     ; ((here+7) & ~7)
  dq dict_HERE, dict_STORE      ; Store aligned HERE

  ;; Store dictionary entry: [link][descriptor_ptr][code]
  dq dict_LATEST, dict_FETCH, dict_COMMA    ; Store link to previous
  dq dict_R_FROM, dict_COMMA    ; Store descriptor pointer from return stack
  dq dict_LIT, DOCREATE, dict_COMMA         ; Store DOCREATE

  ;; Update LATEST to point to new dictionary entry
  dq dict_HERE, dict_FETCH, dict_LIT, 24, dict_SUB
  dq dict_LATEST, dict_STORE

  dq dict_EXIT

IMMED_TEST_descriptor:
  db 6, "IMMED?", 0
dict_IMMED_TEST:
  dq dict_CREATE
  dq IMMED_TEST_descriptor
  dq IMMED_TEST

IMMED_descriptor:
  db 5, "IMMED", 0, 0
dict_IMMED:
  dq dict_IMMED_TEST
  dq IMMED_descriptor
  dq IMMED

COLON_descriptor:
  db 1, ":", 0, 0, 0, 0, 0, 0
dict_COLON:
  dq dict_IMMED
  dq COLON_descriptor
  dq DOCOL
  dq dict_CREATE

  ;; replace DOCREATE with DOCOL
  dq dict_LIT, DOCOL
  dq dict_HERE
  dq dict_FETCH                 ; Get HERE value, not address
  dq dict_LIT, 8
  dq dict_SUB
  dq dict_STORE

  ;; set compilation mode
  dq dict_LIT, 1
  dq dict_STATE_STORE
  dq dict_EXIT

SEMICOLON_descriptor:
  db 129, ";", 0, 0, 0, 0, 0, 0
dict_SEMICOLON:
  dq dict_COLON
  dq SEMICOLON_descriptor
  dq DOCOL
  dq dict_LIT, dict_EXIT, dict_COMMA
  dq dict_LIT, 0
  dq dict_STATE_STORE
  dq dict_EXIT

THREAD_descriptor:
  db 6, "THREAD", 0
dict_THREAD:
  dq dict_SEMICOLON
  dq THREAD_descriptor
  dq THREAD

WAIT_descriptor:
  db 4, "WAIT", 0, 0, 0
dict_WAIT:
  dq dict_THREAD
  dq WAIT_descriptor
  dq FWAIT

WAKE_descriptor:
  db 4, "WAKE", 0, 0, 0
dict_WAKE:
  dq dict_WAIT
  dq WAKE_descriptor
  dq WAKE

CLOCK_FETCH_descriptor:
  db 6, "CLOCK@", 0
dict_CLOCK_FETCH:
  dq dict_WAKE
  dq CLOCK_FETCH_descriptor
  dq CLOCK_FETCH

SLEEP_descriptor:
  db 5, "SLEEP", 0, 0
dict_SLEEP:
  dq dict_CLOCK_FETCH
  dq SLEEP_descriptor
  dq SLEEP

  ;; STATE@ ( -- n ) Get compile/interpret state
STATE_FETCH_descriptor:
  db 6, "STATE@", 0
dict_STATE_FETCH:
  dq dict_SLEEP
  dq STATE_FETCH_descriptor
  dq STATE_FETCH

  ;; STATE! ( n -- ) Set compile/interpret state
STATE_STORE_descriptor:
  db 6, "STATE!", 0
dict_STATE_STORE:
  dq dict_STATE_FETCH
  dq STATE_STORE_descriptor
  dq STATE_STORE

  ;; OUTPUT@ ( -- n ) Get output stream
OUTPUT_FETCH_descriptor:
  db 7, "OUTPUT@"
dict_OUTPUT_FETCH:
  dq dict_STATE_STORE
  dq OUTPUT_FETCH_descriptor
  dq OUTPUT_FETCH

  ;; OUTPUT! ( n -- ) Set output stream
OUTPUT_STORE_descriptor:
  db 7, "OUTPUT!"
dict_OUTPUT_STORE:
  dq dict_OUTPUT_FETCH
  dq OUTPUT_STORE_descriptor
  dq OUTPUT_STORE

  ;; DEBUG@ ( -- n ) Get debug flag
DEBUG_FETCH_descriptor:
  db 6, "DEBUG@", 0
dict_DEBUG_FETCH:
  dq dict_OUTPUT_STORE
  dq DEBUG_FETCH_descriptor
  dq DEBUG_FETCH

  ;; DEBUG! ( n -- ) Set debug flag
DEBUG_STORE_descriptor:
  db 6, "DEBUG!", 0
dict_DEBUG_STORE:
  dq dict_DEBUG_FETCH
  dq DEBUG_STORE_descriptor
  dq DEBUG_STORE

CC_SIZE_descriptor:
  db 7, "CC-SIZE"
dict_CC_SIZE:
  dq dict_DEBUG_STORE
  dq CC_SIZE_descriptor
  dq CC_SIZE

extern CALL_CC
CALL_CC_descriptor:
  db 7, "CALL/CC"
dict_CALL_CC:
  dq dict_CC_SIZE
  dq CALL_CC_descriptor
  dq CALL_CC

  ;; INTERACT ( -- ) Enable interactive mode (prompts and bye message)
INTERACT_descriptor:
  db 7, "INTERAC"
dict_INTERACT:
  dq dict_CALL_CC
  dq INTERACT_descriptor
  dq INTERACT


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
  global dict_QUIT
  global HERE

  ;; Import all the primitives from other files
  extern NEXT
  extern DOCOL
  extern DOCREATE
  extern EXIT
  extern EXECUTE
  extern BRANCH
  extern ZBRANCH
  extern CC_SIZE
  extern LIT
  extern DUP
  extern DROP
  extern OVER
  extern SWAP
  extern ROT
  extern SP_FETCH
  extern TWO_DUP
  extern TWO_DROP
  extern ADD
  extern SUB
  extern ZEROEQ
  extern EQUAL
  extern AND
  extern LSHIFT
  extern OR
  extern LESS_THAN
  extern RSHIFT
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
  extern SCAN_CHAR
  extern SOURCE_FETCH
  extern LINE_NUMBER_FETCH
  extern COLUMN_NUMBER_FETCH
  extern TYPE
  extern STATE_word
  extern OUTPUT_word
  extern FLAGS_word
  extern HERE_word
  extern LATEST_word
  extern INTERACT
  extern PROMPT
  extern BYE_MSG
  extern IACR
  extern ABORT_word
  extern COMMA
  extern ALLOT
  extern IMMED_TEST
  extern IMMED
  extern STATE_FETCH
  extern STATE_STORE
  extern OUTPUT_FETCH
  extern OUTPUT_STORE
  extern DEBUG_FETCH
  extern DEBUG_STORE
  extern THREAD
  extern FWAIT
  extern WAKE
  extern CLOCK_FETCH
  extern SLEEP
  extern CMOVE

  ;; ---- Main Program ----

_start:
  ;; Call ABORT to start the system
  ;; ABORT will clear stacks and jump to QUIT
  jmp ABORT_word

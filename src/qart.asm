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

dict_LSHIFT:
  dq dict_AND
  db 6, "LSHIFT", 0
  dq LSHIFT

dict_OR:
  dq dict_LSHIFT
  db 2, "OR", 0, 0, 0, 0, 0
  dq OR

dict_LESS_THAN:
  dq dict_OR
  db 1, "<", 0, 0, 0, 0, 0, 0
  dq LESS_THAN

dict_RSHIFT:
  dq dict_LESS_THAN
  db 6, "RSHIFT", 0
  dq RSHIFT

dict_DROP:
  dq dict_RSHIFT
  db 4, "DROP", 0, 0, 0
  dq DROP

dict_SWAP:
  dq dict_DROP
  db 4, "SWAP", 0, 0, 0
  dq SWAP

dict_ROT:
  dq dict_SWAP
  db 3, "ROT", 0, 0, 0, 0
  dq ROT

dict_TWO_DUP:
  dq dict_ROT
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
  db 67, "LIT", 0, 0, 0, 0  ; 3 | COMPILE_ONLY_FLAG = 67
  dq LIT

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
  dq EXECUTE              ; Code field

dict_BRANCH:
  dq dict_EXECUTE
  db 70, "BRANCH", 0       ; 6 | COMPILE_ONLY_FLAG = 70
  dq BRANCH

dict_ZBRANCH:
  dq dict_BRANCH
  db 71, "0BRANCH"         ; 7 | COMPILE_ONLY_FLAG = 71
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
  db 129, 92, 0, 0, 0, 0, 0, 0 ; Name (ASCII code not to confuse emacs) - IMMEDIATE (bit 7 set)
  dq BACKSLASH            ; Code field

dict_SCANC:
  dq dict_BACKSLASH       ; Link to previous
  db 5, "SCANC", 0, 0    ; Name
  dq SCAN_CHAR            ; Code field

dict_SOURCE_FETCH:
  dq dict_SCANC           ; Link to previous
  db 7, "SOURCE@"        ; Name (7 chars exactly)
  dq SOURCE_FETCH         ; Code field

dict_LINE_NUMBER_FETCH:
  dq dict_SOURCE_FETCH    ; Link to previous
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
  dq FIND                 ; ( xt 1 | c-addr u 0 )
  dq ZBRANCH, .try_number ; If not found, skip to .try_number

  ;; Found - check what to do with it
  dq DUP                  ; ( xt xt )
  dq LIT
  dq 8                    ; ( xt xt 8 )
  dq ADD                  ; ( xt name-field-addr )
  dq C_FETCH              ; ( xt length-byte )

  ;; First check compile-only in interpret mode
  dq DUP                  ; ( xt length-byte length-byte )
  dq LIT
  dq COMPILE_ONLY_FLAG ; ( xt length-byte length-byte 0x40 )
  dq AND                  ; ( xt length-byte compile-only? )
  dq STATE_FETCH          ; ( xt length-byte compile-only? state )
  dq ZEROEQ               ; ( xt length-byte compile-only? interpreting? )
  dq AND                  ; ( xt length-byte error? )
  dq ZBRANCH, .no_compile_only_error

  ;; Compile-only error path
  dq DROP                 ; ( xt )
  dq BRANCH, .compile_only_error

  .no_compile_only_error: ; ( xt length-byte )
  ;; Check if we should execute (immediate or interpreting)
  dq LIT
  dq IMMED_FLAG       ; ( xt length-byte 0x80 )
  dq AND                  ; ( xt immediate? )
  dq STATE_FETCH          ; ( xt immediate? state )
  dq ZEROEQ               ; ( xt immediate? interpreting? )
  dq OR                   ; ( xt should-execute? )
  dq ZBRANCH, .compile_it

  ;; Execute the word
  dq EXECUTE              ; Execute the word
  dq BRANCH, .loop

  .compile_it:            ; ( xt )
  ;; Compile the word
  dq COMMA
  dq BRANCH, .loop

  .compile_only_error:
  ;; Print compile-only error
  dq LIT
  dq compile_only_msg
  dq LIT
  dq compile_only_msg_len
  dq ERRTYPE              ; Print "Interpreting compile-only word: "
  ;; Need to get the word name from the dictionary entry
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
  dq ABORT_word

dict_TICK:
  dq dict_INTERPRET
  db 1, "'", 0, 0, 0, 0, 0, 0
TICK:                     ; Execution token points here
  dq DOCOL                ; Colon definition
  dq PARSE_WORD           ; ( -- c-addr u )
  dq DUP
  dq ZBRANCH, .missing_word
  dq FIND                 ; ( xt -1 | c-addr u 0 )
  dq ZBRANCH, .unknown_word
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
  dq STATE_word           ; Code field

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

  ;; LATEST ( -- addr ) Push address of HERE variable
dict_LATEST:
  dq dict_HERE          ; Link to previous
  db 6, "LATEST", 0
  dq LATEST_word           ; Code field

  ;; PROMPT ( -- ) Show prompt if interactive
  align 8
dict_PROMPT:
  dq dict_LATEST
  db 6, "PROMPT", 0
  dq PROMPT

  ;; BYE_MSG ( -- ) Show bye message if interactive  
  align 8
dict_BYE_MSG:
  dq dict_PROMPT
  db 7, "BYE-MSG"
  dq BYE_MSG

  ;; IACR ( -- ) Output CR only if interactive
  align 8  
dict_IACR:
  dq dict_BYE_MSG
  db 4, "IACR", 0, 0, 0
  dq IACR

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
  dq ABORT_word           ; Code field (primitive)

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
  dq COMMA

dict_ALLOT:
  dq dict_COMMA
  db 5, "ALLOT", 0, 0
  dq ALLOT

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
  dq ABORT_word

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
  dq IMMED_TEST

dict_IMMED:
  dq dict_IMMED_TEST
  db 5, "IMMED", 0, 0
  dq IMMED

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
  dq THREAD

dict_WAIT:
  dq dict_THREAD
  db 4, "WAIT", 0, 0, 0
  dq FWAIT

dict_WAKE:
  dq dict_WAIT
  db 4, "WAKE", 0, 0, 0
  dq WAKE

dict_CLOCK_FETCH:
  dq dict_WAKE
  db 6, "CLOCK@", 0
  dq CLOCK_FETCH

dict_SLEEP:
  dq dict_CLOCK_FETCH
  db 5, "SLEEP", 0, 0
  dq SLEEP

  ;; STATE@ ( -- n ) Get compile/interpret state
dict_STATE_FETCH:
  dq dict_SLEEP
  db 6, "STATE@", 0
  dq STATE_FETCH

  ;; STATE! ( n -- ) Set compile/interpret state  
dict_STATE_STORE:
  dq dict_STATE_FETCH
  db 6, "STATE!", 0
  dq STATE_STORE

  ;; OUTPUT@ ( -- n ) Get output stream
dict_OUTPUT_FETCH:
  dq dict_STATE_STORE
  db 7, "OUTPUT@"
  dq OUTPUT_FETCH

  ;; OUTPUT! ( n -- ) Set output stream
dict_OUTPUT_STORE:
  dq dict_OUTPUT_FETCH
  db 7, "OUTPUT!"
  dq OUTPUT_STORE

  ;; DEBUG@ ( -- n ) Get debug flag
dict_DEBUG_FETCH:
  dq dict_OUTPUT_STORE
  db 6, "DEBUG@", 0
  dq DEBUG_FETCH

  ;; DEBUG! ( n -- ) Set debug flag
dict_DEBUG_STORE:
  dq dict_DEBUG_FETCH
  db 6, "DEBUG!", 0
  dq DEBUG_STORE

dict_CC_SIZE:
  dq dict_DEBUG_STORE
  db 7, "CC-SIZE"
  dq CC_SIZE

extern CALL_CC
dict_CALL_CC:
  dq dict_CC_SIZE
  db 7, "CALL/CC"
  dq CALL_CC

  ;; INTERACT ( -- ) Enable interactive mode (prompts and bye message)
dict_INTERACT:
  dq dict_CALL_CC
  db 7, "INTERAC"
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
  global QUIT
  global ERRTYPE
  global ERRCR
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

  ;; ---- Main Program ----

_start:
  ;; Call ABORT to start the system
  ;; ABORT will clear stacks and jump to QUIT
  jmp ABORT_word

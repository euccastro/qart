\ stdlib.fth - Standard library for qart Forth

: ( 41 SCANC DROP ; IMMED ( Now we have paren comments!)

\ Stack manipulation words
: NIP SWAP DROP ;
: TUCK SWAP OVER ;
: -ROT ROT ROT ;

\ Arithmetic words
: 1+ 1 + ;
: 1- 1 - ;
: 2+ 2 + ;
: 2- 2 - ;
: 2TIMES DUP + ;
: NEGATE 0 SWAP - ;

\ Boolean words
: TRUE -1 ;
: FALSE 0 ;
: NOT 0= ;

\ Comparison words
: <> = NOT ;
: > SWAP < ;
: <= > NOT ;
: >= < NOT ;
: 0< 0 < ;
: 0> 0 > ;
: 0<> 0 <> ;

\ Memory access helpers
: +! DUP @ ROT + SWAP ! ;
: CELL+ 8 + ;
: CELL- 8 - ;
\ : CELLS 8 * ; \ Needs multiplication operator

\ I/O helpers
: SPACE 32 EMIT ;
: BL 32 ;

\ XXX: error handling
\ Skip single space after ."; print any spaces after that.
: ." SOURCE@ 1+ 34 SCANC 1- TYPE ;

\ State control words for immediate execution in compile mode
: [ 0 STATE! ; IMMED  ( Switch to interpret mode )
: ] 1 STATE! ;        ( Switch to compile mode )

\ Immediate comma - compile a value during compilation
: [,] , ; IMMED

\ LITERAL - compile a number from stack as a literal
: LITERAL LIT LIT , , ; IMMED

: IF LIT 0BRANCH , HERE @ 777 , ; IMMED
: ELSE LIT BRANCH , HERE @ 777 , HERE @ ROT ! ; IMMED
: THEN HERE @ SWAP ! ; IMMED

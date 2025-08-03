\ stdlib.fth - Standard library for qart Forth

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

\ Simple greeting to show stdlib loaded
CR 
115 EMIT 116 EMIT 100 EMIT 108 EMIT 105 EMIT 98 EMIT 32 EMIT 
108 EMIT 111 EMIT 97 EMIT 100 EMIT 101 EMIT 100 EMIT 
CR
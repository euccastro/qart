SP@ >R  \ Save initial stack pointer

\ Verify stack tracking works
SP@ R@ = ASSERT

\ Line tracking tests
\ Test that LINE# returns current line number
LINE# 8 = ASSERT  \ This is line 8
LINE# 9 = ASSERT  \ This is line 9
\ Comment line - next should be 11
LINE# 11 = ASSERT

\ Test with blank lines

LINE# 15 = ASSERT

\ Test multiple LINE# on same line
LINE# 18 = ASSERT LINE# 18 = ASSERT

\ Test LINE# after comment on same line  
LINE# 21 = ASSERT \ Should still be 21

\ Verify stack is clean after line tests
SP@ R@ = ASSERT

\ Test COL# (column tracking)
COL# 4 = ASSERT COL# 20 = ASSERT
COL#
4 = ASSERT

\ Verify stack is clean after column tests
SP@ R@ = ASSERT

\ Test +
5 5 + 10 = ASSERT
21 21 + 42 = ASSERT  
0 0 + 0 = ASSERT
-5 5 + 0 = ASSERT

\ Test + with negative numbers
-10 -20 + -30 = ASSERT
-100 50 + -50 = ASSERT
100 -50 + 50 = ASSERT

\ Test + identity (n + 0 = n)
42 0 + 42 = ASSERT
0 42 + 42 = ASSERT
-42 0 + -42 = ASSERT

SP@ R@ = ASSERT

\ Test -
5 5 - 0 = ASSERT
0 0 - 0 = ASSERT
-5 5 - -10 = ASSERT
5 10 - -5 = ASSERT

\ Test - with negative numbers
-10 -20 - 10 = ASSERT
-100 50 - -150 = ASSERT
100 -50 - 150 = ASSERT

\ Test - identity (n - 0 = n)
42 0 - 42 = ASSERT
0 42 - -42 = ASSERT
-42 0 - -42 = ASSERT

SP@ R@ = ASSERT

\ Test AND
15 3 AND 3 = ASSERT
7 4 AND 4 = ASSERT
255 1 AND 1 = ASSERT
SP@ R@ = ASSERT

\ Test DUP
5 DUP + 10 = ASSERT
0 DUP + 0 = ASSERT
42 DUP = ASSERT
-7 DUP = ASSERT
1 2 3 DUP 3 = ASSERT 3 = ASSERT 2 = ASSERT 1 = ASSERT
SP@ R@ = ASSERT

\ Test DROP
1 2 DROP 1 = ASSERT
10 20 30 40 DROP 30 = ASSERT DROP 10 = ASSERT
0 DROP
-5 DROP
SP@ R@ = ASSERT

\ Test SWAP
1 2 SWAP 1 = ASSERT 2 = ASSERT
10 20 SWAP 10 = ASSERT 20 = ASSERT
0 -5 SWAP 0 = ASSERT -5 = ASSERT
SP@ R@ = ASSERT

\ Test 2DUP
1 2 2DUP 2 = ASSERT 1 = ASSERT 2 = ASSERT 1 = ASSERT
SP@ R@ = ASSERT

5 10 2DUP 10 = ASSERT 5 = ASSERT 10 = ASSERT 5 = ASSERT  
SP@ R@ = ASSERT

-1 -2 2DUP -2 = ASSERT -1 = ASSERT -2 = ASSERT -1 = ASSERT
SP@ R@ = ASSERT

\ Test 2DROP
1 2 3 4 2DROP 2 = ASSERT 1 = ASSERT
SP@ R@ = ASSERT

10 20 30 40 2DROP 20 = ASSERT 10 = ASSERT
SP@ R@ = ASSERT

-5 -10 2DROP
SP@ R@ = ASSERT

\ Test TYPE more comprehensively (visual output)
WORD Hello TYPE CR
WORD Testing TYPE CR
WORD 123 TYPE CR
SP@ R@ = ASSERT

\ Test WORD parsing
WORD ABC 3 = ASSERT DROP
WORD XYZ 3 = ASSERT DROP
WORD 12345 5 = ASSERT DROP
WORD A 1 = ASSERT DROP
SP@ R@ = ASSERT

\ Test WORD with various strings
WORD test 4 = ASSERT DROP
WORD @#$ 3 = ASSERT DROP
SP@ R@ = ASSERT

\ ZBRANCH (0BRANCH) is compile-only - cannot test interactively
\ It reads branch offset from [NEXTIP] which points to interpreter code during interpretation

\ Test 0= (ZEROEQ)
0 0= -1 = ASSERT
1 0= 0 = ASSERT
-1 0= 0 = ASSERT
42 0= 0 = ASSERT
-42 0= 0 = ASSERT
2147483647 0= 0 = ASSERT
-2147483648 0= 0 = ASSERT
SP@ R@ = ASSERT

\ Test ' (tick) operator
\ Tick should parse the next word and push its execution token
5 ' DUP EXECUTE 5 = ASSERT 5 = ASSERT
SP@ R@ = ASSERT

42 ' DROP EXECUTE
SP@ R@ = ASSERT

5 ' DOUBLE EXECUTE 10 = ASSERT
SP@ R@ = ASSERT

\ Test tick with various words
3 4 ' + EXECUTE 7 = ASSERT
SP@ R@ = ASSERT

\ ROT not implemented yet, so test differently
1 2 ' SWAP EXECUTE 1 = ASSERT 2 = ASSERT
SP@ R@ = ASSERT

\ Test that tick pushes dictionary pointer that EXECUTE can use
' DUP ' DROP = 0 = ASSERT  \ Different words have different addresses
SP@ R@ = ASSERT

\ Test tick with FIND comparison
' DUP WORD DUP FIND ASSERT = ASSERT  \ ' DUP should equal FIND result for "DUP"
SP@ R@ = ASSERT

\ Tick should work with any defined word
100 ' DUP EXECUTE 100 = ASSERT 100 = ASSERT
SP@ R@ = ASSERT

\ Note: Testing tick with undefined words would cause ABORT
\ so we can't test error cases in this framework

\ Test OVER
1 2 OVER 1 = ASSERT DROP
1 2 OVER DROP DROP 1 = ASSERT DROP
10 20 OVER 10 = ASSERT 20 = ASSERT 10 = ASSERT
-5 7 OVER -5 = ASSERT 7 = ASSERT -5 = ASSERT
SP@ R@ = ASSERT

\ Test 2DUP
1 2 2DUP 2 = ASSERT 1 = ASSERT 2 = ASSERT 1 = ASSERT
10 20 2DUP 20 = ASSERT 10 = ASSERT 20 = ASSERT 10 = ASSERT
SP@ R@ = ASSERT

\ Test 2DROP  
1 2 3 4 2DROP 2 = ASSERT 1 = ASSERT
10 20 30 40 2DROP 20 = ASSERT 10 = ASSERT
SP@ R@ = ASSERT

\ Test = (equality)
5 5 = ASSERT
5 6 = 0 = ASSERT
0 0 = ASSERT
-1 -1 = ASSERT

\ Test = with mixed signs
5 -5 = 0 = ASSERT
-10 10 = 0 = ASSERT
0 -0 = ASSERT  \ 0 and -0 should be equal

SP@ R@ = ASSERT

\ Test 0= (zero check)
0 0= ASSERT
5 0= 0 = ASSERT
-1 0= 0 = ASSERT
SP@ R@ = ASSERT

\ Test return stack operations
5 >R R@ 5 = ASSERT R> 5 = ASSERT
SP@ R@ = ASSERT
1 2 >R 3 R> 2 = ASSERT 3 = ASSERT DROP
SP@ R@ = ASSERT

\ Test return stack with negative and zero
0 >R R@ 0 = ASSERT R> 0 = ASSERT
-42 >R R@ -42 = ASSERT R> -42 = ASSERT

\ Test multiple items on return stack
10 >R 20 >R R@ 20 = ASSERT R> 20 = ASSERT R@ 10 = ASSERT R> 10 = ASSERT

SP@ R@ = ASSERT

\ Test byte store/fetch
SP@ DUP DUP 65 SWAP C! C@ 65 = ASSERT DROP
SP@ R@ = ASSERT

\ Test C! and C@ with various byte values
0 SP@
DUP 0 SWAP C! DUP C@ 0 = ASSERT      \ Zero byte
DUP 255 SWAP C! DUP C@ 255 = ASSERT  \ Max byte value
DUP 128 SWAP C! DUP C@ 128 = ASSERT  \ Middle value
DUP 1 SWAP C! DUP C@ 1 = ASSERT      \ Min non-zero

\ Test that C! only affects one byte
DUP 305419896 SWAP !              \ 0x12345678
DUP 255 SWAP C!                   \ Change lowest byte to 0xFF
DUP @ 305420031 = ASSERT              \ Should be 0x123456FF
2DROP

SP@ R@ = ASSERT

\ Test CMOVE (character move)
CREATE CMOVE_SRC 20 ALLOT
CREATE CMOVE_DEST 20 ALLOT

\ Test zero-length copy
CMOVE_SRC CMOVE_DEST 0 CMOVE    \ Should do nothing
SP@ R@ = ASSERT

\ Test single byte copy
65 CMOVE_SRC C!                 \ Store 'A' at source
CMOVE_SRC CMOVE_DEST 1 CMOVE    \ Copy 1 byte
CMOVE_DEST C@ 65 = ASSERT       \ Should read 'A'

\ Test multi-byte copy
66 CMOVE_SRC 1 + C!             \ Store 'B' at source+1
67 CMOVE_SRC 2 + C!             \ Store 'C' at source+2
68 CMOVE_SRC 3 + C!             \ Store 'D' at source+3

\ Clear destination first
0 CMOVE_DEST C!
0 CMOVE_DEST 1 + C!
0 CMOVE_DEST 2 + C!
0 CMOVE_DEST 3 + C!

\ Copy 4 bytes
CMOVE_SRC CMOVE_DEST 4 CMOVE
CMOVE_DEST C@ 65 = ASSERT       \ 'A'
CMOVE_DEST 1 + C@ 66 = ASSERT   \ 'B'
CMOVE_DEST 2 + C@ 67 = ASSERT   \ 'C'
CMOVE_DEST 3 + C@ 68 = ASSERT   \ 'D'

\ Test partial copy (only first 2 bytes) - clear ALL destination bytes first
0 CMOVE_DEST C!                 \ Clear all destination bytes
0 CMOVE_DEST 1 + C!
0 CMOVE_DEST 2 + C!
0 CMOVE_DEST 3 + C!
CMOVE_SRC CMOVE_DEST 2 CMOVE    \ Copy only 2 bytes
CMOVE_DEST C@ 65 = ASSERT       \ 'A' should be copied
CMOVE_DEST 1 + C@ 66 = ASSERT   \ 'B' should be copied
CMOVE_DEST 2 + C@ 0 = ASSERT    \ Should remain 0
CMOVE_DEST 3 + C@ 0 = ASSERT    \ Should remain 0

SP@ R@ = ASSERT

\ Test variable-length word names (regression test)
: TESTWORD 123 ;         \ 8-character name
: VERYLONGWORDNAMETHATISTHELONGESTPOSSIBLELENGTHATSIXTYTHREE 456 ;  \ 63-character name

TESTWORD 123 = ASSERT
VERYLONGWORDNAMETHATISTHELONGESTPOSSIBLELENGTHATSIXTYTHREE 456 = ASSERT

SP@ R@ = ASSERT

\ Test user-defined word DOUBLE
21 DOUBLE 42 = ASSERT
0 DOUBLE 0 = ASSERT
-5 DOUBLE -10 = ASSERT
SP@ R@ = ASSERT

\ Test NUMBER parsing
WORD 123 NUMBER ASSERT 123 = ASSERT  \ Using WORD to get string since no literals yet
SP@ R@ = ASSERT
WORD -456 NUMBER ASSERT -456 = ASSERT
SP@ R@ = ASSERT
WORD 0 NUMBER ASSERT 0 = ASSERT
SP@ R@ = ASSERT

\ Test FIND and EXECUTE
2 WORD DOUBLE FIND -1 = ASSERT EXECUTE 4 = ASSERT
SP@ R@ = ASSERT

\ Test FIND with non-existent word
WORD NOTAWORD FIND 0 = ASSERT 2DROP
SP@ R@ = ASSERT
1 1 = ASSERT  \ Simple sanity check
SP@ R@ = ASSERT

\ Test OUTPUT variable (stdout/stderr control using new accessors)
OUTPUT@ 1 = ASSERT
2 OUTPUT!
OUTPUT@ 2 = ASSERT
1 OUTPUT!
OUTPUT@ 1 = ASSERT
SP@ R@ = ASSERT

\ Test TYPE with empty string
0 0 TYPE
SP@ R@ = ASSERT

\ Test CR (carriage return)
CR
SP@ R@ = ASSERT

SP@ R@ = ASSERT

\ Test ! and @ (store/fetch) with edge values
SP@ DUP 0 SWAP ! @ 0 = ASSERT
SP@ R@ = ASSERT

SP@ DUP -1 SWAP ! @ -1 = ASSERT
SP@ R@ = ASSERT

SP@ DUP 2147483647 SWAP ! @ 2147483647 = ASSERT
SP@ R@ = ASSERT

SP@ DUP -2147483648 SWAP ! @ -2147483648 = ASSERT
SP@ R@ = ASSERT

\ Test overwriting values
SP@ DUP 99 SWAP ! DUP @ 99 = ASSERT 
DUP -99 SWAP ! @ -99 = ASSERT
SP@ R@ = ASSERT

\ Test that ! and @ target correct addresses
0 0 0 SP@ >R
111 R@ !
222 R@ 8 + !
333 R@ 16 + !
R@ @ 111 = ASSERT
R@ 8 + @ 222 = ASSERT
R@ 16 + @ 333 = ASSERT
777 R@ 4 + !  \ Test unaligned store
R@ 4 + @ 777 = ASSERT
R> DROP
DROP DROP DROP
SP@ R@ = ASSERT

\ Verify ! and @ don't have compensating errors
1111 2222 3333 4444 5555 SP@ >R
9999 R@ 24 + !
R@ @ 5555 = ASSERT
R@ 8 + @ 4444 = ASSERT
R@ 16 + @ 3333 = ASSERT
R@ 24 + @ 9999 = ASSERT
R@ 32 + @ 1111 = ASSERT
R> DROP
DROP DROP DROP DROP DROP
SP@ R@ = ASSERT

\ Test comment functionality
\ This is a comment - it should be ignored
5 5 + 10 = ASSERT

21 21 + \ Comment after code
42 = ASSERT

\ Comment at start of line
1 2 + 3 = ASSERT

\ Multiple comments
\ in a row
\ should all be ignored
7 7 + 14 = ASSERT

100 \ Push 100 then ignore this
200 \ Push 200 then ignore this  
+ 300 = ASSERT

SP@ R@ = ASSERT

\ Test , and HERE
HERE @ DUP 565 , @ 565 = ASSERT HERE @ SWAP - 8 = ASSERT

SP@ R@ = ASSERT

\ Test LSHIFT
1 0 LSHIFT 1 = ASSERT
1 1 LSHIFT 2 = ASSERT
1 2 LSHIFT 4 = ASSERT
1 3 LSHIFT 8 = ASSERT
5 1 LSHIFT 10 = ASSERT
255 8 LSHIFT 65280 = ASSERT

SP@ R@ = ASSERT

\ Test OR
0 0 OR 0 = ASSERT
1 2 OR 3 = ASSERT
5 2 OR 7 = ASSERT
15 240 OR 255 = ASSERT
0 -1 OR -1 = ASSERT

SP@ R@ = ASSERT

\ Test CREATE
CREATE FOO
42 ,
FOO @ 42 = ASSERT

\ Test CREATE with multiple values
CREATE BAR
100 ,
200 ,
300 ,
BAR @ 100 = ASSERT
BAR 8 + @ 200 = ASSERT
BAR 16 + @ 300 = ASSERT

\ Test that CREATE'd words push their data field address
CREATE BAZ
BAZ HERE @ = ASSERT  \ BAZ should push current HERE (its data field)

SP@ R@ = ASSERT

\ Test immediate flag
CREATE TESTIM
LATEST @ IMMED? 0 = ASSERT  \ Not immediate by default
IMMED
LATEST @ IMMED? -1 = ASSERT  \ Now it's immediate

\ Test that FIND still works with immediate flag set
WORD TESTIM FIND -1 = ASSERT IMMED? -1 = ASSERT

SP@ R@ = ASSERT

\ Note: Can't test CREATE error cases without causing ABORT
\ which would terminate the test suite
\ Manual testing shows:
\ CREATE (empty word) -> "Wrong word size" error
\ CREATE TOOLONGNAME -> "Wrong word size" error  

\ Test colon definitions
: TRIPLE DUP DUP + + ;
3 TRIPLE 9 = ASSERT
7 TRIPLE 21 = ASSERT

\ Test that semicolon is immediate
' ; IMMED? -1 = ASSERT

\ Test nested definitions
: ADDONE 1 + ;
: ADDTWO ADDONE ADDONE ;
5 ADDTWO 7 = ASSERT

\ Test compiling literals
: ANSWER 42 ;
ANSWER 42 = ASSERT

SP@ R@ = ASSERT

\ Test ROT ( a b c -- b c a )
\ With 1 2 3: a=1 b=2 c=3, result should be b c a = 2 3 1
\ Top of stack after ROT is 'a' = 1
1 2 3 ROT 1 = ASSERT 3 = ASSERT 2 = ASSERT
10 20 30 ROT 10 = ASSERT 30 = ASSERT 20 = ASSERT

SP@ R@ = ASSERT

\ Test basic threading (minimal - see test-thread.fth for more)
' EXIT THREAD 0= ASSERT    \ Thread creation should succeed

SP@ R@ = ASSERT

\ Test CC-SIZE with various stack configurations
\ Test 1: Baseline (3 return addresses on return stack (incl. saved data stack address)
CC-SIZE 56 = ASSERT
\ 32 (header) + 16 (2 return addresses: abort_program+8 and QUIT's call to INTERPRET)
\ abort_program+8 points to dict_SYSEXIT, saved when DOCOL entered QUIT

\ Test 2: One item on data stack
42 CC-SIZE 64 = ASSERT DROP

\ Test 3: Multiple items on data stack
1 2 3 CC-SIZE 80 = ASSERT
2DROP DROP

\ Test 4: With return stack usage in colon definition
: TEST-R
  >R CC-SIZE 72 = ASSERT R> DROP ;
5 TEST-R

\ Test 5: Many data stack items
10 20 30 40 50   \ 5 items on data stack
CC-SIZE 96 = ASSERT
2DROP 2DROP DROP

SP@ R@ = ASSERT

\ Test constants

12345 CONSTANT TEST-CONSTANT
TEST-CONSTANT 12345 = ASSERT

SP@ R@ = ASSERT

\ Test S"

HERE @ S" 12345" 5 = ASSERT = ASSERT

SP@ R@ = ASSERT

S" 123" 3 = ASSERT
DUP C@ 49 = ASSERT
DUP 1 + C@ 50 = ASSERT
2 + C@ 51 = ASSERT

SP@ R@ = ASSERT
R> DROP
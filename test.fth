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

\ Test ADD
5 5 + 10 = ASSERT
21 21 + 42 = ASSERT  
0 0 + 0 = ASSERT
-5 5 + 0 = ASSERT

\ Test ADD with negative numbers
-10 -20 + -30 = ASSERT
-100 50 + -50 = ASSERT
100 -50 + 50 = ASSERT

\ Test ADD identity (n + 0 = n)
42 0 + 42 = ASSERT
0 42 + 42 = ASSERT
-42 0 + -42 = ASSERT

SP@ R@ = ASSERT

\ Test AND
15 3 AND 3 = ASSERT
7 4 AND 4 = ASSERT
255 1 AND 1 = ASSERT
SP@ R@ = ASSERT

\ Test DUP
5 DUP + 10 = ASSERT
0 DUP + 0 = ASSERT
SP@ R@ = ASSERT

\ Test DROP
1 2 DROP 1 = ASSERT

\ Test SWAP
1 2 SWAP 1 = ASSERT DROP
SP@ R@ = ASSERT

\ Test OVER
1 2 OVER 1 = ASSERT DROP
1 2 OVER DROP DROP 1 = ASSERT DROP
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
2 WORD DOUBLE FIND 1 = ASSERT EXECUTE 4 = ASSERT
SP@ R@ = ASSERT

\ Test FIND with non-existent word
WORD NOTAWORD FIND 0 = ASSERT 2DROP
SP@ R@ = ASSERT
1 1 = ASSERT  \ Simple sanity check
SP@ R@ = ASSERT

\ Test OUTPUT variable (stdout/stderr control)
OUTPUT @ 1 = ASSERT
2 OUTPUT !
OUTPUT @ 2 = ASSERT
1 OUTPUT !
OUTPUT @ 1 = ASSERT
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

R> DROP

WORD Done. TYPE CR
SP@ >R  \ Save initial stack pointer

\ Verify stack tracking works
SP@ R@ = 1 ASSERT

\ Test ADD
5 5 + 10 = 100 ASSERT
21 21 + 42 = 101 ASSERT  
0 0 + 0 = 102 ASSERT
-5 5 + 0 = 103 ASSERT
SP@ R@ = 104 ASSERT

\ Test DUP
5 DUP + 10 = 200 ASSERT
0 DUP + 0 = 201 ASSERT
SP@ R@ = 202 ASSERT

\ Test DROP
1 2 DROP 1 = 300 ASSERT

\ Test SWAP
1 2 SWAP 1 = 400 ASSERT DROP
SP@ R@ = 401 ASSERT

\ Test OVER
1 2 OVER 1 = 500 ASSERT DROP
1 2 OVER DROP DROP 1 = 501 ASSERT DROP
SP@ R@ = 502 ASSERT

\ Test = (equality)
5 5 = 600 ASSERT
5 6 = 0 = 601 ASSERT
0 0 = 602 ASSERT
-1 -1 = 603 ASSERT
SP@ R@ = 604 ASSERT

\ Test 0= (zero check)
0 0= 700 ASSERT
5 0= 0 = 701 ASSERT
-1 0= 0 = 702 ASSERT
SP@ R@ = 703 ASSERT

\ Test return stack operations
5 >R R@ 5 = 800 ASSERT R> 5 = 801 ASSERT
SP@ R@ = 802 ASSERT
1 2 >R 3 R> 2 = 803 ASSERT 3 = 804 ASSERT DROP
SP@ R@ = 805 ASSERT

\ Test byte store/fetch
SP@ DUP DUP 65 SWAP C! C@ 65 = 1000 ASSERT DROP
SP@ R@ = 1001 ASSERT

\ Test user-defined word DOUBLE
21 DOUBLE 42 = 1100 ASSERT
0 DOUBLE 0 = 1101 ASSERT
-5 DOUBLE -10 = 1102 ASSERT
SP@ R@ = 1103 ASSERT

\ Test NUMBER parsing
WORD 123 NUMBER 2000 ASSERT 123 = 2001 ASSERT  \ Using WORD to get string since no literals yet
SP@ R@ = 2002 ASSERT
WORD -456 NUMBER 2003 ASSERT -456 = 2004 ASSERT
SP@ R@ = 2005 ASSERT
WORD 0 NUMBER 2006 ASSERT 0 = 2007 ASSERT
SP@ R@ = 2008 ASSERT

\ Test FIND and EXECUTE
2 WORD DOUBLE FIND 1 = 3000 ASSERT EXECUTE 4 = 3001 ASSERT
SP@ R@ = 3002 ASSERT

\ Test FIND with non-existent word
WORD NOTAWORD FIND 0 = 3100 ASSERT 2DROP
SP@ R@ = 3101 ASSERT
1 1 = 3999 ASSERT  \ Simple sanity check
SP@ R@ = 3998 ASSERT

\ Test OUTPUT variable (stdout/stderr control)
OUTPUT @ 1 = 6000 ASSERT
2 OUTPUT !
OUTPUT @ 2 = 6001 ASSERT
1 OUTPUT !
OUTPUT @ 1 = 6002 ASSERT
SP@ R@ = 6003 ASSERT

\ Test TYPE with empty string
0 0 TYPE
SP@ R@ = 6004 ASSERT

\ Test CR (carriage return)
CR
SP@ R@ = 6005 ASSERT

SP@ R@ = 8000 ASSERT

\ Test ! and @ (store/fetch) with edge values
SP@ DUP 0 SWAP ! @ 0 = 10000 ASSERT
SP@ R@ = 10001 ASSERT

SP@ DUP -1 SWAP ! @ -1 = 10002 ASSERT
SP@ R@ = 10003 ASSERT

SP@ DUP 2147483647 SWAP ! @ 2147483647 = 10004 ASSERT
SP@ R@ = 10005 ASSERT

SP@ DUP -2147483648 SWAP ! @ -2147483648 = 10006 ASSERT
SP@ R@ = 10007 ASSERT

\ Test overwriting values
SP@ DUP 99 SWAP ! DUP @ 99 = 10100 ASSERT 
DUP -99 SWAP ! @ -99 = 10101 ASSERT
SP@ R@ = 10102 ASSERT

\ Test that ! and @ target correct addresses
0 0 0 SP@ >R
111 R@ !
222 R@ 8 + !
333 R@ 16 + !
R@ @ 111 = 10200 ASSERT
R@ 8 + @ 222 = 10201 ASSERT
R@ 16 + @ 333 = 10202 ASSERT
777 R@ 4 + !  \ Test unaligned store
R@ 4 + @ 777 = 10203 ASSERT
R> DROP
DROP DROP DROP
SP@ R@ = 10204 ASSERT

\ Verify ! and @ don't have compensating errors
1111 2222 3333 4444 5555 SP@ >R
9999 R@ 24 + !
R@ @ 5555 = 10300 ASSERT
R@ 8 + @ 4444 = 10301 ASSERT
R@ 16 + @ 3333 = 10302 ASSERT
R@ 24 + @ 9999 = 10303 ASSERT
R@ 32 + @ 1111 = 10304 ASSERT
R> DROP
DROP DROP DROP DROP DROP
SP@ R@ = 10305 ASSERT

\ Test comment functionality
\ This is a comment - it should be ignored
5 5 + 10 = 20000 ASSERT

21 21 + \ Comment after code
42 = 20001 ASSERT

\ Comment at start of line
1 2 + 3 = 20002 ASSERT

\ Multiple comments
\ in a row
\ should all be ignored
7 7 + 14 = 20003 ASSERT

100 \ Push 100 then ignore this
200 \ Push 200 then ignore this  
+ 300 = 20004 ASSERT

SP@ R@ = 20005 ASSERT

R> DROP

WORD Done. TYPE CR
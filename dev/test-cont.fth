\ test-cont.fth - Test continuations (CALL/CC)
\ Run separately since continuation bugs can corrupt program state

\ Test CC-SIZE returns reasonable size
CC-SIZE DUP 32 < 0= ASSERT   \ Should be at least header size (32 bytes)
DUP 100000 < ASSERT           \ Should be less than 100KB (sanity check)
DROP

\ Test basic CALL/CC - function returns normally
: TESTN
  DROP
  42
;

100 200                       \ Put some values on stack
HERE CC-SIZE DUP ALLOT        \ Allocate space for continuation
' TESTN CALL/CC               \ Capture and call
DROP                          \ Drop continuation address
42 = ASSERT                   \ Should have 42 from normal return
200 = ASSERT                  \ Original 200 should still be there
100 = ASSERT                  \ Original 100 should still be there

\ Test continuation invocation - save and invoke later
0 STATE !                     \ Ensure interpret mode
LATEST @ HERE !               \ Reset dictionary (crude but works)

\ Variable to store continuation
CREATE SAVEDK 0 ,

: SAVEC
  DUP SAVEDK !
  99
;

10 20                         \ Initial stack values
HERE CC-SIZE DUP ALLOT        \ Allocate continuation space
' SAVEC CALL/CC               \ Capture and call
DROP                          \ Drop cont-addr
30 + * .                      \ Should print 10 * (20 + 99 + 30) = 1490
CR

\ Now invoke the saved continuation with different value
10 20                         \ Reset stack
77                            \ Value to pass to continuation
SAVEDK @                      \ Get saved continuation
DUP 0= 0= ASSERT              \ Make sure we saved something
\ Direct execution - continuation is a word!
\ This will restore state right after CALL/CC with 77 on stack
SAVEDK @                      \ Get continuation again (we dropped it)
77 SWAP                       \ Put 77 under continuation
\ We can't directly test this because invoking continuation
\ will jump back and re-execute from there...

\ Test that continuation preserves return stack
: INNER
  DROP
  123
;

: OUTER
  456 >R
  HERE CC-SIZE DUP ALLOT
  ' INNER CALL/CC
  DROP
  R>
  + ;

OUTER 579 = ASSERT            \ Should be 123 + 456

\ Test multiple values on stack are preserved
: MULTI
  DROP
  11 22 33
;

1 2 3                         \ Initial values
HERE CC-SIZE DUP ALLOT        \ Allocate continuation
' MULTI CALL/CC               \ Call
DROP                          \ Drop cont-addr
33 = ASSERT                   \ Check returned values
22 = ASSERT
11 = ASSERT
3 = ASSERT                    \ Check original values still there
2 = ASSERT
1 = ASSERT

\ Test empty stack handling
: USEE
  DROP
;

HERE CC-SIZE DUP ALLOT        \ Allocate continuation
' USEE CALL/CC                \ Call with empty data stack
DROP                          \ Drop cont-addr

\ Test continuation with colon definition
: CONTC
  100
  HERE CC-SIZE DUP ALLOT
  ' TESTN CALL/CC
  DROP
  200 + ;

CONTC 242 = ASSERT            \ Should be 42 + 200

\ If we got here, basic continuation tests passed!
." Continuation tests PASSED" CR

\ Note: We can't easily test actual continuation invocation
\ because it would jump back to earlier code and re-execute.
\ That would need more complex test infrastructure.
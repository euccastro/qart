\ Timer tests for Forth
\ Test CLOCK@ for timing measurements

\ Test 1: CLOCK@ returns two values
CLOCK@ 
SWAP DROP           \ Keep just nanoseconds
DUP 1000000000 < ASSERT  \ Should be < 1 billion
DROP

\ Test 2: CLOCK@ returns reasonable seconds
CLOCK@
DROP                \ Keep just seconds
DUP 0 > ASSERT      \ Should be positive (monotonic clock)
DROP

\ Test 3: Basic < comparison
5 10 < ASSERT       \ 5 < 10 should be true (-1)
10 5 < 0= ASSERT    \ 10 < 5 should be false (0)
5 5 < 0= ASSERT     \ 5 < 5 should be false (0)
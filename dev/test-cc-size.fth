\ Test CC-SIZE primitive

\ CC-SIZE should return a reasonable size (at least header size)
CC-SIZE DUP 32 < 0= ASSERT  
DUP 100000 < ASSERT
DROP

\ CC-SIZE varies with stack depth - that's expected
\ Just verify it works with different stack depths
10 20 30
CC-SIZE 32 < 0= ASSERT
DROP DROP DROP
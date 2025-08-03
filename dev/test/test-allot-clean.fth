\ Clean test of ALLOT with continuations

\ Test ALLOT
HERE @ 100 ALLOT HERE @ SWAP - 100 = ASSERT

\ Test CC-SIZE
CC-SIZE 32 < 0= ASSERT

\ Helper to allocate continuation space
: CONT, 
  HERE @        
  CC-SIZE       
  ALLOT         
;

\ Test CALL/CC with proper allocation
: FN DROP 999 ;
10 20 30
CONT,
' FN CALL/CC
999 = ASSERT
30 = ASSERT  
20 = ASSERT
10 = ASSERT
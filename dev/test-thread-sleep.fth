\ Test threading with SLEEP
\ Demonstrates threads can sleep without blocking each other

\ Shared counter
CREATE COUNTER 0 ,

\ Thread that increments counter after sleeping
: WORKER
  DROP
  100000000 SLEEP  
  COUNTER @ 1 + COUNTER !
;

\ Create two threads
' WORKER THREAD 0= ASSERT
' WORKER THREAD 0= ASSERT

\ Parent sleeps a bit longer to let threads finish
200000000 SLEEP  

\ Both threads should have incremented counter
COUNTER @ 2 = ASSERT

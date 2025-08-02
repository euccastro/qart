\ Test threading with SLEEP
\ Demonstrates threads can sleep without blocking each other

\ Shared counter
CREATE COUNTER 0 ,

\ Thread that increments counter after sleeping
: WORKER ( mmap-base -- )
  DROP
  100000000 SLEEP     \ Sleep 100ms
  COUNTER @ 1 + COUNTER !  \ Increment counter
;

\ Create two threads
' WORKER THREAD 0= ASSERT
' WORKER THREAD 0= ASSERT

\ Parent sleeps a bit longer to let threads finish
200000000 SLEEP      \ Sleep 200ms

\ Both threads should have incremented counter
COUNTER @ 2 = ASSERT
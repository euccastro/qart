\ Test SLEEP functionality
\ Measure that SLEEP actually pauses execution

\ Test 1: Basic SLEEP call (should not crash)
1000000 SLEEP  \ Sleep for 1ms (1 million nanoseconds)

\ Test 2: Measure sleep duration
\ Get start time (nanoseconds only)
CLOCK@ DROP  \ Keep just nanoseconds

\ Sleep for 10ms (10 million nanoseconds)
10000000 SLEEP

\ Get end time (nanoseconds only)
CLOCK@ DROP

\ Calculate elapsed time
SWAP -

\ Should be at least 10 million nanoseconds
\ (may be more due to scheduling)
DUP 10000000 < 0= ASSERT

\ Should be less than 100 million nanoseconds
\ (sanity check - didn't sleep for seconds)
DUP 100000000 < ASSERT

\ Clean up
DROP
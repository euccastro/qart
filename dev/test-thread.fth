\ Threading tests for Forth
\ Run with: ./test-thread.sh

\ Test 1: Basic thread creation
' EXIT THREAD  \ Create thread that immediately exits
0= ASSERT      \ Should return 0 (success)

\ Test 2: Basic WAKE returns count  
HERE 0 WAKE    \ Wake 0 threads at HERE
0 = ASSERT     \ Should return 0 (none woken)

\ Test 3: WAKE with count returns actual woken
HERE 10 WAKE   \ Try to wake 10 threads (none waiting)
0 = ASSERT     \ Should return 0 (none actually woken)

\ Note: We can't easily test thread errors without control flow.
\ Invalid xt like 0 might "succeed" but crash the child.
\ More sophisticated tests require BEGIN/UNTIL loops.
\ Threading tests for Forth
\ Run with: ./test-thread.sh

\ Test 1: Basic thread creation
' EXIT THREAD  \ Create thread that immediately exits
0= ASSERT      \ Should return 0 (success)

\ Test 2: Thread error on unaligned execution token
1 THREAD       \ Unaligned address (not multiple of 8)
-22 = ASSERT   \ Should return -EINVAL

\ Test 3: Thread error on kernel space address (unaligned)
-1 THREAD      \ 0xFFFFFFFFFFFFFFFF = kernel space + unaligned
-22 = ASSERT   \ Should return -EINVAL

\ Test 4: Thread error on aligned kernel space address
-8 THREAD      \ 0xFFFFFFFFFFFFFFF8 = kernel space but 8-byte aligned
-22 = ASSERT   \ Should return -EINVAL

\ Test 5: Basic WAKE returns count  
HERE 0 WAKE    \ Wake 0 threads at HERE
0 = ASSERT     \ Should return 0 (none woken)

\ Test 6: WAKE with count returns actual woken
HERE 10 WAKE   \ Try to wake 10 threads (none waiting)
0 = ASSERT     \ Should return 0 (none actually woken)
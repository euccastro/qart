\ Complete test for SCANC
\ The input buffer contains this test file when we run it

\ Test 1: Search for 'C' (should find it in "Complete" on line 1)
67 SCANC DUP . CR
0 < 0= ASSERT

\ Test 2: Search for a character not in comment (should not find)
126 SCANC DUP . CR  
-1 = ASSERT

\ Test 3: Search for space (should find one quickly)
32 SCANC DUP . CR
0 < 0= ASSERT

\ Test 4: Search for newline (should find at end of line)
10 SCANC DUP . CR
0 < 0= ASSERT
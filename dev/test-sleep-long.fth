\ Test SLEEP with values > 1 second

\ Simple test: Just verify it doesn't crash with large values
1500000000 SLEEP  \ 1.5 seconds
2000000000 SLEEP  \ 2 seconds

\ Test exact 1 second boundary
1000000000 SLEEP  \ Exactly 1 second
999999999 SLEEP   \ Just under 1 second

\ If we got here without crashing, the division logic works
\ Test SOURCE@ word
\ Get current position in buffer
SOURCE@ DUP . CR

\ It should point to somewhere in the input buffer
\ Let's read the character at that position
C@ DUP . CR

\ It should be a printable ASCII character
DUP 32 < 0= SWAP 127 < AND ASSERT
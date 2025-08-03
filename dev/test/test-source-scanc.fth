\ Test SOURCE@ with SCANC
\ Save current position
SOURCE@ >R

\ Skip to next closing paren
41 SCANC some text here)

\ Get new position
SOURCE@ 

\ Should be different from original  
R> = 0= ASSERT

\ The distance should have been returned by SCANC
DUP 0 < 0= ASSERT
. CR
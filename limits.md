# System Limitations

This document describes known limitations of the qart Forth implementation.

## Word Name Length
- **Maximum: 7 characters**
- Dictionary structure allocates exactly 8 bytes for length (1 byte) + name (7 bytes)
- Words longer than 7 characters cannot be defined
- Example: `VERYLONGWORD` will abort with "Wrong word size" error

## Stack Sizes
- **Data Stack**: 1024 items (8KB)
  - No overflow checking
  - No underflow checking
  - Silent corruption if exceeded
- **Return Stack**: 512 items (4KB)
  - Limits recursion depth
  - Limits nested colon definitions
  - No overflow/underflow protection

## Numeric Limitations
- **Integer size**: 64-bit signed only (-2^63 to 2^63-1)
- **No unsigned support**: All numbers treated as signed
- **Base**: Decimal only (base 10)
  - No hex, binary, or other base support
- **NUMBER overflow**: No detection when parsing strings
  - Large numbers silently wrap around
  - Example: "99999999999999999999" produces incorrect result
- **Arithmetic overflow**: Operations wrap on overflow
  - No carry/overflow flags checked

## Memory Access
- **No bounds checking**: @ and ! can access any address
  - Can read/write arbitrary memory
  - Can cause segmentation faults
- **Buffer size**: 20 bytes for number conversion
  - Sufficient for 64-bit integers but hardcoded

## Dictionary Limitations  
- **Fixed entry size**: 24 bytes per word header
  - 8 bytes link
  - 8 bytes name (including length byte with immediate flag in bit 7)
  - 8 bytes code field
  - Additional space for word body (colon definitions, CREATE data)
- **Dictionary space**: 512KB allocated in .bss
  - New words created at runtime grow the dictionary
  - No bounds checking on dictionary overflow
- **Linear search**: O(n) lookup time
  - Performance degrades with dictionary size
- **No hash tables**: Simple linked list only
- **Case sensitive**: No case-insensitive option

## Missing Error Handling
- **Stack operations**: No checking for sufficient items
  - DUP on empty stack causes segfault
  - Binary operations need 2 items

## I/O Limitations
- **No string literals**: Cannot type strings in source code
  - Must use character codes with EMIT
  - No S" or ." operators
- **Input buffer size**: 1MB (1048576 bytes)
  - Single line cannot exceed this size
  - Files piped to stdin cannot exceed this size (entire file read at once)
  - Test files must fit in buffer since REFILL reads all available input
- **No file operations**: Cannot open, read, or write files
- **No formatted output**: Only decimal numbers and single characters
- **No input editing**: No backspace or line editing

## Compiler Limitations
- **No DOES>**: Cannot define defining words with custom runtime
- **No POSTPONE**: Cannot compile immediate words
- **No [COMPILE]**: Cannot force compilation of immediate words
- **No [ ]**: Cannot switch STATE during compilation
- **No LITERAL**: Must rely on automatic number compilation
- **No compiler security**: Can corrupt dictionary with invalid operations
- **No recursion support**: Cannot reference word being defined
- **No forward references**: Words must be defined before use

## General Limitations
- **No floating point**: Integer-only system
- **No ALLOT**: Cannot reserve dictionary space
- **No heap allocation**: Only dictionary growth supported
- **Single-threaded**: No concurrency support
- **Linux x86-64 only**: Not portable to other platforms
- **No signal handling**: Ctrl-C kills process ungracefully
- **No saved images**: Cannot save/load system state

## Typical Forth Features Not Yet Implemented
- Variables and constants (VARIABLE, CONSTANT words)
- Control structures (IF/THEN, loops)
- DOES> for custom runtime behavior
- Vocabulary/wordlist support
- File I/O
- Exception handling
- String literals (S", .")
- Double-cell operations (2@, 2!)
- Memory operations (MOVE, FILL)
- Additional stack operations (ROT, PICK, ROLL)
# System Limitations

This document describes known limitations of the qart Forth implementation.

## Word Name Length
- **Maximum: 7 characters**
- Dictionary structure allocates exactly 8 bytes for length (1 byte) + name (7 bytes)
- Words longer than 7 characters cannot be defined
- Example: `VERYLONGWORD` would be truncated or cause issues

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
- **Fixed entry size**: 24 bytes per word
  - 8 bytes link
  - 8 bytes name (including length byte)
  - 8 bytes code field
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
  - Buffer allocated in .bss section to keep executable small

## Compiler Limitations
- **No immediate words**: Cannot mark words as immediate
  - No compile-time execution control
- **No compilation mode**: STATE exists but unused
  - Cannot define new words interactively
  - No : and ; operators
- **No CREATE/DOES>**: Cannot define defining words
- **No compiler security**: Can corrupt dictionary

## General Limitations
- **No floating point**: Integer-only system
- **No dynamic memory**: No ALLOT, HERE, or heap
- **Single-threaded**: No concurrency support yet
- **Linux x86-64 only**: Not portable to other platforms

## Typical Forth Features Not Yet Implemented
- Variables and constants
- Control structures (IF/THEN, loops)
- Defining words (CREATE, DOES>)
- Vocabulary/wordlist support
- File I/O
- Exception handling
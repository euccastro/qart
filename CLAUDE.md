# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a hobby project exploring x86_64 assembly programming with the goal of bootstrapping a Forth-like language with advanced features including:
- Scheme-like features and continuations
- Structured concurrency
- Functional effect systems (inspired by Missionary in Clojure)
- Persistent data structures
- Host interfacing for graphical desktop applications

## Development Environment

- **Platform**: Ubuntu 24.04 on x86_64
- **Assembler**: NASM (Intel syntax)
- **Linker**: GNU ld
- **Debugger**: GDB
- **Build System**: Make

## Build Commands

```bash
make          # Build all targets
make clean    # Remove build artifacts
make run      # Build and run the current program
```

## Project Structure

- `qart.asm` - Main file with data section and entry point
- `flow.asm` - Control flow primitives (NEXT, DOCOL, EXIT)
- `stack.asm` - Stack manipulation (LIT, DUP, DROP)
- `arithmetic.asm` - Arithmetic operations (ADD)
- `memory.asm` - Memory access (TO_R, R_FROM, R_FETCH, FETCH, STORE, C_FETCH, C_STORE, STATE_word, OUTPUT_word)
- `io.asm` - I/O operations (DOT, NUMBER, EMIT, KEY, TYPE)
- `test.asm` - Testing primitives (ASSERT)
- `dictionary.asm` - Dictionary lookup (FIND)
- `input.asm` - Input buffer management (REFILL)
- `word.asm` - Word parsing (PARSE_WORD/WORD)
- `forth.inc` - Common definitions (register assignments, constants)
- `Makefile` - Build configuration
- `test.fth` - Regression test suite (run with `./qart < test.fth`)
- Object files and executables are built in the root directory

## Assembly Conventions

- Using NASM with Intel syntax
- x86_64 Linux system calls
- Entry point is `_start`
- Following standard Linux x86_64 ABI conventions

## Current Status

- Working Forth interpreter with modular assembly files:
  - Dictionary-based NEXT inner interpreter (ITC model)
  - Data stack with DSP in R15
  - Return stack with RSTACK in R14
  - Instruction pointer (IP) in RBX
  - Dictionary structure with linked list
  - DOCOL runtime for colon definitions
  - Core primitives: LIT, DUP, DROP, ADD, >R, R>, R@, @, !, C@, C!, DOT (.), EXIT, EXECUTE, FIND, NUMBER, REFILL, WORD, SP@ (stack pointer fetch)
  - I/O primitives: EMIT for characters, KEY for input
- Input system:
  - 1MB input buffer (in .bss section) with position/length tracking
  - Line-based input with newline stripping
  - Direct pointer returns from WORD (no copying)
- Test program demonstrates:
  - Basic arithmetic: 21 + 21 = 42
  - Colon definition: DOUBLE word that duplicates and adds
  - EXECUTE primitive: dynamically calling DUP
  - Line input and word parsing

## Technical Decisions

- Using NASM assembler with Intel syntax (not GNU AS)
- Using System V AMD64 ABI for Linux x86_64
- Building with GNU ld linker
- Makefile set up for easy compilation
- Indirect Threaded Code (ITC) for good balance of size/speed/flexibility
- Classical two-stack memory model (data stack + return stack)
- R15 dedicated to data stack pointer
- R14 dedicated to return stack pointer
- Dictionary-based execution model

## Register Usage

Please maintain `register-cheatsheet.md` as we use more registers. When implementing new functionality:
1. Check the cheatsheet before choosing registers
2. Update the "Our Usage" column when dedicating a register
3. Add new registers to the "Used in Our Forth Implementation" section
4. Document why each register choice was made (required vs arbitrary)

## System Call Documentation

Please maintain `syscall-abi.md` with information about:
1. New system calls as we use them
2. Any surprising behavior or gotchas discovered
3. Register preservation/clobbering rules
4. Error handling patterns

## Implementation Roadmap

### Completed
- Dictionary-based ITC interpreter with NEXT mechanism
- Data stack operations (R15)
- Return stack operations (R14) with >R, R>, R@
- Memory access: @, !, C@, C!
- Stack primitives: DUP, DROP, SWAP, OVER, 2DUP, 2DROP, SP@
- Arithmetic: ADD (+), SUB (-), = (EQUAL), 0= (ZEROEQ), AND, OR, LSHIFT
- Control flow: BRANCH, 0BRANCH (ZBRANCH) using branchless CMOVcc optimization
- I/O: DOT (.) for decimal output, EMIT for character output, KEY for character input, TYPE for string output
- Testing: ASSERT for unit test support (prints line:col on failure)
- Output control: OUTPUT variable for stdout/stderr switching
- Debug control: FLAGS variable (bit 0 = verbose ASSERT)
- EXECUTE for dynamic execution of words
- Dictionary structure with 7-char names
- FIND for dictionary lookups (returns dictionary pointer as execution token)
- NUMBER for parsing integers (returns success flag)
- DOCOL runtime for colon definitions
- INTERPRET for processing input (colon definition)
- EXIT for returns and program termination
- Input buffer (1MB in .bss) with position/length tracking
- REFILL for reading full lines from stdin
- WORD for parsing space-delimited tokens from input buffer
- Working colon definitions: CR, ERRTYPE, ERRCR demonstrating OUTPUT switching
- QUIT/ABORT architecture: QUIT is the main interpreter loop, ABORT clears stacks and jumps to QUIT
- Tick operator (') for getting execution tokens without executing
- Line tracking: LINE# and COL# for debugging support
- Comments: \ (BACKSLASH) for rest-of-line comments
- **Dictionary building**: HERE @, LATEST @, , (comma) for compilation
- **CREATE**: Creates new dictionary entries with DOCREATE runtime
- **Immediate words**: IMMED to set immediate flag, IMMED? to test it
- **Colon compiler**: : and ; for defining new words! 
- **Full metacircular Forth**: Can now define new words from within Forth itself

### Immediate Next Steps
1. **Additional stack words** - ROT, -ROT, 2SWAP, NIP, TUCK
2. **Control flow structures** - IF/THEN/ELSE, BEGIN/UNTIL/WHILE/REPEAT
3. **More arithmetic** - *, /, MOD, <, >, XOR, INVERT, NEGATE
4. **Constants and variables** - CONSTANT, VARIABLE, ALLOT
5. **Memory words** - MOVE, FILL, CMOVE

### Future Steps
1. String handling - S" for string literals, ." for printing
2. Advanced features (continuations, effects, concurrency)
3. Persistent data structures
4. Low-level networking - raw socket programming for future distributed computing
5. Host interfacing for graphical desktop applications

## Key Documentation Files

- `register-cheatsheet.md` - x86_64 register reference and our usage
- `syscall-abi.md` - Linux system call conventions and preservation rules

## Implementation Notes

### Session Learnings
- EXECUTE implementation: Primitives must handle their own `jmp NEXT` after execution
- Stack ordering for EXECUTE: execution token should be on top of stack
- Character I/O uses a temporary buffer for syscalls (can't pass stack directly)
- KEY returns -1 for EOF, following Unix convention
- Test programs can be built incrementally in the data section using dictionary references
- **Register preservation is critical**: Accidentally clobbering RBX (IP) causes crashes. Always preserve IP, DSP, RSTACK
- **NASM reserved words**: WORD is reserved, had to rename to PARSE_WORD internally
- **Direct pointers are more efficient**: WORD returns pointers into input_buffer rather than copying
- **Constants in forth.inc**: Shared constants like INPUT_BUFFER_SIZE should go in forth.inc to avoid duplication
- **sys_read behavior**: Always includes newline when user presses Enter; REFILL strips it for cleaner parsing
- **Primitive structure**: Assembly primitives don't use code pointer indirection like colon definitions
- **Dictionary name field alignment**: Names need exactly 8 bytes total (1 length byte + up to 7 name chars). Tick (') has `db 1, "'", 0, 0, 0, 0, 0, 0` - that's 1 + 1 + 6 = 8 bytes
- **LIT behavior in threaded code**: `dq dict_LIT, value` creates TWO cells; must account for this when calculating branch offsets
- **MOV doesn't set flags**: Must use explicit TEST or CMP before conditional jumps; this caught us with ZBRANCH
- **Branchless optimizations**: CMOVcc for conditional data movement (ZBRANCH), SETcc for flag-to-value conversion (ZEROEQ)
- **Forth architecture constraint**: Primitives shouldn't call other words; use colon definitions for that (this is why INTERPRET should be a colon word)
- **NASM syntax**: Multiple values on one line need commas: `dq dict_LIT, 42` not `dq dict_LIT 42`
- **Execution tokens are dictionary pointers**: Not CFAs! This unifies threaded code and EXECUTE semantics
- **DOCOL receives dictionary pointer in RDX**: Both from NEXT and EXECUTE, enabling uniform handling
- **NUMBER returns proper flag**: (n -1) on success, (c-addr u 0) on failure - can distinguish zero from error
- **OUTPUT variable controls streams**: Colon definitions like ERRTYPE save/restore OUTPUT for stderr output
- **Test suite**: `test.fth` contains regression tests; run with `./test.sh` or `./test-verbose.sh` for detailed output
- **FLAGS variable for debugging**: Bit 0 controls verbose ASSERT output (pass/fail messages to stderr)
- **SP@ for memory testing**: Returns stack pointer, useful for getting valid addresses in tests
- **Input buffer size matters**: Increased from 256 bytes to 1MB to handle large test files
- **.bss section for large buffers**: Keeps executable size small while allowing large runtime buffers
- **FIND return values**: When found returns (xt -1), when not found returns (c-addr u 0)
- **Standard Forth true value**: All boolean operations now return -1 for true, 0 for false (EQUAL, ZEROEQ, FIND, NUMBER)
- **Branch offset calculations**: Must account for LIT using two cells when calculating offsets
- **0BRANCH is compile-only**: Cannot be used interactively; it reads offset from [IP] which points to interpreter code during interpretation, not user input
- **Immediate flag in length byte**: Bit 7 of name length byte indicates immediate words; FIND must mask with 0x7F when comparing
- **DOCREATE runtime**: CREATE'd words push their data field address (after code field), not their dictionary pointer
- **Dictionary growth in .bss**: New words created at runtime go in dict_space (.bss), not .data section
- **HERE management**: Points to next free dictionary space; advanced by comma (,)
- **Immediate words and STATE**: Immediate words execute even during compilation (STATE=1); normal words are compiled
- **Colon definition flow**: : switches DOCREATE→DOCOL, sets STATE=1; loops compiling until ; which is immediate
- **Word name validation**: CREATE enforces 1-7 character names using (u=0)|(u&~7) test
- **Stack notation reminder**: Forth comments show rightmost as TOS: (a b c) means c is on top
- **CREATE usage in :**: Colon calls CREATE directly (CREATE calls WORD internally)

### Critical Things to Watch For
1. **Register preservation**: Never clobber RBX (IP), R15 (DSP), or R14 (RSTACK) in primitives
2. **Stack direction**: Data stack grows downward (sub DSP, 8 to push)
3. **NASM reserved words**: Check if a word name conflicts before using it
4. **Buffer bounds**: Always validate positions against buffer length
5. **Transient strings**: WORD results are only valid until next REFILL
6. **Forth stack notation**: (2 1) means 1 is TOS (top of stack), not that 2 is on top! This is the opposite of visual/pictorial representations. Be very careful when writing tests.
7. **Dictionary name field syntax**: Must use commas between all elements! `db 1, "'", 0, 0, 0, 0, 0, 0` not `db 1 "'", 0, 0, 0, 0, 0, 0`. Missing commas cause incorrect assembly and dictionary misalignment.

### Development Approach
**Collaborative implementation**: The developer implements features while asking questions about design decisions, optimization opportunities, and debugging issues. Claude provides guidance, spots bugs, and suggests improvements without implementing directly unless requested.

### Current Status - Working Forth Compiler!
**Major milestone achieved**: Full colon compiler implementation
- **Working compiler**: Can define new words with : and ; 
- **Immediate word support**: ; is immediate and executes during compilation
- **STATE-aware compilation**: Properly handles compile vs interpret modes
- **Literal compilation**: Numbers are compiled as LIT instructions
- **Nested definitions**: New words can call previously defined words
- **Dictionary management**: CREATE builds proper entries, LATEST tracks newest
- **Error handling**: Word length validation, unknown word detection
- **Test suite**: Comprehensive tests for all primitives and compiler

### Recent Accomplishments
- Implemented \ (BACKSLASH) for rest-of-line comments
- Merged comprehensive store tests into main test.fth
- Added comments to all tests explaining what they verify
- Updated ASSERT to show line:col instead of numeric IDs
- Tests now use comments to clarify test purposes without over-explaining mechanics
- Added comprehensive tests for all words in alphabetical order:
  - Stack manipulation: DUP, DROP, SWAP, OVER, 2DUP, 2DROP, SP@
  - Arithmetic: ADD (+), = (EQUAL), 0= (ZEROEQ), AND
  - Memory: @, !, C@, C!, >R, R>, R@
  - I/O: DOT (.), EMIT, KEY, TYPE
  - Control: EXECUTE, BRANCH, 0BRANCH (noted as compile-only)
  - Parsing: WORD, NUMBER, FIND
  - System: REFILL, EXIT, STATE, OUTPUT, FLAGS, ASSERT
  - Comments: \ (BACKSLASH)
  - Debugging: LINE#, COL#
- Refactored to QUIT/ABORT architecture:
  - Removed test_program entry point
  - QUIT is now the main interpreter loop (colon definition)
  - ABORT clears stacks and jumps to QUIT
  - _start simply calls ABORT to initialize the system
- Standardized boolean return values: FIND and NUMBER now return -1 for success (consistent with EQUAL, ZEROEQ)
- Implemented tick operator (') for getting execution tokens
- Fixed ZBRANCH understanding: it consumes the flag it tests

### Test Organization
- test.sh runs all test files with headers showing which file is running
- test-verbose.sh takes a filename argument for debugging specific tests with PASS/FAIL output
- Merged store-test.fth into main test.fth to avoid test fragmentation
- All tests in test.fth now have descriptive comments

### Next Actions
1. Implement:
   - **Compiler words** - CREATE, : (colon), ; (semicolon) with STATE support
   - **Additional stack words** - ROT, -ROT, 2SWAP, NIP, TUCK
   - **Control flow** - IF/THEN/ELSE, BEGIN/UNTIL/WHILE/REPEAT

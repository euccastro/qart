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
  - Core primitives: LIT, DUP, DROP, ADD, >R, R>, R@, @, !, C@, C!, DOT (.), EXIT, EXECUTE, FIND, NUMBER, REFILL, WORD
  - I/O primitives: EMIT for characters, KEY for input
- Input system:
  - 256-byte input buffer with position/length tracking
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
- Stack primitives: DUP, DROP, SWAP, OVER
- Arithmetic: ADD, = (EQUAL), 0= (ZEROEQ) using branchless SETcc technique
- Control flow: BRANCH, 0BRANCH (ZBRANCH) using branchless CMOVcc optimization
- I/O: DOT (.) for decimal output, EMIT for character output, KEY for character input, TYPE for string output
- Testing: ASSERT for unit test support with numeric IDs
- Output control: OUTPUT variable for stdout/stderr switching
- EXECUTE for dynamic execution of words
- Dictionary structure with 7-char names
- FIND for dictionary lookups (returns dictionary pointer as execution token)
- NUMBER for parsing integers (returns success flag)
- DOCOL runtime for colon definitions
- INTERPRET for processing input (colon definition)
- EXIT for returns and program termination
- Input buffer (256 bytes) with position/length tracking
- REFILL for reading full lines from stdin
- WORD for parsing space-delimited tokens from input buffer
- Working colon definitions: CR, ERRTYPE, ERRCR demonstrating OUTPUT switching

### Immediate Next Steps
1. **Tick operator (')** - Push execution token without executing
   - Needed for testing EXECUTE and for metaprogramming
2. **Compiler words** - CREATE, : (colon), ; (semicolon)
   - STATE variable exists but needs compiler support
3. **QUIT** - Outer interpreter loop that calls REFILL and INTERPRET
4. **Additional stack words** - ROT, -ROT, 2SWAP, NIP, TUCK

### Future Steps
1. Control flow: IF, THEN, ELSE, BEGIN, UNTIL
2. More stack manipulation: ROT, -ROT, 2DUP, 2DROP
3. Constants and variables
4. Advanced features (continuations, effects, concurrency)
5. Low-level networking - raw socket programming for future distributed computing

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
- **Dictionary name field alignment**: 7-character names need exactly 8 bytes total (1 length + 7 chars), no extra padding needed
- **LIT behavior in threaded code**: `dq dict_LIT, value` creates TWO cells; must account for this when calculating branch offsets
- **MOV doesn't set flags**: Must use explicit TEST or CMP before conditional jumps; this caught us with ZBRANCH
- **Branchless optimizations**: CMOVcc for conditional data movement (ZBRANCH), SETcc for flag-to-value conversion (ZEROEQ)
- **Forth architecture constraint**: Primitives shouldn't call other words; use colon definitions for that (this is why INTERPRET should be a colon word)
- **NASM syntax**: Multiple values on one line need commas: `dq dict_LIT, 42` not `dq dict_LIT 42`
- **Execution tokens are dictionary pointers**: Not CFAs! This unifies threaded code and EXECUTE semantics
- **DOCOL receives dictionary pointer in RDX**: Both from NEXT and EXECUTE, enabling uniform handling
- **NUMBER returns proper flag**: (n 1) on success, (c-addr u 0) on failure - can distinguish zero from error
- **OUTPUT variable controls streams**: Colon definitions like ERRTYPE save/restore OUTPUT for stderr output

### Critical Things to Watch For
1. **Register preservation**: Never clobber RBX (IP), R15 (DSP), or R14 (RSTACK) in primitives
2. **Stack direction**: Data stack grows downward (sub DSP, 8 to push)
3. **NASM reserved words**: Check if a word name conflicts before using it
4. **Buffer bounds**: Always validate positions against buffer length
5. **Transient strings**: WORD results are only valid until next REFILL

### Development Approach
**Collaborative implementation**: The developer implements features while asking questions about design decisions, optimization opportunities, and debugging issues. Claude provides guidance, spots bugs, and suggests improvements without implementing directly unless requested.

### Next Action
Implement the tick operator (') to enable pushing execution tokens without executing them. This will allow proper testing of EXECUTE and enable metaprogramming capabilities.
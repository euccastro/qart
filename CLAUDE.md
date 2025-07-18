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
- `memory.asm` - Memory access (TO_R, R_FROM, R_FETCH, FETCH, STORE, C_FETCH, C_STORE)
- `io.asm` - I/O operations (DOT, NUMBER, EMIT, KEY)
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
- Stack primitives: DUP, DROP
- Arithmetic: ADD
- I/O: DOT (.) for decimal output, EMIT for character output, KEY for character input
- EXECUTE for dynamic execution of words
- Dictionary structure with 7-char names
- FIND for dictionary lookups
- NUMBER for parsing integers
- DOCOL runtime for colon definitions
- EXIT for returns and program termination
- Input buffer (256 bytes) with position/length tracking
- REFILL for reading full lines from stdin
- WORD for parsing space-delimited tokens from input buffer

### Immediate Next Steps
1. **Stack manipulation** - SWAP, OVER for more complex operations
2. **INTERPRET** - Main interpreter loop
   - Use WORD to get next token
   - Use FIND to look it up
   - Execute if found, try NUMBER if not
3. **Compiler words** - CREATE, : (colon), ; (semicolon)
4. **QUIT** - Outer interpreter loop that calls REFILL and INTERPRET

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

### Critical Things to Watch For
1. **Register preservation**: Never clobber RBX (IP), R15 (DSP), or R14 (RSTACK) in primitives
2. **Stack direction**: Data stack grows downward (sub DSP, 8 to push)
3. **NASM reserved words**: Check if a word name conflicts before using it
4. **Buffer bounds**: Always validate positions against buffer length
5. **Transient strings**: WORD results are only valid until next REFILL

### Next Action
Implement SWAP and OVER stack manipulation words, then build INTERPRET to create a basic REPL.
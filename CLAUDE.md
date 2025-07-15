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

- `*.asm` - Assembly source files (NASM Intel syntax)
- `Makefile` - Build configuration
- Object files and executables are built in the root directory

## Assembly Conventions

- Using NASM with Intel syntax
- x86_64 Linux system calls
- Entry point is `_start`
- Following standard Linux x86_64 ABI conventions

## Current Status

- Working Forth interpreter in qart.asm with:
  - Dictionary-based NEXT inner interpreter (ITC model)
  - Data stack with DSP in R15
  - Return stack with RSTACK in R14
  - Instruction pointer (IP) in RBX
  - Dictionary structure with linked list
  - DOCOL runtime for colon definitions
  - Core primitives: LIT, DUP, DROP, ADD, >R, R>, R@, @, !, C@, C!, DOT (.), EXIT
  - FIND word for dictionary lookup
  - NUMBER word for parsing integers
- Test program demonstrates:
  - Basic arithmetic: 21 + 21 = 42
  - Colon definition: DOUBLE word that duplicates and adds

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
- I/O: DOT (.) for decimal output
- Dictionary structure with 7-char names
- FIND for dictionary lookups
- NUMBER for parsing integers
- DOCOL runtime for colon definitions
- EXIT for returns and program termination

### Immediate Next Steps
1. **EXECUTE** - Execute word given execution token
2. **Input Buffer** - Basic line input with KEY
3. **WORD** - Parse next word from input buffer
4. **INTERPRET** - Main interpreter loop
   - Use WORD to get next token
   - Use FIND to look it up
   - Execute if found, try NUMBER if not
5. **Compiler words** - CREATE, : (colon), ; (semicolon)

### Future Steps
1. Basic I/O: EMIT for character output, KEY for input
2. Control flow: IF, THEN, ELSE, BEGIN, UNTIL
3. More stack manipulation: SWAP, OVER, ROT
4. Constants and variables
5. Advanced features (continuations, effects, concurrency)

## Key Documentation Files

- `register-cheatsheet.md` - x86_64 register reference and our usage
- `syscall-abi.md` - Linux system call conventions and preservation rules
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
  - NEXT inner interpreter (ITC model)
  - Data stack with DSP in RBP
  - Instruction pointer (IP) in RBX
  - Core primitives: LIT, ADD, DOT (.), EXIT
- Test program demonstrates: 10 20 + 15 + .

## Technical Decisions

- Using NASM assembler with Intel syntax (not GNU AS)
- Using System V AMD64 ABI for Linux x86_64
- Building with GNU ld linker
- Makefile set up for easy compilation
- Indirect Threaded Code (ITC) for good balance of size/speed/flexibility
- Classical two-stack memory model (data stack + return stack)
- RBP dedicated to data stack pointer

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
- Basic ITC interpreter with NEXT mechanism
- Data stack operations
- LIT for inline literals
- ADD arithmetic primitive
- DOT (.) for output
- EXIT for clean termination

### Next Steps
1. Stack primitives: DUP, DROP, SWAP, OVER
2. More arithmetic: SUB (-), MUL (*), DIV (/)
3. Basic I/O: EMIT, KEY
4. Dictionary structure with FIND
5. Number parsing (NUMBER)
6. INTERPRET loop for interactive use
7. Compiler words: CREATE, : (colon), ; (semicolon)
8. Control flow: IF, THEN, ELSE, BEGIN, UNTIL
9. Advanced features (continuations, effects, concurrency)

## Key Documentation Files

- `register-cheatsheet.md` - x86_64 register reference and our usage
- `syscall-abi.md` - Linux system call conventions and preservation rules
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

- Minimal "Hello World" implementation complete (hello_nasm.asm)
- Began Forth interpreter bootstrap with tiny incremental steps:
  - Step 0.1: Basic stack in memory with manual push/pop (step01_stack.asm)
  - Step 0.2: Push/pop subroutines with multiple values (step02_push_pop.asm)
  - Next: Step 0.3 - Threaded list without interpreter
- Using Indirect Threaded Code (ITC) model
- Stack pointer in RBP, growing downward

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

### Completed Steps
0.1. Stack in memory - allocate buffer, manual push/pop
0.2. Push/pop subroutines - reusable functions

### Next Tiny Steps
0.3. Threaded list (no interpreter) - array of addresses, manual walk
0.4. Code vs Data - introduce LIT primitive
0.5. NEXT mechanism - the inner interpreter
0.6. Add primitive - first arithmetic operation

### Future Steps
1. Basic I/O primitives (EMIT, KEY)
2. Static dictionary structure  
3. Number parsing
4. INTERPRET loop
5. Compiler words
6. Advanced features (continuations, effects, etc.)

## Key Documentation Files

- `register-cheatsheet.md` - x86_64 register reference and our usage
- `syscall-abi.md` - Linux system call conventions and preservation rules
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
- Ready to begin Forth interpreter bootstrap
- Explored NASM data directives (db, dw, dd, dq), sections, and alignment
- Created example files demonstrating various assembly concepts

## Technical Decisions

- Using NASM assembler with Intel syntax (not GNU AS)
- Using System V AMD64 ABI for Linux x86_64
- Building with GNU ld linker
- Makefile set up for easy compilation

## Next Steps for Forth Implementation

- Design basic Forth memory layout (dictionary, stacks)
- Implement core interpreter loop (NEXT, DOCOL, EXIT)
- Create primitive words
- Add input parsing and number conversion
- Build up toward advanced features (continuations, effects, etc.)
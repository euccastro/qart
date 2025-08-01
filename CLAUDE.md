# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a hobby project exploring x86_64 assembly programming with the goal of bootstrapping a Forth-like language with advanced features including:
- Structured concurrency with functional effect systems (current focus)
- Scheme-like features (continuations designed with caller-managed memory)
- Functional effect systems inspired by Missionary in Clojure
- Persistent data structures
- Host interfacing for graphical desktop applications

Currently preparing to implement OS-level threading (clone/futex) as the foundation for structured concurrency and Missionary-style task composition.

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

The project is organized to separate source code, development tools, documentation, and build artifacts:

- **Source code** in `src/` - All Forth interpreter assembly files including threading
- **Development tools** in `dev/` - Tests and utility scripts
- **Documentation** in `doc/` - Reference materials kept separate from code
- **Build outputs** in `out/` - All compiled binaries go here, keeping source directories clean
- **Build system** - Makefile at project root

### Directory Details

- `src/` - Forth interpreter implementation
  - `qart.asm` - Main file with data section and entry point
  - `flow.asm` - Control flow primitives (NEXT, DOCOL, EXIT)
  - `stack.asm` - Stack manipulation (LIT, DUP, DROP)
  - `arithmetic.asm` - Arithmetic operations (ADD)
  - `memory.asm` - Memory access (TO_R, R_FROM, R_FETCH, FETCH, STORE, C_FETCH, C_STORE, STATE_word, OUTPUT_word)
  - `io.asm` - I/O operations (DOT, NUMBER, EMIT, KEY, TYPE)
  - `debug.asm` - Testing primitives (ASSERT)
  - `dictionary.asm` - Dictionary lookup (FIND)
  - `input.asm` - Input buffer management (REFILL)
  - `word.asm` - Word parsing (PARSE_WORD/WORD)
  - `thread.asm` - Threading primitives (THREAD, WAIT, WAKE)
  - `forth.inc` - Common definitions (register assignments, constants)
- `dev/` - Development tools and tests
  - `test.fth` - Regression test suite (run with `dev/test.sh`)
  - `test.sh` - Test runner script
  - `test-verbose.sh` - Verbose test runner
- `doc/` - Documentation
  - `register-cheatsheet.md` - Register usage reference
  - `syscall-abi.md` - System call documentation
  - `clone-flags.md` - Clone flags reference
- `out/` - Build output directory (object files and executables)
- `var/` - Variable runtime data (test output, temporary files)

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

Please maintain `doc/register-cheatsheet.md` as we use more registers. When implementing new functionality:
1. Check the cheatsheet before choosing registers
2. Update the "Our Usage" column when dedicating a register
3. Add new registers to the "Used in Our Forth Implementation" section
4. Document why each register choice was made (required vs arbitrary)

## System Call Documentation

Please maintain `doc/syscall-abi.md` with information about:
1. New system calls as we use them
2. Any surprising behavior or gotchas discovered
3. Register preservation/clobbering rules
4. Error handling patterns

See also `doc/clone-flags.md` for detailed information about clone() system call flags.

## Assembly Code Formatting

Please follow these emacs-style assembly formatting conventions for consistency:

### Comment Styles
- **3 semicolons (;;;)**: File headers and major section dividers (rarely used)
- **2 semicolons (;;)**: Comments about the next function/label or describing a group of code
- **1 semicolon (;)**: Inline comments on the same line as code

### Indentation
- **Global labels**: Start at column 0 (no indentation)
- **Local labels**: Indent 2 spaces (e.g., `.loop:`)
- **Instructions**: Indent to align with longest mnemonic (typically 8-10 spaces)
- **Directives**: Same indentation as instructions

### Spacing
- **Label colons**: Attach directly to label name (e.g., `NEXT:` not `NEXT :`)
- **Inline comments**: Align to a consistent column (typically 40-50)
- **Operands**: Single space after instruction mnemonic
- **Section directives**: Blank line before `section` declarations

### Example
```asm
  ;; flow.asm - Control flow for the Forth interpreter
  ;; Contains NEXT, DOCOL, EXIT and other flow control primitives

  section .text

  ;; NEXT - The inner interpreter
  ;; Dictionary-based execution: IP points to dictionary entry addresses
NEXT:
  mov rdx, [IP]           ; Get dictionary entry address
  add IP, 8               ; Advance IP
  mov rax, [rdx+16]       ; Get code field from dict entry
  jmp rax                 ; Execute the code

thread_func:
  ;; Print message 3 times with delays
  mov r12, 3
.loop:
  mov rax, SYS_write
  mov rdi, 1              ; stdout
```

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
- **Threading primitives**: THREAD, WAIT (FWAIT), WAKE with automatic cleanup and thread-local R13 state
- **ROT**: Stack rotation primitive
- **< (LESS_THAN)**: Comparison operator for numbers
- **CLOCK@**: High-resolution monotonic time
- **SLEEP**: Nanosecond-precision sleep
- **Thread-local state accessors**: STATE@/!, OUTPUT@/!, DEBUG@/!
- **CC-SIZE**: Calculate memory needed for continuations (preparation for CALL/CC)

### Immediate Next Steps
1. **Additional stack words** - -ROT, 2SWAP, NIP, TUCK
2. **Control flow structures** - IF/THEN/ELSE, BEGIN/UNTIL/WHILE/REPEAT
3. **Build synchronization library** - Mutexes, semaphores, channels as Forth words using WAIT/WAKE

### Threading API Design

After analyzing Forth philosophy and our Linux primitives, we've designed a minimal threading API:

**Core primitives** (assembly implementations):
```forth
THREAD ( xt -- error )      \ Execute xt in new thread, 0 on success
WAIT ( addr expected -- )   \ Atomic check-and-wait (futex wait)
WAKE ( addr n -- n' )       \ Wake n waiters, return number woken
```

**Key design decisions**:
1. **Minimal primitive set** - Only 3 words provide complete threading capability
2. **Automatic cleanup** - Threads clean up their stacks when the xt returns (no THREAD-EXIT needed)
3. **Resource passing** - Thread receives mmap base on data stack: `( mmap-base -- )`
4. **Memory barriers hidden** - WAIT/WAKE implementations handle all necessary fences/barriers internally
5. **No built-in mutex** - Mutexes are a Forth library pattern, not a primitive
6. **Composition over features** - Complex synchronization built from simple parts

**Example mutex implementation** (pure Forth):
```forth
: MUTEX@ ( addr -- )          \ Acquire mutex
  BEGIN
    DUP @ 0= IF               \ Is it free?
      1 OVER !                \ Try to take it
      EXIT
    THEN
    DUP 1 WAIT                \ Wait if value is 1
  AGAIN ;

: MUTEX! ( addr -- )          \ Release mutex
  0 OVER !                    \ Release (WAKE ensures visibility)
  1 WAKE DROP ;               \ Wake one waiter
```

**Philosophy**: Following Forth tradition, we provide the minimal set of primitives that can't be written in Forth itself. All memory ordering complexities (mfence, etc.) are encapsulated in the primitive implementations, never exposed to Forth code. This keeps the language simple while ensuring correctness on all architectures.

### Future Steps
1. String handling - S" for string literals, ." for printing
2. Advanced features (continuations, effects, concurrency)
3. Persistent data structures
4. Low-level networking - raw socket programming for future distributed computing
5. Host interfacing for graphical desktop applications

## Continuations Design (Complete, Implementation Postponed)

### CALL/CC Implementation Plan

We're implementing Scheme-style call-with-current-continuation to enable advanced control flow:

**Syntax**: `' MY-FN CALL/CC` (consistent with EXECUTE)

**What a continuation captures**:
- Complete data stack state at time of capture
- Complete return stack state at time of capture  
- Instruction pointer (pointing to instruction after CALL/CC)
- Note: Does NOT capture R13 (STATE/OUTPUT/DEBUG) - these remain as current environment

**How CALL/CC works**:
1. Pop execution token from data stack
2. Save current continuation (both stacks + IP after CALL/CC)
3. Package as continuation object
4. Execute the function with continuation on stack
5. If function returns normally, continue after CALL/CC
6. If continuation is invoked later, restore saved state and jump to saved IP

**Key design decisions**:
- **Stack-based syntax** (`' FN CALL/CC` not `CALL/CC FN`) for consistency with EXECUTE and to enable dynamic function selection
- **IP points after CALL/CC** to exclude the capture mechanism from the continuation (avoiding infinite loops)
- **Function boundary via EXIT** - when called function returns, we know it's done (natural Forth mechanism)
- **Full stack capture** - Unlike delimited continuations, we capture entire stack states (simpler to implement)

**Example usage**:
```forth
: EXAMPLE
  10 20
  ' MY-FN CALL/CC  
  30 + * ;         ( if normal return: 10 * (20 + 5 + 30) = 550 )
                   ( if K invoked with 99: 10 * (20 + 99 + 30) = 1490 )

: MY-FN ( cont -- n )
  GLOBAL-K !       ( save continuation )
  5 ;              ( return 5 normally )
```

**Why call/cc pattern**: Prevents self-referential infinite loops - the continuation represents "everything after CALL/CC" but excludes the capture itself.

**Future**: After CALL/CC works, we'll explore delimited continuations (reset/shift) for more composable control flow needed for effect systems.

### Continuation Object Structure

Continuations are packaged as executable objects with the following memory layout:

```
Offset  Contents
+0:     Code pointer (to RESTORE-CONT primitive)
+8:     Data stack depth (in cells)
+16:    Return stack depth (in cells)
+24:    Saved IP (instruction pointer)
+32:    Data stack contents (variable size)
+?:     Return stack contents (variable size)
```

This structure makes continuations directly executable - calling EXECUTE on a continuation jumps to RESTORE-CONT, which knows how to unpack and restore the saved state. Importantly, continuations capture only control state, not environmental state (R13 flags stay current).

### Continuation Memory Management

**Caller-Managed Approach**:
We avoid GC requirements with explicit memory management:

```forth
CC-SIZE ( -- n )                    \ Returns bytes needed for continuation
CALL/CC ( cont-addr xt -- cont-addr )  \ Captures into user-provided buffer
```

**Usage example**:
```forth
: EXAMPLE
  HERE CC-SIZE ALLOT        ( cont-addr )
  ' MY-FN CALL/CC           ( cont-addr )
  DUP GLOBAL-K ! DROP ;     ( save for later use )

: MY-FN ( cont -- n )       
  K2 !                      ( handler saves continuation )
  5 ;                       ( return normally )
```

**Key insights**:
- User allocates memory (stack, dictionary, or custom heap)
- cont-addr IS the continuation (directly executable)
- No hidden allocations or GC needed
- Very Forth-like explicit memory management

**Implementation status**: Design complete, implementation postponed to focus on higher-level concurrency abstractions first.

## Structured Concurrency Design (Current Focus)

Moving toward Missionary-style functional effects with structured concurrency:

**Task Contract** (inspired by Missionary):
```forth
\ Task signature: ( success-xt failure-xt -- cancel-xt )
\ - Takes success and failure callbacks
\ - Returns a cancellation thunk
\ - Does nothing until callbacks are provided (lazy)
```

**Execution Model - Trampoline**:
- Tasks return "what to do next" rather than doing it directly
- Avoids need for continuations or stack switching
- Natural composition through callback chaining

**Key Design Decisions**:
1. **Top-level parking only** - Can only yield between tasks, not within
2. **Stack-neutral steps** - Each async step must leave stacks balanced
3. **Thread values through callbacks** - Not through Forth stacks
4. **OS threads first** - Build on clone/futex before green threads

**Implementation Path**:
1. ~~Implement OS-level threading (clone/futex)~~ ✓ Complete
2. Add synchronization (channels/mutexes) - In Progress
3. Build trampoline executor
4. Create task combinators (BIND-THEN, RACE, etc.)
5. Add syntax sugar (M/SP, M/?) to hide callback complexity

## Key Documentation Files

- `doc/register-cheatsheet.md` - x86_64 register reference and our usage
- `doc/syscall-abi.md` - Linux system call conventions and preservation rules
- `doc/clone-flags.md` - Detailed reference for clone() system call flags

## Implementation Notes

### Key Implementation Learnings

#### Core Architecture
- **Execution tokens are dictionary pointers**: Not CFAs! This unifies threaded code and EXECUTE semantics
- **DOCOL receives dictionary pointer in RDX**: Both from NEXT and EXECUTE, enabling uniform handling
- **Primitives must handle their own `jmp NEXT`**: Unlike colon definitions
- **Dictionary name field**: Exactly 8 bytes (1 length + up to 7 name chars)
- **Immediate flag in bit 7**: FIND masks with 0x7F when comparing names
- **SYSEXIT for clean termination**: No special 0 sentinel in EXIT; ABORT runs abort_program (QUIT then SYSEXIT)

#### Stack and Memory
- **Stack notation**: (a b c) means c is TOS - rightmost is top!
- **LIT uses TWO cells**: `dq dict_LIT, value` - account for this in branch offsets
- **.bss for large buffers**: Keeps executable small (1MB input buffer)
- **Direct pointers**: WORD returns pointers into input_buffer, no copying

#### Boolean and Control Flow  
- **Standard true is -1**: All comparisons return -1/0 (EQUAL, ZEROEQ, FIND, NUMBER)
- **MOV doesn't set flags**: Use TEST/CMP before conditional jumps
- **0BRANCH is compile-only**: Can't use interactively
- **Branchless optimizations**: CMOVcc (ZBRANCH), SETcc (ZEROEQ)

#### Threading and Concurrency
- **CLONE_VM for thread creation**: Share memory, avoid CLONE_THREAD
- **Clone returns 0 in child, PID in parent**: Test with `test rax, rax`
- **Each thread needs 8KB mmap**: 3KB return, 4KB data, 1KB system stack
- **Futex needs 4-byte alignment**: Use `align 4` directive
- **Reserved words**: 'lock' (prefix), 'wait' (FWAIT) - our WAIT is FWAIT
- **XCHG is always atomic**: Useful for simple locks

#### I/O and Testing
- **KEY returns -1 for EOF**: Unix convention
- **sys_read includes newline**: REFILL strips it
- **Test with `dev/test.sh`**: Or `dev/test-verbose.sh` for PASS/FAIL output

### Recent Session Insights
- **Continuations don't require GC**: Our caller-managed design avoids GC by having users explicitly allocate continuation storage.
- **Forth offers unique opportunities**: The return stack provides power that most languages lack, potentially allowing "deep parking" in async code, though we're choosing explicit parking points for clarity.
- **Graphics/UI options analyzed**: 
  - X11 requires networking (it's a network protocol)
  - Framebuffer/DRM/input would take over the whole screen
  - OpenGL/Vulkan need C library linkage (no pure network protocol)
  - Terminal UI (ANSI escapes) offers immediate visual feedback with zero dependencies
- **Threading as foundation**: OS-level threading (clone/futex) chosen as the starting point for async work because it:
  - Provides real parallelism
  - Forces us to solve synchronization properly
  - Stays in pure computation land (no external dependencies)
  - Sets patterns for later cooperative concurrency

### Critical Things to Watch For
1. **Register preservation**: Never clobber RBX (IP), R15 (DSP), or R14 (RSTACK) in primitives
2. **Stack direction**: Data stack grows downward (sub DSP, 8 to push)
3. **NASM reserved words**: Check if a word name conflicts before using it
4. **Buffer bounds**: Always validate positions against buffer length
5. **Transient strings**: WORD results are only valid until next REFILL
6. **Forth stack notation**: (2 1) means 1 is TOS (top of stack), not that 2 is on top! This is the opposite of visual/pictorial representations. Be very careful when writing tests.
7. **Dictionary name field syntax**: Must use commas between all elements! `db 1, "'", 0, 0, 0, 0, 0, 0` not `db 1 "'", 0, 0, 0, 0, 0, 0`. Missing commas cause incorrect assembly and dictionary misalignment.
8. **Data alignment**: Multi-word structures (timespec, futex vars, etc.) should be explicitly aligned with `align 8` or `align 4`. x86-64 tolerates misalignment but it hurts performance and isn't portable.
9. **sys_clone behavior with stacks**: The child gets a NEW stack pointer (passed in RSI), so push/pop around sys_clone only affects parent. Child must calculate its own values from its stack pointer.
10. **Callee-saved registers inherit across clone**: R12-R15, RBX, RBP all preserve their values in the child. RBP ideal for passing mmap base (though we push/pop defensively for C interop).
11. **Thread-local state via R13**: Using bit fields in R13 gives automatic thread-local STATE/OUTPUT/DEBUG without any memory access or synchronization overhead.

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
- dev/test.sh runs all test files with headers showing which file is running
- dev/test-verbose.sh runs tests with PASS/FAIL output for debugging
- Merged store-test.fth into main dev/test.fth to avoid test fragmentation
- All tests in dev/test.fth now have descriptive comments

### Threading Implementation - COMPLETE!
- **THREAD primitive working**: Creates OS threads with clone() that share memory via CLONE_VM
- **Stack layout per thread** (8KB total):
  - Bottom 3KB: Return stack
  - Middle 4KB: Data stack  
  - Top 1KB: System stack
- **Execution model**: Thread executes mini-program `[user_xt, dict_THREAD_CLEANUP]`
- **Automatic cleanup**: THREAD_CLEANUP unmaps memory when thread exits
- **Thread-local flags via R13**: Each thread has its own STATE/OUTPUT/DEBUG in R13 bit fields
- **Clean register usage**: Uses RBP (callee-saved) for mmap base, with defensive push/pop for C interop safety

### Timing and Synchronization Primitives
- **CLOCK@ ( -- seconds nanoseconds )**: Returns monotonic time via clock_gettime(CLOCK_MONOTONIC)
  - Used for timing measurements
  - Nanosecond precision (though actual resolution depends on hardware)
- **SLEEP ( nanoseconds -- )**: Sleep for specified nanoseconds via nanosleep()
  - Handles durations > 1 second by dividing into seconds/nanoseconds
  - Yields to scheduler (not busy-waiting)
  - Essential for thread coordination without burning CPU
- **< (LESS_THAN)**: Added for time comparisons in tests

### Thread-Local State - COMPLETE!
**Solution implemented**: STATE, OUTPUT, and FLAGS are now packed into R13 as bit fields:
- Bit 0: STATE (compile/interpret)
- Bits 1-2: OUTPUT (stdin/stdout/stderr)  
- Bit 3: DEBUG (verbose ASSERT)
- Bits 4-63: Reserved

This gives automatic thread-local behavior since each thread has its own R13. Accessor words (STATE@/STATE!/OUTPUT@/OUTPUT!/DEBUG@/DEBUG!) provide clean interface.

### Next Actions
1. Additional stack words - ROT (done), -ROT, 2SWAP, NIP, TUCK
2. Control flow - IF/THEN/ELSE, BEGIN/UNTIL/WHILE/REPEAT
3. Build synchronization library - Mutexes, semaphores, channels as Forth words using WAIT/WAKE

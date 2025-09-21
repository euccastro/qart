# SDL3 Integration Guide

This document describes how to use SDL3 from assembly in the qart project.

## Overview

SDL3 is statically linked into qart, allowing direct calls to SDL functions from assembly code using the System V AMD64 ABI. No wrapper code is needed - SDL functions can be called directly following standard calling conventions.

## Build Configuration

### Static Library Location
- **SDL3 Source**: `third_party/SDL-release-3.2.22/`
- **Static Library**: `third_party/SDL-release-3.2.22/build/libSDL3.a` (5.8MB)
- **Headers**: `third_party/SDL-release-3.2.22/include/SDL3/`

### Makefile Integration
```makefile
SDL3_DIR = third_party/SDL-release-3.2.22
SDL3_BUILD_DIR = $(SDL3_DIR)/build
SDL3_LIB = $(SDL3_BUILD_DIR)/libSDL3.a
SDL3_LDLIBS = -lm -ldl -lpthread -lrt
```

The static library is automatically linked during the build process.

### Features Enabled
- **Graphics**: OpenGL, OpenGL ES, Vulkan rendering
- **Windowing**: X11 support
- **Audio**: ALSA, PulseAudio, PipeWire
- **Input**: Full HID, joystick, gamepad support
- **All subsystems**: Audio, Video, GPU, Render, Camera, Joystick, Haptic

## Calling SDL Functions from Assembly

### System V ABI Quick Reference
- **Parameters**: RDI, RSI, RDX, RCX, R8, R9 (first 6), then stack
- **Return value**: RAX (integers/pointers), XMM0 (floats)
- **Caller-saved**: RAX, RCX, RDX, RSI, RDI, R8-R11, XMM0-XMM15
- **Callee-saved**: RBX, RBP, R12-R15

### Function Declaration Pattern
```asm
;; Declare external SDL functions
extern SDL_Init
extern SDL_CreateWindow
extern SDL_Quit

;; Call with proper parameter setup
mov rdi, SDL_INIT_VIDEO
call SDL_Init
test rax, rax           ; Check return value
```

### Parameter Passing Examples

#### Single Parameter
```asm
mov rdi, SDL_INIT_VIDEO
call SDL_Init           ; int SDL_Init(Uint32 flags)
```

#### Multiple Parameters (≤6)
```asm
;; SDL_CreateWindow(title, x, y, w, h, flags)
mov rdi, window_title   ; const char* title
mov rsi, x_pos         ; int x
mov rdx, y_pos         ; int y
mov rcx, width         ; int w
mov r8, height         ; int h
mov r9, flags          ; Uint32 flags
call SDL_CreateWindow
```

#### 7+ Parameters
```asm
;; Push extra parameters in reverse order
push param8
push param7
mov rdi, param1        ; First 6 in registers
;; ... set rsi through r9
call some_function
add rsp, 16           ; Clean stack (2 params × 8 bytes)
```

## SDL3 Constants

SDL3 constants are now defined in Forth using CONSTANT definitions in `src/sdl.fth`:

### Current Constants Available
```forth
32 CONSTANT SDL_INIT_VIDEO        \ 0x00000020
4 CONSTANT SDL_WINDOW_SHOWN       \ 0x00000004
```

### Usage in Forth Code
```forth
SDL_INIT_VIDEO SDL_INIT           \ Initialize SDL video subsystem
0= IF ." SDL init failed" THEN    \ Check for success (0 = success)
```

### Adding New Constants
To add more SDL constants, simply append to `src/sdl.fth`:
```forth
\ Add to src/sdl.fth:
16 CONSTANT SDL_INIT_AUDIO        \ 0x00000010
512 CONSTANT SDL_INIT_JOYSTICK    \ 0x00000200
805306368 CONSTANT SDL_WINDOWPOS_CENTERED  \ 0x2FFF0000
```

### Renderer (SDL_render.h)
```asm
%define SDL_RENDERER_ACCELERATED  0x00000002
%define SDL_RENDERER_PRESENTVSYNC 0x00000004
```

## Example: Basic Window Creation

```asm
section .data
    window_title db "Qart SDL3 Window", 0

section .text
    extern SDL_Init, SDL_CreateWindow, SDL_CreateRenderer
    extern SDL_SetRenderDrawColor, SDL_RenderClear, SDL_RenderPresent
    extern SDL_Delay, SDL_DestroyRenderer, SDL_DestroyWindow, SDL_Quit

    %define SDL_INIT_VIDEO 0x00000020
    %define SDL_WINDOWPOS_CENTERED 0x2FFF0000
    %define SDL_WINDOW_SHOWN 0x00000004

sdl_demo:
    ;; Initialize SDL
    mov rdi, SDL_INIT_VIDEO
    call SDL_Init
    test rax, rax
    jnz .error

    ;; Create window
    mov rdi, window_title
    mov rsi, SDL_WINDOWPOS_CENTERED
    mov rdx, SDL_WINDOWPOS_CENTERED
    mov rcx, 640
    mov r8, 480
    mov r9, SDL_WINDOW_SHOWN
    call SDL_CreateWindow
    test rax, rax
    jz .error
    mov rbx, rax                   ; Save window

    ;; Create renderer
    mov rdi, rbx
    mov rsi, -1
    mov rdx, 0
    call SDL_CreateRenderer
    mov r12, rax                   ; Save renderer

    ;; Set red background
    mov rdi, r12
    mov rsi, 255                   ; Red
    mov rdx, 0                     ; Green
    mov rcx, 0                     ; Blue
    mov r8, 255                    ; Alpha
    call SDL_SetRenderDrawColor

    ;; Clear and present
    mov rdi, r12
    call SDL_RenderClear
    mov rdi, r12
    call SDL_RenderPresent

    ;; Wait 2 seconds
    mov rdi, 2000
    call SDL_Delay

    ;; Cleanup
    mov rdi, r12
    call SDL_DestroyRenderer
    mov rdi, rbx
    call SDL_DestroyWindow
    call SDL_Quit
    ret

.error:
    call SDL_Quit
    mov rax, 1
    ret
```

## Integration with Forth

### Available SDL Words

SDL functions are implemented as Forth words in `src/sdl.asm` using exact SDL naming (e.g., `SDL_Init`, `SDL_CreateWindow`, `SDL_Delay`). Constants are defined in `src/sdl.fth`.

### Working Example

See `dev/test/manual/sdl-minimal.fth` for a complete working example demonstrating:
- SDL initialization and error checking
- Constant usage (SDL_INIT_VIDEO, SDL_WINDOW_SHOWN)
- Proper handling of headless environments
- SDL cleanup

Run the example with the provided script:
```bash
dev/sdl-test.sh dev/test/manual/sdl-minimal.fth
```

The script automatically loads SDL constants from `src/sdl.fth` before running the test.

### Error Handling
Always check SDL function return values:
- **SDL_Init**: Returns 0 on success, negative on error
- **Pointer returns**: NULL indicates failure
- **SDL_GetError()**: Can be called to get error string

### Memory Management
- SDL creates its own objects (windows, renderers, textures)
- Always destroy SDL objects in reverse creation order
- Call `SDL_Quit()` before program termination

## Header File Locations

Key SDL3 headers for constants and function signatures:
- `SDL3/SDL.h` - Main header, includes most others
- `SDL3/SDL_init.h` - Initialization constants
- `SDL3/SDL_video.h` - Window and display functions
- `SDL3/SDL_render.h` - 2D rendering
- `SDL3/SDL_events.h` - Event handling
- `SDL3/SDL_audio.h` - Audio subsystem
- `SDL3/SDL_joystick.h` - Joystick/gamepad input

## Building Debug Version

For debugging SDL3 internals:

```bash
# Create debug build
mkdir -p third_party/SDL-release-3.2.22/build-debug
cd third_party/SDL-release-3.2.22/build-debug

cmake .. \
  -DCMAKE_BUILD_TYPE=Debug \
  -DSDL_SHARED=OFF \
  -DSDL_STATIC=ON \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON

make -j$(nproc)

# Use in Makefile
SDL3_LIB = $(SDL3_BUILD_DIR)-debug/libSDL3.a
```

Debug version enables:
- Full debug symbols (`-g3`)
- No optimization (`-O0`)
- SDL debug assertions
- GDB can step into SDL source

## Performance Notes

- **Static linking**: No runtime library dependencies
- **Direct calls**: No FFI overhead, just function call cost
- **Register preservation**: Only save registers you actually need
- **SDL overhead**: Modern SDL3 is well-optimized, minimal overhead for basic operations

## Examples in Project

See `dev/test/manual/sdl-minimal.fth` for a working Forth example, or run:
```bash
dev/sdl-test.sh dev/test/manual/sdl-minimal.fth
```

The example demonstrates:
- SDL initialization with error handling
- Proper use of SDL constants
- Graceful handling of headless environments
- SDL cleanup

For implementing new SDL functionality, see `src/sdl.asm` for the pattern of wrapping SDL functions as Forth words.
;;; sdl.asm - SDL3 wrapper functions and constants for qart
;;; This file contains SDL3 function wrappers and related constants
;;;
;;; Textual order in the source to match parameter order in documentation. This
;;; means TOS is the last argument, and TOS+8*(args-N) is the Nth argument. For
;;; example, for 3 arguments:
;;;
;;; TOS+16 -> rdi (first arg)
;;; TOS+8 -> rsi (second arg)
;;; TOS -> rdx (third arg)
;;;
;;; Then add 24 to DSP to pop them all.

  %include "forth.inc"

  section .data
  ;; SDL3 initialization constants
  SDL_INIT_TIMER          equ 0x00000001
  SDL_INIT_AUDIO          equ 0x00000010
  SDL_INIT_VIDEO          equ 0x00000020
  SDL_INIT_JOYSTICK       equ 0x00000200
  SDL_INIT_HAPTIC         equ 0x00001000
  SDL_INIT_GAMEPAD        equ 0x00002000
  SDL_INIT_EVENTS         equ 0x00004000
  SDL_INIT_SENSOR         equ 0x00008000
  SDL_INIT_CAMERA         equ 0x00010000

  ;; SDL3 window constants
  SDL_WINDOWPOS_UNDEFINED equ 0x1FFF0000
  SDL_WINDOWPOS_CENTERED  equ 0x2FFF0000
  SDL_WINDOW_FULLSCREEN   equ 0x00000001
  SDL_WINDOW_OPENGL       equ 0x00000002
  SDL_WINDOW_SHOWN        equ 0x00000004
  SDL_WINDOW_HIDDEN       equ 0x00000008
  SDL_WINDOW_BORDERLESS   equ 0x00000010
  SDL_WINDOW_RESIZABLE    equ 0x00000020
  SDL_WINDOW_MINIMIZED    equ 0x00000040
  SDL_WINDOW_MAXIMIZED    equ 0x00000080

  ;; SDL3 renderer constants
  SDL_RENDERER_SOFTWARE      equ 0x00000001
  SDL_RENDERER_ACCELERATED   equ 0x00000002
  SDL_RENDERER_PRESENTVSYNC  equ 0x00000004

  section .text
  ;; External SDL3 function declarations
  extern SDL_Init
  extern SDL_Quit
  extern SDL_CreateWindow
  extern SDL_DestroyWindow
  extern SDL_Delay
  extern SDL_GetError

  ;; Forth system symbols
  extern NEXT
  extern DSP, RSTACK, TLS

  ;; SDL dictionary word definitions
  ;; Following qart's descriptor-before-entry layout

  ;; SDL-INIT ( flags -- success? )
  ;; Initialize SDL with given subsystem flags
  ;; Returns 0 on success, error code on failure
  ;; *Call on main thread*
SDL_Init_descriptor:
  db 8, "SDL_Init"
  align 8
dict_SDL_Init:
  extern dict_FIRST_SDL    ; Link to main dictionary chain
  dq dict_FIRST_SDL
  dq SDL_Init_descriptor
  dq SDL_Init_code
SDL_Init_code:
  mov rdi, [DSP]          ; Get flags from data stack
  add DSP, 8              ; Pop flags
  call SDL_Init           ; Call SDL_Init(flags)
  sub DSP, 8              ; Push result
  mov [DSP], rax          ; Store result (0 = success, <0 = error)
  jmp NEXT

  ;; SDL-QUIT ( -- )
  ;; Shutdown SDL and cleanup all subsystems
SDL_Quit_descriptor:
  db 8, "SDL_Quit"
  align 8
dict_SDL_Quit:
  dq dict_SDL_Init        ; Link to previous word
  dq SDL_Quit_descriptor
  dq SDL_Quit_code
SDL_Quit_code:
  call SDL_Quit           ; No parameters, no return value
  jmp NEXT

  ;; SDL-CREATE-WINDOW ( title w h flags -- window )
  ;; Create an SDL window with specified parameters
  ;; Returns window pointer or 0 on failure

  ;; Temporary placeholder until we have S"
SDL_CreateWindow_descriptor:
  db 16, "SDL_CreateWindow"
  align 8
dict_SDL_CreateWindow:
  dq dict_SDL_Quit
  dq SDL_CreateWindow_descriptor
  dq SDL_CreateWindow_code
SDL_CreateWindow_code:
  mov rdi, [DSP+24]       ; title (1st parameter)
  mov rsi, [DSP+16]        ; width (2nd parameter)
  mov rdx, [DSP+8]        ; width (2nd parameter)
  mov rcx, [DSP]          ; flags (4rd parameter)
  add DSP, 24             ; Pop 3 parameters, keep space for result
  call SDL_CreateWindow
  mov [DSP], rax          ; Store window pointer (or NULL on failure)
  jmp NEXT

  ;; SDL-DESTROY-WINDOW ( window -- )
  ;; Destroy an SDL window
SDL_DestroyWindow_descriptor:
  db 17, "SDL_DestroyWindow"
  align 8
dict_SDL_DestroyWindow:
  dq dict_SDL_CreateWindow
  dq SDL_DestroyWindow_descriptor
  dq SDL_DestroyWindow_code
SDL_DestroyWindow_code:
  mov rdi, [DSP]          ; Get window pointer
  add DSP, 8              ; Pop window pointer
  call SDL_DestroyWindow
  jmp NEXT

  ;; SDL-DELAY ( ms -- )
  ;; Delay execution for specified milliseconds
dict_SDL_Delay:
  dq dict_SDL_DestroyWindow
  dq SDL_Delay_descriptor
  dq SDL_Delay_code
SDL_Delay_descriptor:
  db 9, "SDL_Delay"
  align 8
SDL_Delay_code:
  mov rdi, [DSP]          ; Get milliseconds
  add DSP, 8              ; Pop milliseconds
  call SDL_Delay
  jmp NEXT


  ;; Export the last SDL dictionary word for linking to main chain
  global dict_LAST_SDL
  dict_LAST_SDL equ dict_SDL_Delay

  ;; Mark stack as non-executable (for security)
  section .note.GNU-stack noalloc noexec nowrite progbits

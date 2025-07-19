; forth.inc - Common definitions for all Forth assembly files

; Register assignments
%define IP rbx              ; Instruction Pointer
%define DSP r15             ; Data Stack Pointer  
%define RSTACK r14          ; Return Stack Pointer

; Constants
INPUT_BUFFER_SIZE equ 256   ; Size of input line buffer
NEWLINE equ 10              ; ASCII newline character
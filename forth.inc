; forth.inc - Common definitions for all Forth assembly files

; Register assignments
%define IP rbx              ; Instruction Pointer
%define DSP r15             ; Data Stack Pointer  
%define RSTACK r14          ; Return Stack Pointer

; Constants
INPUT_BUFFER_SIZE equ 1048576  ; Size of input line buffer (1MB)
NEWLINE equ 10                 ; ASCII newline character
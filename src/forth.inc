; forth.inc - Common definitions for all Forth assembly files

; Register assignments
%define IP r12              ; Instruction Pointer
%define TLS r13             ; Thread Local Storage (pointer to thread descriptor)
%define RSTACK r14          ; Return Stack Pointer
%define DSP r15             ; Data Stack Pointer

; Thread descriptor offsets
%define TLS_FLAGS 0         ; Offset to flags field
%define TLS_DATA_BASE 8     ; Offset to data stack base
%define TLS_RETURN_BASE 16  ; Offset to return stack base
%define TLS_CLEANUP 24      ; Offset to cleanup function pointer

; Continuation structure offsets
%define CONT_CODE 0         ; Offset to code pointer (RESTORE_CONT)
%define CONT_DATA_SIZE 8    ; Offset to data stack size in bytes
%define CONT_RETURN_SIZE 16 ; Offset to return stack size in bytes
%define CONT_SAVED_IP 24    ; Offset to saved IP
%define CONT_HEADER_SIZE 32 ; Total header size before stack data

; Constants
INPUT_BUFFER_SIZE equ 1048576  ; Size of input line buffer (1MB)
NEWLINE equ 10                 ; ASCII newline character
; Main File for PONG

BITS 64
CPU X64

; Utility Functions
extern cout

section .rodata
hello: db "Hello"
static hello:data

section .text


global _start

_start:
	lea rdi, [hello]
	mov rsi, 6
	call cout

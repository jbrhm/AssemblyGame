; Main File for PONG

BITS 64
CPU X64

%define SYSCALL_EXIT 60

; GUI Functions
extern open_window

; Utility Functions
extern cout

section .rodata
hello: db "Hello"
static hello:data

section .text
global _start

_start:


	call open_window

	lea rdi, [hello]
	mov rsi, 6
	call cout


	mov rax, SYSCALL_EXIT
	mov rdi, 0
	syscall

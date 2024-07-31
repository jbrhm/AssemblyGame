; Main File for PONG

BITS 64
CPU X64

%define SYSCALL_EXIT 60

; GUI Functions
extern open_window
extern set_color
extern draw_line
extern draw_rectangle

; Utility Functions
extern cout

section .rodata
hello: db "Hello"
static hello:data

section .text
global _start

_start:


	call open_window

	call set_color

	mov rdi, 20
	mov rsi, 30
	mov rdx, 100
	mov rcx, 200
	call draw_rectangle


	.loop:
		lea rdi, [hello]
		mov rsi, 6
		call cout

	jmp .loop

	mov rax, SYSCALL_EXIT
	mov rdi, 0
	syscall

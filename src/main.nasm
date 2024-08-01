; Main File for PONG

BITS 64
CPU X64

%define SYSCALL_EXIT 60

; GUI Functions
extern open_window
extern set_color
extern draw_line
extern draw_rectangle
extern draw_solid_rectangle

extern event_handle

; Utility Functions
extern cout
extern sleep_in_ms

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
	call draw_solid_rectangle


	.loop:
		call event_handle
		mov rdi, 25
		call sleep_in_ms

	jmp .loop

	mov rax, SYSCALL_EXIT
	mov rdi, 0
	syscall

; GUI Code

BITS 64
CPU X64

%define nullptr 0x0

; X11 Externs
extern XOpenDisplay

; Utility Functions
extern exit_error

; Functions
global open_window

open_window:
	push rbp
	mov rbp, rsp

	sub rsp, 64

	mov rdi, nullptr
	call XOpenDisplay

	mov [display], rax

	add rsp, 64
	pop rbp
	ret

section .data
display: dq 0x0

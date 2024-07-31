; GUI Code

BITS 64
CPU X64

%define nullptr 0x0

; X11 Externs
extern XOpenDisplay

; Functions
global open_window

open_window:
	push rbp
	mov rbp, rsp

	sub rsp, 64

	mov rdi, nullptr
	call XOpenDisplay

	add rsp, 64
	pop rbp
	ret

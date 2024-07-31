; GUI Code

BITS 64
CPU X64

%define nullptr 0x0

; X11 Externs
extern XOpenDisplay
extern XDefaultScreen
extern XBlackPixel
extern XWhitePixel

; Utility Functions
extern exit_error

; Functions
global open_window

open_window:
	push rbp
	mov rbp, rsp

	sub rsp, 64

	; Get the display ptr
	mov rdi, nullptr
	call XOpenDisplay

	mov [display], rax
	cmp QWORD [display], nullptr
	je exit_error ; Make sure the display ptr isnt null

	; Get the screen
	call XDefaultScreen
	mov [screen], rax

	; Get white and black colors
	mov rdi, [display]
	mov rsi, [screen]
	call XBlackPixel
	mov [black_color], rax

	mov rdi, [display]
	mov rsi, [screen]
	call XWhitePixel
	mov [white_color], rax

	add rsp, 64
	pop rbp
	ret


section .data
display: dq 0x0
static display:data

black_color: dq 0x0
static black_color:data

white_color: dq 0x0
static white_color:data

screen: dq 0x0
static screen:data

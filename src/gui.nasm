; GUI Code

BITS 64
CPU X64

%define nullptr 0x0

; X11 Externs
extern XOpenDisplay
extern XDefaultScreen
extern XDefaultRootWindow
extern XBlackPixel
extern XWhitePixel
extern XCreateSimpleWindow

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

	; Get root window
	mov rdi, [display]
	call XDefaultRootWindow
	mov [root_window], rax

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

	; Create the X11 window
	mov rdi, [display]
	mov rsi, [root_window]
	mov rdx, 0x0
	mov rcx, 0x0
	mov r8, [window_width]
	mov r9, [window_height]
	mov r10, [black_color]
	push r10 ; These are just integers
	push r10
	push nullptr
	call XCreateSimpleWindow
	pop r10
	pop r10
	pop r10

	add rsp, 64
	pop rbp
	ret

section .rodata
window_width: dq 640
static window_width:data

window_height: dq 480
static window_height:data

section .data
display: dq 0x0
static display:data

black_color: dq 0x0
static black_color:data

white_color: dq 0x0
static white_color:data

screen: dq 0x0
static screen:data

root_window: dq 0x0
static root_window:data

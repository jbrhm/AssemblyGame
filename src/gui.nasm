; GUI Code

BITS 64
CPU X64

%define nullptr 0x0
%define StructureNotifyMask 0x20000
%define KeyPressMask 0x1
%define KeyReleaseMask 0x2
%define MapNotify 0x13
%define KeyPress 0x2
%define KeyRelease 0x3

; X11 Externs
extern XOpenDisplay
extern XDefaultScreen
extern XDefaultRootWindow
extern XBlackPixel
extern XWhitePixel
extern XCreateSimpleWindow
extern XSelectInput
extern XMapWindow
extern XCreateGC
extern XNextEvent
extern XSetForeground
extern XDrawLine
extern XFlush
extern XDrawRectangle
extern XPending
extern XLookupKeysym
extern XClearWindow

; Utility Functions
extern cout
extern exit_error
extern sleep_in_ms

; Functions
global open_window
global set_color

global event_handle
global render
global collision_handle

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

	add rsp, 0x18 ; Undo the stack pushes

	mov [window], rax

	; Select Inputs
	mov rdi, [display]
	mov rsi, [window]
	mov rdx, StructureNotifyMask | KeyPressMask | KeyReleaseMask
	call XSelectInput

	; Map the window
	mov rdi, [display]
	mov rsi, [window]
	call XMapWindow

	; Get the graphical context
	mov rdi, [display]
	mov rsi, [window]
	mov rdx, nullptr
	mov rcx, nullptr
	call XCreateGC
	mov [graphical_context], rax

wait_loop_start:
    mov rdi, [display]
    lea rsi, [event]
    call XNextEvent

    mov eax, [event]
    cmp rax, MapNotify ; wait for mapping event
    je wait_loop_end

    jmp wait_loop_start
wait_loop_end:

	add rsp, 64
	pop rbp
	ret

; Sets the foreground color to white
set_color:
	push rbp
	mov rbp, rsp

	sub rsp, 64

	mov rdi, [display]
	mov rsi, [graphical_context]
	mov rdx, [white_color]
	call XSetForeground

	add rsp, 64
	pop rbp

	ret

; Draws a line from two window coordinates
; rdi: x1
; rsi: y1
; rdx: x2
; rcx: y2
draw_line:
	push rbp
	mov rbp, rsp

	sub rsp, 64
	
	; Reorder params
	push rcx ; 7
	mov r9, rdx ; 6
	mov r8, rsi ; 5
	mov rcx, rdi ; 4
	mov rdx, [graphical_context] ; 3
	mov rsi, [window] ; 2
	mov rdi, [display] ; 1
	call XDrawLine

	pop r9 ; undo the push

	; Flush the command
	mov rdi, [display]
	call XFlush


	add rsp, 64
	pop rbp
	ret

; Draws a rectanlge at window coordinates
; rdi: x
; rsi: y
; rdx: width
; rcx: height
draw_rectangle:
	push rbp
	mov rbp, rsp

	sub rsp, 64
	
	; Reorder params
	push rcx ; 7
	mov r9, rdx ; 6
	mov r8, rsi ; 5
	mov rcx, rdi ; 4
	mov rdx, [graphical_context] ; 3
	mov rsi, [window] ; 2
	mov rdi, [display] ; 1
	call XDrawRectangle

	pop r9 ; undo the push

	; Flush the command
	mov rdi, [display]
	call XFlush

	add rsp, 64
	pop rbp
	ret

; Draws a solid rectangle at window coordinates
; rdi: x
; rsi: y
; rdx: width
; rcx: height
draw_solid_rectangle:
	push rbp
	mov rbp, rsp

	sub rsp, 64

	mov QWORD [rsp + 0*8], rdi ; x
	mov QWORD [rsp + 1*8], rsi ; y
	mov QWORD [rsp + 2*8], rdx ; w
	mov QWORD [rsp + 3*8], rcx ; h


	loop:
		; Reorder params
		mov r9, [rsp + 2*8] ; 6
		mov r8, [rsp + 1*8] ; 5
		mov rcx, [rsp + 0*8] ; 4
		mov rdx, [graphical_context] ; 3
		mov rsi, [window] ; 2
		mov rdi, [display] ; 1
		mov r10, [rsp + 3*8]
		push r10 ; 7
		call XDrawRectangle

		pop r10 ; undo the push
		
		; Make the rectangle one smaller
		add QWORD [rsp + 0*8], 1
		add QWORD [rsp + 1*8], 1
		sub QWORD [rsp + 2*8], 2
		sub QWORD [rsp + 3*8], 2

		cmp QWORD [rsp + 3*8], 0
		jl break
	
		cmp QWORD [rsp + 2*8], 0
		jl break

		jmp loop

	break:

	; Flush the command
	mov rdi, [display]
	call XFlush

	add rsp, 64
	pop rbp
	ret

; Handle the various inputs
event_handle:
	push rbp
	mov rbp, rsp

	sub rsp, 64

	; Move the right paddle
	call move_right_paddle_up
	call move_right_paddle_down

	; See if there are any pedning events so that we aren't blocked while waiting for an event
	mov rdi, [display]
	call XPending

	; See of there are any pending events
	cmp rax, 0
	je no_events ; if there are no events, then exit fnc

    mov rdi, [display]
    lea rsi, [event] ; pointer to event
    call XNextEvent

	; https://www.cl.cam.ac.uk/~mgk25/ucs/keysymdef.h
	lea rdi, [event]
	mov rsi, 0x0
	call XLookupKeysym
	mov [key], rax

	call move_left_paddle_up
	call move_left_paddle_down

	add rsp, 64
	pop rbp
    ret

no_events:

	; Prints movement out to stdout
	lea edi, [no_input_msg]
	mov rsi, 9
	call cout

	add rsp, 64
	pop rbp
    ret

; Move LeftPaddle Up if the input says so
; Requires any events to be put into the [event] variable
move_left_paddle_up:
	
	push rbp
	mov rbp, rsp

	sub rsp, 64

	%define K_UP 0xff52
	%define K_DOWN 0xff54

	cmp DWORD [key], K_UP
	jne not_left_up

	lea rdi, [left_paddle_up_msg]
	mov rsi, 15
	call cout

	mov rax, [left_height]
	sub rax, [paddle_speed]
	mov [left_height], rax

not_left_up:
	add rsp, 64
	pop rbp
    ret

; Move LeftPaddle Up if the input says so
; Requires any events to be put into the [event] variable
move_left_paddle_down:
	
	push rbp
	mov rbp, rsp

	sub rsp, 64

	%define K_UP 0xff52
	%define K_DOWN 0xff54

	cmp DWORD [key], K_DOWN
	jne not_left_down

	lea rdi, [left_paddle_down_msg]
	mov rsi, 17
	call cout

	mov rax, [left_height]
	add rax, [paddle_speed]
	mov [left_height], rax

not_left_down:
	add rsp, 64
	pop rbp
    ret

; Moves right paddle up if the input says so
; Requires any events to be put into the [event] variable
move_right_paddle_up:
	
	push rbp
	mov rbp, rsp

	sub rsp, 64

	mov r10, [right_height]
	add r10, [half_paddle_height]
	mov r11, [ball_y]
	cmp r10, r11
	jl not_right_up

	lea rdi, [right_paddle_up_msg]
	mov rsi, 16
	call cout

	mov rax, [right_height]
	sub rax, [paddle_speed]
	mov [right_height], rax

not_right_up:
	add rsp, 64
	pop rbp
    ret

; Moves right paddle down if the input says so
; Requires any events to be put into the [event] variable
move_right_paddle_down:
	
	push rbp
	mov rbp, rsp

	sub rsp, 64

	mov r10, [right_height]
	add r10, [half_paddle_height]
	mov r11, [ball_y]
	cmp r11, r10
	jle not_right_down

	lea rdi, [right_paddle_down_msg]
	mov rsi, 18
	call cout

	mov rax, [right_height]
	add rax, [paddle_speed]
	mov [right_height], rax

not_right_down:
	add rsp, 64
	pop rbp
    ret

; Renders the two paddles
render:
	push rbp
	mov rbp, rsp

	sub rsp, 64

	; Clear the screen
	mov rdi, [display]
	mov rsi, [window]
	call XClearWindow

	; Render the two paddles
	mov rdi, [paddle_x_distance]
	mov rsi, [left_height]
	mov rdx, [paddle_width]
	mov rcx, [paddle_height]
	call draw_solid_rectangle

	mov rdi, [window_width]
	sub rdi, [paddle_x_distance]
	sub rdi, [paddle_width]
	mov rsi, [right_height]
	mov rdx, [paddle_width]
	mov rcx, [paddle_height]
	call draw_solid_rectangle

	; Render ball
	mov rdi, [ball_x]
	sub rdi, [half_ball_width]
	mov rsi, [ball_y]
	sub rsi, [half_ball_height]
	mov rdx, [ball_width]
	mov rcx, [ball_height]
	call draw_solid_rectangle

	; Update ball pos
	mov r10, [ball_x]
	add r10, [ball_v_x]
	mov [ball_x], r10

	mov r10, [ball_y]
	add r10, [ball_v_y]
	mov [ball_y], r10

	add rsp, 64
	pop rbp
	ret

; Determine if the ball hits any boundary/paddle
collision_handle:
	push rbp
	mov rbp, rsp

	sub rsp, 64

	; Check respawn
	mov r10, [ball_x]
	mov r11, [respawn_zone_width]
	cmp r10, r11
	jle respawn_ball

	mov r10, [ball_x]
	mov r11, [window_width]
	sub r11, [respawn_zone_width]
	cmp r11, r10
	jle respawn_ball

	; Check lower bound
	mov r10, [ball_y]
	mov r11, [window_height]
	cmp r11, r10
	jle flip_y
	
	; Check upper bound
	mov r10, [ball_y]
	mov r11, 0x0
	cmp r10, r11
	jle flip_y

	; Check right paddle
check_right_paddle:
	mov r10, [ball_x]
	mov r11, [window_width]
	sub r11, [paddle_x_distance]
	sub r11, [paddle_width]
	cmp r10, r11
	jle check_left_paddle

	mov r10, [ball_x]
	mov r11, [window_width]
	sub r11, [paddle_x_distance]
	cmp r11, r10
	jle check_left_paddle

	mov r10, [ball_y]
	mov r11, [right_height]
	cmp r10, r11
	jle check_left_paddle

	add r11, [paddle_height]
	cmp r11, r10
	jle check_left_paddle

	jmp flip_x
	
check_left_paddle:
	mov r10, [ball_x]
	mov r11, [paddle_x_distance]
	add r11, [paddle_width]
	cmp r11, r10
	jl collision_handle_end

	mov r10, [ball_x]
	mov r11, [paddle_x_distance]
	cmp r10, r11
	jl collision_handle_end

	mov r10, [ball_y]
	mov r11, [left_height]
	cmp r10, r11
	jle collision_handle_end

	add r11, [paddle_height]
	cmp r11, r10
	jle collision_handle_end

	jmp flip_x

flip_y:
	mov r10, [ball_v_y]
	neg r10
	mov [ball_v_y], r10
	jmp collision_handle_end

flip_x:
	mov r10, [ball_v_x]
	neg r10
	mov [ball_v_x], r10
	jmp collision_handle_end

respawn_ball:
	mov r10, [ball_respawn_x]
	mov [ball_x], r10
	mov r10, [ball_respawn_y]
	mov [ball_y], r10

collision_handle_end:
	add rsp, 64

	pop rbp
	ret

section .rodata
window_width: dq 640
static window_width:data

window_height: dq 480
static window_height:data

; Paddles
paddle_height: dq 75
static paddle_height:data

paddle_width: dq 30
static paddle_width:data

paddle_x_distance: dq 75
static paddle_x_distance:data

half_paddle_height: dq 37
static half_paddle_height:data

paddle_speed: dq 0x2
static paddle_speed:data

; Left Paddle

left_paddle_up_msg: db "Left Paddle Up"
static left_paddle_up_msg:data

left_paddle_down_msg: db "Left Paddle Down"
static left_paddle_down_msg:data

; Right Paddle

right_paddle_up_msg: db "Right Paddle Up"
static right_paddle_up_msg:data

right_paddle_down_msg: db "Right Paddle Down"
static Right_paddle_down_msg:data

no_input_msg: db "No Input"
static no_input_msg:data

; Ball

ball_width: dq 20
static ball_width:data

ball_height: dq 20
static ball_height:data

half_ball_width: dq 10
static half_ball_width:data

half_ball_height: dq 10
static half_ball_height:data

ball_respawn_x: dq 320
static ball_respawn_x:data

ball_respawn_y: dq 240
static ball_respawn_y:data

respawn_zone_width: dq 30
static respawn_zone_width:data

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

window: dq 0x0
static window:data

graphical_context: dq 0x0
static graphical_context:data

event: resb 0xc0

key: dq 0x0

; Left Paddle

; Height Location
left_height: dq 0x0
static left_height:data

right_height: dq 0x0
static right_height:data

; Ball Vars
ball_x: dq 320
static ball_x:data

ball_y: dq 240
static ball_y:data

ball_v_x: dq 0x1
static ball_v_x:data

ball_v_y: dq 0x1
static ball_v_y:data

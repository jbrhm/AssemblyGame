; Game written in assembly

BITS 64 ; We are running on a 64 bit machine
CPU X64 ; We are targeting the x86_64 CPU family

; Syscalls
%define SYSCALL_READ 0
%define SYSCALL_WRITE 1
%define SYSCALL_POLL 7
%define SYSCALL_SOCKET 41
%define SYSCALL_CONNECT 42
%define SYSCALL_EXIT 60
%define SYSCALL_FNCTL 72

; File Descriptors
%define STDOUT 1

; Stream Constants
%define AF_UNIX 1 ; Means to open the socket on the Unix Socket Domain
%define SOCK_STREAM 1 ; Means that the socket is stream oriented

; Creates a unix socket that connects to the x11 server
; returns The socket fd
x11_server_connect:
static x11_server_connect:function
	push rbp
	mov rbp, rsp

	mov rax, SYSCALL_SOCKET
	mov rdi, AF_UNIX
	mov rsi, SOCK_STREAM
	mov rdx, 0
	syscall

	cmp rax, 0
	jle die

	mov rdi, rax ; stores the file descriptor into rdi instead of rax

	sub rsp, 112

	; Copies the necessary data onto the stack in the places that the movsb command expects
	mov WORD [rsp], AF_UNIX
	lea rsi, sun_path
	mov r12, rdi
	lea rdi, [rsp + 2]
	cld
	mov ecx, 19 ; Length of string + null terminator
	rep movsb ; copy the data

	; Connects to the server
	mov rax, SYSCALL_CONNECT
	mov rdi, r12
	lea rsi, [rsp]
	%define SIZEOF_SOCKADDR_UN 2+108 ; the sizes of the two arguments
	mov rdx, SIZEOF_SOCKADDR_UN
	syscall

	cmp rax, 0
	jne die

	mov rax, rdi

	add rsp, 112
	pop rbp
	ret

x11_handshake:
static x11_handshake:function
	; prolog
	push rbp
	mov rbp, rsp

	sub rsp, 1<<15 ; Get 32k of space on the stack for the return value

	mov BYTE [rsp + 0], 'l' ; little endian
	mov WORD [rsp + 2], 11 ; major version

	; Send the handshake using write syscall
	mov rax, SYSCALL_WRITE
	mov rdi, rdi
	lea rsi, [rsp]
	mov rdx, 12 ; Size of the message
	syscall
	
	cmp rax, 12 ; The value in rax is the number of bytes that were written, make sure all were written properly
	jnz die

	; Read the X11 server response
	; The server first provides 8 bytes then the rest of the message
	; The response data will be written to the stack
	mov rax, SYSCALL_READ
	mov rdi, rdi
	lea rsi, [rsp]
	mov rdx, 8
	syscall

	; Make sure that the response was 8 bytes
	cmp rax, 8
	jnz die

	; Check that the server response was successful
	cmp BYTE [rsp], 1
	jnz die


	; Read the rest of the server's response
	mov rax, SYSCALL_READ
	mov rdi, rdi ; fd
	lea rsi, [rsp] ; pointer to the buffer to read into
	mov rdx, 1<<15 ; Size of the read
	syscall

	cmp rax, 0 ; Checks to make sure the server replied
	jle die

	; set id_base
	; The value must be in a register to write to the var
	mov edx, DWORD [rsp + 4]
	mov DWORD [id_base], edx

	; Set the id_mask
	mov edx, DWORD [rsp + 8]
	mov DWORD [id_mask], edx

	; pointer adjustment
	lea rdi, [rsp]

	mov cx, WORD [rsp + 16] ; vendor length
	movzx rcx, cx

	mov al, BYTE [rsp + 21] ; number of formats
	movzx rax, al ; mova al with zeros preceding it
	imul rax, 8

	add rdi, 32 ; skip connection

	; skip padding
	add rdi, 3
	and rdi, -4

	add rdi, rax ; skip formatting
	add rdi, rcx ; skip vendor

	mov eax, DWORD [rdi] ; store the window root id

	; set root_visual_id
	mov edx, DWORD [rdi + 32]
	mov DWORD [root_visual_id], edx

	; epilog
	add rsp, 1<<15
	pop rbp
	ret

x11_next_id:
static x11_next_id:function
	push rbp
	mov rbp, rsp

	mov eax, DWORD [id] ; load the currently used id

	; load id_base and id_mask
	mov edi, DWORD [id_base]
	mov edx, DWORD [id_mask]

	; calc id_mask & id | id_base
	and eax, edx
	or eax, edi

	add DWORD [id], 1 ; Increment the id

	pop rbp
	ret

; Open the font server side
; rdi: socket fd
; esi font id
x11_open_font:
static x11_open_font:function
	push rbp
	mov rbp, rsp

	%define OPEN_FONT_NAME_BYTE_COUNT 5
	%define OPEN_FONT_PADDING ((4 - (OPEN_FONT_NAME_BYTE_COUNT % 4)) % 4)
	%define OPEN_FONT_PACKET_U32_COUNT (3 + (OPEN_FONT_NAME_BYTE_COUNT + OPEN_FONT_PADDING) / 4)
	%define X11_OP_REQ_OPEN_FONT 0x2d

	sub rsp, 6*8

	; 4 byte aligned
	mov DWORD [rsp + 0*4], X11_OP_REQ_OPEN_FONT | (OPEN_FONT_NAME_BYTE_COUNT << 16)
	mov DWORD [rsp + 1*4], esi
	mov DWORD [rsp + 2*4], OPEN_FONT_NAME_BYTE_COUNT
	mov BYTE [rsp + 3*4 + 0], 'f'
	mov BYTE [rsp + 3*4 + 1], 'i'
	mov BYTE [rsp + 3*4 + 2], 'x'
	mov BYTE [rsp + 3*4 + 3], 'e'
	mov BYTE [rsp + 4*4 + 0], 'd'

	mov rax, SYSCALL_WRITE
	mov rdi, rdi
	lea rsi, [rsp]
	mov rdx, OPEN_FONT_PACKET_U32_COUNT*4
	syscall

	cmp rax, OPEN_FONT_PACKET_U32_COUNT*4
	jnz die

	add rsp, 6*8

	pop rbp
	ret

x11_create_gc:
static x11_create_gc:function
	push rbp
	mov rbp, rsp

	sub rsp, 8*8

	%define X11_OP_REQ_CREATE_GC 0x37
	%define X11_FLAG_GC_BG 0x00000004
	%define X11_FLAG_GC_FG 0x00000008
	%define X11_FLAG_GC_FONT 0x00004000
	%define X11_FLAG_GC_EXPOSE 0x00010000

	%define CREATE_GC_FLAGS X11_FLAG_GC_BG | X11_FLAG_GC_FG | X11_FLAG_GC_FONT
	%define CREATE_GC_PACKET_FLAG_COUNT 3
	%define CREATE_GC_PACKET_U32_COUNT (4 + CREATE_GC_PACKET_FLAG_COUNT)
	%define MY_COLOR_RGB 0x0000ffff


	mov DWORD [rsp + 0*4], X11_OP_REQ_CREATE_GC | (CREATE_GC_PACKET_U32_COUNT<<16)
	mov DWORD [rsp + 1*4], esi
	mov DWORD [rsp + 2*4], edx
	mov DWORD [rsp + 3*4], CREATE_GC_FLAGS
	mov DWORD [rsp + 4*4], MY_COLOR_RGB
	mov DWORD [rsp + 5*4], 0
	mov DWORD [rsp + 6*4], ecx

	mov rax, SYSCALL_WRITE
	mov rdi, rdi
	lea rsi, [rsp]
	mov rdx, CREATE_GC_PACKET_U32_COUNT*4
	syscall

	cmp rax, CREATE_GC_PACKET_U32_COUNT*4
	jnz die

	add rsp, 8*8

	pop rbp
	ret

; Create the window
; rdi: socket fd
; esi: new window id
; edx window root id
; ecx root visual id
; r8d x and y
; r9d w and h
x11_create_window:
static x11_create_window:function
	push rbp
	mov rbp, rsp

	%define X11_OP_REQ_CREATE_WINDOW 0x01
	%define X11_FLAG_WIN_BG_COLOR 0x00000002
	%define X11_EVENT_FLAG_KEY_RELEASE 0x0002
	%define X11_EVENT_FLAG_EXPOSURE 0x8000
	%define X11_FLAG_WIN_EVENT 0x00000800

	%define CREATE_WINDOW_FLAG_COUNT 2
	%define CREATE_WINDOW_PACKET_U32_COUNT (8 + CREATE_WINDOW_FLAG_COUNT)
	%define CREATE_WINDOW_BORDER 1
	%define CREATE_WINDOW_GROUP 1

	sub rsp, 12*8

	mov DWORD [rsp + 0*4], X11_OP_REQ_CREATE_WINDOW | (CREATE_WINDOW_PACKET_U32_COUNT << 16)
	mov DWORD [rsp + 1*4], esi
	mov DWORD [rsp + 2*4], edx
	mov DWORD [rsp + 3*4], r8d
	mov DWORD [rsp + 4*4], r9d
	mov DWORD [rsp + 5*4], CREATE_WINDOW_GROUP | (CREATE_WINDOW_BORDER << 16)
	mov DWORD [rsp + 6*4], ecx
	mov DWORD [rsp + 7*4], X11_FLAG_WIN_BG_COLOR | X11_FLAG_WIN_EVENT
	mov DWORD [rsp + 8*4], 0
	mov DWORD [rsp + 9*4], X11_EVENT_FLAG_KEY_RELEASE | X11_EVENT_FLAG_EXPOSURE

	mov rax, SYSCALL_WRITE
	mov rdi, rdi
	lea rsi, [rsp]
	mov rdx, CREATE_WINDOW_PACKET_U32_COUNT*4
	syscall

	cmp rax, CREATE_WINDOW_PACKET_U32_COUNT*4
	jnz die

	add rsp, 12*8

	pop rbp
	ret

; Map X11 window
; rdi: fd
; esi: window id
x11_map_window:
static x11_map_window:function
	push rbp
	mov rbp, rsp

	sub rsp, 16

	%define X11_OP_REQ_MAP_WINDOW 0x08
	mov DWORD [rsp + 0*4], X11_OP_REQ_MAP_WINDOW | (2<<16)
	mov DWORD [rsp + 1*4], esi

	mov rax, SYSCALL_WRITE
	mov rdi, rdi
	lea rsi, [rsp]
	mov rdx, 2*4
	syscall
	
	cmp rax, 2*4
	jnz die

	add rsp, 16

	pop rbp
	ret

; Sets the socket fd to non-blocking
; this allows it to be polled
; rdi: fd
set_fd_non_blocking:
static set_fd_non_blocking:static
	push rbp
	mov rbp, rsp

	%define F_GETFL 3
	%define F_SETFL 4

	%define O_NONBLOCK 2048

	mov rax, SYSCALL_FNCTL
	mov rdi, rdi
	mov rsi, F_GETFL
	mov rdx, 0
	syscall

	cmp rax, 0
	jl die

	mov rdx, rax
	or rdx, O_NONBLOCK

	mov rax, SYSCALL_FNCTL
	mov rdi, rdi
	mov rsi, F_SETFL
	mov rdx, rdx
	syscall

	cmp rax, 0
	jl die

	pop rbp
	ret

; Read the X11 server reply
; returns the msg code in al
x11_read_reply:
static x11_read_reply:function
	push rbp
	mov rbp, rsp

	sub rsp, 32

	mov rax, SYSCALL_READ
	mov rdi, rdi
	lea rsi, [rsp]
	mov rdx, 32
	syscall

	cmp rax, 1
	jle die

	mov al, BYTE [rsp]

	add rsp, 32

	pop rbp
	ret

; Polls the X11 server for messages
; rdi socket fd
; esi window id
; edx graphical context id
poll_messages:
static poll_messages:function
	push rbp
	mov rbp, rsp

	sub rsp, 32

	%define POLLIN   0x001
	%define POLLPRI  0x002
	%define POLLOUT  0x004
	%define POLLERR  0x008
	%define POLLHUP  0x010
	%define POLLNVAL 0x020

	mov DWORD [rsp + 0*4], edi
	mov DWORD [rsp + 1*4], POLLIN

	mov DWORD [rsp + 16], esi ; window id
	mov DWORD [rsp + 20], edx ; gc id
	mov BYTE [rsp + 24], 0

	.loop:
		mov rax, SYSCALL_POLL
		lea rdi, [rsp]
		mov rsi, 1
		mov rdx, -1
		syscall

		cmp rax, 0
		jle die

		cmp DWORD [rsp + 2*4], POLLERR
		je die

		cmp DWORD [rsp + 2*4], POLLHUP
		je die

		mov rdi, [rsp + 0*4]
		call x11_read_reply

		%define X11_EVENT_EXPOSURE 0xc
		cmp eax, X11_EVENT_EXPOSURE
		jnz .received_other_event

		.received_exposed_event:
		mov BYTE [rsp + 24], 1

		.received_other_event:
		cmp BYTE [rsp + 24], 1
		jnz .loop

		.draw_text:
			mov rdi, [rsp + 0*4] ; socket fd
			lea rsi, [hello_world]
			mov edx, 13 ; len
			mov ecx, [rsp + 16] ; window id
			mov r8d, [rsp + 20] ; gc id
			mov r9d, 100 ; x
			shl r9d, 16
			or r9d, 100 ; y
			call x11_draw_text

		.draw_pixels:
			mov rdi, [rsp + 0*4] ; socket fd
			mov esi, [rsp + 16] ; window id
			mov edx, [rsp + 20] ; gc id
			mov ecx, (100 << 16) | 25 ; x and y
			call x11_draw_coordinate


		jmp .loop
	
	add rsp, 32
	pop rbp
	ret

; Draw text on X11 window
; rdi: socket fd
; rsi: text
; edx: string length in bytes
; ecx: window id
; r8d: gc id
; r9d: x and y
x11_draw_text:
static x11_draw_text:function
	push rbp
	mov rbp, rsp

	sub rsp, 1024

	mov DWORD [rsp + 1*4], ecx ; put window id on the stack
	mov DWORD [rsp + 2*4], r8d ; store gc id on the stack
	mov DWORD [rsp + 3*4], r9d ; store x and y on the stack
	
	mov r8d, edx ; store string length in r8d
	mov QWORD [rsp + 1024 - 8], rdi ; store the socket fd

	; Compute padding and packet u32 count
	mov eax, edx ; dividend
	mov ecx, 4 ; divisor
	cdq; sign extend
	idiv ecx ; LLVM optimizer
	neg edx
	and edx, 3
	mov r9d, edx ; padding

	mov eax, r8d
	add eax, r9d
	shr eax, 2 
	add eax, 4 ; eax has packet u32 count

	%define X11_OP_REQ_IMAGE_TEXT8 0x4c
	mov DWORD [rsp + 0*4], r8d
	shl DWORD [rsp + 0*4], 8
	or DWORD [rsp + 0*4], X11_OP_REQ_IMAGE_TEXT8
	mov ecx, eax
	shl ecx, 16
	or [rsp + 0*4], ecx

	; copy string into packet
	mov rsi, rsi
	lea rdi, [rsp + 4*4] ; dest
	cld ; set the move forward flag
	mov ecx, r8d ; str len
	rep movsb ; copy the data

	mov rdx, rax ; packet u32 count form calc earlier
	imul rdx, 4
	mov rax, SYSCALL_WRITE
	mov rdi, QWORD [rsp + 1024 - 8] ; fd
	lea rsi, [rsp]
	syscall

	cmp rax, rdx
	jnz die

	add rsp, 1024

	pop rbp
	ret

; Draw a coordinate on a X11 window
; rdi: socket fd
; esi: window id
; edx: gc id
; ecx: x and y
x11_draw_coordinate:
static x11_draw_coordinate:
	;prolog
	push rbp
	mov rbp, rsp

	sub rsp, 1024

	%define X11_OP_REQ_POLYPOINT 0x40
	mov BYTE [rsp + 0*4], 0 ; put 0 into the beginning of the request because we are relative to the origin
	shl [rsp + 0*4], 8 ; shift the zero to the beginning of the message because the socket is little endian
	or [rsp + 0*4], X11_OP_REQ_POLYPOINT ; add the OP code to the request, this is right at the beginning because it is little endian
	or [rsp + 0*4], (4<<16) ; this is four because 3 * 4 bytes for the header, and one byte for the one pixel
	mov [rsp + 1*4], esi
	mov [rsp + 2*4], edx
	mov [rsp + 3*4], ecx

	; Write to the socket
	mov rax, SYSCALL_WRITE
	mov rdi, rdi
	lea rsi, [rsp]
	mov rdx, 16 ; This is 16 because every call is 16 BYTES 12 for header 4 for data 

	cmp rax, rdx ; make sure we wrote all of the bytes
	jnz die

	; epilog
	add rsp, 1024
	pop rbp


die: 
	mov rax, SYSCALL_EXIT
	mov rdi, 1
	syscall

section .rodata:

sun_path: db "/tmp/.X11-unix/X1", 0
static sun_path:data

hello_world: db "Hello, World"
static hello_world:data

section .data
id: dd 0
static id:data

id_base: dd 0
static id_base:data

id_mask: dd 0
static id_mask:data

root_visual_id: dd 0
static root_visual_id:data

section .text
global _start

_start:
	call x11_server_connect
	mov r15, rax ; store the file descriptor

	mov rdi, rax
	call x11_handshake

	mov r12d, eax ; Store the window root id

	call x11_next_id
	mov r13d, eax ; store the graphical context in r13

	call x11_next_id 	
	mov r14d, eax ; store the font id in r14

	mov rdi, r15
	mov esi, r14d
	call x11_open_font

	mov rdi, r15
	mov esi, r13d
	mov edx, r12d
	mov ecx, r14d
	call x11_create_gc

	call x11_next_id

	mov ebx, eax ; window id

	mov rdi, r15
	mov esi, eax
	mov edx, r12d
	mov ecx, [root_visual_id]
	mov r8d, 200 | (200 << 16)
	%define WINDOW_W 800
	%define WINDOW_H 600
	mov r9d, WINDOW_W | (WINDOW_H << 16)
	call x11_create_window

	mov rdi, r15
	mov esi, ebx
	call x11_map_window

	mov rdi, r15 ; fd
	call set_fd_non_blocking

	mov rdi, r15 ; fd
	mov esi, ebx ; window id
	mov edx, r13d ; gc id
	call poll_messages

	mov rax, SYSCALL_EXIT
	mov rdi, 0
	syscall

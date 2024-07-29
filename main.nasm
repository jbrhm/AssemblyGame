; Game written in assembly

BITS 64 ; We are running on a 64 bit machine
CPU X64 ; We are targeting the x86_64 CPU family

; Syscalls
%define SYSCALL_READ 0
%define SYSCALL_WRITE 1
%define SYSCALL_SOCKET 41
%define SYSCALL_CONNECT 42
%define SYSCALL_EXIT 60

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
	mov rcx, 19 ; Length of string + null terminator
	rep movsb ; copy the data

	; Connects to the server
	mov rax, SYSCALL_CONNECT
	mov rdi, r12
	mov rsi, rsp
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
	mov rsi, [rsp] ; pointer to the buffer to read into
	mov rdx, 1<<15 ; Size of the read
	syscall

	cmp rax, 0 ; Checks to make sure the server replied
	jnz die

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
	add rdi, rcx ; skip vendor

	; skip padding
	add rdi, 3
	add rdi, -4

	add rdi, rax ; skip formatting

	mov eax, DWORD [rdi] ; store the window root id

	; set root_visual_id
	mov eax, DWORD [rdi + 32]
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

die: 
	mov rax, SYSCALL_EXIT
	mov rdi, 1
	syscall

section .rodata:

sun_path: db "/tmp/.X11-unix/X1", 0
static sun_path:data

section .data:
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


	mov rax, SYSCALL_EXIT
	mov rdi, 0
	syscall

; Game written in assembly

BITS 64 ; We are running on a 64 bit machine
CPU X64 ; We are targeting the x86_64 CPU family

; Syscalls
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

die: 
	mov rax, SYSCALL_EXIT
	mov rdi, 1
	syscall

section .rodata:

sun_path: db "/tmp/.X11-unix/X1", 0
static sun_path:data

section .text
global _start

_start:

	call x11_server_connect


	mov rax, SYSCALL_EXIT
	mov rdi, 0
	syscall

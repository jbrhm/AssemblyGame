; Game written in assembly

BITS 64 ; We are running on a 64 bit machine
CPU X64 ; We are targeting the x86_64 CPU family

; Syscalls
%define SYSCALL_WRITE 1
%define SYSCALL_EXIT 60

; File Descriptors
%define STDOUT 1

print_hello:
	push rbp
	mov rbp, rsp

	sub rsp, 5 ; Reserves 5 bytes of data on the stack
	mov BYTE [rsp + 0], 'h'
	mov BYTE [rsp + 1], 'e'
	mov BYTE [rsp + 2], 'l'
	mov BYTE [rsp + 3], 'l'
	mov BYTE [rsp + 4], 'o'

	; Perform write syscall
	mov rax, SYSCALL_WRITE
	mov rdi, STDOUT
	lea rsi, [rsp]
	mov rdx, 5
	syscall

    add rsp, 5

	pop rbp

	ret

section .text
global _start

_start:

	call print_hello

	mov rax, SYSCALL_EXIT
	mov rdi, 0
	syscall

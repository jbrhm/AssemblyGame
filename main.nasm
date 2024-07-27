; Game written in assembly

BITS 64 ; We are running on a 64 bit machine
CPU X64 ; We are targeting the x86_64 CPU family

%define SYSCALL_EXIT 60

section .text
global _start

_start:
	mov rax, SYSCALL_EXIT
	mov rdi, 0
	syscall

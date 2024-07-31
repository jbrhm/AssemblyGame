; Utility Functions

; https://stackoverflow.com/questions/9989593/nasm-x86-64-assembly-in-32-bit-mode-why-does-this-instruction-produce-rip-relat
BITS 64
CPU X64

; Functions

global cout
global exit_error

; SYSCALLS
%define SYSCALL_WRITE 1
%define SYSCALL_EXIT 60

; File Descriptors
%define STDOUT 1

; Prints data out to stdout
; PARAMS:
;	rdi: const char* data
; 	rsi: size_t count (in bytes)
cout:
	; prologue
	push rbp
	mov rbp, rsp
	add rsp, 64

	mov rax, SYSCALL_WRITE
	mov rdx, rsi
	mov rsi, rdi
	mov rdi, STDOUT
	syscall

	sub rsp, 64
	pop rbp
	ret

; Exits the Program with exit code 1
exit_error:
	mov rax, SYSCALL_EXIT
	mov rdi, 1
	syscall

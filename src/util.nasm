; Utility Functions

; https://stackoverflow.com/questions/9989593/nasm-x86-64-assembly-in-32-bit-mode-why-does-this-instruction-produce-rip-relat
BITS 64
CPU X64

global cout

; SYSCALLS
%define SYSCALL_WRITE 1

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

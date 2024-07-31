; Utility Functions

; https://stackoverflow.com/questions/9989593/nasm-x86-64-assembly-in-32-bit-mode-why-does-this-instruction-produce-rip-relat
BITS 64
CPU X64

; Functions

global cout
global exit_error
global sleep_in_ms

; SYSCALLS
%define SYSCALL_WRITE 1
%define SYSCALL_SLEEP 35
%define SYSCALL_EXIT 60

; Misc
%define STDOUT 1
%define nullptr 0x0

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

; Causes the program to sleep in ms
; rdi: duration in ms
sleep_in_ms:
	push rbp
	mov rbp, rsp

	sub rsp, 64

	imul rdi, 1000000 ; Convert the ms to ns
	xor rax, rax ; zero out rax

	push rdi
	push rax

	; Sleep syscall
	mov rax, SYSCALL_SLEEP
	mov rdi, rsp
	mov rsi, nullptr
	syscall

	pop r10
	pop r10

	add rsp, 64
	pop rbp
	ret

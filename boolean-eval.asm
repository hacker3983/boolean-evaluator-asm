section .data
	text1 db "Please enter a boolean expression: ", 0
	len equ $-text1

	true db "true", 0xa, 0
	false db "false", 0xa, 0
	none db "none", 0xa, 0

	true_cp db "True", 0xa, 0
	false_cp db "False", 0xa, 0
	none_cp db "None", 0xa, 0
section .text
	global _start
strlen:
	mov rax, 0
	cmp byte[rsi+rax], 0
	jne .glen
	ret
	.glen:
		inc rax
		cmp byte[rsi+rax], 0
		jne .glen
		ret
; def strcmp(str1, str2)
; then
;	if len(str1) != len(str2)
;	then
;		return false;
;	done
;	for i in range(0, len(str1))
;	do
;		if str1[i] != str2[i]
;		then
;			return false
;		done
;	done
;	return true
; done
strcmp: ; def strcmp(str1, str2)
	; then
	; if len(str1) != len(str2)
	; then
	xor r8, r8 ; set r8 to zero
	xor r9, r9 ; set r9 to zero
	xor r10, r10 ; r10 = i
	push rsi ; save the value of rsi on the stack
	mov rsi, rdi ; set rsi equal to the value in rdi (str1)
	call strlen ; get the string length of str1
	mov r8, rax ; store the length of str1 in the r8 register
	pop rsi

	call strlen ; get the length of str2
	mov r9, rax ; store the length of str2 in the r9 register

	cmp r8, r9
	je .compare
	mov rax, 0 ; return false
	ret
	; for i in range(0, len(str1))
	; do
	.compare:
		; if str1[i] != str2[i]
		; then
		push r8
		push r9
		mov r8, [rdi+r10]
		mov r9, [rsi+r10]
		and r8, 255
		and r9, 255
		cmp r8, r9
		jne .ret_false ; return false
		; done
		pop r8
		pop r9

		inc r10
		cmp r10, r8
		jl .compare
		mov rax, 1
		ret ; return true
	; done
	.ret_false:
		pop r8
		pop r9
		mov rax, 0
		ret
; done

; def tolower(c)
; do
;	if c >= ord('A') && c <= ord('Z')
;	then
;		return ord(c) + (ord('a') - ord('A'))
;	done
;	return c
; done
; converts a character to lowercase
tolower:
	; dil is the character we are going to convert
	cmp dil, 'A' ; if c >= ord('A')
	jge .check_z
	ret ; return c
	.check_z:
		cmp dil, 'Z' ; c <= ord('Z')
		jle .convert_lower
		ret
	.convert_lower:
		; when we add 32 dil it will give us the lowercase ascii version of the character
		; in the dil register
		add dil, 32 ; ord(c) + (ord('a') - ord('A') = 32 or ' ')
		ret
strtolower: ; equivalent to lower function in python
	mov rax, 0
	cmp byte[rsi], 0
	jne .convert_cs_lower
	ret
	.convert_cs_lower:
		mov dil, [rsi+rax]
		call tolower
		mov [rsi+rax], dil
		add rax, 1
		cmp byte[rsi+rax], 0
		jne .convert_cs_lower
		ret
; evaluates a expression
convert_to_expression:
	call strtolower
	mov rdi, true
	call strcmp
	cmp rax, 1
	jne .check_false_print
	mov rax, 1
	mov rdi, 1
	mov rsi, true_cp
	mov rdx, 5
	syscall
	ret
	.check_false_print:
		mov rdi, false
		call strcmp
		cmp rax, 1
		jne .check_none_print
		mov rax, 1
		mov rdi, 1
		mov rsi, false_cp
		mov rdx, 6
		syscall
		ret
	.check_none_print:
		mov rdi, none
		call strcmp
		cmp rax, 1
		jne .print_other
		mov rax, 1
		mov rdi, 1
		mov rsi, none_cp
		mov rdx, 5
		syscall
		ret
	.print_other:
		call strlen
		mov rdx, rax
		mov rax, 1
		mov rdi, 1
		syscall
		ret
; set n bytes in a string to null
bzero:
	mov rax, 0
	.loop:
		mov byte[rsi+rax], 0
		inc rax
		cmp rax, rdi
		jne .loop
		ret
_start:
	mov rax, 1 ; write
	mov rdi, 1 ; file descriptor stdout
	mov rsi, text1 ; buffer or text
	mov rdx, len ; length of text
	syscall ; call write function / system call

	sub rsp, 50_000 ; allocate 50_000 bytes on the stack
	mov rax, 0 ; read
	mov rdi, 0 ; file descriptor stdin
	mov rsi, rsp ; buffer or text
	mov rdx, 50_000 ; amount of characters / bytes to read
	syscall ; call the read function / system call
	mov byte[rsp+49_000], 0 ; set the last argument in the buffer to 0 (null)
	call convert_to_expression ; evaluate the expression entered by the user

	mov rsi, rsp
	mov rdi, 50_000
	call bzero
	add rsp, 50_000 ; free / deallocate the amount of bytes allocated

	jmp _start

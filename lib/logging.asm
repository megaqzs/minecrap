; asmsyntax=tasm
; copy me before the include:
;GraphicsMode equ [graphics mode]
; set to UNCHAINED for mode x (requires graphics.asm to be included first) or BIOS for any chained/text modes
UNCHAINED equ 0
BIOS equ 1

DATASEG
if GraphicsMode eq UNCHAINED
	cursor dw ?
endif
CODESEG

macro printf str, a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16
	rpush a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16
	push si
	mov si, str
	call _printf
	pop si
endm printf


macro putstackstr exit_code
	local printchr, printloop

	if GraphicsMode eq BIOS
		mov ah,2h
	elseif GraphicsMode eq UNCHAINED
		mov di, [cursor]
	endif

	printloop:
		if GraphicsMode eq BIOS
			pop dx
			cmp dx, 0
		elseif GraphicsMode eq UNCHAINED
			pop si
			cmp si, 0
		endif

		jne printchr
			if GraphicsMode eq UNCHAINED
				mov [cursor], di
			endif
			exit_code
		printchr:
		if GraphicsMode eq UNCHAINED
			shl si, 2
			lea si, [si+font]
			call Xprintchar
			add di, 2
		elseif GraphicsMode eq BIOS
			int 21h
		endif
		jmp printloop
endm putstackstr

macro printchar
	if GraphicsMode eq BIOS
		mov ah,2h
		int 21h
	elseif GraphicsMode eq UNCHAINED
		mov di, [cursor]
		mov si, dx
		shl si, 2
		lea si, [si+font]
		call Xprintchar
		add [cursor], 2
	endif
endm printchar

; si: table index
uchextable db "0123456789ABCDEF"
lchextable db "0123456789abcdef"
macro printlhex
	local printloop
	xor bx,bx
	mov cx,bx
	printloop:
		dwrol ax, cx, 4
		mov bl,cl
		and bl, 1111b

endm printlhex

; prints the integer at ax
proc printint
	locals @@
	mov cx, 10
	; get the absolute value of ax and store sign in dx
	cwd
	xor ax, dx
	sub ax, dx

	push 0

	@@storeloop:
		xor dx,dx
		div cx
		add dx, '0'
		push dx
	cmp ax,0
	jne @@storeloop

	putstackstr ret
	return:
		pop cx ax dx
endp printint


; changes ax bx cx dx
proc printulong
	locals @@
	mov cx, 10
	push 0

	@@storeloop:
		xor dx,dx
		div cx
		xchg ax, bx
		div cx
		xchg ax, bx

		add dx, '0'
		push dx
	cmp bx,0
	jne @@storeloop
	cmp ax,0
	jne @@storeloop

	putstackstr ret
endp printulong

; print the float in ST(0)
decimalfloat dd 10000.0
decimalint equ 10000
decimaldigits equ 4
proc printfloat
	locals @@

	ftst
	fstsw [word low fputmp]
	test [byte high word low fputmp], c0_mask
	jz @@nosign
		fabs
		mov dx, '-'
		printchar
	@@nosign:

	fmul [decimalfloat]
	fistp [fputmp]
	mov ax, [word high fputmp]
	mov bx, [word low fputmp]

	xor dx,dx
	mov cx, decimalint

	div cx
	xchg ax, bx
	div cx
	xchg ax, bx
	push dx
	call printulong

	mov dx, '.'
	printchar

	pop ax
	mov bx, 10
	rept decimaldigits
		xor dx,dx
		div bx
		push dx
	endm
	mov ah,2

	rept decimaldigits
		pop dx
		add dx, '0'
		printchar
	endm
endp printfloat

proc _printf
	;local argcount:word,roundmultiple:word
	push bp
	mov bp, sp
	mov di, 4

	mov sp,bp
	pop bp
	ret
endp _printf

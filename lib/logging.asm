; asmsyntax=nasm
; copy me before the include:
; 	GraphicsMode equ [graphics mode]
; set to UNCHAINED for mode x (requires graphics.asm to be included first) or BIOS for any chained/text modes
UNCHAINED equ 0
BIOS equ 1

FontReady equ False

section data
if GraphicsMode == UNCHAINED
	cursor dw ?
endif
section code

%macro printf 2+
	rpush %2
	push si
	mov si,%1
	call _printf
	pop si
%endmacro printf


; changes di, si, ax, dx
%macro putstackstr 1
	%if GraphicsMode == BIOS
		mov ah,2h
	%elif GraphicsMode == UNCHAINED
		mov di, word [cursor]
	%endif

	%%printloop:
		%if GraphicsMode == BIOS
			pop dx
			cmp dx, 0
		%elif GraphicsMode == UNCHAINED
			pop si
			cmp si, 0
		%endif

		jne %%printchr
			%if GraphicsMode == UNCHAINED
				mov word [cursor], di
			%endif
			%1
		%%printchr:
		%if GraphicsMode == UNCHAINED
			shl si, 2
			lea si, dword [si+font]
			call Xprintchar
			add di, 2
		%elif GraphicsMode == BIOS
			int 21h
		endif
		jmp %%printloop
%endmacro putstackstr

%macro printchar 0
	%if GraphicsMode == BIOS
		mov ah,2h
		int 21h
	%elif GraphicsMode == UNCHAINED
		mov di, word [cursor]
		mov si,dx
		shl si,2
		lea si,dword [font+si]
		call Xprintchar
		add word [cursor], 2
	%endif
%endmacro printchar

; si: table index
uchextable db "0123456789ABCDEF"
lchextable db "0123456789abcdef"
%macro printlhex
	xor bx,bx
	mov cx,bx
	%%printloop:
		dwrol ax,cx,4
		mov bl,cl
		and bl, 1111b
%endmacro printlhex

; prints the unsigned integer at ax
printuint:
	push ax,cx,dx,di,si
	mov cx, 10
	push 0

	.storeloop:
		xor dx,dx
		div cx
		add dx, '0'
		push dx
	cmp ax,0
	jne .storeloop

	putstackstr jmp .return
	.return:
		rpop ax,cx,dx,di,si
		ret


; prints the integer at ax
printint:
	push ax,bx,cx,dx,di,si
	mov cx, 10
	push 0
	; get the absolute value of ax and store sign in dx
	cwd
	xor ax, dx
	sub ax, dx
	mov bx, dx

	.storeloop:
		xor dx,dx
		div cx
		add dx, '0'
		push dx
	cmp ax,0
	jne .storeloop

	or bx,bx
	jns .nosign
		push '-'
	.nosign:
	putstackstr jmp .return
	.return:
		rpop ax,bx,cx,dx,di,si
		ret



; changes ax bx cx dx
printulong:
	push ax,bx,cx,dx,di,si
	mov cx,10
	push 0

	.storeloop:
		xor dx,dx
		div cx
		xchg ax, bx
		div cx
		xchg ax, bx

		add dx, '0'
		push dx
	cmp bx,0
	jne .storeloop
	cmp ax,0
	jne .storeloop

	putstackstr <jmp .return>
	.return:
		rpop ax,bx,cx,dx,di,si
		ret


; print the float in st0
decimalfloat dd 100000.0
printfloat:
	push ax,bx,cx,dx,di,si

	ftst
	fstsw word [WordLow(fputmp)]
	test byte [1 + WordLow(fputmp)],c0_mask
	jz .nosign
		fabs
		mov dx, '-'
		printchar
	.nosign:
	fsetrc rnd_floor

	fist [fputmp]

	mov ax, word [WordHigh(fputmp)]
	mov bx, word [WordLow(fputmp)]
	call printulong

	mov dx, '.'
	printchar

	fld1
	fxch st1
	fprem
	fstp st1
	fmul [decimalfloat]
	fistp [fputmp]
	
	mov ax, word [WordHigh(fputmp)]
	mov bx, word [0*2 fputmp]
	fsetrc rnd_near
	mov cx,10
	push 0

	%rep 5
		xor dx,dx
		div cx
		xchg ax, bx
		div cx
		xchg ax, bx

		add dx, '0'
		push dx
	%endrep

	putstackstr <jmp .exit>
	.exit:
	rpop ax,bx,cx,dx,di,si
	ret


_printf:
	;local argcount:word,roundmultiple:word
	push bp
	mov bp, sp
	mov di, 4

	mov sp,bp
	pop bp
	ret

; di = cursor, si = character
Xprintchar:
	mov ax,0
	mov ah,10001b
	xchg al,cl
	and al,11b
	shl ah,cl
	xchg al,cl

	%assign i 0
	%assign j 0
	%rep 4
		push ax
		and ah,1111b
		setreg SEQUENCER_CTRL, Plane_Mask
		pop ax
		push di
		mov bl, byte [ds:si + i]
		%rep 8
			shr bl,1
			jnc MKLabelI(.nopixel,j)
				mov byte [es:di], 0fh
			MKLabelI(.nopixel,j):
			add di, 320/4
			%assign j j+1
		%endrep
		pop di
		shl ah,1
		%assign i i+1
	%endrep
	ret


; define the symbols required for the font
; put me in the data segment
%macro fontinit 0
	%if !FontReady
		FontReady equ True
		font:
		db 4*32 dup(0)
		; space
		db 00000000b
		db 00000000b
		db 00000000b
		db 00000000b
		; !
		db 00000000b
		db 11011111b
		db 11011111b
		db 00000000b
		db 4*11 dup(0)
		; -
		db 00010000b
		db 00010000b
		db 00010000b
		db 00010000b
		; .
		db 00000000b
		db 11000000b
		db 11000000b
		db 00000000b
		; /
		db 11000000b
		db 00110000b
		db 00001100b
		db 00000011b
		; 0
		db 01111110b
		db 10000001b
		db 10000001b
		db 01111110b
		; 1
		db 00000000b
		db 10000001b
		db 11111111b
		db 10000000b
		; 2
		db 11100010b
		db 10010001b
		db 10010001b
		db 10001110b
		; 3
		db 10001001b
		db 10001001b
		db 10001001b
		db 01110110b
		; 4
		db 00001100b
		db 00001011b
		db 00001000b
		db 11111111b
		; 5
		db 10001111b
		db 10001001b
		db 10001001b
		db 01110001b
		; 6
		db 01111110b
		db 10001011b
		db 10001001b
		db 01110001b
		; 7
		db 00000001b
		db 11100001b
		db 00111001b
		db 00001111b
		; 8
		db 01110110b
		db 10001001b
		db 10001001b
		db 01110110b
		; 9
		db 10000110b
		db 10001001b
		db 11001001b
		db 01111110b
		; :
		db 11100111b
		db 11100111b
		db 11100111b
		db 00000000b
		; ;
		db 10000111b
		db 11000111b
		db 01100111b
		db 00000000b
		; <
		db 00010000b
		db 00101000b
		db 01000100b
		db 01000100b
		; =
		db 00100100b
		db 00100100b
		db 00100100b
		db 00100100b
		; >
		db 01000100b
		db 01000100b
		db 00101000b
		db 00010000b
		; ?
		db 00000000b
		db 10111001b
		db 00001001b
		db 00000110b
		; @
		db 01111110b
		db 10001001b
		db 10010101b
		db 01011110b
		; A
		db 11111110b
		db 00010001b
		db 00010001b
		db 11111110b
		; B
		db 11111111b
		db 10001001b
		db 10001001b
		db 01110110b
		; C
		db 01111110b
		db 11000011b
		db 10000001b
		db 10000001b
		; D
		db 11111111b
		db 10000001b
		db 11000011b
		db 01111110b
		; E
		db 11111111b
		db 10001001b
		db 10001001b
		db 10001001b
		; F
		db 11111111b
		db 00001001b
		db 00001001b
		db 00001001b
		; G
		db 11111111b
		db 10000001b
		db 10001001b
		db 11111001b
		; H
		db 11111111b
		db 00001000b
		db 00001000b
		db 11111111b
		; I
		db 10000001b
		db 11111111b
		db 10000001b
		db 00000000b
		; J
		db 11000000b
		db 10000001b
		db 10000001b
		db 11111111b
		; K
		db 11111111b
		db 00100100b
		db 01000010b
		db 10000001b
		; L
		db 11111111b
		db 10000000b
		db 10000000b
		db 10000000b
		; M
		db 11111111b
		db 00000110b
		db 00000110b
		db 11111111b
		; N
		db 11111111b
		db 00001110b
		db 01110000b
		db 11111111b
		; O
		db 11111111b
		db 10000001b
		db 10000001b
		db 11111111b
		; P
		db 11111111b
		db 00001001b
		db 00001001b
		db 00000110b
		; Q
		db 01111111b
		db 01000001b
		db 01100001b
		db 11111111b
		; R
		db 11111111b
		db 00011001b
		db 00101001b
		db 11000110b
		; S
		db 10000110b
		db 10001001b
		db 10001001b
		db 01110001b
		; T
		db 00000001b
		db 11111111b
		db 00000001b
		db 00000001b
		; U
		db 11111111b
		db 10000000b
		db 10000000b
		db 11111111b
		; V
		db 00011111b
		db 11100000b
		db 11100000b
		db 00011111b
		; W
		db 11111111b
		db 00110000b
		db 00110000b
		db 11111111b
		; X
		db 11100111b
		db 00011000b
		db 00011000b
		db 11100111b
		; Y
		db 00000111b
		db 11111000b
		db 00000111b
		db 00000000b
		; Z
		db 11000001b
		db 10110001b
		db 10001101b
		db 10000011b
	%endif
%endmacro

; asmsyntax=tasm

VGASegment equ 0A000h

; vga register channels
CRTC_CTRL equ 3d4h
SEQUENCER_CTRL equ 3c4h
GRAPHICS_CTRL equ 3ceh
INPUT_STATUS_1 equ 03dah

; vga register indicies
Memory_Mode equ 4h
Underline_Loc equ 14h
Mode_Control equ 17h
Plane_Mask equ 02h
ADDRESS_HIGH equ 0ch
ADDRESS_LOW equ 0dh

; vga masks
VSYNC_MASK equ 08h
DE_MASK equ 01h

CODESEG

macro setreg channel, index, value
	mov dx, channel
	ifnb <value>
		mov ax, index OR (value SHL 8)
	else
		mov al, index
	endif
		out dx,ax
endm setreg

macro SetModeX
	mov ax,13h
	int 10h

	setreg SEQUENCER_CTRL, Memory_Mode, 06h
	setreg CRTC_CTRL, Underline_Loc, 0
	setreg CRTC_CTRL, Mode_Control, 0e3h
endm SetModeX

macro XSetPixel color
	local r1, r2
	mov ah, 1

	shr di, 1
	jnc r1
		shl ah, 1
	r1:
	shr di, 1
	jnc r2
		shl ah, 2
	r2:

	setreg SEQUENCER_CTRL, Plane_Mask

	mov [byte es:di], color
endm XSetPixel

macro WaitDisplayEnable
	local WaitDELoop
	mov dx,INPUT_STATUS_1
	WaitDELoop:
			in al,dx
			and al,DE_MASK
			jnz WaitDELoop
endm WaitDisplayEnable

macro flippage currpage
	mov ax, es
	sub ax, VGASegment
	shl ax, 4
	push ax

	cli
	setreg CRTC_CTRL, ADDRESS_HIGH
	pop ax
	mov ah,al
	setreg CRTC_CTRL, ADDRESS_LOW
	sti

	mov ax, es
	xchg ax, currpage
	mov es, ax
endm flippage

macro WaitVSync
	local WaitNotVSyncLoop, WaitVSyncLoop
	mov     dx,INPUT_STATUS_1
	WaitNotVSyncLoop:
		in al,dx
		and al,VSYNC_MASK
		jnz WaitNotVSyncLoop
	WaitVSyncLoop:
		in al,dx
		and al,VSYNC_MASK
		jz WaitVSyncLoop
endm WaitVSync

; di = cursor, si = character
proc Xprintchar color
	mov ax,0
	mov ah,10001b
	xchg al,cl
	and al,11b
	shl ah,cl
	xchg al,cl

	index = 0
	rept 4
		push ax
		and ah,1111b
		setreg SEQUENCER_CTRL, Plane_Mask
		pop ax
		push di
		mov bl, [byte ds:si + index]
		rept 8
			local nopix
			shr bl,1
			jnc nopix
				mov [byte es:di], 0fh
			nopix:
			add di, 320/4
		endm
		pop di
		shl ah,1
		index = index + 1
	endm
ret
endp Xprintchar

; define the symbols required for the font
; put me in the data segment
macro fontinit
	font = $
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
endm fontinit

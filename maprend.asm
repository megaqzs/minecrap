; vim style select: asmsyntax=tasm
IDEAL
MODEL SMALL
P286
STACK 100h

include "lib/helper16.asm"
USE_FLOAT equ 1
include "lib/math.asm"
include "lib/graphics.asm"
include "evnthand.asm"

GraphicsMode equ 0
include "lib/logging.asm"

DATASEG
;                        screen width or height
; set FocalLen to:     ⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼
;                              2*tan(ɑ/2)
; where ɑ is the field of view in the width or height (depending on what you set)
FocalLen dd 250.0
WallHalfHeight dd 0.25
PlayerSpeed dd 0.08 ; blocks / frames (there are 60 frames per second)
MouseSensetivity dd 0.001 ; [MouseSensetivity] = half radians / mouse movment

map \
db 20h, 20h, 20h, 20h, 20h, 20h, 20h, 27h, 27h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 30h, 30h, 00h, 00h, 00h, 00h, 00h, 00h, 30h, 30h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 30h, 30h, 00h, 00h, 00h, 00h, 00h, 00h, 30h, 30h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 34h, 34h, 34h, 34h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 34h, 00h, 00h, 34h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 34h, 00h, 00h, 34h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 34h, 00h, 00h, 34h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 30h, 30h, 00h, 00h, 00h, 00h, 00h, 00h, 30h, 30h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 30h, 30h, 00h, 00h, 00h, 00h, 00h, 00h, 30h, 30h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
db 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h

CameraX dd 7.5
CameraZ dd 3.0

; in half radians (the pieriod is π instead of 2π)
CameraRotY dd 0.0
HalfHeight dd 0.5

CameraRotYSin dd ?
CameraRotYCos dd ?

; an array of the slopes of the rays that are representing columns
SlopeTable dd 320 dup(?)
; an array of the directions of the rays from before
DirTable db 320 dup(0)

; the vga page that is shown
visiblepage dw VGASegment

MapWidth dw 32
PrintPath db 0


fontinit
CODESEG

include "cast.asm"
include "draw.asm"

sWidth equ 320
sHeight equ 200
sCenter equ sWidth*(sHeight+1)/2

; could be optimized
macro drawcursor color
		mov di,sCenter-320
		XSetPixel color
		mov di, sCenter-1
		XSetPixel color
		mov di, sCenter
		XSetPixel color
		mov di, sCenter+1
		XSetPixel color
		mov di,sCenter+320
		XSetPixel color
endm drawcursor

; ST(0) = z, ST(1) = x, ST(2) = focal length
macro GetColumnHeight DestReg
	local exit_m, mult
	; TODO implement z axis rotation instead of this stupidity
	fstp ST(1)
	fsub [CameraZ]
	fchs

	; do [FocalLen]*WallHeight/z
	;fdivr ST(0), ST(1) ; [FocalLen]*WallHeight is in ST(1)
	fdivr [FocalLen]
	fistp [word low fputmp]

	mov DestReg,[word low fputmp]
	cmp DestReg,200/2-1
	jb mult
		mov DestReg,320*(200/2-1)
		jmp exit_m
	mult:
	; DestReg = height * 320
	shl DestReg,2
	add DestReg,[word low fputmp]
	shl DestReg,6
	exit_m:
endm GetColumnHeight

; logging calls

fld ST(0)
mov [cursor], 161+800*0
call printfloat


main:
	mov ax, @data
	mov ds,ax

	; change keyboard handler
	xor ax,ax
	mov es,ax
	cli
	push [word es:4*9] [word es:4*9+2]
	mov [word es:4*9+2], seg keyboardhandler
	mov [word es:4*9], offset keyboardhandler
	sti

	; store mouse handler segment in es
	mov ax,seg mousehandler
	mov es,ax

	; set mouse handler
	mov bx,offset mousehandler
	mov ax,0c207h
	int 15h

	; initialize mouse
	mov bh,01h
	mov ax,0c200h
	int 15h
	mov [PointerX],0
	mov [PointerY],0

	; change to graphical mode
	mov ax,13h
	int 10h
	SetModeX

	; prepare for display loop
	; SHR 4 is there because the address is 20 bits wide and es is 16 bits wide and at the end of the address
	mov ax,VGASegment + 320*200/4 SHR 4
	mov es,ax

	finit
	fld [FocalLen]

	; initialize slope table
	mov bx,160*4
	mov cx,-160
	SlopeLoop:
		sub bx,4
		inc cx
		mov [word low fputmp],cx
		fild [word low fputmp]
		fdiv ST(0),ST(1)
		fstp [fputmp]
		mov ax,[word low fputmp]
		mov [word SlopeTable + bx + 160 * 4], ax
		mov ax, [word high fputmp]
		mov [word SlopeTable + bx + 160 * 4 + 2], ax
	cmp bx,-160*4
	jne SLopeLoop
	fmul [WallHalfHeight]

	fld [CameraRotY]
	sincos halfrad
	fstp [CameraRotYSin]
	fstp [CameraRotYCos]
	cld

	FrameLoop:
		setreg SEQUENCER_CTRL, Plane_Mask, 1111b
		xor di,di
		WaitVSync
		;cmemset 320*200/4/2,09h
		cmemset 320*200/4,00h

		mov dx,1
		mov bx,320*4
		mov di, 200 * 320 / 2
		CastLoop:
		dec di
		sub bx,4
		mov cx,[word high SlopeTable + bx]
		xor cx,dx
		jns SignIsDiffrent
			neg dx ; make sure the sign is diffrent
		SignIsDiffrent:
		pusha
			fld [SlopeTable + bx]
			call CastRay
			GetColumnHeight bx
			;XSetPixel cl
			XDrawColumn cl,bx ; can be used as picture index instead
		popa
		or bx,bx
		jnz CastLoop

		;drawcursor 0fh

		WaitDisplayEnable
		flippage [visiblepage]

		fldpi
		cli
		fild [PointerX]
		mov [PointerX],0
		sti

		fmul [MouseSensetivity]
		fadd [CameraRotY]
		fprem
		fadd ST(0), ST(1)
		fprem
		fstp ST(1)
		fst [CameraRotY]

		sincos halfrad
		fstp [CameraRotYSin]
		fstp [CameraRotYCos]

		; check for events
		mov al, [kbstatus]

		; load (x,z) vector and initialize it to zero
		fldz
		fldz

		; load the speed of the player
		fld [PlayerSpeed]

		; test if we are moving in x and z
		mov ah,al
		shr ah,1
		xor ah,al
		test ah,101b ; zf is unset and pf is set only if (((move left) ⊕ (move right)) ∧ ((move backward) ⊕ (move forward)))
		jz switch0
		jnp switch0
			
		; if we are moving in x and y then we need to multiply by 1/√2 because sin(45°)=1/√2 (and cos)
		fmul [InvSqrt2]

		; ST(0): increment, ST(1): x, ST(2): z
		switch0:
		shr al,1
		jnc case1
			fadd ST(1), ST(0)
		case1:
		shr al,1
		jnc case2
			fsub ST(1), ST(0)
		case2:
		shr al,1
		jnc case3
			fsub ST(2), ST(0)
		case3:
		shr al,1
		jnc endswitch0
			fadd ST(2), ST(0)
		endswitch0:

		fstp ST(0) ; we dont need the corrected increment any more

		; rotate the velocity vector by the y axis rotation
		cmacrot [CameraRotYSin] [CameraRotYCos]

		; add the velocity vector to the location (since x=x₀+v*t and we are repeatedly adding the velocity over time which is equivilant to multiplacation)
		fadd [CameraX]
		fstp [CameraX]

		fadd [CameraZ]
		fstp [CameraZ]

		shr al,3
		jc exit
		continue:
			jmp FrameLoop
exit:
	; restore keyboard handler
	xor ax,ax
	mov es,ax

	; pop is not atomic
	cli
	pop [word es:4*9+2] [word es:4*9]
	sti

	; remove FocalLen from the fpu's stack
	fstp ST(0)

	; disable mouse
	mov bh,00h
	mov ax,0c200h
	int 15h

	; remove mouse handler
	mov bx,0
	mov ax,0c207h
	int 15h

	; go to text mode
	mov ax,3h
	int 10h

	exitcode 0
END main

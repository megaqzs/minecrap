; vim style select: asmsyntax=tasm
IDEAL
MODEL SMALL
P386
STACK 100h

include "lib/helper16.asm"
USE_FLOAT equ 1
include "lib/math.asm"
include "lib/graphics.asm"
include "evnthand.asm"

DATASEG
;                        screen width or height
; set FocalLen to:     ⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼
;                              2*tan(ɑ/2)
; where ɑ is the field of view in the width or height (depending on what you set)
FocalLen dd 250.0
PlayerSpeed dd 0.02 ; blocks / frames (there are 60 frames per second)
MouseSensetivity dd 0.001 ; [MouseSensetivity] = half radians / mouse movment

CameraX dd 2.6
CameraY dd ?
CameraZ dd 6.0

; in half radians (the pieriod is π instead of 2π)
CameraRotY dd 0.392699082

; define a cube centered around the world origin in euclidean space
pointX dd 8.5, 7.5, 8.5, 7.5,   6.5, 6.5,  9.5, 9.5
pointZ dd 0.5, -0.5, -0.5, 0.5, 0.5, -0.5, 0.5, -0.5
pointCount = ($-pointX) / 4 / 2
HalfHeight dd 0.5

CameraRotYSin dd ?
CameraRotYCos dd ?
CameraRotYTan dd ?

; the vga page that is shown
visiblepage dw VGASegment
CODESEG
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
	; end changing

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
	fld [CameraRotY]
	sincos halfrad
	fstp [CameraRotYSin]
	fstp [CameraRotYCos]
	cld

	FrameLoop:
		setreg SEQUENCER_CTRL, Plane_Mask, 1111b
		xor di,di
		WaitVSync
		cmemset 320*200/4/2,09h
		cmemset 320*200/4/2,00h

		fld [CameraRotYSin]
		fdiv [CameraRotYCos]

		;drawcursor 0fh

		; the intent of the loop below is to draw the vertices of the cube onto the screen,
		; the way it works is by taking the vertices as line intersections from a camera centered axis system
		; where the lines go through (0,0) and (px, py)
		; from there all it needs to do is to calculate the slopes of the lines in x and y in relation to z
		; and multiply them by the focal length to get the position of the pixel in the display plane
		i = 0
		rept pointCount
			local popandnextpoint, nextpoint

			;; load the position of the vertex and translate the origin to the camera's location
			;; the size of a float is 4 bytes
			fld [HalfHeight]
			;;fsub [CameraY]

			fld [pointX + i*4]
			fsub [CameraX]

			fld [pointZ + i*4]
			fsub [CameraZ]

			;; rotate the the axis system with the camera's rotation
			cmacrot [CameraRotYSin] [CameraRotYCos]

			;; compare the z position (ST(0)) to 0 and store result in fputmp
			ftst
			fstsw [word low fputmp]

			;; jump to the next point if this point is behind the camera (ST(0) <= 0)
			test [byte high word low fputmp], c0_mask OR c2_mask OR c3_mask 
			jz popandnextpoint

			;; do [FocalLen]/z and replace z with the result
			fdivr ST(0), ST(3)
			
			;; find the x position on screen
			fxch ST(1)
			fmul ST(0), ST(1)
			fistp [word low fputmp]
			mov cx, [word low fputmp]
			add cx, 320/2

			;; find the y position
			fmulp
			fistp [word low fputmp]
			mov dx, [word low fputmp]
			add dx, 200/2

			;; check if the position is in display range
			cmp cx,320
			jae nextpoint

			push cx dx
			mov di,320*200/2
			add di,cx
			XSetPixel 0fh
			pop dx cx

			cmp dx,200
			jae nextpoint

			;; dx * 320 ➔ di
			mov di,dx
			shl di,2
			add di,dx
			shl di,6
			
			add di,cx
			push cx dx
			XSetPixel 0fh
			pop dx cx

			neg dx
			add dx, 200
			;; dx * 320 ➔ di
			mov di,dx
			shl di,2
			add di,dx
			shl di,6
			
			add di,cx
			XSetPixel 0fh

			jmp nextpoint

			popandnextpoint:
				fstp ST(0)
				fstp ST(0)
				fstp ST(0)
			nextpoint:
			;; change the next point
			i = i + 1
		endm
		WaitDisplayEnable
		flippage [visiblepage]

		fldpi
		cli

		fild [PointerX]
		fmul [MouseSensetivity]
		fadd [CameraRotY]
		fprem
		fadd ST(0), ST(1)
		fprem
		fst [CameraRotY]

		sincos halfrad
		fstp [CameraRotYSin]
		fstp [CameraRotYCos]

		mov [PointerX],0
		mov [PointerY],0

		sti
		fstp ST(0)

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

		; deal with the y axis (dont rotate since there is no rotation on y axis)
		shr al,1
		jnc case5
			fld [CameraY]
			fadd [PlayerSpeed]
			fstp [CameraY]
		case5:
		shr al,1
		jnc case6
			fld [CameraY]
			fsub [PlayerSpeed]
			fstp [CameraY]
		; exit if escape is pressed
		case6:
			shr al,1
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

; vim style select: asmsyntax=tasm
IDEAL
MODEL SMALL
STACK 100h

include "lib/helper16.asm"
include "lib/math.asm"
include "lib/graphics.asm"

sWidth equ 320
sHeight equ 200

; uncomment the following bit of code if you want to add logging
;GraphicsMode=0
;include "lib/logging.asm"

DATASEG
;                        screen width or height
; set FocalLen to:     ⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼
;                              2*tan(ɑ/2)
; where ɑ is the field of view in the width or height (depending on what you set)
FocalLen dd 250.0
WallHalfHeight dd 0.5
CollisionBoxHalfWidth dd 0.2 ; must be less than 0.5 because there will be gaps in the collision box above 0.5
PlayerSpeed dd 0.1 ; blocks / frame (there are 60 frames per second if no frame is skipped)
MouseSensetivity dd 0.001 ; [MouseSensetivity] = half radians / mouse movment

CameraX dd 1.0
CameraZ dd 1.0

; in half radians (the pieriod is π instead of 2π)
CameraRotY dd 0
HalfHeight dd 0.5

CameraRotYSin dd ?
CameraRotYCos dd ?

RotCos dd ?
RotSin dd ?

; an array of the slopes of the rays that are representing columns
SlopeTable dd sWidth dup(?)
; an array of the directions of the rays from before on the z axis
DirTable dw sWidth dup(-1)

; the vga page that is shown
visiblepage dw VGASegment


; bit field of player status:
; [0: left, 1: right, 2: forward, 3: backward, 4: up, 5: down, 6: escape]
kbstatus db 0000000b
scancode db 0ffh

PointerX dw 0
PointerY dw 0

; each byte is a block on the map the player is in
; the color of the block is determined by the value of the byte in the pallete
; this map currently contains a maze
map \
db 20h,20h,20h,20h,20h,20h,20h,20h,27h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h; 0
db 20h,00h,20h,00h,20h,00h,20h,20h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,20h,00h,00h,00h,00h,00h,20h; |
db 20h,00h,20h,00h,20h,00h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,00h,20h,00h,20h,00h,20h,00h,20h; |
db 20h,00h,20h,00h,20h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,20h,00h,20h,00h,20h,00h,00h,00h,00h,00h,20h; |
db 20h,00h,20h,00h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h; |
db 20h,00h,20h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,20h,20h,00h,20h,00h,20h,00h,20h,00h,00h,00h,00h,00h,20h; |
db 20h,00h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,00h,20h,20h,00h,20h,00h,20h,00h,20h,20h,20h,20h,20h,00h,20h; |
db 20h,00h,20h,00h,00h,00h,00h,00h,00h,00h,20h,00h,20h,00h,00h,00h,20h,00h,20h,20h,00h,20h,00h,20h,00h,00h,00h,00h,00h,20h,00h,20h; |
db 20h,00h,20h,20h,20h,20h,20h,20h,20h,00h,20h,00h,00h,00h,20h,00h,20h,00h,20h,20h,00h,20h,00h,20h,20h,20h,20h,20h,00h,20h,00h,20h; |
db 20h,00h,20h,00h,00h,00h,00h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,00h,20h,00h,20h,00h,20h,00h,00h,00h,20h,00h,20h,00h,20h; |
db 20h,00h,20h,20h,20h,20h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h; |
db 20h,00h,00h,00h,00h,00h,00h,00h,20h,00h,20h,00h,20h,00h,20h,00h,00h,00h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h; |
db 20h,00h,20h,20h,20h,20h,20h,20h,20h,00h,20h,20h,20h,00h,20h,20h,20h,20h,20h,20h,00h,20h,00h,20h,00h,20h,20h,20h,00h,20h,00h,20h; |
db 20h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,20h,00h,20h,00h,00h,20h,00h,00h,20h,00h,20h; |
db 20h,00h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,00h,20h,20h,00h,20h,00h,20h,20h,00h,20h; |
db 20h,00h,20h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,20h,00h,00h,20h,00h,20h,20h,00h,20h; |
db 20h,00h,20h,00h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,00h,20h,20h,00h,20h,20h,00h,20h; Z
db 20h,00h,20h,00h,20h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,20h,00h,00h,00h,00h,00h,20h,00h,00h,00h,20h,00h,20h,20h,00h,20h; |
db 20h,00h,20h,00h,20h,00h,20h,20h,20h,20h,20h,20h,20h,00h,20h,00h,20h,00h,20h,20h,20h,00h,20h,00h,20h,00h,20h,00h,20h,20h,00h,20h; |
db 20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,00h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,20h,20h,00h,20h,20h,00h,20h; |
db 20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,00h,20h,20h,00h,00h,20h,00h,20h; |
db 20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,20h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,20h,00h,20h,20h,20h,00h,20h,00h,20h; |
db 20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,00h,00h,00h,00h,20h,00h,20h,00h,20h,00h,20h,00h,00h,00h,00h,20h,00h,00h,00h,00h,00h,20h; |
db 20h,00h,20h,00h,20h,00h,20h,00h,20h,20h,20h,20h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,20h,20h,20h,00h,20h,20h,20h,20h,20h; |
db 20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,00h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,00h,00h,00h,20h,00h,00h,00h,20h; |
db 20h,00h,20h,00h,20h,00h,20h,00h,20h,20h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,20h,20h,20h,00h,20h,20h,20h; |
db 20h,00h,20h,00h,00h,00h,00h,00h,00h,00h,00h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,00h,20h,00h,20h,00h,20h; |
db 20h,00h,20h,00h,20h,20h,20h,00h,20h,20h,20h,20h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,20h,00h,00h,20h,00h,20h,00h,20h; |
db 20h,00h,20h,00h,00h,00h,20h,00h,20h,00h,00h,00h,00h,00h,20h,00h,00h,00h,20h,00h,20h,00h,20h,00h,20h,00h,00h,20h,00h,20h,00h,20h; |
db 20h,00h,20h,20h,20h,20h,20h,00h,20h,20h,20h,20h,20h,00h,20h,20h,20h,20h,20h,00h,20h,00h,20h,00h,20h,20h,20h,20h,00h,20h,00h,20h; |
db 20h,00h,00h,00h,00h,00h,00h,00h,20h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,20h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,20h; |
db 20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h; 31
;   0------------------------------------------------------------X--------------------------------------------------------------31-🢒🢓
CODESEG

include "evnthand.asm"
include "cast.asm"

; create long jump macros that are needed
JumpMacCreate e,ge

; draws a column of a block on to the screen at di
; di = column, cl = color
; ST(0) = z, ST(1) = x, ST(2) = focal length * half wall height
; changes bx
proc DrawBlockColumn
	local @@

	;; find column height
	fsub [CameraZ]
	fxch ST(1)
	fsub [CameraX]
	cmcrotz [CameraRotYSin], [CameraRotYCos]
	fabs

	; FocalLen is the distance between the focal point and the grid of 'pixels'
	; and z is the distance on the camera's z between the camera and the object
	; our goal is to find the height of the point at z = [FocalLen]
	; on a line that intersects the origin and the point at (z,[HalfWallHeight])
	; so we do [FocalLen]*[HalfWallHeight]/z because [HalfWallHeight]/z is the slope
	; and [FocalLen] is the z which is the good old y = mx + b where b is zero
	fdivr ST(0), ST(1) ;; [FocalLen]*[HalfWallHeight] is in ST(1)
	fistp [word low fputmp]

	mov bx,[word low fputmp]
	imin bx,sHeight/2,bx
	mov [word low fputmp],bx

	; bx *= sWidth >> 2
	sal bx,2
	add bx,[word low fputmp]
	sal bx,4

	sub di,bx
	@@AboveLoop:
		mov [byte es:di+sWidth*sHeight/2/4],cl
		add di,80
	jl @@AboveLoop

	add di,bx
	sub di,80
	@@BelowLoop:
		mov [byte es:di+sWidth*sHeight/2/4],cl
		sub di,80
	jge @@BelowLoop
	ret
endp DrawBlockColumn

macro GetCornerBlock x,z
	fld [CameraX]
	if x eq 1
		fadd [CollisionBoxHalfWidth]
	else
		fsub [CollisionBoxHalfWidth]
	endif
	fistp [word low fputmp]

	fld [CameraZ]
	if z eq 1
		fadd [CollisionBoxHalfWidth]
	else
		fsub [CollisionBoxHalfWidth]
	endif
	fistp [word high fputmp]

	mov bx,[word high fputmp]
	shl bx,5
	add bx,[word low fputmp]
endm GetCornerBlock

proc RestoreIfColided
		; check for collision on each corner of the hitbox and return ST(1) if collided
		irp xDir,<1,-1>
			irp zDir,<1,-1>
				local NextCorner
				GetCornerBlock xDir,zDir
				cmp [map+bx],0
				je NextCorner
					fstp ST(0)
					ret
				NextCorner:
			endm
		endm
		; return ST(0) if no collision has occured
		fstp ST(1)
		ret
endp RestoreIfColided

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
	mov ax,VGASegment + sWidth*sHeight/4 SHR 4
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
		mov [word low SlopeTable + bx + 160 * 4], ax
		mov ax, [word high fputmp]
		mov [word high SlopeTable + bx + 160 * 4], ax
	cmp bx,-160*4
	jne SLopeLoop
	fmul [WallHalfHeight]

	fld [CameraRotY]
	sincos halfrad
	fstp [CameraRotYSin]
	fstp [CameraRotYCos]
	cld

	FrameLoop:
		setreg SEQUENCER_CTRL, Plane_Mask, 1111b ; write to all four planes at once
		xor di,di ; start from the start of the page
		cmemset sWidth*sHeight/2/4,09h ; fill sky with blue
		cmemset sWidth*sHeight/2/4,00h ; fill ground with black

		; use seperate loops for diffrent planes in order to improve efficency
		i = 0
		rept 4
			local CastLoop, SignIsDiffrent
			mov ah, 1 SHL i
			setreg SEQUENCER_CTRL, Plane_Mask ;; set the plane we draw to as plane i

			mov dx,1 ; initial guess for the direction on the z axis
			mov bx,(sWidth - 4+i)*4
			mov di,sWidth SHR 2
			CastLoop:
				dec di

				mov cx,[word high (SlopeTable + bx)]
				xor cx,dx
				jns SignIsDiffrent
					neg dx ;; make sure the sign is diffrent
				SignIsDiffrent:

				push bx
				fld [SlopeTable + bx]
				shr bx,1 ;; the size of a word is half of the size of a double
				mov bx,[DirTable + bx]
				call CastRay

				call DrawBlockColumn
				pop bx
			sub bx,4 * 4
			or bx,bx ;; same as cmp bx,0
			jge CastLoop
			i = i + 1
		endm

		cli
		mov ax,[PointerX]
		mov [PointerX],0
		cmp ax,0
		sti
		lje NoRot
		RotateCam:
			mov [word low fputmp],ax
			fild [word low fputmp]
			fmul [MouseSensetivity]
			sincos halfrad
			fstp [RotSin]
			fstp [RotCos]

			; rotate the camera's slope table and direction table
			mov di,sWidth*4
			mov si,sWidth*2
			RotLoop:
				sub si,2 ; sizeof(word) = 2
				sub di,4 ; sizeof(float) = 4
				fild [DirTable + si]
				fld [SlopeTable + di]

				cmacrot [RotSin], [RotCos]
				fxch ST(1)

				fst [fputmp]
				mov ax,[DirTable + si]
				xor ax,[word high fputmp]
				jns NoChange
					neg [DirTable + si]
				NoChange:

				fabs
				fdivp
				fstp [SlopeTable + di]

			or di,di ; the same as cmp bx,0
			jg RotLoop


			fld [CameraRotYSin]
			fld [CameraRotYCos]
			cmacrot [RotSin], [RotCos]
			fstp [CameraRotYCos]
			fstp [CameraRotYSin]
		NoRot:

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
			
		; if we are moving in x and z then we need to multiply by 1/√2 because sin(45°)=1/√2 (and cos)
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
		fld [CameraX]
		fadd ST(1),ST(0)
		fxch ST(1)
		fst [CameraX]
		call RestoreIfColided
		fstp [CameraX]

		fld [CameraZ]
		fadd ST(1),ST(0)
		fxch ST(1)
		fst [CameraZ]
		call RestoreIfColided
		fstp [CameraZ]

		shr al,3
		jc exit
		continue:
			WaitDisplayEnable
			flippage [visiblepage]
			WaitVSync
			jmp FrameLoop
exit:
	; restore keyboard handler
	xor ax,ax
	mov es,ax

	; pop is not atomic so we disable interrupts
	; to make sure that there is no interrupt to unallocated
	; regions of memory
	cli
	pop [word es:4*9+2] [word es:4*9]
	sti ; reenable interrupts

	; remove FocalLen * HalfWallHeight from the fpu's stack
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

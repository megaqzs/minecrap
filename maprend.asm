; vim style select: asmsyntax=nasm
org 0x7C00  ; add 0x7C00 (MBR loading address) to label addresses
bits 16  ; use 16 bit instructions because of realmode

%include "lib/helper16.asm"
%include "lib/math.asm"
%include "lib/graphics.asm"

%include "evnthand.asm"
%include "cast.asm"

; uncomment the following bit of code if you want to add logging
;GraphicsMode=0
;include "lib/logging.asm"

section code follows=entry
section data follows=code

section entry
	cli
	xor ax,ax
	mov ss, ax   ; Set up stack, zero the stack segment
	mov sp, 0x7BFF  ; Stack grows downwards, starting right before the code
	sti

	mov ax,(0x7C00+512) >> 4
	mov es,ax
	mov cx,2 ; the code is at the sector after this one
	mov dh,0
	mov bx,0
	mov ax,0x200+ceildiv(dataseg_size+codeseg_size, 512) ; the number of sectors that are needed
	int 13h
	mov ax,3
	int 10h
	call main

	; power off (or at least for qemu)
	mov dx,0x604
	mov ax,0x2000
	out dx,ax
	jmp $ ; loop forever if it failed

times 510-($-$$) db 0   ; What is this unholy abomination???
dw 0xAA55 ; the magic word

section data
;                        screen width or height
; set FocalLen to:     ⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼
;                              2*tan(ɑ/2)
; where ɑ is the field of view in the width or height (depending on what you set)
FocalLen dd 250.0
WallHalfHeight dd 0.5
CollisionBoxHalfWidth dd 0.2 ; must be less than 0.5 because there will be gaps in the collision box above 0.5
PlayerSpeed dd 0.1 ; blocks / frame
MouseSensetivity dd 0.001 ; [MouseSensetivity] = half radians / mouse movment

CameraX dd 1.0
CameraZ dd 1.0

; in half radians (the pieriod is π instead of 2π)
HalfHeight dd 0.5

CameraRotYSin dd 0.0
CameraRotYCos dd -1.0

; 0 degrees
RotCos dd 1.0
RotSin dd 0.0

; an array of the slopes of the rays that are representing columns
SlopeTable times sWidth dd 0
; an array of the directions of the rays from before on the z axis
DirTable times sWidth dw 1

; the vga page that is shown
visiblepage dw VGASegment

; each byte is a block on the map the player is in
; the color of the block is determined by the value of the byte in the pallete
; this map currently contains a maze
map:
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

dataseg_size equ $-$$

section code

RotateCam:
	; rotate the camera's slope table and direction table
	mov di,sWidth*4
	mov si,sWidth*2
	RotLoop:
		sub si,2 ; sizeof(word) = 2
		sub di,4 ; sizeof(float) = 4
		fild word [DirTable + si]
		fld dword [SlopeTable + di]

		cmacrot dword [RotSin], dword [RotCos]
		fxch st1

		fst dword [fputmp]
		mov ax,word [DirTable + si]
		xor ax,word [WordHigh(fputmp)]
		jns NoChange
			neg word [DirTable + si]
		NoChange:

		fabs
		fdivp
		fstp dword [SlopeTable + di]

	or di,di ; the same as cmp bx,0
	jg RotLoop


	fld dword [CameraRotYSin]
	fld dword [CameraRotYCos]
	cmacrot dword [RotSin], dword [RotCos]
	fstp dword [CameraRotYCos]
	fstp dword [CameraRotYSin]
	ret

; create long jump macros that are needed

; draws a column of a block on to the screen at di
; di = column, cl = color
; st0 = z, st1 = x, ST(2) = focal length * half wall height
; changes bx
DrawBlockColumn:
	;; find column height
	fsub dword [CameraZ]
	fxch st1
	fsub dword [CameraX]
	cmcrotz dword [CameraRotYSin],dword [CameraRotYCos]
	fabs

	; FocalLen is the distance between the focal point and the grid of 'pixels'
	; and z is the distance on the camera's z between the camera and the object
	; our goal is to find the height of the point at z = [FocalLen]
	; on a line that intersects the origin and the point at (z,[HalfWallHeight])
	; so we do [FocalLen]*[HalfWallHeight]/z because [HalfWallHeight]/z is the slope
	; and [FocalLen] is the z which is the good old y = mx + b where b is zero
	fdivr st0, st1 ;; [FocalLen]*[HalfWallHeight] is in ST(1)
	fistp word [WordLow(fputmp)]

	mov bx,word [WordLow(fputmp)]
	imin bx,sHeight/2,bx
	mov word [WordLow(fputmp)],bx

	; bx *= sWidth >> 2
	sal bx,2
	add bx,word [WordLow(fputmp)]
	sal bx,4

	sub di,bx
	.AboveLoop:
		mov byte [es:di+sWidth*sHeight/2/4],cl
		add di,80
	jl .AboveLoop

	add di,bx
	sub di,80
	.BelowLoop:
		mov byte [es:di+sWidth*sHeight/2/4],cl
		sub di,80
	jge .BelowLoop
	retn


; args: x, z
%macro GetCornerBlock 2
	fld dword [CameraX]
	%if %1 == 1
		fadd dword [CollisionBoxHalfWidth]
	%else
		fsub dword [CollisionBoxHalfWidth]
	%endif
	fistp word [WordLow(fputmp)]

	fld dword [CameraZ]
	%if %2 == 1
		fadd dword [CollisionBoxHalfWidth]
	%else
		fsub dword [CollisionBoxHalfWidth]
	%endif
	fistp word [WordHigh(fputmp)]

	mov bx,word [WordHigh(fputmp)]
	shl bx,5
	add bx,word [WordLow(fputmp)]
%endmacro

RestoreIfColided:
		; check for collision on each corner of the hitbox and return st1 if collided
		%assign i 0
		%assign xDir -1
		%rep 2
			%assign zDir -1
			%rep 2
				GetCornerBlock xDir,zDir
				cmp byte [map+bx],0
				je MKLabelI(.NextCorner,i)
					fstp st0
					ret
				MKLabelI(.NextCorner,i):
				%assign zDir 1
				%assign i i+1
			%endrep
		%assign xDir 1
		%endrep
		; return st0 if no collision has occured
		fstp st1
		retn

main:
	; change keyboard handler
	xor ax,ax
	mov es,ax
	mov ds,ax

	mov ah,PS2WR_Bit
	call PS2Wait
	mov al,0xA8
	out 0x64,al
	call PS2rd

	; change the compaq status byte
	mov ah,PS2WR_Bit
	call PS2Wait
	mov al,0x20
	out 0x64,al
	call PS2rd
	bts ax,1
	btr ax,5
	mov bl,al

	; write the new compaq status byte
	mov ah,PS2WR_Bit
	call PS2Wait
	mov al,0x60
	out 0x64,al
	call PS2Wait
	mov al,bl
	out 0x60,al
	call PS2rd ; read optional ACK

	; set defaults
	mov ah,PS2WR_Bit
	call PS2Wait
	mov al,0xD4
	out 0x64,al
	mov ah,PS2WR_Bit
	call PS2Wait
	mov al,0xF6
	out 0x60,al
	call PS2rd

	; enable packets
	mov ah,PS2WR_Bit
	call PS2Wait
	mov al,0xD4
	out 0x64,al
	mov ah,PS2WR_Bit
	call PS2Wait
	mov al,0xF4
	out 0x60,al
	call PS2rd

	mov word [PointerX],0
	mov word [PointerY],0

	cli
	; save the current interrupt service rutines
	push dword [es:IRQOffset(1)]
	push dword [es:IRQOffset(12)]

	; replace them with the ones from evnthand.asm
	mov word [es:IRQOffset(1)+2],0
	mov word [es:IRQOffset(1)],keyboardhandler
	mov word [es:IRQOffset(11)+2],0
	mov word [es:IRQOffset(11)],mousehandler
	sti

	; change to graphical mode
	mov ax,13h
	int 10h
	SetModeX

	; prepare for display loop

	; es is the page we currently draw to so it is the vga segment + the offset of the page in it
	; right shift by 4 is there because the address is 20 bits wide and es is 16 bits wide and at the end of the address
	mov ax,VGASegment + (320*200/4 >> 4)
	mov es,ax
	finit
	fld dword [FocalLen]

	; initialize slope table
	mov bx,sWidth*4
	mov cx,160
	.SlopeLoop:
		sub bx,4
		dec cx
		mov word [WordLow(fputmp)],cx
		fild word [WordLow(fputmp)]
		fdiv st0,st1
		fstp dword [fputmp]
		mov ax,word [WordLow(fputmp)]
		mov word [WordLow(SlopeTable + bx)], ax
		mov ax, word [WordHigh(fputmp)]
		mov word [WordHigh(SlopeTable + bx)], ax
	cmp bx,0
	jne .SlopeLoop
	fmul dword [WallHalfHeight]

	call RotateCam
	cld

	.FrameLoop:
		setreg SEQUENCER_CTRL, Plane_Mask, 1111b ; write to all four planes at once
		xor di,di ; start from the start of the page
		cmemset sWidth*sHeight/2/4,09h ; fill sky with blue
		cmemset sWidth*sHeight/2/4,00h ; fill ground with black

		; use seperate loops for diffrent planes in order to improve efficency
		%assign i 0
		%rep 4
			mov ah, 1 << i
			setreg SEQUENCER_CTRL, Plane_Mask ;; set the plane we draw to as plane i

			mov dx,1 ; initial guess for the direction on the z axis
			mov bx,(sWidth - 4+i)*4
			mov di,sWidth >> 2
			MKLabelI(.CastLoop,i):
				dec di

				mov cx,word [WordHigh(SlopeTable + bx)]
				xor cx,dx
				jns MKLabelI(.SignIsDiffrent,i)
					neg dx ;; make sure the sign is diffrent
				MKLabelI(.SignIsDiffrent,i):

				push bx
				fld dword [SlopeTable + bx]
				shr bx,1 ;; the size of a word is half of the size of a double
				mov bx,word [DirTable + bx]
				call CastRay

				call DrawBlockColumn
				pop bx
			sub bx,4 * 4
			or bx,bx ;; same as cmp bx,0
			jge MKLabelI(.CastLoop,i)
			%assign i i+1
		%endrep

		cli
		mov ax,word [PointerX]
		mov word [PointerX],0
		sti
		cmp ax,0
		je .NoRot
			; calculate the sin and cos of the angle of rotation
			mov word [WordLow(fputmp)],ax
			fild word [WordLow(fputmp)]
			fmul dword [MouseSensetivity]
			sincos halfrad
			fstp dword [RotSin]
			fstp dword [RotCos]

			call RotateCam
		.NoRot:

		; check for events
		mov al, byte [kbstatus]

		; load (x,z) vector and initialize it to zero
		fldz
		fldz

		; load the speed of the player
		fld dword [PlayerSpeed]
		; test if we are moving in x and z
		mov ah,al
		shr ah,1
		xor ah,al
		test ah,101b ; zf is unset and pf is set only if (((move left) ⊕ (move right)) ∧ ((move backward) ⊕ (move forward)))
		jz .if0
		jnp .if0
			
		; if we are moving in x and z then we need to multiply by 1/√2 because sin(45°)=1/√2 (and cos)
		fmul dword [InvSqrt2]

		; st0: increment, st1: x, ST(2): z
		.if0:
		shr al,1
		jnc .if1
			fadd st1, st0
		.if1:
		shr al,1
		jnc .if2
			fsub st1, st0
		.if2:
		shr al,1
		jnc .if3
			fsub st2, st0
		.if3:
		shr al,1
		jnc .endif3
			fadd st2, st0
		.endif3:

		fstp st0 ; we dont need the corrected increment any more

		; rotate the velocity vector by the y axis rotation
		cmacrot dword [CameraRotYSin], dword [CameraRotYCos]

		; add the velocity vector to the location (since x=x₀+v*t and we are repeatedly adding the velocity over time which is equivilant to multiplacation)
		fld dword [CameraX]
		fadd st1,st0
		fxch st1
		fst dword [CameraX]
		call RestoreIfColided
		fstp dword [CameraX]

		fld dword [CameraZ]
		fadd st1,st0
		fxch st1
		fst dword [CameraZ]
		call RestoreIfColided
		fstp dword [CameraZ]

		shr al,3
		jc exit
		.continue:
			WaitDisplayEnable ; the start address is calculated at the end of a scanline which means there is plenty of time to set it
			flippage word [visiblepage]
			WaitVSync ; wait until the vga has had time to read the start address so that we dont draw into the current display
			jmp .FrameLoop
exit:
	; restore keyboard handler
	xor ax,ax
	mov es,ax

	; we disable interrupts to make sure that there
	; is no interrupt to unallocated regions of memory
	cli
	pop dword [es:IRQOffset(12)]
	pop dword [es:IRQOffset(1)]
	sti ; reenable interrupts

	; remove FocalLen * HalfWallHeight from the fpu's stack
	fstp st0

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

	ret
codeseg_size equ $-$$

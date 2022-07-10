; vim style select: asmsyntax=nasm

ClippingDistance equ 64 ; the number of block checks before we give up on finding a collision

section data
section code
; jump to IfDoesntExists if the block at si is empty
; or to SafeExit if the loop exceeded the limit number of iterations
; args: IfDoesntExists, SafeExit
%macro CmpBlock 2
	dec cx ; reduce the block collision counter
	ljcc l,%2 ; safely exit if the ray is to long

	cmp byte [map+si],0
	je %1

	mov cl, byte [map+si]
%endmacro CmpBlock


; why did i think this was easy
; gets a slope in st0, dx and bx for the x and z directions respectively
; and returns an intersection point in st0 for z and st1 for x and cl for the value of the block
; changes ax,bx,cx,si
CastRay:
	; find the distance in x to the collision of the ray with the edge of the square on the z axis
	fld dword [CameraZ]
	fist word [WordLow(fputmp)] ; save the cameras z for later and now

	; the rounding mode is nearest meanning
	; this is the position in the block relative to the center on the z axis
	fisub word [WordLow(fputmp)]
	or bx,bx ; the same as cmp bx,0
	jg .Positive
		fadd dword [Half]
		jmp .EndIf
	.Positive:
		fsubr dword [Half]
	.EndIf:

	fmul st0, st1 ; st1 is the slope so this turns st(0) to the distance

	mov si,word [WordLow(fputmp)] ; the cameras z from before
	sal si,5 ; the map is 32 blocks wide and log2(32) = 5
	; which means this multiplies si by 32

	fld dword [CameraX]
	fist word [WordLow(fputmp)]
	mov ax,word [WordLow(fputmp)] ; store the x in ax
	; add the x to si to turn it into the block index of the camera
	add si,ax

	faddp
	fist word [WordLow(fputmp)]
	fisub word [WordLow(fputmp)]

	; loop through every block in the ray's path until we find a collision
	; and calculate its location or until we reach the limit of attempts
	sub ax,word [WordLow(fputmp)]
	neg ax
	sal bx,5 ; bx * 32 because 32 is the map's width
	mov cx,ClippingDistance ; the number of block collisions we test before giving up
	jmp .RayTest
	.ZLoop:
		add si,bx
		; the block below is executed if the ray collided on the z axis
		CmpBlock .NotCollidingOnZ, .SafeExit
			fstp st1 ; we dont need the slope any more
			; find the x of the collision
			mov word [WordLow(fputmp)],si
			and word [WordLow(fputmp)],11111b ; word [WordLow(fputmp)] = si % 32 or block x
			fiadd word [WordLow(fputmp)] ; add it to the in block x

			; find the z of the collision
			mov word [WordLow(fputmp)],si
			sar word [WordLow(fputmp)],5 ; word [WordLow(fputmp)] = si / 32 or block z
			fild word [WordLow(fputmp)]
			or bx,bx ; this means cmp bx,0
			jl .ZEnd2
			; end 1
			fsub dword [Half]
			ret
			.ZEnd2:
			fadd dword [Half]
			ret
		.NotCollidingOnZ:
		; find the distance to the next point on the line in st0
		fadd st0, st1
		fist word [WordLow(fputmp)]
		fisub word [WordLow(fputmp)]

		; put the distance to the current point on the x line in ax
		mov ax, word [WordLow(fputmp)]
		.XLoop:
			or ax,ax ; faster than cmp ax,0 on real hardware but also acts the same way
			je .ZLoop

			sub ax,dx
			add si,dx

			.RayTest:
			; the block below is executed if the ray collided on the x axis
			CmpBlock .XLoop,.SafeExit
				add cl,48h ; use a darker color for x collision

				fstp st0
				; find the x of the collision
				mov word [WordLow(fputmp)],si
				and word [WordLow(fputmp)],11111b ; word [WordLow(fputmp)] = si % 32 or block x
				fild word [WordLow(fputmp)]
				; block x + dx * 0.5
				or dx,dx ; same as cmp dx,0
				jl .NegXDir
					fsub dword [Half]
					jmp .endIf1
				.NegXDir:
					fadd dword [Half]
				.endIf1:

				fxch st1

				; find the z of the collision
				fld st1
				fsubr dword [CameraX]
				fdivrp ; stupid division why couldn't it be multiplication
				or bx,bx ; cmp bx,0 again
				jl .XEnd2
				fsubr dword [CameraZ]
				ret
				.XEnd2:
				fadd dword [CameraZ]
				ret
		.SafeExit: 
		fstp st0
		fstp st0
		fldz
		fldz
		retn

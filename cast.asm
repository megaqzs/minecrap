; vim style select: asmsyntax=tasm
ClippingDistance equ 50 ; the number of block checks before we give up on rendering the column

; jump to IfDoesntExists if the block at si is empty
; or to SafeExit if the loop exceeded the limit number of iterations
macro CmpBlock IfDoesntExists, SafeExit
	local NoSafeExit
	dec cx ; reduce the block collision counter
	jnz NoSafeExit ; safely exit if the ray is to long
		jmp SafeExit ; safely exit if the ray is to long
	NoSafeExit:

	cmp [map+si],0
	je IfDoesntExists

	mov cl, [map+si]
endm CmpBlock


; why did i think this was easy
; gets a slope in ST(0), and dx and bx for the x direction and z direction respectively
; and returns an intersection point in ST(0) for z and ST(1) for x
; changes ax,bx,cx,si
proc CastRay
	locals @@
	; find the distance in x to the collision of the ray with the edge of the square on the z axis
	fld [CameraZ]
	fist [word low fputmp] ; save the cameras z for later and now

	; the rounding mode is nearest meanning
	; this is the position in the block relative to the center on the z axis
	fisub [word low fputmp]
	or bx,bx ; the same as cmp bx,0
	jg @@Positive
		fadd [Half]
		jmp @@EndIf
	@@Positive:
		fsubr [Half]
	@@EndIf:

	fmul ST(0), ST(1) ; st(1) is the slope so this turns st(0) to the distance

	mov si,[word low fputmp] ; the cameras z from before
	sal si,5 ; the map is 32 blocks wide and log2(32) = 5
	; which means this multiplies si by 32

	fld [CameraX]
	fist [word low fputmp]
	mov ax,[word low fputmp] ; store the x in ax
	; add the x to si to turn it into the block index of the camera
	add si,ax

	faddp
	fist [word low fputmp]
	fisub [word low fputmp]

	; loop through every block in the ray's path until we find a collision
	; and calculate its location or until we reach the limit of attempts
	sub ax,[word low fputmp]
	neg ax
	sal bx,5 ; bx * 32 because 32 is the map's width
	mov cx,80 ; the number of block collisions we test before giving up
	jmp @@RayTest
	@@ZLoop:
		add si,bx
		; the block below is executed if the ray collided on the z axis
		CmpBlock @@NotCollidingOnZ, @@SafeExit
			fstp ST(1) ; we dont need the slope any more
			; find the x of the collision
			mov [word low fputmp],si
			and [word low fputmp],11111b ; [word low fputmp] = si % 32 or block x
			fiadd [word low fputmp] ; add it to the in block x

			; find the z of the collision
			mov [word low fputmp],si
			sar [word low fputmp],5 ; [word low fputmp] = si / 32 or block z
			fild [word low fputmp]
			or bx,bx ; this means cmp bx,0
			jl @@ZEnd2
			; end 1
			fsub [Half]
			ret
			@@ZEnd2:
			fadd [Half]
			ret
		@@NotCollidingOnZ:
		; find the distance to the next point on the line in ST(0)
		fadd ST(0), ST(1)
		fist [word low fputmp]
		fisub [word low fputmp]

		; put the distance to the current point on the x line in ax
		mov ax, [word low fputmp]
		@@XLoop:
			or ax,ax ; faster than cmp ax,0 on real hardware
			jz @@ZLoop

			sub ax,dx
			add si,dx

			@@RayTest:
			; the block below is executed if the ray collided on the x axis
			CmpBlock @@XLoop, @@SafeExit
				add cl,48h ; use darker color for x collision

				fstp ST(0)
				; find the x of the collision
				mov [word low fputmp],si
				and [word low fputmp],11111b ; [word low fputmp] = si % 32 or block x
				fild [word low fputmp]
				; block x + dx * 0.5
				or dx,dx ; same as cmp dx,0
				jl @@NegXDir
					fsub [Half]
					jmp @@endIf1
				@@NegXDir:
					fadd [Half]
				@@endIf1:

				fxch ST(1)

				; find the z of the collision
				fld ST(1)
				fsubr [CameraX]
				fdivrp ; stupid division why couldn't it be multiplication
				or bx,bx ; cmp bx,0 again
				jl @@XEnd2
				fsubr [CameraZ]
				ret
				@@XEnd2:
				fadd [CameraZ]
				ret
		@@SafeExit: 
		fstp ST(0)
		fstp ST(0)

		fldz
		fldz
		ret
endp CastRay

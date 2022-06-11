; vim style select: asmsyntax=tasm
macro CmpBlock IfDoesntExists, SafeExit
	local NoSafeExit
	jnz NoSafeExit ; safely exit if the ray is to long
		jmp SafeExit ; safely exit if the ray is to long
	NoSafeExit:

	cmp [map+bx],0
	je IfDoesntExists

	mov cl, [map+bx] ; use as color for now
endm CmpBlock


; why did i think this was easy
; gets a slope in ST(0)
; and returns an intersection point in ST(0) for z and ST(1) for x
; changes ax,bx,cx
proc CastRay
	locals @@
	; find the distance in x to the collision of the ray with the edge of the square on the z axis
	fld [CameraZ]
	fist [word low fputmp] ; save the cameras z for later and now

	; the rounding mode is nearest meanning
	; this is the negative of the position in the block relative to the center on the z axis
	fisub [word low fputmp]
	fadd [Half] ; fix me later

	fmul ST(0), ST(1) ; st(1) is the slope so this turns st(0) to the distance

	mov bx,[word low fputmp] ; the cameras z from before
	shl bx,4 ; the map is sixteen blocks wide and log2(16) = 4
	; which means this multiplies bx by 16

	fld [CameraX]
	fist [word low fputmp]
	mov ax,[word low fputmp] ; store the x in ax
	; add the x to bx to turn it into the block index of the camera
	add bx,ax

	faddp
	fist [word low fputmp]
	fisub [word low fputmp]

	sub ax,[word low fputmp]
	neg ax
	mov cx,26
	mov [word high fputmp],-16
	jmp @@RayTest
	@@ZLoop:
		add bx, [word high fputmp] ; TODO change sign if ray direction
		dec cl ; make sure this isn't infinite
		; the block below is executed if the ray collided on the z axis
		CmpBlock @@NotCollidingOnZ, @@SafeExit
			fstp ST(1) ; we dont need the slope any more
			; find the x of the collision
			mov [word low fputmp],bx
			and [word low fputmp],1111b ; [word low fputmp] = bx % 16 or block x
			fiadd [word low fputmp] ; add it to the in block x

			; find the z of the collision
			mov [word low fputmp],bx
			shr [word low fputmp],4 ; [word low fputmp] = bx / 16 or block z
			fild [word low fputmp]
			fadd [Half] ; fix me later
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
			add bx,dx

			@@RayTest:
			dec cl ; make sure this isn't infinite
			jz @@SafeExit ; safely exit if the ray is to long

			; the block below is executed if the ray collided on the x axis
			CmpBlock @@XLoop, @@SafeExit
				fstp ST(0)
				; find the x of the collision
				mov [word low fputmp],bx
				and [word low fputmp],1111b ; [word low fputmp] = bx % 16 or block x
				fild [word low fputmp]
				fld [Half]
				; block x + dx * 0.5
				or dx,dx
				js @@neg
					fchs
				@@neg:
				faddp
				fxch ST(1)

				; find the z of the collision
				fld ST(1)
				fsubr [CameraX]
				fdivrp ; stupid division why couldn't it be multiplication

				fadd [CameraZ]

				add cl,48h ; use darker color for x collision
				ret
		@@SafeExit: 
		fstp ST(0)
		fstp ST(0)

		fldz
		fldz
		ret
endp CastRay

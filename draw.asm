; asmsyntax=tasm

macro XDrawColumn color,HalfHeight
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

	shr HalfHeight,2
	push di
	sub di,HalfHeight
	AboveLoop:
		mov [byte es:di], color
	add di,80
	cmp di,8000
	jb AboveLoop
	pop di

	add di,HalfHeight
	add di,80
	BelowLoop:
		mov [byte es:di], color
	sub di,80
	cmp di,8000
	jae BelowLoop
endm XDrawColumn


; asmsyntax=tasm

TRUE equ 1
FALSE equ -1

CODESEG

macro memset Size, value
	mov ax, value OR (value SHL 8)
	shr cx,1
	rep stosw
	adc cx,0
	rep stosb
endm memset

; set Size values in es:di to Value
; changes ax cx di df
macro cmemset Size, Value
	local id
	if Size eq 0
		goto exitm
	endif

	cld
	mov al,Value

	if (Size and 1) eq 1
		stosb
		if (Size / 2) eq 0
			goto exitm
		endif
	endif

	mov ah,al
	mov cx, Size / 2
	rep stosw
	:exitm
endm cmemset

macro memcpy
	shr cx,1
	rep movsw
	adc cx,0
	rep movsb
endm memcpy

; same as memcpy but only works on constant sizes and faster
; changes cx, df
macro cmemcpy Size
	if (Size and 1) eq 1
		movsb
	endif
	if (Size / 2) eq 0
		goto exitm
	endif

	mov cx, Size / 2
	rep movsw
	:exitm
endm cmemcpy

macro ljz addr
	local mexit
	jnz mexit
		jmp addr
	mexit:
endm ljz

macro ljnz addr
	local mexit
	jz mexit
		jmp addr
	mexit:
endm ljnz

macro lje addr
	local mexit
	jne mexit
		jmp addr
	mexit:
endm lje

macro ljne addr
	local mexit
	je mexit
		jmp addr
	mexit:
endm ljne

macro dwrol reg1, reg2, count
	clc
	rept count
		rcl reg1,1
		rcl reg2,1
		adc reg1,0
	endm
endm dwrol

macro dwror reg1, reg2, count
	clc
	rept count
		rcr reg2,1
		rcr reg1,1
		rcl reg2,1
		ror reg2,1
	endm
endm dwrol

macro rpush a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15
	ifnb <a1>
		rpush a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15
		push a1
	endif
endm rpush

macro rpop a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15
	ifnb <a1>
		rpop a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15
		pop a1
	endif
endm rpop

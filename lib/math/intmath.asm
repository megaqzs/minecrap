; vim syntax type: asmsyntax=tasm

; the floor of log base 2 of loc into loc
; loc_size is the size of loc in bits
macro ulog2 loc, loc_size
	local exit_m, i
	cmp loc, 0

	i = -1
	rept loc_size
		local no_exit

		jnz no_exit
			mov loc, i
			jmp exit_m
		no_exit:
		shr loc, 1
		i = i + 1
	endm
	exit_m:
endm ulog2

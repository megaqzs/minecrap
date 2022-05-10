; asmsyntax=tasm
IDEAL
MODEL small
STACK 200h

; set to 0 for mode x (requires graphics.asm to be included first) or 1 for any chained/text modes
GraphicsMode equ 1

include "lib/helper16.asm"
include "lib/graphics.asm"
USE_FLOAT=1
include "lib/math.asm"
include "lib/logging.asm"

DATASEG

asdf dd 12.567899
CODESEG

macro rangered
	local end_m
	;; leave a comment if you want to be bored to death with comments explaining this
	;; and make your comment explain this because i dont want to
	fabs
	fld [HalfPi]
	fxch ST(1)
	fprem
	fstsw [word high fputmp]
	test [byte high word high fputmp], c1_mask
	jz end_m
		fsub ST(0), ST(1)
	end_m:
	fstp ST(1)
endm rangered

macro fast_sin
	fadd [HalfPi]
	fast_cos
endm fast_sin

Four dw 4
; Bhaskara I's cosine approximation
macro fast_cos
	local end_m
	rangered
	;; Magic
	fmul ST(0), ST(0)
	fld ST(0)
	fimul [Four]
	fldpi
	fmul ST(0), ST(0)
	fsubr ST(1), ST(0)
	faddp ST(2)
	fdivrp
	;; the xor truth table of bit 0 and bit 1 lines up with the sign in the quadrents of cos x so...
	test [byte high word high fputmp], c1_mask OR c3_mask
	jp end_m
		fchs
	end_m:
endm fast_cos

main:
	push @data
	pop ds

	fld [asdf]
	call printfloat
exit:
	exitcode 0
END main

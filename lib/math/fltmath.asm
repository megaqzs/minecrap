; vim syntax type: asmsyntax=tasm

; condition code flag masks in the higher byte of the status word
c0_mask equ  00000001b
c1_mask equ  00000010b
c2_mask equ  00000100b
c3_mask equ  01000000b

; angle conversion names
rad equ 0
deg equ 1
halfrad equ 2

; rounding modes for floating point to integer conversion

; round to the nearest numbers (0<=x<0.5 ➞ 0, 0.5<=x<=1 ➞ 1)
rnd_near  equ 00b

; round to the number closest to -∞ (⌊x⌋ or 0<=x<1 ➞ 0, -1<=x<0 ➞ -1)
rnd_floor equ 01b

; round to the number closest to ∞ (⌈x⌉ or 0<x<=1 ➞ 1, -1<=x<0 ➞ 0)
rnd_ceil  equ 10b

; remove the part after the decimal point (0<=x<1 ➞ 0, 0>=x>-1 ➞ 0)
rnd_trunc equ 11b

; some usefull values
DEF_PI equ 3.141592653589793
DEF_TWOPI equ 6.283185307179586
DEF_QUARTERPI equ 0.7853981633974483
DEF_HALFPI equ 1.5707963267948966
DEF_SQRT2 equ 1.4142135623730951
DEF_INVSQRT2 equ 0.7071067811865476

DATASEG
; there's no need for pi because of fldpi
TwoPi dd 6.283185307179586 ; 2π
QuarterPI dd 0.7853981633974483 ; π/4
HalfPI dd 1.5707963267948966 ; π/2
Sqrt2 dd 1.4142135623730951 ; √2
InvSqrt2 dd 0.7071067811865476 ; 1/√2

Four dw 4
Two dw 2
Half dd 0.5

; temporary buffer for fpu data
fputmp dd ?

; conversion constants
; multiplly to convert from the first unit to the second
; and divide by the constant to convert the second unit to the first
	; degrees to half radians or π/360
	DegToHalfRad dd 0.00872664625997
	; degrees to radians or 2π/360
	DegToRad dd 0.01745329251994
CODESEG

; ST(0) = tan(ST(0)) (in radians)
; put the 3 least significant bits of (ST(0) / π/4) into [word low fputmp] along with some garbage
; or fptan with range reduction and division
; requires one more fpu stack register
; changes [fputmp]
proc tan
	locals @@
;---- NOTES ----
	; ST(0) is the current value in ST(0) and ɑ is the original value of ST(0) at the start of the procedure
;---- CODE ----

	; store the result of comparing ɑ to zero in [word high fputmp] and replace ST(0) with |ɑ| in order to not deal with the sign
	ftst
	fstsw [word high fputmp]
	fabs

	; do ST(0) % π/4 and put the lower 3 bits of (ST(0) / π/4) into [word low fputmp] (among all the things in the status word at the time)
	fld [QuarterPI]
	fxch ST(1)
	fprem
	fstsw [word low fputmp]

	; we test the first 2 bits since the range is reduced to 0 ≤ x ≤ π/4
	; and since this creates four quadrents in the period of tan (the period is π)
	; tan can be called from four seperate places which represent the four diffrent quadrents of the period
	test [byte high word low fputmp], c3_mask
	jnz @@q1x
		test [byte high word low fputmp], c1_mask
		jnz @@q01
	;if ⌊|ɑ| / π/4⌋ % 4 == 00b than
			fxch ST(1)
			fstp ST(0)
			fptan
			fdivp
			; change the sign if ɑ is negative or zero (-tan(ɑ)=tan(-ɑ))
			test [byte high word high fputmp], c0_mask OR c2_mask OR c3_mask
			jnz @@changesign_ret
			ret
		@@q01:
	;if ⌊|ɑ| / π/4⌋ % 4 == 01b than
			fsubp
			fptan
			fdivrp
			; change the sign if ɑ is negative or zero (-tan(ɑ)=tan(-ɑ))
			test [byte high word high fputmp], c0_mask OR c2_mask OR c3_mask
			jnz @@changesign_ret
			ret
	@@q1x:
		test [byte high word low fputmp], c1_mask
		jnz @@q11
	;if ⌊|ɑ| / π/4⌋ % 4 == 10b than
			fxch ST(1)
			fstp ST(0)
			fptan
			fdivrp
			; change the sign if ɑ is positive (-tan(ɑ)=tan(-ɑ))
			test [byte high word high fputmp], c0_mask OR c2_mask OR c3_mask
			jz @@changesign_ret
			ret
		@@q11:
	;if ⌊|ɑ| / π/4⌋ % 4 == 11b than
			fsubp
			fptan
			fdivp
			; change the sign if ɑ is positive (-tan(ɑ)=tan(-ɑ))
			test [byte high word high fputmp], c0_mask OR c2_mask OR c3_mask
			jz @@changesign_ret
			ret
	@@changesign_ret:
	fchs
	ret
endp tan

; ST(0) = cos(ST(0)) (in the unit angle_unit)
; requires two more free fpu stack registers
macro cos angle_unit
	if angle_unit eq rad
		fmul [Half]
	elseif angle_unit eq deg
		fmul [DegToHalfRad]
	elseif angle_unit eq halfrad
	;; no need for conversion 
	else
		fmul [Half]
	endif

	;; the code below represents:
	;;    1 - tan²(ɑ/2)
	;;   ⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼
	;;    1 + tan²(ɑ/2)

	call tan
	fmul ST(0), ST(0)
	fld ST(0)

	fld1
	fadd ST(2), ST(0)
	fsubrp

	fdivrp
endm cos

; ST(0) = sin(ST(0)) (in the unit angle_unit)
; halfrad is the most efficent unit
; requires two more fpu stack registers
macro sin angle_unit
	if angle_unit eq rad
		fmul [Half]
	elseif angle_unit eq deg
		fmul [DegToHalfRad]
	elseif angle_unit eq halfrad
	;; no need for conversion 
	else
		fmul [Half]
	endif

	;; the code below represents:
	;;      2tan(ɑ/2)
	;;   ⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼⎼ = sin(ɑ)
	;;    1 + tan²(ɑ/2)

	call tan
	fld ST(0)
	fimul [Two]
	fxch ST(1)

	fmul ST(0), ST(0)
	fld1
	faddp

	fdivp
endm sin

; same as sin and cos together but more efficent
; ST(0) = sin(ST(0)), ST(1) = cos(ST(0))
; requires three more fpu stack registers
macro sincos angle_unit
	ifnb <angle_unit>
		if angle_unit eq rad
			fmul [Half]
		elseif angle_unit eq deg
			fmul [DegToHalfRad]
		elseif angle_unit eq halfrad
		;; no need for conversion 
		else
			fmul [Half]
		endif
	else
		fmul [Half]
	endif

	call tan
	fld ST(0)
	fimul [Two]
	fxch ST(1)

	fmul ST(0), ST(0)
	fld ST(0)

	fld1
	fadd ST(2), ST(0)
	fsubrp

	fdiv ST(0), ST(1)

	fxch ST(2)
	fdivrp
endm sincos

macro rangered
	local end_m
endm rangered

macro fast_sin
	fadd [HalfPi]
	fast_cos
endm fast_sin

; Bhaskara I's cosine approximation
macro fast_cos angle_unit
	local end_a, end_b
	ifnb <angle_unit>
		if angle_unit eq deg
			fmul [DegToRad]
		elseif angle_unit eq halfrad
			fmul [Half]
		endif
	endif
	;; leave a comment if you want to be bored to death with comments explaining this
	;; and make your comment explain this because i dont want to
	fabs
	fld [HalfPi]
	fxch ST(1)
	fprem
	fstsw [word high fputmp]
	test [byte high word high fputmp], c1_mask
	jz end_a
		fsub ST(0), ST(1)
	end_a:
	fstp ST(1)
	;; Magic
	fmul ST(0), ST(0)
	fld ST(0)
	fimul [Four]
	fldpi
	fmul ST(0), ST(0)
	fsubr ST(1), ST(0)
	faddp ST(2)
	fdivrp
	;; the parity truth table of bit 0 and bit 1 lines up with the sign in the quadrents of cos x so...
	test [byte high word high fputmp], c1_mask OR c3_mask
	jp end_b
		fchs
	end_b:
endm fast_cos

; sets the round control bits in the fpu's status word to RoundingMode
; changes [word low fputmp]
macro fsetrc RoundingMode
	fstcw [word low fputmp]
	and [byte high word low fputmp], NOT (11b SHL 2)
	or [byte high word low fputmp], RoundingMode SHL 2
	fldcw [word low fputmp]
endm fsetrc

; change the round control bits in the fpu's status word from CURR_RoundingMode to NEW_RoundingMode
; changes [word low fputmp]
macro fchgrc NEW_RoundingMode, CURR_RoundingMode
	fstcw [word low fputmp]
	xor [byte high word low fputmp], (NEW_RoundingMode XOR CURR_RoundingMode) SHL 2
	fldcw [word low fputmp]
endm fchgrc

; rotate the x and y locations in ST(0) and ST(1) by ɑ expressed by sin(ɑ) and cos(ɑ) in the arguments
; since x and y locations can be seen as x=c*cos(ɑ) or y=c*sin(ɑ)
; if we put them in the identities used by the macro as the "sin(beta)" and "cos(beta)" we get x=c*cos(ɑ + beta), y=c*sin(ɑ + beta)
; which is essentially rotation
macro cmacrot sin, cos
	;;                       (  sin(ɑ + β) = sin(ɑ) * cos(β) + cos(ɑ) * sin(β), )
	;; angle sum identities: <                                                  >
	;;                       (  cos(ɑ + β) = cos(ɑ) * cos(β) - sin(ɑ) * sin(β)  )
	fld ST(0)
	fld ST(2)

	fmul cos
	fxch ST(1)
	fmul sin
	faddp
	fxch ST(2)

	fmul sin
	fxch ST(1)
	fmul cos
	fsubrp
endm cmacrot

; get the inversely rotated z location from x in ST(0) and z in ST(1) and sin,cos of the angle in the arguments
macro cmcrotz sin,cos
	;; angle diffrence identitiy: sin(ɑ - β) = sin(ɑ) * cos(β) - cos(ɑ) * sin(β)
	fmul sin
	fxch ST(1)
	fmul cos
	fsubrp
endm cmcrotz

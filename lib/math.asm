; vim syntax type: asmsyntax=nasm

; condition code flag masks in the higher byte of the status word
c0_mask equ  0000000100000000b
c1_mask equ  0000001000000000b
c2_mask equ  0000010000000000b
c3_mask equ  0100000000000000b

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

section data
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
fputmp dd 0

; conversion constants
; multiplly to convert from the first unit to the second
; and divide by the constant to convert the second unit to the first
	; degrees to half radians or π/360
	DegToHalfRad dd 0.00872664625997
	; degrees to radians or 2π/360
	DegToRad dd 0.01745329251994
section code

; st0 = tan(st0) (in radians)
; put the 3 least significant bits of (st0 / π/4) into word [WordLow(fputmp)] along with some garbage
; or fptan with range reduction and division
; requires one more fpu stack register
; changes [fputmp]
tan:
	; store the result of comparing ɑ to zero in word [WordHigh(fputmp)] and replace st0 with |ɑ| in order to not deal with the sign
	ftst
	fstsw word [WordHigh(fputmp)]
	fabs

	; do st0 % π/4 and put the lower 3 bits of (st0 / π/4) into word [WordLow(fputmp)] (among all the things in the status word at the time)
	fld dword [QuarterPI]
	fxch st1
	fprem
	fstsw word [WordLow(fputmp)]


	; we test the first 2 bits since the range is reduced to 0 ≤ x ≤ π/4
	; and since this creates four quadrents in the period of tan (the period is π)
	; tan can be called from four seperate places which represent the four diffrent quadrents of the period
	test word [WordLow(fputmp)], c3_mask
	jnz .q1x
		test word [WordLow(fputmp)], c1_mask
		jnz .q01
	;if ⌊|ɑ| / π/4⌋ % 4 == 00b than
			fxch st1
			fstp st0
			fptan
			fdivp
			; change the sign if ɑ is negative or zero (-tan(ɑ)=tan(-ɑ))
			test word [WordHigh(fputmp)], c0_mask | c2_mask | c3_mask
			jnz .changesign_ret
			retn
	;if ⌊|ɑ| / π/4⌋ % 4 == 01b than
		.q01:
			fsubp
			fptan
			fdivrp
			; change the sign if ɑ is negative or zero (-tan(ɑ)=tan(-ɑ))
			test word [WordHigh(fputmp)], c0_mask | c2_mask | c3_mask
			jnz .changesign_ret
			retn
	.q1x:
		test word [WordLow(fputmp)], c1_mask
		jnz .q11
	;if ⌊|ɑ| / π/4⌋ % 4 == 10b than
			fxch st1
			fstp st0
			fptan
			fdivrp
			; change the sign if ɑ is positive (-tan(ɑ)=tan(-ɑ))
			test word [WordHigh(fputmp)], c0_mask | c2_mask | c3_mask
			jz .changesign_ret
			retn
	;if ⌊|ɑ| / π/4⌋ % 4 == 11b than
		.q11:
			fsubp
			fptan
			fdivp
			; change the sign if ɑ is positive (-tan(ɑ)=tan(-ɑ))
			test word [WordHigh(fputmp)], c0_mask | c2_mask | c3_mask
			jz .changesign_ret
			retn
	.changesign_ret:
	fchs
	retn

; st0 = sin(st0), st1 = cos(st0)
; requires three more fpu stack registers
%macro sincos 0-1 rad
	%if %1 == rad
		fmul dword [Half]
	%elif %1 == deg
		fmul dword [DegToHalfRad]
	%endif
	;; halfrad is the default of the following code
	;; so no need for conversion

	call tan
	fld st0
	fimul word [Two]
	fxch st1

	fmul st0,st0
	fld st0

	fld1
	fadd st2,st0
	fsubrp

	fdiv st0,st1

	fxch st2
	fdivrp
%endmacro sincos

; sets the round control bits in the fpu's status word to RoundingMode
; changes word [WordLow(fputmp)]
%macro fsetrc 1
	fstcw word [WordLow(fputmp)]
	and word [WordLow(fputmp)], ~(11b << 10)
	or word [WordLow(fputmp)], %1 << 10
	fldcw word [WordLow(fputmp)]
%endmacro fsetrc

; rotate the x and y locations in st0 and st1 by ɑ expressed by sin(ɑ) and cos(ɑ) in the arguments
; since x and y locations can be seen as x=c*cos(ɑ) or y=c*sin(ɑ)
; if we put them in the identities used by the %macro as the "sin(beta)" and "cos(beta)" we get x=c*cos(ɑ + beta), y=c*sin(ɑ + beta)
; which is essentially rotation
; args: sin,cos
%macro cmacrot 2
	;;                       (  sin(ɑ + β) = sin(ɑ) * cos(β) + cos(ɑ) * sin(β), )
	;; angle sum identities: <                                                  >
	;;                       (  cos(ɑ + β) = cos(ɑ) * cos(β) - sin(ɑ) * sin(β)  )
	fld st0
	fld st2

	fmul %2
	fxch st1
	fmul %1
	faddp
	fxch st2

	fmul %1
	fxch st1
	fmul %2
	fsubrp
%endmacro cmacrot

; get the inversely rotated z location from x in st0 and z in st1 and sin,cos of the angle in the arguments
; args: sin,cos
%macro cmcrotz 2
	;; angle diffrence identitiy: sin(ɑ - β) = sin(ɑ) * cos(β) - cos(ɑ) * sin(β)
	fmul %1
	fxch st1
	fmul %2
	fsubrp
%endmacro cmcrotz

; args: a,b,res
%macro imax 3
	cmp %2,%1
	jg %%Bigger
		mov %3,%1
		jmp %%end_m
	%%Bigger:
		mov %3,%2
	%%end_m:
%endmacro imax

; args: a,b,res
%macro imin 3
	cmp %1,%2
	jg %%Bigger
		mov %3,%1
		jmp %%end_m
	%%Bigger:
		mov %3,%2
	%%end_m:
%endmacro imin

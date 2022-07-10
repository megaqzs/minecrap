; asmsyntax=nasm

%idefine TRUE 1
%idefine FALSE 0

%define WordLow(address) (0*2 + (address))
%define WordHigh(address) (1*2 + (address))
%define ByteLow(address) (0*1 + (address))
%define ByteHigh(address) (1*1 + (address))

%define IRQOffset(IRQ) (4*((IRQ) > 7 ? (0x70 + (IRQ) - 7) : (0x8 + (IRQ))))
%define MKLabelI(label,i) label %+ i ; make a label with the index i for rep loops

; this works because a and b are integers meaning that 1 doesn't need to be infinitesimally small
%define ceildiv(a,b) (((a) + (b) - 1) / (b))

; args size, value
%macro memset 2
	mov ax, %1 | (%2 << 8)
	shr cx,1
	rep stosw
	adc cx,0
	rep stosb
%endmacro memset

; set Size values in es:di to Value
; changes ax cx di df
; args: size, value
%macro cmemset 2
	%if %1 != 0
		cld
		mov al,%2

		%if (%1 % 2) == 1
			stosb
		%endif

		%if %1 > 1
			mov ah,al
			mov cx, %1 / 2
			rep stosw
		%endif
	%endif
%endmacro cmemset

%macro memcpy 0
	shr cx,1
	rep movsw
	adc cx,0
	rep movsb
%endmacro memcpy

; same as memcpy but only works on constant sizes and faster
; changes cx, df
%macro cmemcpy 1
	%if (%1 % 2) == 1
		movsb ; write a byte if the size is odd in order to make it even
	%endif

	%if (%1 / 2) != 0
		mov cx, %1 / 2
		rep movsw ; write the rest of the bytes as words
	%endif
%endmacro cmemcpy

%imacro ljcc 2
	j%-1 %%skip
		jmp %2
	%%skip:
%endmacro ljcc

; args: reg1, reg2, count
%macro dwrol 3
	clc
	%rep %3
		rcl %1,1
		rcl %2,1
		adc %1,0
	%endrep
%endmacro dwrol

; args: reg1, reg2, count
%macro dwror 3
	clc
	%rep %3
		rcr %2,1
		rcr %1,1
		rcl %2,1
		ror %2,1
	%endrep
%endmacro dwrol

%macro rpush 1-*
	%rep %0
		%rotate -1
		push %1
	%endrep
%endmacro

%macro rpop 1-*
	%rep %0
		%rotate -1
		pop %1
	%endrep
%endmacro

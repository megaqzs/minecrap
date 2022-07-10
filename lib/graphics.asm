; asmsyntax=nasm

FontReady equ False
VGASegment equ 0A000h

sWidth equ 320
sHeight equ 200

; vga register channels
CRTC_CTRL equ 3d4h
SEQUENCER_CTRL equ 3c4h
GRAPHICS_CTRL equ 3ceh
INPUT_STATUS_1 equ 03dah

; vga register indicies
Memory_Mode equ 4h
Underline_Loc equ 14h
Mode_Control equ 17h
Plane_Mask equ 02h
ADDRESS_HIGH equ 0ch
ADDRESS_LOW equ 0dh

; vga masks
VSYNC_MASK equ 08h
DE_MASK equ 01h

section code

; args: channel, index, value
%macro setreg 2-3
	%if %0 == 3
		mov ax, %2 | (%3 << 8)
	%else
		mov al, %2
	%endif
	mov dx,%1
	out dx,ax
%endmacro setreg

%macro SetModeX 0
	mov ax,13h
	int 10h

	setreg SEQUENCER_CTRL, Memory_Mode, 06h
	setreg CRTC_CTRL, Underline_Loc, 0
	setreg CRTC_CTRL, Mode_Control, 0e3h
%endmacro SetModeX

; args: color
%macro XSetPixel 1
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

	mov byte [es:di], %1
%endmacro XSetPixel

; wait until the vga chipset is writing pixels
%macro WaitDisplayEnable 0
	mov dx,INPUT_STATUS_1
	%%WaitDELoop:
			in al,dx
			and al,DE_MASK
			jnz %%WaitDELoop
%endmacro WaitDisplayEnable

; args: displayed_page
%macro flippage 1
	mov ax, es
	sub ax, VGASegment
	shl ax, 4
	push ax

	cli
	setreg CRTC_CTRL, ADDRESS_HIGH
	pop ax
	mov ah,al
	setreg CRTC_CTRL, ADDRESS_LOW
	sti

	mov ax, es
	xchg ax, %1
	mov es, ax
%endmacro flippage

; wait until the next line
%macro WaitVSync 0
	mov     dx,INPUT_STATUS_1
	%%WaitNotVSyncLoop:
		in al,dx
		and al,VSYNC_MASK
		jnz %%WaitNotVSyncLoop
	%%WaitVSyncLoop:
		in al,dx
		and al,VSYNC_MASK
		jz %%WaitVSyncLoop
%endmacro WaitVSync

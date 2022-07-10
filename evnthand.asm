; asmsyntax=nasm
SCAN_Down_w equ 11h
SCAN_Down_a equ 1eh
SCAN_Down_s equ 1fh
SCAN_Down_d equ 20h
SCAN_Down_SPACE equ 39h
SCAN_Down_SHIFT equ 2ah
SCAN_Down_ESC equ  01h

SCAN_Up_w equ 91h
SCAN_Up_a equ 9eh
SCAN_Up_s equ 9fh
SCAN_Up_d equ 0a0h
SCAN_Up_SPACE equ 0b9h
SCAN_Up_SHIFT equ 0aah

PS2RD_Bit equ 1b
PS2WR_Bit equ 10b
section data

PointerX dw 0
PointerY dw 0

; bit field of player status:
; [0: left, 1: right, 2: forward, 3: backward, 4: up, 5: down, 6: escape]
kbstatus db 0000000b
scancode db 0ffh

ByteHandler dw mousehandler.byte1
PacketInfo db 0 ; the extra part is for bt

section code
; ah=PS2RD_Bit or PS2WR_Bit
; carry is set on fail
PS2Wait:
	mov cx,30000 ; imagine making it overflow accidentliy
	.loop:
		in al,0x64
		test al,ah ; resets carry bit
		jz .end
		dec cx
		jnz .loop
		stc ; only set if cx is less then 0
	.end:
		ret

PS2rd:
	mov ah,1b
	call PS2Wait
	xor al,al
	jc .end
	in al,0x60
	.end:
		ret

; recive a packet from the mouse byte by byte as seperate interrupts
mousehandler:
	push ax
	push ds

	xor ax,ax
	mov ds,ax
	in al,60h
	jmp word [ByteHandler]

	.overflowbyte2:
		mov word [ByteHandler],.overflowbyte3
		jmp .end

	.overflowbyte3:
		mov word [ByteHandler],.byte1
		jmp .end

	.byte1:
		; test for overflow
		mov word [ByteHandler],.overflowbyte2 ; if there is an overflow in x or y ignore the packet
		shl al,1
		jc .end
		js .end

		shl al,1
		mov byte [PacketInfo],al
		mov word [ByteHandler],.byte2
		jmp .end

	.byte2:
		mov ah, byte [PacketInfo]
		shl ah,2
		sbb ah,ah ; if the sign bit is 1 set ah to -1
		sub word [PointerX],ax
		mov word [ByteHandler],.byte3
		jmp .end

	.byte3:
		mov ah, byte [PacketInfo]
		shl ah,1
		sbb ah,ah ; if the sign bit is 1 set ah to -1
		add word [PointerY],ax
		mov word [ByteHandler],.byte1

	.end:
		; clear the master and slave pics (programmable interrupt controllers)
		mov al,0x20
		out 0x20,al ; master
		out 0xA0,al ; slave

		pop ds
		pop ax
		iret

keyboardhandler:
	; save status
	push ax
	push ds

	; set data segment
	xor ax,ax
	mov ds,ax

	; get scancode from keyboard
	in al,0x60


	cmp al, byte [scancode]
	ljcc e,.exit
	; save importent key status
	cmp al,SCAN_Down_a
	jne .down0
		or byte [kbstatus], 1b
		jmp .storecode
	.down0:
	cmp al,SCAN_Down_d
	jne .down1
		or byte [kbstatus], 10b
		jmp .storecode
	.down1:
	cmp al,SCAN_Down_w
	jne .down2
		or byte [kbstatus], 100b
		jmp .storecode
	.down2:
	cmp al,SCAN_Down_s
	jne .down3
		or byte [kbstatus], 1000b
		jmp .storecode
	.down3:
	cmp al,SCAN_Down_SPACE
	jne .down4
		or byte [kbstatus], 10000b
		jmp .storecode
	.down4:
	cmp al,SCAN_Down_SHIFT
	jne .down5
		or byte [kbstatus], 100000b
		jmp .storecode
	.down5:
	cmp al,SCAN_Down_ESC
	jne .up0
		or byte [kbstatus], 1000000b
		jmp .storecode


	.up0:
	cmp al,SCAN_Up_a
	jne .up1
		and byte [kbstatus], 11111110b
		jmp .storecode
	.up1:
	cmp al,SCAN_Up_d
	jne .up2
		and byte [kbstatus], 11111101b
		jmp .storecode
	.up2:
	cmp al,SCAN_Up_w
	jne .up3
		and byte [kbstatus], 11111011b
		jmp .storecode
	.up3:
	cmp al,SCAN_Up_s
	jne .up4
		and byte [kbstatus], 11110111b
		jmp .storecode
	.up4:
	cmp al,SCAN_Up_SPACE
	jne .up5
		and byte [kbstatus], 11101111b
		jmp .storecode
	.up5:
	cmp al,SCAN_Up_SHIFT
	jne .storecode
		and byte [kbstatus], 11011111b
	; escape is handled by display loop

	.storecode:
		mov byte [scancode],al

	.exit:
	; clear pic (programmable interrupt controller)
    mov al,20h
    out 20h,al

	; restore status
	pop ds
	pop ax

	; return
	iret

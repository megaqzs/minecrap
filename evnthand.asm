; asmsyntax=tasm
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

CODESEG

proc mousehandler far
	pushf
	push bp
	mov bp, sp
	push ax ds
	
	push @data
	pop ds

	mov al, [byte bp + 12]
	cbw
	sub [PointerX], ax

	mov al, [byte bp + 10]
	cbw
	add [PointerY], ax

	pop ds ax bp
	popf
	ret
endp mousehandler

proc keyboardhandler
	locals @@

	; save status
	pushf
	push ax ds

	; set data segment
	mov ax, @data
	mov ds,ax

	; get scancode from keyboard
	in al,60h 


	cmp al, [scancode]
	lje @@exit
	; save importent key status
	cmp al,SCAN_Down_a
	jne @@down0
		or [kbstatus], 1b
		jmp @@storecode
	@@down0:
	cmp al,SCAN_Down_d
	jne @@down1
		or [kbstatus], 10b
		jmp @@storecode
	@@down1:
	cmp al,SCAN_Down_w
	jne @@down2
		or [kbstatus], 100b
		jmp @@storecode
	@@down2:
	cmp al,SCAN_Down_s
	jne @@down3
		or [kbstatus], 1000b
		jmp @@storecode
	@@down3:
	cmp al,SCAN_Down_SPACE
	jne @@down4
		or [kbstatus], 10000b
		jmp @@storecode
	@@down4:
	cmp al,SCAN_Down_SHIFT
	jne @@down5
		or [kbstatus], 100000b
		jmp @@storecode
	@@down5:
	cmp al,SCAN_Down_ESC
	jne @@up0
		or [kbstatus], 1000000b
		jmp @@storecode


	@@up0:
	cmp al,SCAN_Up_a
	jne @@up1
		and [kbstatus], 11111110b
		jmp @@storecode
	@@up1:
	cmp al,SCAN_Up_d
	jne @@up2
		and [kbstatus], 11111101b
		jmp @@storecode
	@@up2:
	cmp al,SCAN_Up_w
	jne @@up3
		and [kbstatus], 11111011b
		jmp @@storecode
	@@up3:
	cmp al,SCAN_Up_s
	jne @@up4
		and [kbstatus], 11110111b
		jmp @@storecode
	@@up4:
	cmp al,SCAN_Up_SPACE
	jne @@up5
		and [kbstatus], 11101111b
		jmp @@storecode
	@@up5:
	cmp al,SCAN_Up_SHIFT
	jne @@storecode
		and [kbstatus], 11011111b
	; escape is handled by display loop

	@@storecode:
		mov [scancode],al

	@@exit:
	; clear pic (programmable interrupt controller)
    mov al,20h
    out 20h,al

	; restore status
	pop ds ax
	popf

	; return
	iret
endp keyboardhandler

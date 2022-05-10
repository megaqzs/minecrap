; asmsyntax=tasm

DATASEG
; bit field of player status:
; [0: left, 1: right, 2: forward, 3: backward, 4: up, 5: down, 6: escape]
kbstatus db 0000000b
scancode db 0ffh

PointerX dw 0
PointerY dw 0

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
	cmp al,1eh ; a
	jne @@down0
		or [kbstatus], 1b
		jmp @@storecode
	@@down0:
	cmp al,20h ; d
	jne @@down1
		or [kbstatus], 10b
		jmp @@storecode
	@@down1:
	cmp al,11h ; w
	jne @@down2
		or [kbstatus], 100b
		jmp @@storecode
	@@down2:
	cmp al,1fh ; s
	jne @@down3
		or [kbstatus], 1000b
		jmp @@storecode
	@@down3:
	cmp al,39h ; space
	jne @@down4
		or [kbstatus], 10000b
		jmp @@storecode
	@@down4:
	cmp al,2ah ; shift
	jne @@down5
		or [kbstatus], 100000b
		jmp @@storecode
	@@down5:
	cmp al,01h ; escape
	jne @@up0
		or [kbstatus], 1000000b
		jmp @@storecode


	@@up0:
	cmp al,9eh ; a
	jne @@up1
		and [kbstatus], 11111110b
		jmp @@storecode
	@@up1:
	cmp al,0a0h ; d
	jne @@up2
		and [kbstatus], 11111101b
		jmp @@storecode
	@@up2:
	cmp al,91h ; w
	jne @@up3
		and [kbstatus], 11111011b
		jmp @@storecode
	@@up3:
	cmp al,9fh ; s
	jne @@up4
		and [kbstatus], 11110111b
		jmp @@storecode
	@@up4:
	cmp al,0b9h ; space
	jne @@up5
		and [kbstatus], 11101111b
		jmp @@storecode
	@@up5:
	cmp al,0aah ; shift
	jne @@storecode
		and [kbstatus], 11011111b
	; escape is handled by display loop

	@@storecode:
		mov [scancode],al

	@@exit:
	; clear pic
    mov al,20h
    out 20h,al

	; restore status
	pop ds ax
	popf

	; return
	iret
endp keyboardhandler

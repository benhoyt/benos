; ─────────────────────────────────────────────────────────────────────────────
;
; Operating system test code for BenOS v1.0 (c) Benjamin Hoyt 1997
;
; ─────────────────────────────────────────────────────────────────────────────
; General stuff
;
.386p					; allow all 386 instructions
locals					; allow local labels
Code		segment dword use32	; 32 bit code segment
assume		cs:Code, ds:Code, es:Code, fs:Code, gs:Code, ss:Code
; ─────────────────────────────────────────────────────────────────────────────
; This code is loaded at linear address 0 by the boot sector loader
;
org		08000h
; ─────────────────────────────────────────────────────────────────────────────
; Interrupt descriptor table and global descriptor table
;
IDT		dq	256 dup (0)	; 256 zeroed IDT entries
GDT		dq	0		; first entry is always NULL
		dq 0cf9a000000ffffh	; 32 bit, 4gb code segment readable
		dq 0cf92000000ffffh	; 32 bit, 4gb data segment read/write
		dq	0,0,0,0,0	; unused entries
; ─────────────────────────────────────────────────────────────────────────────
; This is where the bootstrapper jumps to (linear offset 08840h)
;
StartOfCode:
	; fill 4 text screen pages with text
	xor	eax, eax		; start w/ colour 0
	xor	ebx, ebx		; start at x,y = 0,0
	mov	esi, offset TextMsg	; esi -> string to display
Msgy:	call	PutStr			; display it
	inc	ah			; change colour
	and	ah, 0fh
	inc	bh			; increment row
	cmp	bh, 100
	jb	Msgy			; write 100 rows

	; reset video offset and text scan line
Redo:	xor	ebx, ebx
	call	WaitVrt
	call	TextScan
	call	vOffset

	; do the smooth scroll itself
	mov	ecx, 16			; # of times to loop
	xor	edi, edi
Jerky:	xor	bl, bl
	cmp	cl, 16
	jne	Smooth
	add	bl, 4
Smooth:	call	WaitVrt			; slow it down and make it smooth
	call	TextScan		; scroll one pixel
	add	bl, 4
	cmp	bl, 16
	jb	Smooth			; scroll 16 pixels like that
	add	di, 80
	mov	bx, di
	call	vOffset			; scroll one text row
	loop	Jerky

	jmp	short Redo		; redo from start

TextMsg		db	'   BenOS v1.0 - A 32 bit Forth-based operating system  (c) Benjamin Hoyt 1997   ',0
; ─────────────────────────────────────────────────────────────────────────────
; Display ASCIIZ string on the text screen
; entry: ah = attribute, bh = row, bl = column, esi -> string
; exit: nothing
; kills: none
;
PutStr		proc
	push	eax ebx esi edi			; save regs
	movzx	edi, bh				; edi = calculated offset
	imul	di, 0a0h
	xor	bh, bh
	add	di, bx
	add	di, bx
	add	edi, 0b8000h			; edi -> video memory
@@Loop:	lodsb					; get a char
	or	al, al				; null byte?
	jz	@@Done				; yep, so done..
	stosw					; store char/colour
	jmp	short @@Loop			; and loop..
@@Done:	pop	edi esi ebx eax			; restore regs and return
	ret
PutStr		endp
; ─────────────────────────────────────────────────────────────────────────────
; Wait for the VGA vertical retrace
;
WaitVrt		proc
	push	eax edx				; save regs
	mov	dx, 03dah			; dx -> VGA status port
@@wEnd:	in	al, dx				; read from port
	test	al, 8				; test VR bit 3
	jnz	@@wEnd				; loop if in a retrace
@@wStt:	in	al, dx				; read from port
	test	al, 8				; test VR bit 3
	jz	@@wStt				; loop if not in a retrace
	pop	edx eax				; restore regs and return
	ret
WaitVrt		endp
; ─────────────────────────────────────────────────────────────────────────────
; Set the textmode scan line position
; entry: bl = scan line position (eg., 0-15)
; exit: nothing
; kills: none
;
TextScan	proc
	push	eax edx				; save regs
	mov	dx, 03d4h			; dx -> index port
	mov	al, 8				; index 8 (set text scanline)
	out	dx, al				; outport it
	mov	al, bl				; get scanline number
	inc	dx				; dx -> data port
	out	dx, al				; outport scanline number
	pop	edx eax				; restore regs and return
	ret
TextScan	endp
; ─────────────────────────────────────────────────────────────────────────────
; Set the VGA video offset (used for hardware scrolling etc.)
; entry: bx = video offset
; exit: nothing
; kills: none
;
vOffset		proc
	push	eax edx				; save regs
	mov	dx, 03d4h			; misc VGA port
	mov	al, 0dh				; index 0dh = low data
	mov	ah, bl				; lo byte of offset
	out	dx, ax				; outport lo byte
	dec	eax				; index 0ch = high data
	mov	ah, bh				; hi byte of offset
	out	dx, ax				; outport hi byte
	pop	edx eax				; restore regs and return
	ret
vOffset		endp
; ─────────────────────────────────────────────────────────────────────────────
; End of code segment and file
;
Code		ends			; end code segment
end
; ─────────────────────────────────────────────────────────────────────────────

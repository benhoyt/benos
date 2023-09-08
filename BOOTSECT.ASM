; ─────────────────────────────────────────────────────────────────────────────
;
; Boot sector code for BenOS v1.0 (c) Benjamin Hoyt 1997
;
; ─────────────────────────────────────────────────────────────────────────────
; General stuff
;
BenOSSects	equ	100		; size of OS in # of sectors
StartSector	equ	1		; starting sector # of BenOS
BenOSSeg	equ	0800h		; segment address to load OS at
SpinFactor	equ	5		; bit tester for spin display
.386p					; allow all 386 instructions
Code		segment word use16	; 16 bit code segment
assume		cs:Code, ds:Code
; ─────────────────────────────────────────────────────────────────────────────
; Boot sector is loaded at address 07c00h and cs:ip set to 0000:7c00
; BUT! We tell the assembler we're starting at zero because that's the
; offset we move ourselves up to straight away.
;
org		0
; ─────────────────────────────────────────────────────────────────────────────
; This 62 byte structure is at offset zero of the boot sector on all MS-DOS
; FAT compatible disks. It contains additional info about the file system
; and operating system, as well as number of heads/sectors etc., and info
; like whether the disk is bootable or not.
;
JumpPadding	label	byte		; 2 byte jump to code + padding
	jmp	short StartBootUp
	nop
OSname		db	'BenOS1.0'	; 8 byte OS name
nBytesPerSect	dw	0200h		; # of bytes/sector
nSectsPerClust	db	1		; # of sectors/cluster
nResvdSects	dw	1		; # of reserved sectors
nFATs		db	2		; # of FATs
nRootDirEnts	dw	0e0h		; # of root directory entries max
nTotalSects	dw	0b40h		; # of total sectors (0 if part > 32mb)
MediaByte	db	0f0h		; media descriptor byte
nSectsPerFAT	dw	9		; # of sectors/FAT
nSectsPerTrack	dw	012h		; # of sectors/track
nHeads		dw	2		; # of heads
nHiddenSects	dd	0		; # of hidden sectors
nTotalSects32	dd	0		; # of total sectors (if part > 32mb)
BootDrive	db	0		; drive # boot sector came from
ResvdByte	db	0		; a reservd byte (used for tmp storage)
ExtBootSig	db	029h		; extended boot signature (always 029h)
VolSerial	dd	0		; not really needed
VolName		db	'BENOS-1.44M'	; 11 byte volume name
FATType		db	'FAT12   '	; 8 byte FAT name (type)
; ─────────────────────────────────────────────────────────────────────────────
; The real bootup code begins here
;
StartBootUp:
	; make sure interrupts are disabled and setup the stack
	cli				; disable interrupts
	mov	ax, 09000h		; put stack at an arbitrary location
	mov	ss, ax			; up high at 9000:8000 (linear 098000h)
	mov	sp, 08000h

	; move ourselves up to 090000h linear so we don't get in the way
	mov	es, ax			; es:di -> 9000:0000 (linear 090000h)
	xor	di, di
	mov	ds, di			; ds:si -> this code in memory
	mov	si, 07c00h		; (ie., 0000:7c00, linear 07c00h)
	mov	cx, 512/2		; # words to move (#bytes/2)
	rep	movsw			; move 512 bytes to 9000:0000

	; now we jump (by means of a RETF) to where we moved ourselves
	push	ax			; push segment
	push	offset NewLocation	; push offset
	retf				; "return" to new location
; ─────────────────────────────────────────────────────────────────────────────
; If error with disk reset or disk read we come here
;
BadDisk:
	mov	si, offset BadDiskMsg	; display error msg
	call	DisplayString
	xor	ah, ah			; wait for keystroke
	int	016h
	int	019h			; and reboot
; ─────────────────────────────────────────────────────────────────────────────
; Here is where we start AFTER we've moved ourselves to 9000:0000
;
NewLocation:
	mov	ds, ax			; set ds to 09000h so as to access data

	; display "Loading" message
	mov	si, offset LoadingMsg	; si -> string
	call	DisplayString		; throw it on the screen

	; reset disk drive by calling BIOS
	xor	ah, ah			; ah = 0 = reset disk drive function
	mov	dl, [BootDrive]
	int	013h			; reset the disk, move head to track 0
	jc	BadDisk			; stop if error with reset

	; load operating system code image into memory
	push	06000h			; es:bx = location to read to
	pop	es			; read to 6000:0000 (temporarily)
	xor	bx, bx			; (before we move it down to 0)
	mov	ax, StartSector		; start at this sector
	mov	cx, BenOSSects		; cx = total # of sectors to read

	; read logical sector ax to memory at es:bx
ReadSector:
	pusha				; to save ax bx cx
	mov	si, [nSectsPerTrack]	; si = #sectors/track
	xor	dx, dx
	div	si			; divide sector# by #sectors/track
	inc	dl			; convert 0-based sector# to start at 1
	mov	[ResvdByte], dl		; absolute sector# to read
	xor	dx, dx			; (logical track# in ax)
	div	[nHeads]		; leaves head# in dl, track# in ax
	mov	dh, [BootDrive]
	xchg	dl, dh			; dh = head#, dl = drive#
	mov	cx, ax			; cx = track#
	xchg	cl, ch			; ch = low byte track#, cl = hi 2 bits
	shl	cl, 6			; shift track# 2 bits to bits 6 & 7
	or	cl, [ResvdByte]		; or in sector#
	mov	al, 1			; read only 1 sector
	mov	ah, 2			; read function#
	int	013h			; load our baby! (bit at a time)
	jc	BadDisk			; error with read?

	; display spinner thing to show we're doing something
	popa				; restore old regs
	test	al, SpinFactor		; is this bit in sector # set?
	jz	NoSpinDisplay		; do spinner only if bit set
	pusha				; save regs again
	mov	si, [Spinner]		; si -> spin msg
	call	DisplayString		; show it
	add	[Spinner], 3		; -> next spinner msg
	cmp	[Spinner], offset SpinMsg+12
	jne	NotEndSpin		; back to beginning of spin messages?
	mov	[Spinner], offset SpinMsg
NotEndSpin:
	popa

	; move on to next sector to read
NoSpinDisplay:
	mov	dx, es			; move segment along 020h = 512 bytes
	add	dx, 020h
	mov	es, dx
	inc	ax			; next sector #
	loop	ReadSector		; read total cx sectors

	; turn off the floppy drive motor (and light)
	mov	dx, 03F2h
	xor	al, al
	out	dx, al			; bit 4 clear means A: motor off

	; move operating system down to BenOSSeg onward
	cli				; disable interrupts again
	push	06000h			; restore es to 06000h
	pop	es
	mov	dx, BenOSSects		; dx = # of 512 byte blocks to move
	push	es			; ds = 6000 = source for move
	pop	ds
	push	BenOSSeg		; es = destination seg for move
	pop	es
MoveSectorLoop:
	xor	si, si			; both offsets zero
	xor	di, di
	mov	cx, 512/2		; # words to move (#bytes/2)
	rep	movsw			; move 512 bytes (a sector) down
	mov	ax, ds			; move ds to next 512 byte block
	add	ax, 020h
	mov	ds, ax
	mov	ax, es			; move es to next 512 byte block
	add	ax, 020h
	mov	es, ax
	dec	dx
	jnz	MoveSectorLoop		; loop and move all sectors

	; enable the A20 line so we can access memory above 1mb
	xor	cx, cx			; loop max 64k times
A20e0:	in	al, 064h
	test	al, 2
	loopnz	A20e0
	mov	al, 0d1h		; these codes enable A20 line
	out	064h, al		; on an AT (thru the keyboard)
	xor	cx, cx
A20e1:	in	al, 064h
	test	al, 2
	loopnz	A20e1
	mov	al, 0dfh
	out	060h, al
	xor	cx, cx
A20e2:	in	al, 064h
	test	al, 2
	loopnz	A20e2

	; setup global and interrupt descriptor tables
	lidt	fword ptr cs:[IDTReg]	; load interrupt descriptor table reg
	lgdt	fword ptr cs:[GDTReg]	; load global descriptor table reg

	; switch to 32 bit protected address mode
	mov	eax, cr0		; eax = control register 0
	or	al, 1			; set pmode bit!
	mov	cr0, eax		; let's hope it works!
	jmp	$+2			; flush instruction queue
	nop				; get the CPU thinking straight
	nop

	; setup stack and other registers
	mov	ax, 010h		; ax = 32 bit data segment selector
	mov	ds, ax			; set all data segments regs to this
	mov	es, ax
	mov	fs, ax
	mov	gs, ax
	mov	ss, ax			; including the stack

	; jump to start of operating system code (linear address 0840h)
	db	066h,0eah		; far jump also initialises CS
	dd	BenOSSeg*010h+0840h	; offset
	dw	8			; selector (32 bit code segment)
; ─────────────────────────────────────────────────────────────────────────────
; Display ASCIIZ string
; entry: si -> string
; exit: nothing
; kills: ax, bx, si
;
DisplayString	proc
	mov	ah, 0eh			; ah = 0eh = display char function
	mov	bx, 7			; bh = 0 = page, bl = 7 = attribute
dLoop:	lodsb				; read char from string
	or	al, al			; is it NULL byte?
	jz	short dDone		; yep, we're done
	int	010h			; else display the char
	jmp	short dLoop		; loop for next char
dDone:	ret				; return to caller
DisplayString	endp
; ─────────────────────────────────────────────────────────────────────────────
; Miscellaneous data of my own
;
IDTReg		dw	07ffh		; IDT limit (256 entries) and base
		dd	BenOSSeg*010h
GDTReg		dw	03fh		; GDT limit (8 descriptors) and base
		dd	BenOSSeg*010h+0800h
BadDiskMsg	db	13,10,'Bad boot disk!',0
LoadingMsg	db	13,10,'Loading BenOS v1.0   ',0
Spinner		dw	offset SpinMsg	; -> current spin msg
SpinMsg		db	8,'/',0		; spinner messages
		db	8,'─',0
		db	8,'\',0
		db	8,'│',0
; ─────────────────────────────────────────────────────────────────────────────
; Add boot sector signature
;
org		01feh			; last word in boot sector
BootSig		dw	0aa5fh		; boot sector signature
; ─────────────────────────────────────────────────────────────────────────────
; End of code segment and file
;
Code		ends
end
; ─────────────────────────────────────────────────────────────────────────────

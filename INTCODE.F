\ BenOS v1.0 CPU interrupts (c) Benjamin Hoyt 1997

code int!  ( offset int# -- )			\ set interrupt handler
	mov		eax, [ebp]
	and		eax, # $FFFF				\ offset bits 0-15
	or		eax, # $80000				\ OR in CS selector (bits 16-31)
	pushfd								\ save flags and disable ints
	cli
	mov		code-base [ebx*8], eax		\ set low dword in IDT
	mov		eax, [ebp]
	and		eax, # $FFFF0000			\ offset bits 16-13
	or		eax, # $8E00				\ present, dpl=0 interrupt descriptor
	mov		code-base 4 + [ebx*8], eax	\ set high dword in IDT
	popfd								\ to restore interrupt flag
	mov		ebx, 4 [ebp]
	add		ebp, # 8
	next
end-code

code int@  ( int# -- offset )			\ get interrupt handler offset
	mov		eax, code-base [ebx*8]		\ low dword of descriptor
	and		eax, # $FFFF				\ offset bits 0-15
	mov		ebx, code-base 4 + [ebx*8]	\ high dword of descriptor
	and		ebx, # $FFFF0000			\ offset bits 16-31
	or		ebx, eax					\ final offset in ebx
	next
end-code

( initialises the 8259 programmable interrupt controller and maps IRQ vectors )
code init-pic  ( -- )
	( ICW1 init command word 1 at port $20 master and $A0 slave, misc stuff )
	mov		al, # $11					\ 00010001
	out		# $20 , al					\ ICW1 master
	push	eax							\ these let 8259 figure itself out
	pop		eax
	out		# $A0 , al					\ ICW1 slave
	push	eax
	pop		eax

	( ICW2 init command word 2 at port $21 and $A1, bits 3-7 are bits 3-7
	  of the CPU interrupt vector which we want at $20 master and $28 slave )
	mov		al, # $20					\ 00100000
	out		# $21 , al					\ ICW2 master
	push	eax
	pop		eax
	mov		al, # $28					\ 00101000
	out		# $A1 , al					\ ICW2 slave
	push	eax
	pop		eax

	( ICW3 init command word 3 at port $21 and $A1, this enables slave 8259 )
	mov		al, # $04					\ 00000100
	out		# $21 , al					\ ICW3 master
	push	eax
	pop		eax
	mov		al, # $02					\ 00000010
	out		# $A1 , al					\ ICW3 slave
	push	eax
	pop		eax

	( ICW4 init command word 4 at port $21 and $A1, misc stuff )
	mov		al, # $01					\ 00000001
	out		# $21 , al					\ ICW4 master
	push	eax
	pop		eax
	out		# $A1 , al					\ ICW4 slave
	push	eax
	pop		eax

	( OCW1 operation control word 1 at port $21 and $A1, mask various IRQs
	  bit=1 and turn them on bit=0: all masked but timer and keyboard )
	mov		al, # $FC					\ 11111100
	out		# $21 , al					\ OCW1 master
	push	eax
	pop		eax
	mov		al, # $FF					\ 11111111
	out		# $A1 , al					\ OCW1 slave
	push	eax
	pop		eax

	sti									\ enable interrupts!
	next
end-code

code i00-div0  							\ divide by zero interrupt handler
	sti
	mov		ebx, # -10
	jmp		' throw
end-code

code i01-trap							\ hardware breakpoint or trap
	sti
	mov		ebx, # -259
	jmp		' throw
end-code

code i02-nmi							\ non-maskable interrupt
	sti
	mov		ebx, # -260
	jmp		' throw
end-code

code i03-break							\ software breakpoint (INT 3)
	sti
	mov		ebx, # -261
	jmp		' throw
end-code

code i04-oflow							\ overflow interrupt (INTO)
	sti
	mov		ebx, # -262
	jmp		' throw
end-code

code i05-bound							\ BOUND instruction exception
	sti
	mov		ebx, # -263
	jmp		' throw
end-code

code i06-opcode							\ invalid opcode
	sti
	mov		ebx, # -264
	jmp		' throw
end-code

code i07-nofpu							\ device (FPU) not available
	sti
	mov		ebx, # -265
	jmp		' throw
end-code

code i08-dfault							\ double fault
	sti
	mov		ebx, # -266
	jmp		' throw
end-code

code i09-fpuseg							\ FPU segment overrun
	sti
	mov		ebx, # -267
	jmp		' throw
end-code

code i0A-tss							\ invalid TSS
	sti
	mov		ebx, # -268
	jmp		' throw
end-code

code i0B-seg							\ segment not present
	sti
	mov		ebx, # -269
	jmp		' throw
end-code

code i0C-stack							\ stack fault
	sti
	mov		ebx, # -270
	jmp		' throw
end-code

code i0D-gpf							\ general protection fault
	sti
	mov		ebx, # -271
	jmp		' throw
end-code

code i0E-page							\ page fault
	sti
	mov		ebx, # -272
	jmp		' throw
end-code

code i10-fpu							\ FPU error
	sti
	mov		ebx, # -274
	jmp		' throw
end-code

create ints  ( -- a-addr )				\ list of int #s and their handlers
	' i00-div0 ,	$00 c,				\ handler offset cell, int# char
	' i01-trap ,	$01 c,
	' i02-nmi ,		$02 c,
	' i03-break ,	$03 c,
	' i04-oflow ,	$04 c,
	' i05-bound ,	$05 c,
	' i06-opcode ,	$06 c,
	' i07-nofpu ,	$07 c,
	' i08-dfault ,	$08 c,
	' i09-fpuseg ,	$09 c,
	' i0A-tss ,		$0A c,
	' i0B-seg ,		$0B c,
	' i0C-stack ,	$0C c,
	' i0D-gpf ,		$0D c,
	' i0E-page ,	$0E c,
	' i10-fpu ,		$10 c,
	' q00-timer ,	$20 c,
	' q01-kbd ,		$21 c,
here constant ints-end					\ end addr of ints table

: init-idt  ( -- )						\ set default IDT entries
	ints-end ints
	do		i @  i cell+ c@  int!		\ get int handler and int# and set int
			[ 1 cells 1 chars + ] literal
	+loop	;							\ next entry in table

: init-ints  ( -- )						\ init IDT and 8259
	init-idt							\ set IDT entries 00-1F and IRQs
	init-pit							\ setup 10ms interval for 8253 timer
	init-keyboard						\ init 8042 and keyboard driver
	init-pic ;							\ hardware 8259 init and enable ints

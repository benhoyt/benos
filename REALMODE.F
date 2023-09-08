\ BenOS v1.0 real mode interface (c) Benjamin Hoyt 1998

$700 constant >ax						\ real mode reg structure at 0000:0700
$702 constant >bx  $704 constant >cx  $706 constant >dx
$708 constant >si  $70A constant >di  $70C constant >bp
$70E constant >ds  $710 constant >es  $712 constant >rf

variable old-esp						\ save ESP here when switching to rmode

create rm-idtr							\ to load IDT reg for real mode
	$03FF w, 0 w, 0 w,					\ base 0, limit 3FF

code rm-irqs  ( -- )					\ switch IRQs to real mode int numbers
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
	mov		al, # $08					\ 00001000
	out		# $21 , al					\ ICW2 master
	push	eax
	pop		eax
	mov		al, # $70					\ 01110000
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
	mov		al, # $00					\ 00000000
	out		# $21 , al					\ OCW1 master
	push	eax
	pop		eax
	mov		al, # $00					\ 00000000
	out		# $A1 , al					\ OCW1 slave
	push	eax
	pop		eax

	ret
end-code

code rmode-ret  ( -- ax flags )			\ return from rmode int call, 32 bit
	mov		ax, # $10					\ setup changed pmode segregs
	mov		ds, ax						\ ds = es = ss = 4gb r/w data seg
	lidt	addr> idtr					\ restore pmode IDT
	mov		es, ax
	mov		ss, ax

	mov		esp, addr> old-esp			\ restore stack pointer esp
	call	' init-pic					\ restore PIC to pmode int numbers
	popad								\ restore all other regs and flags
	popfd

	sub		ebp, # 4					\ adjust Forth stack
	movzx	eax, word >ax				\ push rmode EAX value (to Forth stack)
	mov		[ebp], eax
	movzx	ebx, word >rf				\ push rmode flags

	next								\ and return to normal execution
end-code

code rmode>  ( -- )						\ return from real mode interrupt
	use16								\ this is 16 bit code here

	cli									\ disable interrupts

	\ store real mode ds
	$2E c, $8C c, $1E c, >ds w,			\ mov cs: >ds , ds

	push	# 0							\ then make sure ds = 0000
	pop		ds
	pushf								\ store real mode flags
	a;  $8F c, $06 c, >rf w,			\ pop word >rf

	\ store other real mode regs
	$89 c, $06 c, >ax w,				\ mov >ax , ax
	$89 c, $1E c, >bx w,				\ mov >bx , bx
	$89 c, $0E c, >cx w,				\ mov >cx , cx
	$89 c, $16 c, >dx w,				\ mov >dx , dx
	$89 c, $36 c, >si w,				\ mov >si , si
	$89 c, $3E c, >di w,				\ mov >di , di
	$89 c, $2E c, >bp w,				\ mov >bp , bp
	$8C c, $06 c, >es w,				\ mov >es , es

	mov		eax, cr0					\ return to pmode
	or		al, # 1
	mov		cr0, eax
	a;  $EA c,  ' rmode-ret w, 8 w,		\ jmp far direct seg:ofs to rmode-ret

	use32
end-code

code >rmode  ( -- )						\ 16 bit code for rmode-int
	use16								\ start generating 16 bit code

	mov		ax, # $20					\ ds = 64k r/w data seg selector
	mov		ds, ax
	mov		es, ax						\ = es = ss
	mov		ss, ax

	mov		sp, # code-base $10 -		\ real mode sp grows down from here

	pushf								\ flags, segment, offset for iret
	push	# 0							\ when we return from interrupt we'll
	push	# ' rmode>					\ go here: seg 0000, ofs rmode<16

	push	dword [ebx*4]				\ for retf to real mode int, ebx = int#

	\ load real mode regs from register structure
	a;  $8B c, $1E c, >bx w,			\ mov bx, >bx
	$8B c, $0E c, >cx w,				\ mov cx, >cx
	$8B c, $16 c, >dx w,				\ mov dx, >dx
	$8B c, $36 c, >si w,				\ mov si, >si
	$8B c, $3E c, >di w,				\ mov di, >di
	$8B c, $2E c, >bp w,				\ mov bp, >bp

	mov		eax, cr0					\ switch to real mode
	and		al, # $FE
	mov		cr0, eax
	a;  $EA c,  here 4 + w,  0 w,		\ far jump to next instr: flush queue

	\ set real mode interrupt descriptor table register: lidt addr> rm-idtr
	$0F c, $01 c, $1E c, addr> rm-idtr w,

	\ load real mode segment regs
	$8E c, $06 c, >es w,				\ mov es, >es
	$8E c, $1E c, >ds w,				\ mov ds, >ds
	xor		ax, ax						\ so ss is a proper rmode segreg
	mov		ss, ax

	\ finally load real mode ax
	a;  $36 c, $8B c, $06 c, >ax w,		\ mov ax, ss: >ax

	sti									\ enable interrupts
	retf								\ "return far" to real mode interrupt

	use32								\ return to 32 bit code generation
end-code

( Execute real mode interrupt int#, real mode registers are passed and
  returned in the reg-struc. AX and the flags are also returned on the stack. )
code rmode-int  ( int# -- ax flags )
	pushfd								\ save flags and all registers
	pushad
	mov		addr> old-esp , esp			\ save this stack pointer
	cli									\ disable all ints till later date

	call	' rm-irqs					\ setup real mode IRQ int numbers

	a;  $EA c,  ' >rmode t,  $18 t,		\ jump far to 0000:>rmode
end-code

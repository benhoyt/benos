\ BenOS v1.0 keyboard driver (c) Benjamin Hoyt 1997

256 constant /raw						\ # bytes in raw buffer
create raw  /raw allot					\ raw scancode queue
raw value raw-in						\ pointer to "next in" scancode
raw value raw-out						\ pointer to "next out" scancode

variable prefix?  0 prefix? !			\ true if we've had an E0 prefix
variable sbits  0 sbits !				\ shift/lock bits
variable ckey-wait  0 ckey-wait !		\ ckey buffer
variable key-wait  0 key-wait !			\ key buffer

hex										\ base changes to HEX here

( tableE0 gives additional rkey codes for scancodes preceded by the E0 prefix.
  Use the scancode as an index into this byte indexed table. See the docs for
  the returned rkey codes. )
create tableE0  ( -- a-addr )
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 6B c, 6D c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 6A c, 00 c, 00 c,
	6C c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 62 c,
	66 c, 64 c, 00 c, 68 c, 00 c, 69 c, 00 c, 63 c,
	67 c, 65 c, 60 c, 61 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, EB c, ED c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, EA c, 00 c, 00 c,
	EC c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, E2 c,
	E6 c, E4 c, 00 c, E8 c, 00 c, E9 c, 00 c, E3 c,
	E7 c, E5 c, E0 c, E1 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,

( shifts is a word-indexed table that gives the shift/lock bit pattern when
  indexed with a hardware scancode. The bits set in this value correspond to
  the bits in bytes 1 and 2 of an ekey code. If a shift key is indexed, the bit
  returned will be set on both press and release. If a lock key is indexed, the
  bit set will be set on a press only. If any other key is indexed a value of
  zero will be returned. )
create shifts  ( -- a-addr )
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0004 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0001 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0002 w, 0000 w,
	0010 w, 0000 w, 0400 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0200 w, 0100 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0020 w, 0008 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0004 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0001 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0002 w, 0000 w,
	0010 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0020 w, 0008 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,
	0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w, 0000 w,

( byte-indexed table that returns a byte with the most significant bit set if
  the index is an rkey code from the number pad )
create numbers  ( -- a-addr )
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 80 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 80 c,
	80 c, 80 c, 80 c, 80 c, 80 c, 80 c, 80 c, 80 c,
	80 c, 80 c, 80 c, 80 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 80 c, 80 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,

( byte-indexed table that returns ckey code when indexed with an rkey code )
create ckeys  ( -- a-addr )
	00 c, 1B c, 31 c, 32 c, 33 c, 34 c, 35 c, 36 c,
	37 c, 38 c, 39 c, 30 c, 2D c, 3D c, 08 c, 09 c,
	71 c, 77 c, 65 c, 72 c, 74 c, 79 c, 75 c, 69 c,
	6F c, 70 c, 5B c, 5D c, 0D c, 00 c, 61 c, 73 c,
	64 c, 66 c, 67 c, 68 c, 6A c, 6B c, 6C c, 3B c,
	27 c, 60 c, 00 c, 5C c, 7A c, 78 c, 63 c, 76 c,
	62 c, 6E c, 6D c, 2C c, 2E c, 2F c, 00 c, 9D c,
	00 c, 20 c, 00 c, 81 c, 82 c, 83 c, 84 c, 85 c,
	86 c, 87 c, 88 c, 89 c, 8A c, 00 c, 00 c, 97 c,
	98 c, 99 c, 9C c, 94 c, 95 c, 96 c, 9B c, 91 c,
	92 c, 93 c, 90 c, 9A c, 00 c, 00 c, 00 c, 8B c,
	8C c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	90 c, 9A c, 97 c, 91 c, 99 c, 93 c, 98 c, 92 c,
	94 c, 96 c, 9E c, 9F c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,

( byte-indexed table that returns the shifted ASCII value from an ckey code )
create shifter  ( -- a-addr )
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	08 c, 09 c, 00 c, 00 c, 00 c, 0D c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 1B c, 00 c, 00 c, 00 c, 00 c,
	20 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 22 c,
	00 c, 00 c, 00 c, 00 c, 3C c, 5F c, 3E c, 3F c,
	29 c, 21 c, 40 c, 23 c, 24 c, 25 c, 5E c, 26 c,
	2A c, 28 c, 00 c, 3A c, 00 c, 2B c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
	00 c, 00 c, 00 c, 7B c, 7C c, 7D c, 00 c, 00 c,
	7E c, 41 c, 42 c, 43 c, 44 c, 45 c, 46 c, 47 c,
	48 c, 49 c, 4A c, 4B c, 4C c, 4D c, 4E c, 4F c,
	50 c, 51 c, 52 c, 53 c, 54 c, 55 c, 56 c, 57 c,
	58 c, 59 c, 5A c, 00 c, 00 c, 00 c, 00 c, 00 c,

( byte-indexed that returns ASCII from number pad key, starts at index $10 )
create numlocks  ( -- a-addr )
	30 c, 31 c, 32 c, 33 c, 34 c, 35 c, 36 c, 37 c,
	38 c, 39 c, 2E c, 2B c, 2D c, 2A c, 2F c, 0D c,

decimal									\ base back to DECIMAL

( wait till 8042 kbd controller input buffer is empty so we can write to it )
code kin-empty  ( -- )
	mov		ecx, # $30000				\ loop 196k times maximum
1 @@:
	jmp		short 2 @@					\ wait a little bit for 8042
2 @@:
	jmp		short 3 @@
3 @@:
	in		al, # $64					\ al = 8042 status byte
	test	al, # $02					\ test bit 1: set means buffer full
	loopnz	1 @@						\ loop until buffer empty (bit = 0)
	next
end-code

( wait till 8042 kbd controller output buffer is full so we can read from it )
code kout-full  ( -- )
	mov		ecx, # $30000				\ loop 196k times maximum
1 @@:
	jmp		short 2 @@					\ wait a little bit for 8042
2 @@:
	jmp		short 3 @@
3 @@:
	in		al, # $64					\ al = 8042 status byte
	test	al, # $01					\ test bit 0: set means buffer full
	loopz	1 @@						\ loop until buffer full (bit = 1)
	next
end-code

code reboot  ( -- )						\ reboot the computer
	cli									\ disable interrupts
	call	' kin-empty					\ wait for input buffer to empty
	mov		al, # $FE					\ tell 8042 to pulse reset line
	out		# $64 , al					\ (strangely, this resets the PC! :-)
end-code

( write a data byte to the keyboard outport port )
code kout  ( -- )						\ al = data byte to outport
	push	eax							\ save data byte for a sec
	call	' kin-empty					\ wait for input buffer to empty
	pop		eax
	out		# $60 , al					\ send data
	call	' kout-full					\ discard kbd ACKnowledge response
	in		al, # $60
	next
end-code

( update the keyboard lock LEDs from the data in sbits )
code update-leds  ( -- )
	pushfd								\ save flags and disable ints
	cli
	mov		al, # $ED					\ send "set status LEDs" command
	call	' kout
	mov		al, sbits 2 +				\ al = keyboard lock bits
	call	' kout						\ send data byte to keyboard
	popfd								\ restore interrupt flag
	next
end-code

code q01-kbd							\ IRQ 1: keyboard interrupt handler
	push	eax							\ save regs
	push	ebx

	in		al, # $60					\ read scancode from keyboard

	( reboot the computer if F12 key is pressed )
	cmp		al, # $58					\ F12 pressed?
	je		short ' reboot				\ yep, reboot the machine

	( store the scancode directly in the queue and update queue pointer )
	mov		ebx, addr> raw-in			\ ebx = raw-in pointer
	mov		[ebx], al					\ store scancode in queue
	inc		ebx
	cmp		ebx, # raw /raw +			\ up to end of buffer?
	jne		short 1 @@
	mov		ebx, # raw					\ pointer back to start of buffer
1 @@:
	mov		addr> raw-in , ebx			\ store back raw-in pointer

	( send "end of interrupt" to the interrupt controller )
	mov		al, # $20					\ send EOI to 8259
	out		# $20 , al

	pop		ebx							\ restore regs and return from int
	pop		eax
	iretd
end-code

code rkey?  ( -- flag )					\ flag true if keyboard event available
	sub		ebp, # 4
	mov		[ebp], ebx
	mov		eax, addr> raw-in			\ wait till we get some data in buf
	cmp		eax, addr> raw-out
	je		short 1 @@					\ if in=out pointer then keys waiting
	mov		ebx, # -1					\ else keys waiting, flag = true
	next
1 @@:
	call	' sleep						\ sleep while waiting for key
	xor		ebx, ebx
	next
end-code

code rkey  ( -- rkey )					\ wait for & return raw kbd event u
	( wait till a key is pressed or released )
	sub		ebp, # 4
	mov		[ebp], ebx
1 @@:
	call	' rkey?						\ check if keys waiting
	add		ebp, # 4
	or		ebx, ebx
	jz		short 1 @@					\ if no keys waiting keep polling

	( fetch the next scancode from the scancode queue and update queue ptr )
	mov		eax, addr> raw-out			\ eax = queue out pointer
	movzx	ebx, byte [eax]				\ ebx = scancode
	inc		eax
	cmp		eax, # raw /raw +			\ up to end of buffer?
	jne		short 2 @@
	mov		eax, # raw					\ pointer back to start of buffer
2 @@:
	mov		addr> raw-out , eax			\ store back raw-out pointer

	( handle the E0 prefix byte, give each key a unique scancode value )
	cmp		byte prefix? , # 0			\ have we just had an E0 prefix?
	jnz		short 3 @@
	cmp		bl, # $E0					\ is this key a prefix?
	jne		short 4 @@
	mov		prefix? , bl				\ yep, set flag to nonzero
	jmp		short 1 @@					\ and wait for next scancode
3 @@:
	mov		bl, tableE0 [ebx]			\ convert E0 keys to something else
4 @@:
	mov		byte prefix? , # 0			\ reset prefix? flag

	( handle shift and lock keys, update sbits accordingly )
	mov		al, sbits 2 +				\ save old kbd lock bits in al
	mov		ecx, ebx					\ ecx = scancode
	mov		cx, shifts [ecx*2]			\ cx = shift/lock bit value
	shl		ecx, # 8					\ shift bits to correct position
	or		bl, bl						\ test scancode MSB (key press/release)
	js		short 6 @@					\ key released
	test	ecx, # $FF0000				\ is it a lock key pressed?
	jz		short 8 @@					\ nope, must be a shift key
	xor		sbits , ecx					\ yep, TOGGLE bits in sbits
	jmp		short 7 @@
8 @@:
	or		sbits , ecx					\ else key press, SET bits in sbits
	jmp		short 7 @@
6 @@:
	not		ecx
	and		sbits , ecx					\ key release, CLEAR bits in sbits
7 @@:
	mov		ecx, sbits					\ ecx = all shift/lock bits
	or		ebx, ecx					\ OR shift/lock bits into scancode

	( update keyboard LEDs if needed )
	cmp		al, sbits 2 +				\ have lock bits in sbits changed?
	je		short 5 @@
	push	ebx							\ yep, update keyboard lock LEDs
	call	' update-leds
	pop		ebx
5 @@:
	next
end-code

( convert rkey to ckey, if successful, return ckey true, else rkey false )
code rkey>ckey  ( rkey -- rkey false | ckey true )
	( if rkey is key release we can't convert it )
	sub		ebp, # 4
	or		bl, bl						\ is it a key release (MSB set)?
	jns		short 1 @@					\ no, it's a key press, continue
2 @@:
	mov		[ebp], ebx					\ else return u
	xor		ebx, ebx					\ and false flag
	next

	( try to convert the rkey to a ckey )
1 @@:
	movzx	eax, bl						\ eax = rkey code
	mov		bl, ckeys [eax]				\ bl = ckey code
	or		bl, bl						\ if ckey code = 0 then no go
	jz		short 2 @@					\ (it was probably a shift/lock key)
	mov		al, numbers [eax]			\ al MSB set if number pad key
	shl		eax, # 24					\ shift to high byte
	or		ebx, eax					\ set MSB of ckey if number pad key

	( well done, good and faithful servant! )
	mov		[ebp], ebx					\ success, store ckey on stack
	mov		ebx, # -1					\ and return true
	next
end-code

( convert ckey to char, if successful, return char true, else ckey false )
code ckey>char  ( ckey -- ckey false | char true )
	( convert to digit/punctuation if it's a number pad key and numlock's on )
	sub		ebp, # 4
	or		ebx, ebx					\ test number pad bit (MSB)
	jns		short 3 @@					\ not set, continue
	test	ebx, # $20000				\ num lock bit set?
	jz		short 4 @@					\ nope, can't convert to char
	and		ebx, # $1F					\ use ebx-$10 as index into numlocks
	mov		bl, numlocks $10 - [ebx]
	mov		[ebp], ebx					\ success, store char on stack
	mov		ebx, # -1					\ and return true
	next

	( otherwise test ASCII bit )
3 @@:
	or		bl, bl						\ is it ASCII (MSB clear)?
	jns		short 1 @@					\ yep, continue
4 @@:
	mov		[ebp], ebx					\ nope, return u
	xor		ebx, ebx					\ and false flag
	next

	( if either shift key pressed convert to shifted character )
1 @@:
	test	ebx, # $300					\ either left or right shift pressed?
	jz		short 2 @@					\ shifts not pressed, leave as is
	and		ebx, # $7F					\ mask off all high bits
	mov		bl, shifter [ebx]			\ convert to shifted character
	mov		[ebp], ebx					\ success, store char on stack
	mov		ebx, # -1					\ and return true
	next

	( if caps lock set convert to uppercase )
2 @@:
	test	ebx, # $040000				\ is caps lock on?
	jz		short 5 @@					\ nope, continue
	and		ebx, # $7F					\ mask off all high bits
	mov		bl, uctable [ebx]			\ convert to uppercase character
5 @@:
	and		ebx, # $7F					\ mask off all high bits
	mov		[ebp], ebx					\ success, store char on stack
	mov		ebx, # -1					\ and return true
	next
end-code

( convert rkey to char, if successful, return char true, else rkey false )
: rkey>char  ( rkey -- rkey false | char true )
	dup rkey>ckey						\ first stop: destination ckey
	if		ckey>char					\ next stop: destination char
			if		nip  true			\ successful arrival!
			else	drop  false
			then
	else	drop  false					\ nope, didn't even make a ckey
	then	;

: ckey?  ( -- flag )					\ return true if ckey event available
	ckey-wait @
	if		true  exit					\ already a key in ckey-wait buffer
	then	rkey?
	if		rkey  rkey>ckey dup
			if		swap ckey-wait !	\ it's a ckey, store in buffer
			else	nip					\ couldn't convert, just discard
			then
	else	false						\ no key ready at all
	then	;

: ckey  ( -- ckey )						\ wait for & return cooked kbd event u
	begin	ckey?
	until	ckey-wait @  ckey-wait off ;

: key?  ( -- flag )						\ return true if kbd char available
	key-wait @
	if		true  exit					\ already a key in ckey-wait buffer
	then	ckey?
	if		ckey  ckey>char dup
			if		swap key-wait !		\ it's a key, store in buffer
			else	nip					\ couldn't convert, just discard
			then
	else	false						\ no key ready at all
	then	;

: key  ( -- char )						\ wait for and return a keyboard char
	begin	key?
	until	key-wait @  key-wait off ;

( ekey, ekey? and ekey>char point to either the "raw" or "cooked" functions )
defer ekey  ( -- u )
defer ekey?  ( -- flag )
defer ekey>char  ( u -- u false | char true )

( initially use cooked keyboard event functions )
' ckey is ekey  ' ckey? is ekey?  ' ckey>char is ekey>char

: raw-keys  ( -- )						\ set ekey funcs to raw mode (rkey)
	['] rkey is ekey  ['] rkey? is ekey?  ['] rkey>char is ekey>char ;

: cooked-keys  ( -- )					\ set ekey funcs to cooked mode (ckey)
	['] ckey is ekey  ['] ckey? is ekey?  ['] ckey>char is ekey>char ;

: cooking?  ( -- flag )					\ return true if using cooked-keys
	[ addr> ekey ] literal  @
	['] ckey  = ;						\ contents of defer = ckey?

code init-8042  ( -- )					\ initialise keyboard controller
	jmp		' update-leds				\ make sure kbd lock LEDs are off
end-code

: init-keyboard  ( -- )					\ initialise keyboard driver
	init-8042 ;

: bl-bksp  ( -- )						\ display a destructive backspace
	8 emit  space  8 emit ;

( accept max u1 chars from keyboard into c-addr, u2 is chars recieved )
: key-accept  ( c-addr +n1 -- +n2 )
	tuck >r
	begin	over						\ loop while countdown > 0
	while	key  dup 13 =
			if		2drop				\ CR pressed, exit
					r> swap -  exit		\ and return +n2
			then	dup 8 =				\ backspace pressed?
			if		drop  over r@ <		\ yep, go back if not at beginning
					if		1 /string	\ remove char from buffer
							bl-bksp		\ and erase it on screen
					then
			else	dup emit			\ otherwise display char
					over c!  -1 /string	\ and insert into buffer
			then
	repeat	drop  r> swap - ;			\ +n1 keys received, return +n2

( accept +n1 characters from keyboard, +n2 is chars actually read to c-addr )
defer accept  ( c-addr +n1 -- +n2 )

' key-accept is accept					\ accept initially set to key-accept

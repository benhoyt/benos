\ BenOS v1.0 timer control (c) Benjamin Hoyt 1998

( set 10ms interval for 8253 programmable interval timer )
code init-pit  ( -- )
	mov		al, # $9C					\ 1,193,182Mhz / $2E9C = 100Hz = 10ms
	out		# $40 , al					\ send low byte
	mov		al, # $2E
	out		# $40 , al					\ then high byte
	next
end-code

code q00-timer							\ IRQ 00 timer interrupt handler
	push	eax
	inc		dword addr> tick#			\ increment 10ms tick counter
	mov		al, # $20					\ send end of interrupt to 8259
	out		# $20 , al
	pop		eax
	iretd
end-code

: ms  ( u -- )							\ delay task for ms milliseconds
	0 10 um/mod nip  tick# +			\ tick# is in 10ms increments
	begin	sleep 						\ so we don't hog CPU!
			dup tick# u<=				\ loop till tick# is correct
	until	drop ;

code tone-on  ( freq-Hz -- )			\ turn speaker on given frequency in Hz
	or		ebx, ebx
	jnz		short 1 @@					\ freq = 0 means no sound
	mov		ebx, # 30000				\ so set Hz = way out of hearing range
1 @@:
	mov		al, # $B6					\ timer 2, LSB/MSB, mode 2, binary
	out		# $43 , al
	mov		eax, # 1193182				\ 1,193,182Hz
	xor		edx, edx					\ divide this by freq in Hz
	div		ebx							\ giving a timer count for the freq
	out		# $42 , al					\ send quotient in ax (low byte)
	push	eax							\ (to timer 2 port)
	pop		eax
	mov		al, ah
	out		# $42 , al					\ high byte to timer 2
	in		al, # $61					\ get speaker control bits
	push	eax
	pop		eax
	or		al, # 3						\ set bits, turning speaker on
	out		# $61 , al
	mov		ebx, [ebp]
	add		ebp, # 4
	next
end-code

code tone-off  ( -- )					\ turn speaker off
	in		al, # $61					\ get speaker control bits
	push	eax
	pop		eax
	and		al, # $FC					\ clear bits, turning speaker off
	out		# $61 , al
	next
end-code

variable beep-ms						\ millisecs to beep (passed to task)

: beeper  ( -- )						\ task for tone
	beep-ms @ ms  tone-off ;			\ make a task so it takes "no" CPU time

: tone  ( freq ms -- )					\ sound speaker @ freq for ms millisecs
	beep-ms !  tone-on					\ store # ms to wait and turn spk on
	['] beeper 10 10					\ beeper task, 10 cell stacks
	start-task drop ;					\ start task and drop tid

: beep  ( -- )							\ beep at 800 Hz for 100 ms
	800 100 tone ;

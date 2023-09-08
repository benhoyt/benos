\ BenOS v1.0 video output (c) Benjamin Hoyt 1997

( variables, values, and constants )
$B8000 value vbase						\ video screen base address
$3D4 value vcrtc						\ port for CRTC: $3D4 colour, $3B4 mono
variable vcols							\ # of columns/rows on screen
variable vrows
variable vscans							\ # of scan lines/character
variable vx								\ current cursor position
variable vy
variable vattr							\ current text attribute
variable vtabs							\ tab stop size
variable vcursor						\ hardware cursor showing?

( array of 80 spaces for speedy spaces output )
create blank-array  ( -- c-addr )  80 chars allot  blank-array 80 bl fill

: attr@  ( -- attr )					\ return text attribute
	vattr @ ;

: attr!  ( attr -- )					\ set text attribute
	vattr ! ;

: tabs@  ( -- n )						\ return tab stop size
	vtabs @ ;

: tabs!  ( n -- )						\ set tab size
	vtabs ! ;

: screen-size  ( -- #cols #rows )		\ return x,y screen resolution
	vcols @  vrows @ ;

code xy>vid  ( x y -- vid-addr )		\ calculate video address form x,y
	mov		eax, addr> vcols
	mul		ebx							\ eax = y*vcols
	add		eax, [ebp]					\       y*vcols+x
	lea		ebx, [eax*2]				\      (y*vcols+x)*2
	add		ebx, addr> vbase			\ add video base to get address
	add		ebp, # 4
	next
end-code

( display characters and attributes from string c-addr u on screen at x,y )
: blotch  ( c-addr u x y -- )
	xy>vid swap move ;

( display characters from string c-addr u at position x,y with attribute )
code blat  ( c-addr u x y attr -- )
	push	esi

	( calculate edi = video address from x,y position )
	mov		eax, addr> vcols
	mul		dword [ebp]					\ eax = y*vcols
	add		eax, 4 [ebp]				\       y*vcols+x
	lea		edi, [eax*2]				\      (y*vcols+x)*2
	add		edi, addr> vbase			\ add video base to get address

	( setup for and do main blat loop )
	mov		ah, bl						\ ah = attribute
	mov		ecx, 8 [ebp]				\ ecx = # chars to blat
	mov		esi, 12 [ebp]				\ esi -> source string
1 @@:
	lodsb								\ al = byte from string
	stosw								\ store char & attribute to edi
	loop	1 @@						\ loop until done whole string

	mov		ebx, 16 [ebp]				\ update stack
	add		ebp, # 20
	pop		esi
	next
end-code

code dark  ( -- )						\ blank whole screen with current attr
	mov		edi, addr> vbase			\ edi -> screen memory
	mov		eax, addr> vcols
	mul		dword addr> vrows			\ eax = # words on screen
	mov		ecx, eax
	shr		ecx, # 1					\ ecx = # dwords on screen
	mov		al, addr> vattr				\ eax byte 3 and byte 1 = attribute
	shl		eax, # 24
	mov		ah, addr> vattr
	or		eax, # $00200020			\ ecx byte 2 and byte 0 = char (space)
	rep		stosd						\ blank out all chars on screen
	next
end-code

code csize!  ( start end -- )			\ set hardware cursor size
	mov		edx, addr> vcrtc
	mov		al, # $A					\ cursor start/on/off register
	out		dx, al
	inc		edx
	in		al, dx						\ read data
	and		al, # $E0					\ mask off current cursor start
	or		al, [ebp]					\ or in new cursor start and write data
	out		dx, al
	dec		edx
	mov		al, # $B					\ cursor end/skew register
	out		dx, al
	inc		edx
	in		al, dx						\ read data
	and		al, # $E0					\ mask off current cursor end
	or		al, bl						\ or in new cursor end and write data
	out		dx, al
	mov		ebx, 4 [ebp]
	add		ebp, # 8
	next
end-code

code csize@  ( -- start end )			\ get hardware cursor size
	mov		edx, addr> vcrtc
	mov		al, # $A					\ cursor start/on/off register
	out		dx, al
	inc		edx
	in		al, dx						\ read data
	and		eax, # $1F					\ clear high bits
	sub		ebp, # 8
	mov		4 [ebp], ebx
	mov		[ebp], eax					\ store start on stack
	dec		edx
	mov		al, # $B					\ cursor end/skew register
	out		dx, al
	inc		edx
	in		al, dx						\ read data
	and		eax, # $1F					\ clear high bits
	mov		ebx, eax					\ store end on stack
	next
end-code

code hat-xy  ( x y -- )					\ set hardware cursor position to x,y
	mov		eax, addr> vcols
	mul		ebx							\ eax = y*vcols
	mov		ecx, [ebp]
	add		ecx, eax					\ ecx = cursor offset = y*vcols+x
	mov		ebx, 4 [ebp]
	add		ebp, # 8
	mov		edx, addr> vcrtc
	mov		al, # $E
	out		dx, al
	inc		edx
	mov		al, ch						\ out high cursor position
	out		dx, al
	dec		edx
	mov		al, # $F
	out		dx, al
	inc		edx
	mov		al, cl						\ out low cursor position
	out		dx, al
	next
end-code

: tat-xy  ( x y -- )					\ position text cursor
	vcursor @							\ if hardware cursor showing
	if		2dup hat-xy					\ .. set hardware cursor as well
	then	vy !  vx ! ;

: tat-xy?  ( -- x y )					\ return text cursor position
	vx @  vy @ ;

: vpage  ( -- )							\ clear screen and move cursor to 0,0
	0 0 tat-xy  dark ;

defer at-xy  ' tat-xy is at-xy			\ position output cursor to x,y
defer at-xy?  ' tat-xy? is at-xy?		\ return output cursor position x,y
defer page  ' vpage is page  			\ do form feed on output device

code hcursor-on  ( -- )					\ display hardware cursor
	mov		edx, addr> vcrtc
	mov		al, # $A					\ cursor start/on/off register
	out		dx, al
	inc		edx
	in		al, dx						\ read data
	and		al, # $DF					\ clear cursor off bit
	out		dx, al						\ write the changed data
	next
end-code

: cursor-on  ( -- )						\ turn on the hardware cursor
	at-xy? hat-xy						\ update hardware cursor position
	vcursor on  hcursor-on ;			\ and then turn it on

code cursor-off  ( -- )					\ turn off the hardware cursor
	mov		edx, addr> vcrtc
	mov		al, # $A					\ cursor start/on/off register
	out		dx, al
	inc		edx
	in		al, dx						\ read data
	or		al, # $20					\ set cursor off bit
	out		dx, al						\ write the changed data
	mov		dword addr> vcursor , # 0
	next
end-code

( scroll screen up n lines, filling blank lines with current attribute )
code scroll-up  ( n -- )
	push	esi

	( calculate source and destination addresses for scroll )
	mov		eax, addr> vcols			\ get distance between src and dest
	mul		ebx							\ ebx = dist
	mov		ebx, eax
	mov		edi, addr> vbase			\ edi = dest (vbase)
	lea		esi, [edi] [ebx*2]			\ esi = source (vbase+dist*2)

	( calculate # of dwords to move and scroll )
	mov		eax, addr> vrows
	mul		dword addr> vcols			\ eax = vcols*vrows
	sub		eax, ebx					\ eax = # words
	shr		eax, # 1
	mov		ecx, eax					\ ecx = # dwords
	rep		movsd						\ scroll data on screen up n lines

	( fill blank lines with spaces in the current attribute )
	shr		ebx, # 1					\ divide dist by 2 to get # dwords
	mov		ecx, ebx
	mov		al, addr> vattr				\ eax byte 3 and byte 1 = attribute
	shl		eax, # 24
	mov		ah, addr> vattr
	or		eax, # $00200020			\ ecx byte 2 and byte 0 = char (space)
	rep		stosd						\ blank out n lines

	mov		ebx, [ebp]					\ update stack
	add		ebp, # 4
	pop		esi
	next
end-code

( scroll screen down n lines, filling blank lines with current attribute )
code scroll-down  ( n -- )
	push	esi

	( calculate source and destination addresses for scroll )
	mov		eax, addr> vcols			\ get distance between src and dest
	mul		ebx							\ ebx = dist
	mov		ebx, eax
	mov		esi, addr> vbase			\ esi = source

	( calculate # of dwords to move and scroll )
	mov		eax, addr> vrows
	mul		dword addr> vcols			\ eax = vcols*vrows
	sub		eax, ebx					\ eax = # words
	shr		eax, # 1
	mov		ecx, eax					\ ecx = # dwords
	lea		esi, -4 [esi] [ecx*4]		\ move from highest to lowest addresses
	lea		edi, [esi] [ebx*2]			\ edi = esi+dist*2
	std
	rep		movsd						\ scroll data on screen up n lines
	cld

	( fill blank lines with spaces in the current attribute )
	mov		edi, addr> vbase			\ addr of first blank line
	shr		ebx, # 1					\ divide dist by 2 to get # dwords
	mov		ecx, ebx
	mov		al, addr> vattr				\ eax byte 3 and byte 1 = attribute
	shl		eax, # 24
	mov		ah, addr> vattr
	or		eax, # $00200020			\ ecx byte 2 and byte 0 = char (space)
	rep		stosd						\ blank out n lines

	mov		ebx, [ebp]					\ update stack
	add		ebp, # 4
	pop		esi
	next
end-code

( scan for next video ctrl char in string, u2 is chars until a ctrl or end )
code vscan  ( c-addr u1 -- u2 false | ctrl true )
	mov		edi, [ebp]
	mov		ecx, ebx
	jecxz	2 @@
	movzx	eax, byte [edi]				\ eax = first byte from string
	test	byte addr> chtypes [eax], # chvctrl
	jz		short 1 @@
	mov		[ebp], eax					\ it's a ctrl char, return true
	mov		ebx, # -1
	next
1 @@:
	mov		al, [edi]					\ read another byte
	dec		ecx
	test	byte addr> chtypes [eax], # chvctrl
	jnz		short 2 @@					\ if it's a ctrl char stop now
	inc		edi
	or		ecx, ecx					\ loop till end of string
	jnz		1 @@
2 @@:
	sub		edi, [ebp]					\ calculate u2 and return false
	mov		[ebp], edi
	xor		ebx, ebx
	next
end-code

: vcr  ( -- )							\ do a video carriage return
	vx off ;

: vlf  ( -- )							\ do a video line feed
	vy incr  vy @  vrows @ =
	if		vy decr  1 scroll-up		\ scroll if at bottom of screen
	then	;

: vblat  ( c-addr u -- )				\ display string, updating cursor
	vx @  over vx +!  vy @  attr@  blat ;

: vtab  ( -- )							\ do a video tab
	vtabs @  vx @  over mod -
	vcols @  vx @ -  umin				\ make sure doesn't go off screen
	blank-array  swap vblat ;			\ uses blank-array for speed

: vbksp  ( -- )							\ do a non-destruct video backspace
	vx @								\ ignore if we're at column 0
	if		vx decr
	then	;

create vctrl-table  ( -- a-addr )		\ video control char handler table
	' beep ,	\ 7 bell
	' vbksp ,	\ 8 backspace
	' vtab ,	\ 9 tab
	' vlf ,		\ 10 line feed
	' noop ,	\ 11 vertical tab
	' vpage ,	\ 12 form feed
	' vcr ,		\ 13 carriage return

: vctrl  ( char -- )					\ process control char
	7 -  cells  vctrl-table +  @ execute ;

: vtype  ( c-addr u -- )				\ fast video mode type routine
	begin	dup							\ stop if end of string or u = 0
	while	vcols @  vx @ -				\ calculate #cols left on screen
			over umin ?dup				\ the min of these is #chars to process
			if		>r over r>  vscan	\ scan for a video control char
					if		vctrl  1	\ this char is ctrl, process
					else	>r over r@	\ display # chars till next ctrl char
							vblat r>
					then	/string		\ move along addr u by #chars processed
			else	vcr vlf				\ at end of line, do a CR/LF
			then
	repeat	2drop  at-xy? at-xy ;		\ update hardware cursor if needed

defer type  ' vtype is type				\ display character string c-addr u

: init-video  ( -- )					\ initialise video routines
	80 vcols !  25 vrows !				\ 80x25 textmode
	16 vscans !  8 tabs!  7 attr!		\ 16 scans/char, tabsize = 8, attr = 7
	cursor-on  page ;					\ cursor on to 0,0 and clear screen

variable emit-char						\ character for emit (for speed)

: emit  ( char -- )						\ display one character char
	emit-char !							\ store char in variable
	emit-char 1 type ;					\ so we can get its address and type

: cr  ( -- )							\ move outputting to start of next line
	$0A0D emit-char !					\ store CR,LF in variable
	emit-char 2 type ;					\ get its address and type (fast!)

: space  ( -- )							\ display one space
	bl emit ;

: spaces  ( n -- )						\ if n > 0, display n spaces
	0 max
	begin	dup  80 min					\ do max 80 spaces at once
			blank-array swap  type		\ throw 'em on screen
			80 -  dup 0<=				\ do next 80 spaces or stop
	until	drop ;

: eeol  ( -- )							\ erase all text till end of line
	at-xy?								\ save current cursor pos
	over  vcols @ swap -  spaces		\ display enough spaces to blank to EOL
	at-xy ;								\ restore cursor pos

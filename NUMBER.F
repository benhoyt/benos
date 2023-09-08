\ BenOS v1.0 number conversion (c) Benjamin Hoyt 1997

80 constant #buf-size  ( -- n )			\ # of chars in #buf (equals /hold)
create #buf  #buf-size chars allot		\ conversion buffer
variable hld							\ conversion buffer pointer

: hex  ( -- )							\ set base to 16, ie., hexadecimal
	16 base ! ;

: decimal  ( -- )						\ set base to 10, ie., decimal
	10 base ! ;

: <#  ( -- )							\ initialise conversion routines
	[ #buf #buf-size chars + ] literal	\ init "stack pointer" for hold
	hld ! ;

: #>  ( ud -- c-addr u )				\ end conversion, leaving char string
	2drop  hld @						\ c-addr
	[ #buf #buf-size chars + ] literal	\ calculate # chars currently in buffer
	over - ;

: hold  ( char -- )						\ add char to conversion buffer
	[ -1 chars ] literal  hld +!		\ works like a stack - growing downward
	hld @ c! ;							\ store char in buffer

( convert one digit from ud1 to a char with BASE, return ud2 as ud1/BASE )
: #  ( ud1 -- ud2 )
	base @  mu/mod rot					\ divide ud1 by base, get rem and ud2
	dup 9 >  7 and +					\ if digit > 9 add 7 so it's from A-Z
	[char] 0 +  hold ;					\ convert to ASCII and HOLD

: sign  ( n -- )						\ if n is negative HOLD a minus sign
	0<
	if		[char] - hold
	then	;

( convert one digit from ud1 with #, continue conversion till ud is zero )
: #s ( ud1 -- ud2 )
	begin	#  2dup d0=
	until	;

: ud.r  ( ud n -- )						\ display ud in right field n wide
	>r  <# #s #>						\ convert ud to string
	r> over -  spaces  type ;			\ display spaces to align and # string

: d.r ( d n -- )						\ display d in right field n wide
	>r  tuck dabs  <# #s  rot sign  #>	\ convert d to string with sign
	r> over -  spaces  type ;			\ display spaces to align and # string

: u.r  ( u n -- )						\ display u in right field n wide
	0 swap  ud.r ;						\ convert u to ud and call ud.r

: .r  ( n1 n2 -- )						\ display n1 in right field n2 wide
	>r s>d r>  d.r ;					\ convert n1 to d and call d.r

: ud.  ( ud -- )						\ display ud with trailing space
	0 ud.r  space ;						\ ud.r does dirty work

: d.  ( d -- )							\ display d with trailing space
	0 d.r  space ;						\ d.r does dirty work

: u.  ( u -- )							\ display u with trailing space
	0 ud. ;								\ convert u to ud and call ud.

: .  ( n -- )							\ display n with trailing space
	s>d d. ;							\ convert n to d and call d.

: ##  ( ud1 -- ud2 )					\ convert 2 digits of ud1
	# # ;

: u.2  ( u -- )							\ display first 2 digits of u
	0  <# ## #>  type ;

: u.4  ( u -- )							\ display first 4 digits of u
	0  <# ## ## #>  type ;

: u.8 ( u -- )							\ display first 8 digits of u
	0  <# ## ## ## ## #>  type ;

: depth  ( -- n )						\ return current data stack depth
	sp@ sp0 @  swap -  cell/ ;

: ?  ( a-addr -- )						\ display contents of cell at a-addr
	@ . ;

( try to convert char to digit u with BASE, flag is true if success )
: digit? ( char -- u flag )
	dup isdigit?
	if		[char] 0 -  dup base @ <	\ if 0-9 just make sure it's < base
	else	dup isalpha?				\ else make sure it's a valid alpha
			if		>upper  $37 -		\ convert to uppercase and then binary
					dup base @ <  exit	\ valid = char-$37 < base?
			then	false
	then	;

( convert digits in string adding to ud1, c-addr2 u2 is chars remaining )
: >number  ( ud1 c-addr1 u1 -- ud2 c-addr2 u2 )
	begin	dup
			ifz		exit				\ if finished converting string, exit
			then	over c@  digit?		\ loop while successful conversion
	while	>r 2swap  base @ mud*		\ ud = ud*base
			r> m+						\      +digit
			2swap  1 /string			\ move string along a char
	repeat	drop ;

( Try to convert string c-addr u to a binary number, return double number
  and 1, single number and -1, or 0 if the string couldn't be converted.
  Note: A leading minus sign '-' will negate the final converted number,
  and a trailing full stop '.' character denotes a double number. )
: number?  ( c-addr u -- d|ud 1 | n|u -1 | 0 )
	over c@  [char] - =					\ is first char a minus - sign?
	if		1 /string  true				\ yep, move string along a char
	else	false
	then	>r							\ sign flag on r:
	0. 2swap  >number  2swap  r>		\ convert to binary
	if		dnegate						\ negate if we had a minus sign
	then	2swap  ?dup					\ any chars left?
	if		1 = swap  c@ [char] . = and	\ if last char is . char then double
			if		1
			else	2drop  0			\ otherwise couldn't convert
			then
	else	2drop  -1					\ return as single number
	then	;

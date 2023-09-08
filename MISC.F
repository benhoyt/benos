\ BenOS v1.0 miscellaneous (c) Benjamin Hoyt 1998

: .state  ( -- )						\ display STATE in visual manner
	state@  negate  2*  [char] [  +		\ '[' means interpreting
	emit  space ;						\ ']' means compiling

: .s  ( -- )							\ show stack depth and ten top values
	." Stack "  depth
	if		depth .  ." deep: "			\ display depth
			depth  10 umin  dup 0
			?do		dup  i - pick  .	\ pick value from stack and display
			loop	drop  ." -- "
	else	." empty "					\ else display "Stack empty"
	then	;

: wid>name  ( wid -- c-addr u )			\ return wid's name c-addr u
	wid>head @  dup
	if		hp>name count
	else	0							\ wordlist doesn't have a name
	then	;

: .wid  ( wid -- )						\ display name of wordlist
	wid>name type  space ;

( page waiting routines )
variable paging  true paging !			\ shall we do paging at all?
variable #crs							\ # of crs performed

: page-reset  ( -- )  -1 #crs ! ;		\ reset count of crs

: ?page  ( -- )							\ pause for page wait if we need to
	paging @
	if		#crs @  screen-size nip 1-  >=
			if		#crs off  ." Press any key to continue... "
					ekey drop  13 emit  eeol
			then
	then	;

: page-cr  ( -- )						\ do a cr and page wait if necessary
	cr  #crs incr  ?page ;

: order  ( -- )							\ display wordlists in search order
	get-order 0 do  .wid  loop
	." / "  get-current .wid ;			\ along with compilation wordlist

: du8  ( addr -- )						\ dump 8 chars in hex from c-addr
	8 bounds
	do		i c@  u.2 space				\ display in hex 2 digit format
	loop	;

: du16  ( addr -- )						\ emit 16 ASCII chars from c-addr
	16 bounds
	do		i c@  dup isctrl?
			if		drop  [char] .
			then	emit
	loop	;

: dump-line  ( addr -- )				\ dump line at c-addr
	dup u.8  ." : "  dup du8  ." - "  dup  8 + du8  space  du16 ;

: dump ( addr u -- )					\ dump u chars from addr
	page-reset  base @ >r  hex  bounds
	?do		page-cr  i dump-line  16	\ dump a 16 char line at a time
	+loop	space  r> base ! ;

variable status  ( -- a-addr )  false status !

: eeol-type  ( y c-addr u -- )			\ display string c-addr u at EOL
	rot  screen-size drop  19 -  swap at-xy  eeol  space  17 umin type ;

: show-status  ( -- )					\ display top-of-screen status line
	at-xy? 2>r  attr@ >r  0 0 at-xy
	$1A attr!  eeol space  .state		\ display state, stack, and unused
	$1F attr!  .s
	$1E attr!  screen-size drop  18 -  0 at-xy  .unused
	$1B attr!  0 context @				\ display wordlists on context stack
	begin	dup context0 @ u<
	while	swap  1+  tuck  over @		\ get wordlist name and display it
			wid>name eeol-type  cell+
	repeat	drop  1+ dup  s" อออออออออออออออออ" eeol-type
	1+  current @  wid>name eeol-type	\ now display definitions wordlist
	r> attr!  2r> at-xy ;				\ restore cursor position etc

: status-prompt ( -- )					\ display prompt with status line
	cr  ." > "  status @
	if		show-status					\ show status if status variable is on
	then	;

' status-prompt is prompt				\ put status-prompt to use

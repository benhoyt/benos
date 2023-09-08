\ BenOS v1.0 Forth exception handling (c) Benjamin Hoyt 1997

( Throw messages defined by the ANS Standard )
( -58 ) t" [IF] [ELSE] or [THEN] exception"
( -57 ) t" Character I/O exception"
( -56 ) t" QUIT"
( -55 ) t" Unidentified floating-point fault"
( -54 ) t" Floating-point underflow"
( -53 ) t" Exception stack overflow"
( -52 ) t" Control-flow stack overflow"
( -51 ) t" Compilation word list changed"
( -50 ) t" Search-order underflow"
( -49 ) t" Search-order overflow"
( -48 ) t" Invalid POSTPONE"
( -47 ) t" Compilation word list deleted"
( -46 ) t" Invalid floating-point argument"
( -45 ) t" Floating-point stack underflow"
( -44 ) t" Floating-point stack overflow"
( -43 ) t" Floating-point result out of range"
( -42 ) t" Floating-point division by zero"
( -41 ) t" Loss of precision"
( -40 ) t" Invalid BASE for floating-point conversion"
( -39 ) t" Unexpected end of file"
( -38 ) t" Non-existent file"
( -37 ) t" File I/O exception"
( -36 ) t" Invalid file position"
( -35 ) t" Invalid block number"
( -34 ) t" Block write exception"
( -33 ) t" Block read exception"
( -32 ) t" Invalid name argument (eg., TO xxx)"
( -31 ) t" >BODY used on non-CREATEd definition"
( -30 ) t" Obsolescent feature"
( -29 ) t" Compiler nesting"
( -28 ) t" User interrupt"
( -27 ) t" Invalid recursion"
( -26 ) t" Loop parameters unavailable"
( -25 ) t" Return stack imbalance"
( -24 ) t" Invalid numeric argument"
( -23 ) t" Address alignment exception"
( -22 ) t" Control structure mismatch"
( -21 ) t" Unsupported operation"
( -20 ) t" Can't write to a read-only location"
( -19 ) t" Definition name too long"
( -18 ) t" Parsed string overflow"
( -17 ) t" Pictured numeric output string overflow"
( -16 ) t" No name given"
( -15 ) t" Can't FORGET below the FENCE"
( -14 ) t" "							\ "compile only" special case
( -13 ) t" "							\ "undefined word" special case
( -12 ) t" Argument type mismatch"
( -11 ) t" Result out of range"
( -10 ) t" Division by zero"
(  -9 ) t" Invalid memory address"
(  -8 ) t" Dictionary overflow"
(  -7 ) t" DO ... LOOPs nested too deeply during execution"
(  -6 ) t" Return stack underflow"
(  -5 ) t" Return stack overflow"
(  -4 ) t" Stack underflow"
(  -3 ) t" Stack overflow"

create std-throws  ( -- a-addr )		\ Standard messages for THROW codes
	, , , , , , , , , ,  , , , , , ,	\ 58 less ABORT and ABORT" = 56
	, , , , , , , , , ,  , , , , , , , , , ,
	, , , , , , , , , ,  , , , , , , , , , ,

( BenOS system throw messages )
( -275 ) t" Printer not ready"
( -274 ) t" FPU error"
( -273 ) t" "
( -272 ) t" Page fault"
( -271 ) t" General protection fault"
( -270 ) t" Stack fault"
( -269 ) t" Segment not present"
( -268 ) t" Invalid TSS"
( -267 ) t" FPU segment overrun"
( -266 ) t" Double fault"
( -265 ) t" Device (FPU) not available"
( -264 ) t" Invalid opcode"
( -263 ) t" BOUND instruction exception"
( -262 ) t" Overflow interrupt (INTO)"
( -261 ) t" Software breakpoint (INT 3)"
( -260 ) t" Non-maskable interrupt"
( -259 ) t" Hardware breakpoint or trap"
( -258 ) t" Memory resize error"
( -257 ) t" Memory free error"
( -256 ) t" Memory allocation error"

create sys-throws  ( -- a-addr )		\ system messages for THROW codes
	, , , , ,  , , , , ,  , , , , ,  , , , , ,

: .throw  ( entry table -- )			\ display message entry in table
	swap  cells +  @ count type  [char] ! emit ;

: std-throw  ( n -- )					\ handle Standard throw code # n
	dup -1 =							\ it's ABORT so just exit
	if		drop exit
	then	dup -2 =					\ it's ABORT" so display the text
	if		abort"msg @ count type  drop exit
	then	dup -13 =					\ "undefined word" special case?
	if		last-parse 2@ type  ."  is undefined!"  drop exit
	then	dup -14 =					\ "compile only" special case?
	if		last-parse 2@ type  ."  is compile only!"  drop exit
	then	negate  3 -					\ calculate entry into std-throws
	std-throws .throw ;					\ and display message

: sys-throw  ( n -- )					\ handle system throw code # n
	negate  256 -  sys-throws .throw ;	\ calculate entry and display

defer quit  ( -- ) ( r: i*x -- )		\ defer quit so we can use it now

: throw-code  ( n -- )					\ handle throw code # n
	dup -58 0 within					\ a Standard throw code?
	if		std-throw
	else	dup -274 -255 within		\ a system throw code?
			if		sys-throw
			else	." Unknown exception # "
					base @  decimal		\ make sure base is decimal
					swap .  base !		\ display throw # in decimal
					base !
			then
	then	sp0 @ sp!  quit ;			\ empty stack and QUIT

( push an exception frame on the return stack and execute xt )
: _catch  ( i*x xt -- j*x 0 | i*x n )
	sp@ >r								\ save data stack pointer
	handler @ >r						\ save previous handler
	rp@ handler !						\ set current handler (rstack ptr)
	execute								\ execute returns if no throw
	r> handler !						\ restore previous handler
	r> drop  0 ;						\ discard saved stack ptr and return 0

' _catch is catch						\ resolve foward reference

( throw an exception back to last CATCHed exception frame if n is nonzero )
: _throw  ( k*x n -- k*x | i*x n )
	?dup								\ don't do anything if n is zero
	if		handler @					\ anything CATCHed yet?
			ifz		throw-code			\ nope, display throw msg and QUIT
			then	handler @ rp!		\ restore previous return stack
			r> handler !				\ restore previous handler
			r> swap >r					\ put n on return stack
			sp!  drop r>				\ restore data stack (drop kills xt)
	then	;							\ now we will return to caller of CATCH

' _throw is throw						\ resolve foward reference

( throw -1, which aborts back to the interpreter without displaying anything )
: abort  ( -- )
	-1 throw ;

( if x is nonzero throw -2 which display inline string and QUITs )
: (abort")  ( x -- )
	if		r> abort"msg !  -2 throw	\ store addr of inline string and throw
	then	r>  count +  >r ;			\ make sure we don't execute string!

' (abort") xt!> t(abort")				\ store target compiler's (abort") xt

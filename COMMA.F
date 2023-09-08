\ BenOS v1.0 dictionary compiling (c) Benjamin Hoyt 1997

: here  ( -- addr )						\ return data space (dictionary) ptr
	dp @ ;

: allot  ( n -- )						\ allot n bytes of data space
	dp +! ;

: c,  ( char -- )						\ compile char to data space
	here c!								\ store char at here
	[ 1 chars ] literal  allot ;		\ then increment dp

: w,  ( word -- )						\ compile 16 bit word to data space
	here w!								\ store char at here
	2 allot ;							\ then increment dp

: ,  ( x -- )							\ compile cell x to data space
	here !								\ store cell at here
	cell allot ;						\ then increment dp

: literal  ( x -- )						\ compile x as literal
	$83 c, $ED c, $04 c,				\ sub ebp, # 4
	$89 c, $5D c, $00 c,				\ mov [ebp], ebx
	$BB c, , ;  immediate restrict		\ mov ebx, # x

: 2literal  ( x1 x2 -- )				\ compile cell pair as double literal
	$83 c, $ED c, $08 c,				\ sub ebp, # 8
	$89 c, $5D c, $04 c,				\ mov 4 [ebp], ebx
	$C7 c, $45 c, $00 c,  swap ,		\ mov dword [ebp], x1
	$BB c, , ;  immediate restrict		\ mov ebx, # x2

: align  ( -- )							\ align data space pointer
	here  aligned dp ! ;

: rel,  ( addr -- )						\ compile addr as a relative address
	here cell+  -  , ;

( compile code to execute the execution semantics identified by xt )
: compile,  ( xt -- )
	$E8 c,  rel, ;						\ call xt

: compile  ( -- )						\ compile following call to code space
	r>  1+ dup  cell+ dup >r			\ correct return address
	swap @ +  compile, ;				\ convert to absolute then compile,

' compile xt!> tcompile					\ store target compiler's tcompile xt

: name,  ( c-addr u -- )				\ compile string c-addr u to dictionary
	tuck  here place					\ place at here as counted string
	1+ chars allot ;					\ and allot dictionary space

( displays the following inline string - runtime for ." )
: (.")  ( -- )
	r>  count  2dup + >r				\ make sure we don't execute string!
	type ;								\ and display it

' (.") xt!> t(.")						\ store target compiler's (.") xt

: (header,)  ( c-addr u -- )			\ compile header for name c-addr u
	messages @							\ do only if messages is true
	if		2dup search-order			\ if c-addr u already defined
			if		drop  cr 			\ then display a message
					2dup type  ."  redefined "
			then
	then	align  here latest !		\ align here and update last
	0 ,  0 c,  name,					\ compile link, type, and name
	align ;								\ and align dictionary pointer

: header,  ( "name" -- )				\ parse and compile header for name
	name (header,) ;

: header  ( "name" -- )					\ defined header for name and reveal
	header,  reveal ;

: unused  ( -- u )						\ return unused data space
	code-base code-size +  here - ;

: ?unused  ( -- )						\ abort if no data space left
	unused 0<  -8 and throw ;			\ unused < 0 means dictionary overflow

: .unused  ( -- )						\ display unused dictionary space
	." Code: "  unused . ;

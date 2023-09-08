\ BenOS v1.0 Forth interpreter and compiler (c) Benjamin Hoyt 1997

: source  ( -- c-addr u )				\ return the input source string
	src 2@ ;

( x1 through xn describes the current input specification )
: save-input  ( -- xn ... x1 n )
	source  >in @  source-id  blk @		\ save variables
	5 ;									\ # of items saved on stack

( attempt to restore input spec xn through x1, flag true on error )
: restore-input  ( xn ... x1 n -- flag )
	dup 5 =								\ only 5 parameters?
	if		drop  dup
			if		dup block drop		\ reload block
			then	blk !				\ restore variables
			src-id !  >in !  src 2!
			false						\ and return false = success
	else	0 ?do  drop  loop  true		\ n <> 5, kill params and return true
	then	;

( saves input specification to return stack, x1 through xn are backwards )
: input>r  ( -- ) ( r: -- x1 .. xn n -- )
	r>  save-input dup
	begin	?dup
	while	1-  rot >r					\ one parameter >r
	repeat	>r  >r ;					\ push n >r and remember return addr!

( restore input specification from return stack, flag is *false if success* )
: inputr>  ( -- flag ) ( r: x1 .. xn n -- )
	r>  r> dup							\ get return address and n from r:
	begin	?dup
	while	1-  r> -rot					\ one parameters from r:
	repeat	restore-input  swap >r ;	\ restore input, put back return addr!

: _compiler  ( i*x c-addr u -- j*x )	\ compile token c-addr u
	2dup search-wordlists ?dup			\ try to find c-addr u in search order
	if		2swap 2drop  0<				\ we found it!
			if		compile,			\ normal word, compile it
			else	execute				\ immediate word, interpret it
			then
	else	number?  dup 0=				\ try to convert to number
			-13 and throw  0>			\ not a number, token undefined
			if		postpone 2literal	\ compile double cell literal
			else	postpone literal
			then
	then	;

( defer main token compiler - we may want to change it later )
defer compiler  ( i*x c-addr u -- j*x )  ' _compiler is compiler

: _interpreter  ( i*x c-addr u -- j*x )	\ interpret token c-addr u
	2dup search-order					\ search for token
	if		nip nip  dup type@
			type.restrict and  0<>		\ is it compile-only?
			-14 and throw				\ don't interpret compile-only word
			xt@ execute					\ else execute it
	else	number? 0=  -13 and throw	\ try to convert to number
	then	;

( defer main token interpreter - we may want to change it later )
defer interpreter  ( i*x c-addr u -- j*x )  ' _interpreter is interpreter

( this points to compiler if state is true, or interpreter if state is false )
defer interp-token  ( i*x c-addr u -- j*x )

: [  ( -- )								\ enter interpretation mode
	['] interpreter is interp-token		\ change token handler to interpreter
	state off ;  immediate				\ and set state to false

: ]  ( -- )								\ enter compiliation mode
	['] compiler is interp-token		\ change token handler to compiler
	state on ;							\ and set state to true

: ?stack  ( -- )						\ throw error message if stack error
	sp@ sp0 @ u>  -4 and throw			\ stack underflow
	sp@  sp0 @ /dstack @ -  u<
	-3 and throw ;						\ stack overflow

: interpret  ( i*x -- j*x )				\ interpret the whole TIB
	begin	parse-word dup				\ try to parse, loop while word parsed
	while	interp-token  ?stack		\ handle token, check for stack errors
	repeat	2drop  ?unused ;			\ check for dictionary overflow

: !csp  ( -- )							\ save the check stack pointer
	sp@ csp ! ;

: ?csp  ( -- )							\ check saved stack pointer
	sp@ csp @ <>  -22 and throw ;		\ current sp is <> csp so throw

( save the current input source specification and interpret string c-addr u )
: evaluate  ( c-addr u -- )
	input>r								\ save input source
	src 2!  >in off  src-id on			\ save input source and define new one
	interpret							\ interpret
	inputr> drop ;						\ restore old input source

: query  ( -- )							\ refill the input source from keyboard
	key-tib @ dup #key-tib accept		\ ACCEPT chars into key-tib
	space  src 2!  >in off ;			\ set SOURCE and reset >IN

( refill the terminal input buffer, returning true if successful )
: refill ( -- flag )
	blk @
	if		false  exit					\ return false if loading block
	then	source-id					\ evaluating/file so return false
	if		false  exit
	then	query  true ;				\ else keyboard

( prompt is deferred, we set it to status-prompt later )
defer prompt  ( -- )

: init-quit  ( -- )						\ set up things for QUIT
	blk off  src-id off					\ no block loading, keyboard input
	postpone [ ;						\ set interpret mode

: .ok  ( -- )							\ display "ok" if interpreting
	state @
	ifz		." ok"
	then	;

: _quit  ( -- ) ( r: i*x -- )			\ reset to text interpreter
	rp0 @ rp!  init-quit
	begin	prompt  refill drop			\ display prompt and refill tib
			interpret  .ok				\ interpret and print "ok" message
	again	;

' _quit is quit							\ resolve forward reference

: load  ( i*x u -- j*x )				\ interpret block u
	input>r								\ save input source
	dup blk !							\ set BLK
	block 1k src 2!  >in off			\ define new input source
	interpret							\ interpret
	inputr> drop ;						\ restore old input source

: thru  ( i*x u1 u2 -- j*x )			\ interpret block u1...u2
	1+ swap
	do		i load
	loop	;

: :  ( "name" -- )						\ create colon def and begin compiling
	!csp								\ store check stack pointer
	header,  ] ;						\ compile header, begin interpreting

: exit  ( -- )							\ exit current definition at runtime
	$C3 c, ;  immediate restrict		\ ret

( end the current definition and allow it to be found in the dictionary )
: ;  ( -- )
	?csp  reveal						\ check stack and reveal name
	postpone exit						\ compile code to exit word
	postpone [ ;  immediate restrict	\ and return to interpreting

: immediate  ( -- )						\ make most recent definition immediate
	type.immediate or-type ;

: restrict  ( -- )						\ make last definition compile-only
	type.restrict or-type ;

: \  ( "ccc<eol>" -- )					\ parse and discard till end-of-line
	blk @
	if		>in @  63 + -64 and
	else	source nip
	then	>in ! ;  immediate

: (  ( "ccc<paren>" -- )				\ parse and discard ccc
	[char] ) parse  2drop ;  immediate	\ used to comment till ending )

: .(  ( "ccc<paren>" -- )				\ parse and discard ccc
	[char] ) parse  type ;  immediate	\ used to display till ending )

: cmp0,  ( -- )							\ compile code to compare TOS with 0
	$0B c, $DB c,						\ or ebx, ebx
	$8B c, $5D c, $00 c,				\ mov ebx, [ebp]
	$8D c, $6D c, $04 c, ;				\ lea ebp, 4 [ebp]

: >mark  ( -- orig )					\ mark a forward branch
	here  0 , ;

: >resolve  ( orig -- )					\ resolve a forward branch
	here  over cell+  -  swap ! ;		\ convert -> relative addr and !

: <mark  ( -- dest )					\ mark a backward branch
	here ;

: <resolve  ( dest -- )					\ resolve a backward branch
	rel, ;								\ relative address for Intel jumps

: if  ( -- orig )						\ begin an IF .. THEN clause
	cmp0,  $0F c, $84 c,				\ branch to orig if TOS = 0
	>mark ;  immediate restrict			\ mark origin

: ifz  ( -- orig )						\ begin an IFZ .. THEN clause
	cmp0,  $0F c, $85 c,				\ branch to orig if TOS <> 0
	>mark ;  immediate restrict			\ mark origin

: then  ( orig -- )						\ end an IF .. THEN clause
	>resolve ;  immediate restrict		\ resolve origin

: else  ( orig1 -- orig2 )				\ begins an if .. ELSE .. THEN clause
	$E9 c,  >mark						\ unconditional branch to orig2
	swap >resolve ;  immediate restrict	\ resolve orig1

: found?  ( x | c-addr 0 -- )			\ abort with error msg if x = 0
	0=  -13 and throw ;

: postpone ( "name" -- )				\ postpone name's compilation semantics
	name								\ parse name
	search-wordlists  ?dup found?  0<	\ try to find it, is it immediate?
	if		compile compile				\ non-immediate word
	then	compile, ;  immediate restrict

: ahead  ( -- orig )					\ unconditional branch to orig
	$E9 c, >mark ;  immediate restrict	\ mark origin

: begin  ( -- dest )					\ begin BEGIN .. UNTIL etc loop
	<mark ;  immediate restrict			\ mark destination

: again  ( dest -- )					\ end BEGIN .. AGAIN loop
	$E9 c,								\ unconditional branch to dest
	<resolve ;  immediate restrict		\ resolve destination

: until  ( dest -- )					\ end BEGIN .. UNTIL loop
	cmp0,  $0F c, $84 c,				\ branch to dest if TOS = 0
	<resolve ;  immediate restrict		\ resolve destination

: while  ( dest -- orig dest )			\ begin .. WHILE .. REPEAT clause
	cmp0,  $0F c, $84 c,				\ branch to dest if TOS = 0
	>mark  swap ;  immediate restrict	\ mark orig and place orig under dest

: repeat  ( orig dest -- )				\ end BEGIN .. WHILE .. REPEAT
	postpone again						\ unconditional branch to dest
	postpone then ;  immediate restrict	\ resolve WHILE origin

: do  ( -- do-sys )						\ begin a DO .. LOOP loop
	postpone (do)						\ call (do)
	>mark								\ mark end of loop address
	<mark ;  immediate restrict			\ mark start of loop address

: ?do  ( -- do-sys )					\ begin a ?DO .. LOOP loop
	postpone (?do)						\ call (?do)
	>mark								\ mark end of loop address
	<mark ;  immediate restrict			\ mark start of loop address

: loop  ( do-sys -- )					\ end a DO .. LOOP loop
	$FF c, $04 c, $24 c,				\ inc dword [esp]
	$0F c, $81 c, rel,					\ jno "start of loop"
	$83 c, $C4 c, $0C c,				\ add esp, # 12
	here swap ! ;  immediate restrict

: +loop  ( do-sys -- )					\ end a DO .. +LOOP loop
	$8B c, $C3 c,						\ mov eax, ebx
	$8B c, $5D c, $00 c,				\ mov ebx, [ebp]
	$83 c, $C5 c, $04 c,				\ add ebp, # 4
	$01 c, $04 c, $24 c,				\ add [esp], eax
	$0F c, $81 c, rel,					\ jno "start of loop"
	$83 c, $C4 c, $0C c,				\ add esp, # 12
	here swap ! ;  immediate restrict

: leave  ( do-sys -- )					\ exit one DO .. LOOP
	$83 c, $C4 c, $08 c,				\ add esp, # 8
	$C3 c, ;  immediate restrict		\ ret

: unloop  ( do-sys -- )					\ discard loop params but don't exit
	$83 c, $C4 c, $0C c,				\ add esp, # 12
	;  immediate restrict

: '  ( "name" -- xt )					\ return name's execution token
	name  search-wordlists found? ;

: `  ( "name" -- hp )					\ return name's header pointer
	name  search-order found? ;

: [']  ( "name" -- )					\ return xt of name at runtime
	'  postpone literal ;  immediate restrict

: char  ( "name" -- char )				\ return first char of parsed name
	name  drop  c@ ;

: [char]  ( "name" -- char )			\ return first char of name at runtime
	char  postpone literal ;  immediate restrict

: recurse  ( -- )						\ recurse to current def at runtime
	last xt@  compile, ;  immediate restrict

: value  ( x "name" -- )				\ define a value which returns x
	header
	$83 c, $ED c, $04 c,				\ sub ebp, # 4
	$89 c, $5D c, $00 c,				\ mov [ebp], ebx
	$8D c, $1D c, ,						\ lea ebx, x (aligned mov ebx, # x)
	$C3 c, ;							\ ret

: constant  ( x "name" -- )				\ define constant name which returns x
	value ;

: create  ( "name" -- )					\ create name which returns addr
	header
	$83 c, $ED c, $04 c,				\ sub ebp, # 4
	$89 c, $5D c, $00 c,				\ mov [ebp], ebx
	$BB c, here 5 + ,					\ mov ebx, # data-addr
	$C3 c, ;							\ ret

: variable  ( "name" -- )				\ create name with one cell data space
	create  0 , ;

: user  ( "name" -- )					\ create user variable called name
	header
	$83 c, $ED c, $04 c,				\ sub ebp, # 4
	$89 c, $5D c, $00 c,				\ mov [ebp], ebx
	$8B c, $9E c, user-ofs @ ,			\ mov ebx, user-ofs [esi]
	cell user-ofs +!  $C3 c, ;			\ ret

: defer  ( "name" -- )					\ define name which executes is ISed xt
	header
	$B8 c, 0 ,							\ mov eax, # xt
	$FF c, $E0 c, ;						\ jmp eax

: >body  ( xt -- a-addr )				\ return data address of xt
	dup c@ $B8 =
	if		1							\ defer
	else	dup 4 + @  $1D8D005D =
			if		8					\ value
			else	12					\ create
			then
	then	+ ;

: addr  ( "name" -- a-addr )			\ return name's data address
	' >body ;

: state@  ( -- state )					\ return contents of STATE
	state @ ;

: ,"  ( "ccc<quote>" -- )				\ parse and compile string ccc
	[char] " parse  name, ;

: abort"  ( "ccc<quote>" -- )			\ if TOS true, abort and display ccc
	postpone (abort")  ," ;  immediate restrict

: ."  ( "ccc<quote>" -- )				\ display ccc at runtime
	postpone (.")  ," ;  immediate restrict

create string-buf  ( -- c-addr )		\ one string buffer for immediate S"
	256 chars allot

: s"  ( "ccc<quote>" -- )				\ parse ccc and return string c-addr u
	state@
	if		postpone (s")  ,"  exit		\ compile (s") and string ccc
	then	[char] " parse				\ interpreting, place in S" buffer
	string-buf place  string-buf count ;  immediate

: c"  ( "ccc<quote>" -- )				\ return c-addr for ccc at runtime
	postpone (c")  ," ;  immediate restrict

: to  ( x "name" -- )					\ store x in value name at runtime
	addr  state@
	if		$8B c, $C3 c,				\ mov eax, ebx
			$8B c, $5D c, $00 c,		\ mov ebx, [ebp]
			$83 c, $C5 c, $04 c,		\ add ebp, # 4
			$A3 c, ,					\ mov data-addr , eax
	else	!							\ interpreting, store IMMEDIATEly
	then	;  immediate

: is  ( xt "name" -- )					\ store xt in defer name at runtime
	postpone to ;  immediate

: defer@  ( "name" -- xt )				\ return defer's current xt
	addr state@
	if		postpone literal			\ postpone data addr as literal
			postpone @					\ and fetch xt from it
	else	@							\ interpreting, just fetch xt now
	then	;  immediate

: wordlist  ( -- wid )					\ create a wordlist returning its wid
	align here
	dup  [ 3 cells ] literal  + ,		\ hash table pointer
	wid-link ,  dup to wid-link			\ link to previous wordlist
	0 ,									\ pointer to this vocab's header
	#threads ,							\ #threads
	here  #threads cells  dup allot		\ hash table
	erase ;								\ initially zeroes

: :noname  ( -- xt )					\ create a nameless colon definition
	align here  ]						\ align, return xt and start compiling
	0 to last  !csp ;					\ last = 0 doesn't allow revealing

: _does>  ( -- )						\ runtime for does>
	here  r@ 1+							\ save here and get ptr to does code
	last xt@  6 +  dp !					\ here -> offset into create code
	$90 c,  compile,					\ nop; call does-code
	dp ! ;								\ restore dp

: does>  ( -- )							\ define run time code for last CREATEd
	postpone _does>						\ call _does>
	$C3 c,								\ ret
	$5B c, ;  immediate restrict		\ pop ebx

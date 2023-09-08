\ BenOS target compiler (c) Benjamin Hoyt 1997

messages off							\ turn "redefined" messages off
wordlist constant tcomp-wid				\ target compiler's wordlist
get-order tcomp-wid swap  1+ set-order	\ search thru tcomp-wid
definitions								\ and compile into it
256 1024 * constant tsize				\ size of target space in bytes
tsize allocate throw constant timage	\ pointer to allocated target space
$8000 constant tbase					\ target space base address
variable tdp  tbase tdp !				\ target dictionary pointer
0 value twid-link						\ target wordlist link
0 value tlast							\ last target word defined
variable tmessages  tmessages on		\ target "redefined" messages?
0 value tforth-wid						\ target forth vocabulary wid
0 value tuser-ofs						\ current offset into user table
variable t(c")  variable t(s")			\ target primitive addresses
variable t(abort")  variable t(.")
variable t(do)  variable t(?do)
variable tcompile

( miscellaneous words )
: xt!>  ( xt "name" -- )  addr ! ;		\ to store an xt to these variables
: cr.(  [char] ) parse  cr ."   " type ;  immediate

( target cell sizes etc. )
: tcells  ( n1 -- n2 )  cells ;
: tchars  ( n1 -- n2 )  ( chars ) ;  immediate
: tcell+  ( a-addr1 -- a-addr2 )  cell+ ;
: tchar+  ( c-addr1 -- c-addr2 )  char+ ;

( target memory addressing - fetches and stores )
: >timage  ( taddr -- addr )  tbase -  timage + ;
: tmemory  ( xt-of-memory-op -- )  create ,
	does>  ( i*x taddr -- )  swap >timage swap  @ execute ;
' c@ tmemory tc@	' c! tmemory tc!
' w@ tmemory tw@	' w! tmemory tw!
'  @ tmemory t@		'  ! tmemory t!
' 2@ tmemory t2@	' 2! tmemory t2!
: tcount  ( taddr -- taddr u )  dup tchar+  swap tc@ ;
: tfill  ( taddr u char -- )  rot >timage -rot  fill ;

( target dicitonary compiling words )
: there  ( -- addr )  tdp @ ;
: tallot  ( n -- )  tdp +! ;
: tc,  ( char -- )  there tc!  [ 1 tchars ] literal  tallot ;
: tw,  ( word -- )  there tw!  2 tallot ;
: t,  ( x -- )  there t!  [ 1 tcells ] literal  tallot ;
: talign  ( -- )  there  aligned  tdp ! ;
: trel,  ( addr -- )  there tcell+  -  t, ;
: tcompile,  ( xt -- )  $E8 tc,  trel, ;
: tname,  ( c-addr u -- )  tuck  there >timage place  1+ tchars tallot ;
: t,"  ( "ccc<quote>" -- )  [char] " parse  tname, ;
: tliteral  ( x -- )
	$83 tc, $ED tc, $04 tc,				\ sub ebp, # 4
	$89 tc, $5D tc, $00 tc,				\ mov [ebp], ebx
	$BB tc, t, ;  immediate restrict	\ mov ebx, # x
: t2literal  ( x1 x2 -- )
	$83 tc, $ED tc, $08 tc,				\ sub ebp, # 8
	$89 tc, $5D tc, $04 tc,				\ mov 4 [ebp], ebx
	$C7 tc, $45 tc, $00 tc,  swap t,	\ mov dword [ebp], x1
	$BB tc, t, ;  immediate restrict	\ mov ebx, # x2

( target header structure handling )
: thp>link  ( thp -- taddr-link )  ( 0 + ) ;  immediate
: thp>type  ( thp -- taddr-type )  4 + ;
: thp>name  ( thp -- taddr-name )  5 + ;
: txt@  ( thp -- xt )  thp>name tcount +  aligned ;
: ttype@  ( thp -- u )  thp>type tc@ ;
: ttype!  ( u thp -- )  thp>type tc! ;
1 constant ttype.immediate
2 constant ttype.restrict

( target wordlist structure handling )
: twid>hash  ( twid -- taddr-hash )  ( 0 + ) ;  immediate
: twid>link  ( twid -- taddr-link )  4 + ;
: twid>head  ( twid -- taddr-hp )  8 + ;

( target dictionary searching )
: tsearch-chain  ( c-addr u tchainptr -- 0 | thp 1 | thp -1 )
	begin	t@  ?dup
	while	dup thp>name  2over  rot >timage count  icompare
		ifz		nip nip  dup ttype@  ttype.immediate and
			if		1
			else	-1
			then	exit
		then	thp>link
	repeat	2drop 0 ;
: thash  ( tc-addr u -- hash-byte )  swap >timage swap  hash ;
: thash>chainptr  ( twid hash-byte -- tchainptr )
	swap twid>hash t@  dup t@ 1-  rot and tcells  + tcell+ ;
: tdsearch  ( c-addr u -- 0 | thp 1 | thp -1 )
	2dup hash  tforth-wid swap  thash>chainptr  tsearch-chain ;
: tsearch>xt  ( 0 | thp 1 | thp -1 -- 0 | xt 1 | xt -1 )
	dup if  swap txt@ swap  then ;
: tsearch  ( c-addr u -- 0 | xt 1 | xt -1 )
	tdsearch tsearch>xt ;
: treveal  ( -- )
	tlast ?dup
	if		thp>name tcount  thash  tforth-wid swap  thash>chainptr
		dup t@  tlast thp>link t!  tlast swap t!
	then	;
: tset-type  ( u -- )  tlast ttype! ;
: tor-type  ( u -- )  tlast  ttype@ or  tset-type ;

( main target compiler and interpreter )
: t?can't  ( i*x flag -- i*x | )  abort" Can't execute this word!" ;
: tcompiler  ( i*x c-addr u -- j*x )
	2dup tsearch ?dup
	if		0<							\ found, immediate?
		if		nip nip  tcompile,		\ nope, just compile
		else	drop  tcomp-wid search-wordlist
			1 <> t?can't  execute		\ exec target compiler's immediate word
		then
	else	2dup tcomp-wid search-wordlist  ?dup
		if		-1 = t?can't  nip nip  execute  exit
		then	number? dup				\ not found, is it a number?
		if		0>
			if		postpone t2literal	\ yep, compile as double or single
			else	postpone tliteral
			then
		else	-13 throw				\ nope
		then
	then	;
: tvalue?  ( taddr -- flag )
	dup  4 + t@  $1D8D005D =  swap 12 + tc@  $C3 =  and ;
: tcreate?  ( taddr -- flag )
	dup  3 + t@  $BB005D89 =  swap 11 + tc@  $C3 =  and ;
: tinterpreter  ( i*x c-addr u -- j*x )
	2dup s" bl" icompare
	if		2dup tsearch
		if		dup tvalue?				\ fetch value/constant
			if		8 + t@  nip nip exit
			then	dup tcreate?		\ return create/variable data address
			if		12 +  nip nip exit
			then	drop
		then
	then	_interpreter ;
: tcompiler-on  ( -- )
	['] tcompiler is compiler  ['] tinterpreter is interpreter ;

( target word creation )
: theader,  ( "name" -- )  name  tmessages @
	if		2dup tdsearch
		if		drop  cr  2dup type  ."  redefined "
		then
	then	talign  there to tlast  0 t,  0 tc,  tname,  talign ;
: theader  ( "name" -- )  theader,  treveal ;
: t:  ( "name" -- )  !csp  theader,  ] ;
: texit  ( -- )  $C3 tc, ;  immediate restrict
: t;  ( -- )  ?csp  treveal  postpone texit  postpone [ ;  immediate restrict
: timmediate  ( -- )  ttype.immediate tor-type ;
: trestrict  ( -- )  ttype.restrict tor-type ;
: tvalue  ( x "name" -- )  theader
	$83 tc, $ED tc, $04 tc,				\ sub ebp, # 4
	$89 tc, $5D tc, $00 tc,				\ mov [ebp], ebx
	$8D tc, $1D tc, t,					\ lea ebx, x (aligned mov ebx, # x)
	$C3 tc, ;							\ ret
: tconstant  ( x "name" -- )  tvalue ;
: tcreate  ( "name" -- )  theader
	$83 tc, $ED tc, $04 tc,				\ sub ebp, # 4
	$89 tc, $5D tc, $00 tc,				\ mov [ebp], ebx
	$BB tc, there 5 + t,				\ mov ebx, # data-addr
	$C3 tc, ;							\ ret
: tvariable  ( "name" -- )  tcreate  0 t, ;
: tuser  ( "name" -- )  theader
	$83 tc, $ED tc, $04 tc,				\ sub ebp, # 4
	$89 tc, $5D tc, $00 tc,				\ mov [ebp], ebx
	$8D tc, $9E tc, tuser-ofs t,		\ lea ebx, user-ofs [esi]
	1 tcells +to tuser-ofs  $C3 tc, ;	\ ret
: tdefer  ( "name" -- )  theader
	$B8 tc, 0 t,						\ mov eax, # xt
	$FF tc, $E0 tc, ;					\ jmp eax
: t>body  ( xt -- tdata-addr )
	dup tc@ $B8 =
	if		1							\ defer
	else	dup 6 + tc@ $BB =
		if		12						\ create
		else	8						\ value/user
		then
	then	+ ;
: t'  ( "name" -- xt )  name  tsearch found? ;
: t`  ( "name" -- hp )  name  tdsearch found? ;
: taddr>  ( "name" -- )  t' t>body ;

( target control structures )
: tcmp0,  ( -- )  $0B tc, $DB tc,		\ or ebx, ebx
	$8B tc, $5D tc, $00 tc,				\ mov ebx, [ebp]
	$8D tc, $6D tc, $04 tc, ;			\ lea ebp, 4 [ebp]
: t>mark  ( -- orig )  there  0 t, ;
: t>resolve  ( orig -- )  there  over tcell+  -  swap t! ;
: t<mark  ( -- dest )  there ;
: t<resolve  ( dest -- )  trel, ;
: tif  ( -- orig )  tcmp0,  $0F tc, $84 tc,  t>mark ;  immediate restrict
: tifz  ( -- orig )  tcmp0,  $0F tc, $85 tc,  t>mark ;  immediate restrict
: tthen  ( orig -- )  t>resolve ;  immediate restrict
: telse  ( orig1 -- orig2 )  $E9 tc,  t>mark  swap t>resolve ;  immediate restrict
: tahead  ( -- orig )  $E9 tc,  t>mark ;  immediate restrict
: tbegin  ( -- dest )  t<mark ;  immediate restrict
: tagain  ( dest -- )  $E9 tc,  t<resolve ;  immediate restrict
: tuntil  ( dest -- )  tcmp0,  $0F tc, $84 tc,  t<resolve ;  immediate restrict
: twhile  ( dest -- orig dest )  tcmp0,  $0F tc, $84 tc,  t>mark  swap ;  immediate restrict
: trepeat  ( orig dest -- )  postpone tagain  postpone tthen ;  immediate restrict
: tdo  ( -- do-sys )  t(do) @ tcompile,  t>mark  t<mark ;  immediate restrict
: t?do  ( -- do-sys )  t(?do) @ tcompile,  t>mark  t<mark ;  immediate restrict
: tloop  ( do-sys -- )
	$FF tc, $04 tc, $24 tc,				\ inc dword [esp]
	$0F tc, $81 tc, trel,				\ jno "start of loop"
	$83 tc, $C4 tc, $0C tc,				\ add esp, # 12
	there swap t! ;  immediate restrict
: t+loop  ( do-sys -- )
	$8B tc, $C3 tc,						\ mov eax, ebx
	$8B tc, $5D tc, $00 tc,				\ mov ebx, [ebp]
	$83 tc, $C5 tc, $04 tc,				\ add ebp, # 4
	$01 tc, $04 tc, $24 tc,				\ add [esp], eax
	$0F tc, $81 tc, trel,				\ jno "start of loop"
	$83 tc, $C4 tc, $0C tc,				\ add esp, # 12
	there swap t! ;  immediate restrict
: tleave  ( do-sys -- )
	$83 tc, $C4 tc, $08 tc,				\ add esp, # 8
	$C3 tc, ;  immediate restrict		\ ret
: tunloop  ( do-sys -- )
	$83 tc, $C4 tc, $0C tc,				\ add esp, # 12
	;  immediate restrict

( more target compiling words )
: t[']  ( "name" -- )  t'  postpone tliteral ;  immediate restrict
: t[char]  ( "name" -- )  char  postpone tliteral ;  immediate restrict
: tabort"  ( "ccc<quote>" -- )  t(abort") @ tcompile,  t," ;  immediate restrict
: t."  ( "ccc<quote>" -- )  t(.") @ tcompile,  t," ;  immediate restrict
: ts"  ( "ccc<quote>" -- )  t(s") @ tcompile,  t," ;  immediate restrict
: tc"  ( "ccc<quote>" -- )  t(c") @ tcompile,  t," ;  immediate restrict
: tt"  ( "ccc<quote>" -- tc-addr )  there  t," ;
: tpostpone  ( "name" -- )  name  tsearch ?dup found?
	0< if  tcompile @ tcompile,  then  tcompile, ;  immediate restrict
: tto  ( "name" -- )  taddr>  state @
	if		$8B tc, $C3 tc,					\ mov eax, ebx
		$8B tc, $5D tc, $00 tc,				\ mov ebx, [ebp]
		$83 tc, $C5 tc, $04 tc,				\ add ebp, # 4
		$A3 tc, t,							\ mov data-addr , eax
	else	t!								\ interpreting, store IMMEDIATEly
	then	;  immediate
: tis  ( "name" -- )  postpone tto ;  immediate
: tuser@  ( "name" -- )  taddr> t@  state @
	if		postpone tliteral
	then	;  immediate
: (  postpone ( ;  immediate			\ redefine into tcomp-wid
: \  postpone \ ;  immediate
: [  postpone [ ;  immediate

( target image saving )
: tsave  ( "name" -- )
	there  s" dp" tsearch  0= -13 and throw  t>body t!
	twid-link  s" wid-link" tsearch  0= -13 and throw  t>body t!
	tuser-ofs  s" user-ofs" tsearch  0= -13 and throw  t>body t!
	name w/o create-file throw
	dup  timage  there tbase -  rot write-file throw
	close-file throw ;

( load target assembler )
include 486asm.fs

( define target's forth vocabulary )
include gdt.f  talign					\ gdt and stuff
talign  there to tlast					\ create the header "forth"
0 t,  0 tc,  t," forth"  talign
$B8 tc, 0 t,  $FF tc, $E0 tc,			\ code: mov eax, # xt; jmp eax
talign  there to twid-link				\ set twid-link for good
there to tforth-wid						\ set tforth-wid
there 12 + t,  0 t,  tlast t,			\ create the wordlist
64 t,  there >timage 64 tcells erase	\ create the hash table
64 tcells tallot
treveal									\ reveal "forth" into hash table

( alias words used by BenOS source code )
' tcells alias cells
' tchars alias chars  immediate
' tcell+ alias cell+
' tchar+ alias char+
' tc@ alias c@
' tc! alias c!
' tw@ alias w@
' tw! alias w!
' t@ alias @
' t! alias !
' t2@ alias 2@
' t2! alias 2!
' tcount alias count
' tfill alias fill
' there alias here
' tallot alias allot
' tc, alias c,
' tw, alias w,
' t, alias ,
' talign alias align
' tliteral alias literal  immediate restrict
' t2literal alias 2literal  immediate restrict
' t: alias :
' texit alias exit  immediate restrict
' t; alias ;  immediate restrict
' tvalue alias value
' tconstant alias constant
' tcreate alias create
' tvariable alias variable
' tuser alias user
' tdefer alias defer
' t>body alias >body
' taddr> alias addr>
' tif alias if  immediate restrict
' tifz alias ifz  immediate restrict
' tthen alias then  immediate restrict
' telse alias else  immediate restrict
' tahead alias ahead  immediate restrict
' tbegin alias begin  immediate restrict
' tagain alias again  immediate restrict
' tuntil alias until  immediate restrict
' twhile alias while  immediate restrict
' trepeat alias repeat  immediate restrict
' tdo alias do  immediate restrict
' t?do alias ?do  immediate restrict
' tloop alias loop  immediate restrict
' t+loop alias +loop  immediate restrict
' tleave alias leave  immediate restrict
' tunloop alias unloop  immediate restrict
' t['] alias [']  immediate restrict
' t[char] alias [char]  immediate restrict
' tabort" alias abort"  immediate restrict
' t." alias ."  immediate restrict
' ts" alias s"  immediate restrict
' tc" alias c"  immediate restrict
' tt" alias t"
' tpostpone alias postpone  immediate restrict
' tto alias to  immediate
' tis alias is  immediate
' tuser@ alias user@  immediate
' timmediate alias immediate
' trestrict alias restrict
' tsave alias save
' t` alias `
' t' alias '

( target compile BenOS! )
tcompiler-on  include kernel.f

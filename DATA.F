\ BenOS v1.0 data structures and variables (c) Benjamin Hoyt 1997

( the following words hide information about the header structure )
0 constant hp.link  ( -- +link )		\ link, ptr to previous header
4 constant hp.type  ( -- +type )		\ type byte denotes type of word
5 constant hp.name  ( -- +name )		\ name of word, counted string

( type constants for hp.type field in header structure )
1 constant type.immediate				\ denotes an immediate word
2 constant type.restrict				\ denotes a compile-only word

: hp>link  ( hp -- addr-link )			\ return address of header's link field
	( hp.link + ) ;						\ 0 + is a no-operation

: hp>type  ( hp -- addr-type )			\ return address of header's type field
	hp.type + ;

: hp>name  ( hp -- addr-name )			\ return address of header's name field
	hp.name + ;

: xt@  ( hp -- xt )						\ return header's execution token
	hp>name count +  aligned ;

: type@  ( hp -- u )					\ fetch header's type u
	hp>type c@ ;

: type!  ( u hp -- )					\ store u as header's type
	hp>type c! ;

( the following words hide information about the wordlist structure )
0 constant wid.hash						\ hash, ptr to wordlist's hash table
4 constant wid.link						\ link, ptr to previous wordlist
8 constant wid.head						\ head, ptr to wid's header or zero

: wid>hash  ( wid -- addr-hash )		\ return address of hash table pointer
	( wid.hash + ) ;					\ 0 + is a no-operation

: wid>link  ( wid -- addr-link )		\ return address of wid's link field
	wid.link + ;

: wid>head  ( wid -- addr-hp )			\ return address of wid's hp field
	wid.head + ;

( define the context stack, ie., search order and related items )
16 constant context-size				\ max # wids on context stack
variable context-stack					\ pointer to context stack
variable context0						\ pointer to bottom of context stack
variable context						\ context stack ptr
variable current						\ compilation wordlist = forth

( define input buffer and parsing items )
255 constant #key-tib					\ terminal input buffer size
variable key-tib						\ always points to keyboard tib
257 constant #word-buf					\ WORD buffer size and pointer
variable word-buf						\ (count + 255 chars + BL on end = 257)
variable >in							\ offset into tib
create src  ( -- a-addr )  0 , 0 ,		\ two-cell input source specifier
create last-parse  0 , 0 ,				\ two-cell last parsed string addr u

( other miscellaneous constants/variables/values )
1024 constant 1k						\ size of a 1k block
64 constant c/l							\ chars/line for block display
variable dp								\ dictionary pointer
variable csp							\ check stack pointer
variable state							\ state is true if compiling
variable handler						\ last exception handler (rstack ptr)
variable messages						\ print "word is redefined" messages?
variable abort"msg						\ message address from abort"
variable latest							\ header pointer of last word defined
variable src-id							\ input source identification
variable user-ofs						\ current offset into user table
variable blk							\ block# being interpreted or zero
variable scr							\ block# of last LISTed or EDITed
variable base							\ number conversion base
0 value wid-link						\ pointer to last defined wordlist
0 value tick#							\ # of ticks elapsed since OS start
64 value #threads						\ # chains in new wordlists

: last  ( -- a-addr )					\ return contents of latest
	latest @ ;

: source-id  ( -- n )					\ return input source identification
	src-id @ ;

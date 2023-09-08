\ BenOS v1.0 Forth startup code (c) Benjamin Hoyt 1997

: version  ( -- )						\ display BenOS hello message
	cr ." BenOS version 1.0 (c) Benjamin Hoyt 1997 " ;

: init-os  ( -- )						\ initialise everything in order
	init-video  init-memory  init-ints
	init-context  init-tib  init-disk
	init-lpt  init-quit ;

: main  ( -- )							\ initialise BenOS and cold start
	handler off  messages on  decimal	\ setup variables
	init-os								\ setup OS features
	1 load								\ load other essentials
	version								\ say hi
	cr ." Type HELP for a brief help page on BenOS"  cr
	quit ;								\ then QUIT (ie., interpret)

' main is init-forth					\ setup up init-forth defer

\ ***
variable seed  ( -- a-addr )			\ random number seed
timer-count seed !
: srand  seed ! ;
: rand  ( -- random-unsigned-number )  seed @  $10450405 *  1+  dup srand ;
: choose  ( u -- random0..u-1 )  rand  um* nip ;

: tt  ( -- )							\ task to display tick# at 70,0
	begin	at-xy?  base @
			70 0 at-xy  decimal  tick# .
			base !  at-xy  10 ms
	again	;

: help  ( -- )							\ view help blocks
	page  254 block  1k type			\ clear screen and display
	255 block  [ 1104 1k - ] literal  type
	quit ;								\ so no "ok" prompt

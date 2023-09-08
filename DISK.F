\ BenOS v1.0 BIOS disk I/O (c) Benjamin Hoyt 1998

$80000 constant dbuf					\ rmode buffer, must be in first 1mb
variable drive							\ current disk drive #
variable #sects							\ # sectors/track
variable #heads							\ # sides or heads

: ?disk  ( n -- )						\ abort with msg if n is nonzero
	abort" Disk error!" ;

: disk  ( -- )							\ call BIOS disk interrupt
	drive @ >dx c!						\ set dl = drive
	$13 rmode-int						\ interrupt 13h are disk routines
	1 and ?disk  drop ;					\ if carry flag set error!

: init-drive  ( drive -- )				\ setup parameters for a given drive
	drive !  0 >ax w!  disk				\ initialise disk
	$800 >ax w!  disk					\ get disk status
	>cx w@ $3F and  #sects !			\ store # sectors/track
	>dx 1+ c@  1+ #heads ! ;			\ store # heads (dh is #heads-1)

: >s  ( sector# -- )					\ convert to head/sec/track in dh cl ch
	dup #sects @ mod  1+  swap			\ low 6 bits of cl = 1-based sector #
	dup #sects @ /  #heads @ mod		\ calculate head number
	>dx 1+ c!							\ dh = head#
	#sects @ #heads @ *  /				\ calculate track/cylinder
	dup 2 rshift $C0 and				\ figure out cx: ch = low 8 bits of cyl
	swap 8 lshift  or  or  >cx w! ;		\ cl = bits 0-5 sector, 6-7 high cyl

: >dbuf  ( -- )							\ store dbuf seg:ofs in >es and >bx
	dbuf  dup $F and >bx w!				\ bx = low 4 bits = offset
	4 rshift >es w! ;					\ es = next 16 bits = segment

: sectors  ( #sectors -- #bytes )		\ multiply by sector size
	9 lshift ;							\ fast *512

\ read #sects sectors (max 128) starting from start-sector on drive to addr
: sread  ( addr #sects start-sect -- )
	>s  dup $200 or >ax w!  >dbuf disk	\ read to dbuf
	dbuf -rot sectors move ;			\ then move from dbuf to addr

\ write #sects sectors (max 128) from addr starting at start-sector on drive
: swrite  ( addr #sects start-sect -- )
	>s  dup $300 or >ax w!
	dbuf swap sectors move				\ move from addr to dbuf
	>dbuf disk ;						\ then write from dbuf

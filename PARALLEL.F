\ BenOS v1.0 parallel port driver (c) Benjamin Hoyt 1998

8192 constant /lpt						\ size of send buffer
variable lpt							\ printer send queue
variable lpt-in							\ offset to "next in" char
variable lpt-out						\ offset to "next out" char
variable #lpt							\ # of chars in buffer
variable pport							\ printer data port address

: pdata  ( -- port )					\ return data port address
	pport @ ;

: pstat  ( -- port )					\ return status port address
	pdata 1+ ;

: pctrl  ( -- port )					\ return control port address
	pdata 2 + ;

: +lpt  ( offset -- addr )				\ give address in queue
	lpt @ + ;

: lpt-empty  ( -- )						\ empty send queue
	lpt-in off  lpt-out off  #lpt off ;

: lpt-queue  ( lpt-var -- )				\ move lpt-in or lpt-out along
	dup @ 1+							\ increment the offset
	dup /lpt <> and  swap ! ;			\ wrap if necessary

: >lpt  ( char -- )						\ put char in lpt queue
	lpt-in @ +lpt c!					\ store char in queue
	lpt-in lpt-queue					\ move lpt-in along
	#lpt incr ;							\ one more char in buf

: lpt>  ( -- char )						\ get char from lpt queue
	lpt-out @ +lpt c@					\ get char
	lpt-out lpt-queue					\ move lpt-out along
	#lpt decr ;							\ one less char in buf

: pstatus  ( -- status-byte )			\ return printer status byte
	pstat pc@ ;

: pbusy?  ( -- flag )					\ check printer busy status
	pstatus $80 and ;					\ 0 = busy?, 1 = ok to send

: psend  ( char -- )					\ send one character to printer port
	pdata pc!							\ send the char
	$0D pctrl pc!						\ "data to printer" bit high,
	$0C pctrl pc! ;						\ then low

: lpt-task  ( -- )						\ background "send data" task
	begin	#lpt @						\ loop while there are chars in buf
	while	pbusy?
			if		lpt> psend			\ not busy, send one char
			else	2 ms				\ otherwise wait for it to be un-busy
			then
	repeat	;

: pinit  ( base-port -- )				\ initialise printer port
	pport !								\ store printer base port
	$08 pctrl pc!  2 ms					\ bit 2 clear (init printer)
	$0C pctrl pc! ;						\ no IRQs, no auto-LF, init set

: init-lpt  ( -- )
	/lpt mallocate lpt !  lpt-empty		\ allocate/init send buffer
	$378 pinit ;						\ init hardware for LPT1

: lpt-emit  ( char -- ior )				\ send one char to printer, return ior
	#lpt @ /lpt =						\ buffer full?
	if		drop  -275 exit
	then	#lpt @						\ if no chars in buf, start bkg task
	ifz		['] lpt-task 20 20 start-task drop
	then	>lpt  0 ;					\ send char to buffer

( send string c-addr u1 to the printer, u2 is # of chars actually sent )
: lpt-write  ( c-addr u1 -- u2 ior )
	tuck								\ save u1
	begin	dup							\ finished string?
	while	over c@ lpt-emit ?dup		\ send char at a time
			if		>r  nip -  r> exit	\ not finished sending, get u2 and exit
			then	1 /string			\ move to next char
	repeat	2drop  0 ;

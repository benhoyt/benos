\ BenOS v1.0 screen and block I/O (c) Benjamin Hoyt 1998

256 constant bstart						\ starting block# for block data
256 bstart + constant blimit			\ limit of data blocks (max block# + 1)
variable block#							\ current block# in buffer
0 value blox							\ address of block buffer(s)
variable ?update						\ block been UPDATEd?

: >b  ( u -- block# )					\ give block# from user block # u
	bstart +  dup						\ get it to correct block#
	bstart blimit within  0= ?disk ;	\ make sure block# is within bounds

: bread  ( addr block# -- )				\ read 1k block# from disk to addr
	>b 2*  2 swap  sread ;				\ two 512 byte sectors = 1k block

: bwrite  ( addr block# -- )			\ write 1k block# at addr to disk
	>b 2*  2 swap  swrite ;

: save-buffers  ( -- )					\ save UPDATEd buffers to disk
	?update @
	if		blox  block# @ bwrite		\ write buffer to disk if modified
			?update off					\ mark buffer as unUPDATEd
	then	;

: buffer  ( u -- a-addr )				\ a-addr is address of block u
	save-buffers  block# !  blox ;

: block  ( u -- a-addr )				\ load block u in and return address
	dup  block# @ =
	if		drop  blox					\ block already loaded
	else	buffer drop  blox			\ not loaded, save/empty buffer
			dup  block# @ bread			\ and read block in
	then	;

: empty-buffers  ( -- )					\ mark buffers unUPDATEd w/out saving
	block# on  ?update off ;			\ -1 is invalid block#

: flush  ( -- )							\ save buffers and mark unUPDATEd
	save-buffers empty-buffers ;

: update  ( -- )						\ mark current buffer as modified
	?update on ;

: list  ( u -- )						\ list block u
	dup scr !  block  16 0
	do		cr  i 2 .r  space  c/l 2dup type  +
	loop	drop ;

: init-disk  ( -- )						\ initialise disk system for Forth
	0 init-drive						\ init boot drive A:
	1k mallocate to blox				\ allocate our block buffer
	empty-buffers ;						\ mark as unused

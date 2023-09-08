\ BenOS v1.0 search order and word find (c) Benjamin Hoyt 1997

( search for name c-addr u in hash chain addressed by chainptr, return hp )
code search-chain  ( c-addr u chainptr -- 0 | hp 1 | hp -1 )
	mov		ebx, [ebx]					\ ebx = chain
	or		ebx, ebx
	jz		short 5 @@					\ null = no word in chain, so exit
	xor		edx, edx
1 @@:
	mov		cl, hp.name [ebx]			\ get length of header name
	cmp		cl, [ebp]					\ does cl = u?
	jne		short 4 @@					\ if lengths not equal move on to next
	mov		eax, 4 [ebp]				\ eax = c-addr
	lea		edi, hp.name 1+ [ebx]		\ edi -> header name
2 @@:
	mov		dl, [eax]					\ get next char from c-addr
	inc		eax
	mov		ch, addr> uctable [edx]		\ convert to upper case
	mov		dl, [edi]
	inc		edi
	cmp		ch, addr> uctable [edx]		\ upper case compare
	jne		short 4 @@					\ not equal so go to next link
	dec		cl
	jnz		short 2 @@					\ next char
	add		ebp, # 4
	mov		[ebp], ebx					\ return addr of header
	test	byte hp.type [ebx], # type.immediate
	jz		short 3 @@
	mov		ebx, # 1					\ immediate, return 1
	next
3 @@:
	mov		ebx, # -1					\ non-immediate, return -1
	next
4 @@:
	mov		ebx, hp.link [ebx]			\ ebx -> previous link
	or		ebx, ebx					\ was this the last link?
	jnz		short 1 @@					\ no, so loop
5 @@:
	add		ebp, # 8					\ nothing found so return false
	next								\ (ebx already = 0)
end-code

( return the hash value of the string c-addr u )
code hash  ( c-addr u -- hash-byte )
	mov		edx, [ebp]					\ edx = c-addr
	add		ebp, # 4
	or		ebx, ebx					\ zero length string?
	jz		short 3 @@
	mov		edx, [edx]					\ edx = first four chars
	mov		cl, dl						\ cl = first char
	cmp		bl, # 2
	jb		short 2 @@					\ name only one char long?
	add		cl, cl						\ cl = first char*3
	add		cl, dl
	shr		edx, # 8
	add		cl, dl						\ add second char
	cmp		bl, # 3
	jb		short 2 @@					\ name only two chars long?
	add		cl, cl						\ multiply by three
	add		cl, dl
	add		cl, dh						\ add third char
2 @@:
	add		cl, cl						\ multiply by two
	add		bl, cl						\ and add length
3 @@:
	next
end-code

( convert hash value to chain pointer from wid's hash table )
code hash>chainptr  ( wid hash-byte -- chainptr )
	mov		edx, [ebp]					\ edx -> vocabulary
	add		ebp, # 4
	mov		edx, wid.hash [edx]			\ edx -> hash table
	mov		ecx, [edx]					\ ecx = #threads in vocabulary
	dec		ecx
	and		ebx, ecx					\ and with #threads-1 to get hash entry
	lea		ebx, 4 [edx] [ebx*4]		\ eax -> chain from hash table
	next
end-code

( search wordlist wid for name c-addr u, return hp )
: search-wid  ( c-addr u wid -- 0 | hp 1 | hp -1 )
	>r  2dup hash						\ get hash-byte for name c-addr u
	r> swap  hash>chainptr				\ get chainptr from wid and hash-byte
	search-chain ;						\ then search the chain

( convert a header pointer to an execution token )
: search>xt  ( 0 | hp 1 | hp -1 -- 0 | xt 1 | xt -1 )
	dup
	if		swap xt@ swap				\ only convert if 1 or -1 on stack
	then	;

( search wordlist wid for name c-addr u, return xt )
: search-wordlist  ( c-addr u wid -- 0 | xt 1 | xt -1 )
	search-wid search>xt ;

( search search order for name c-addr u, return hp )
: search-order  ( c-addr u -- 0 | hp 1 | hp -1 )
	context @							\ start at top of context stack
	begin	dup context0 @ u<			\ bottom of context stack yet?
	while	>r  2dup  r@ @				\ get a wid from context stack
			search-wid ?dup				\ search this wordlist
			if		r> drop				\ we found it, leave hp and 1 or -1
					2swap 2drop  exit
			then	r> cell+			\ else move on to next wordlist
	repeat	drop 2drop  0 ;				\ not found, return 0

( search search order for name c-addr u, return xt )
: search-wordlists  ( c-addr u -- 0 | xt 1 | xt -1 )
	search-order search>xt ;

: set-current  ( wid -- )				\ set compilation wordlist to wid
	current ! ;

: get-current  ( -- wid )				\ get compilation wordlist wid
	current @ ;

: reveal  ( -- )						\ reveal last definition into CURRENT
	last ?dup							\ if last=0 it's :noname - don't reveal
	if		hp>name count  hash			\ get hash value of last defined word
			get-current swap			\ current wordlist
			hash>chainptr				\ get chain pointer in it's hash table
			dup @  last hp>link !		\ link last definition into chain
			last swap !					\ update chainhead in hash table
	then	;

: set-type  ( u -- )					\ set type of last header defined to u
	last type! ;

: or-type  ( u -- )						\ OR u with type of last header
	last  type@ or  set-type ;

tforth-wid constant forth-wordlist		\ wid of main forth wordlist

: _forth  ( -- )						\ put forth wordlist on top of context
	forth-wordlist context @  ! ;

' _forth is forth						\ set original "forth" to this

: init-context  ( -- )					\ initialse context stack
	[ context-size cells ] literal  dup mallocate
	dup context-stack !  +  dup context0 !  cell- context !
	forth  forth-wordlist set-current ;

: definitions  ( -- )					\ set compilation wordlist = context
	context @ @ set-current ;

: get-order  ( -- widn .. wid1 n )		\ get search order wid1 through widn
	0 context0 @
	begin	cell-  dup @  -rot			\ get one wid
			1 under+  dup context @ u<=	\ increment count
	until	drop ;

: set-order  ( widn .. wid1 n -- )		\ set search order to widn thru wid1
	dup context-size >  -49 and throw	\ search order overflow
	dup -1 =
	if		drop  forth-wordlist 1		\ if n = -1 then put only forth
	then	context0 @ over  cells -	\ make space on context
	dup context !  swap 0
	?do		tuck !  cell+
	loop	drop ;

: also  ( -- )							\ duplicate top wid on search order
	get-order  over swap 1+  set-order ;

: only  ( -- )							\ put only forth in search order
	-1 set-order ;

: previous  ( -- )						\ drop top wid from search order
	get-order  nip 1-  set-order ;

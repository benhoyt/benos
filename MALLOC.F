\ BenOS v1.0 memory allocation (c) Benjamin Hoyt 1997

$100000 constant 1mb					\ 1mb = 1024k = 1,048,576 bytes
1mb constant mlow						\ bottom of allocation space
0 value mhigh							\ top of allocation space
mlow value free-chain					\ pointer to list of free malloc blocks

: memory  ( -- n )						\ return # bytes memory on system
	$686E6562  $1FFFFC					\ start at 2mb (assume 1mb)
	begin	0 over !					\ set initially to zero
			2dup !						\ store "benh" test dword
			2dup @ =					\ loop until read-back doesn't match
	while	1mb +						\ try next meg
 	repeat	nip  $FFF00000 and ;		\ convert to # bytes (1mb increments)

: init-memory  ( -- )					\ initialise memory allocation
	free-chain off						\ store NULL link (one big block)
	memory  dup to mhigh				\ set top of allocation space
	mlow -  free-chain cell+ ! ;		\ store size of free block

( allocate u bytes of memory from the free-chain, return block addr and ior )
code allocate  ( u -- a-addr ior )
	sub		ebp, # 4					\ make room on stack
	or		ebx, ebx
	jz		short 3 @@					\ don't allocate zero bytes
	cmp		ebx, # $FFFFFFF4
	ja		short 3 @@					\ don't allocate more than this
	add		ebx, # 3 8 +				\ get aligned amount with header size
	and		ebx, # $FFFFFFFC
	mov		ecx, addr> free-chain		\ ecx = ptr to free chain
	mov		edx, # addr> free-chain		\ first find big enough free block
1 @@:
	jecxz	short 3 @@					\ end of free chain?
	cmp		ebx, 4 [ecx]				\ this block big enough?
	jbe		short 2 @@
	mov		edx, ecx					\ save ptr to this block
	mov		ecx, [ecx]					\ get ptr to next block
	jmp		short 1 @@
3 @@:
	mov		ebx, # -256					\ error, no free block big enough
	next
2 @@:
	add		ebx, # 12					\ cut block if big enough
	cmp		ebx, 4 [ecx]
	jbe		short 4 @@					\ yep, it's big enough to cut
	mov		edi, [ecx]					\ don't cut, get ptr to next
	mov		[edx], edi					\ make prev or free-chain point to next
	mov		dword [ecx], # $13579BDF	\ store magic used block number
	add		ecx, # 8					\ ecx -> past header
	mov		[ebp], ecx					\ store a-addr on stack
	xor		ebx, ebx					\ ior = zero, success
	next
4 @@:
	mov		edi, ecx					\ cut this block
	add		edi, 4 [ecx]
	sub		ebx, # 12
	sub		edi, ebx					\ edi -> new block
	mov		4 [edi], ebx				\ set size of new block
	mov		dword [edi], # $13579BDF	\ store new block's magic used number
	sub		4 [ecx], ebx				\ new size for free block
	add		edi, # 8
	mov		[ebp], edi					\ store a-addr on stack
	xor		ebx, ebx					\ ior = zero, success
	next
end-code

( free block with header address a-addr, does no error checking )
code bfree  ( a-addr -- )
	mov		eax, ebx					\ eax = a-addr
	mov		ebx, [ebp]
	add		ebp, # 4
	mov		edi, addr> free-chain
	or		edi, edi					\ anything in free chain?
	jz		short 1 @@					\ nope, make this block the free chain
	cmp		eax, edi					\ block below free chain?
	jb		short 2 @@
	mov		edi, # addr> free-chain
4 @@:
	mov		edx, edi					\ previous entry in edx
	mov		edi, [edi]					\ edi -> next entry
	or		edi, edi					\ past last entry in free chain?
	jz		short 3 @@
	cmp		eax, edi					\ below this entry?
	ja		short 4 @@					\ nope, so loop until it is
	mov		ecx, 4 [eax]				\ ecx = eax + eax block size
	add		ecx, eax
	cmp		ecx, edi					\ adjacent to free chain block above?
	jne		short 6 @@					\ nope, link to block above
	mov		ecx, 4 [edi]				\ yep, join the two blocks
	add		4 [eax], ecx
	mov		ecx, [edi]					\ get link of above block
	mov		[eax], ecx					\ make this block link to it
	jmp		short 7 @@
6 @@:
	mov		[eax], edi					\ link to above block
7 @@:
	mov		edi, edx					\ back to previous entry
	mov		ecx, 4 [edi]				\ ecx = edi + edi block size
	add		ecx, edi
	cmp		ecx, eax					\ adjacent to free chain block below?
	jne		short 8 @@					\ nope, link previous block to this
	mov		ecx, 4 [eax]				\ yep, join the two blocks
	add		4 [edi], ecx				\ add two sizes together
	mov		ecx, [eax]
	mov		[edi], ecx					\ set this big block's link
	next
8 @@:
	mov		[edi], eax					\ not adjacent below
	next
1 @@:
	mov		[eax], edi					\ set link to edi
	mov		addr> free-chain , eax		\ free-chain -> current block
	next
2 @@:
	mov		ecx, 4 [eax]				\ ecx = eax + eax block size
	add		ecx, eax
	cmp		ecx, edi					\ adjacent to free chain block above?
	jne		short 1 @@					\ no, make this 1st block in free chain
	mov		ecx, [edi]					\ yep, join the two blocks
	mov		[eax], ecx
	mov		ecx, 4 [edi]				\ add next block's size
	add		4 [eax], ecx
	mov		addr> free-chain , eax		\ free-chain -> current block
	next
3 @@:
	mov		edi, edx					\ back to previous entry
	mov		ecx, 4 [edi]				\ ecx = edi + edi block size
	add		ecx, edi
	cmp		ecx, eax					\ adjacent to free-chain block below?
	jne		short 5 @@					\ no, make this last block in freechain
	mov		ecx, 4 [eax]				\ yep, join the two blocks
	add		4 [edi], ecx
	next
5 @@:
	mov		dword [eax], # 0			\ make this block last in free-chain
	mov		[edi], eax					\ previous blocks points to this one
	next
end-code

( return true if a-addr1 is a corrupted block, a-addr2 is block header addr )
: bad-block?  ( a-addr1 -- a-addr2 flag )
	[ 2 cells ] literal  -				\ a-addr2 = a-addr1 - 8
	dup  mlow mhigh within				\ addr within the allocation space?
	ifz		true  exit					\ nope, bad address!
	then	dup @  $13579BDF <> ;		\ and magic number still $13579BDF?

( free memory block a-addr back into free-chain, ior is zero if success )
: free  ( a-addr -- ior )
	bad-block?							\ have they mangled the block?
	if		drop  -257  exit			\ yep, return ior <> 0
	then	bfree  0 ;					\ else free and ior = 0

: mallocate  ( u -- a-addr )			\ allocate u bytes, THROW ior
	allocate throw ;

: mfree  ( a-addr -- )					\ free block a-addr, THROW ior
	free throw ;

: msize  ( a-addr -- u )				\ return size of allocated block a-addr
	cell+ @  [ 2 cells ] literal  - ;

: mem-avail  ( -- u )					\ return total free memory left
	0  free-chain
	begin	dup							\ go thru free blocks adding up sizes
	while	dup  msize under+  @		\ add to # bytes and fetch link to prev
	repeat	drop ;

: max-avail  ( -- u )					\ return size of largest free block
	0  free-chain
	begin	dup							\ go thru free blox looking for biggest
	while	swap  over msize  umax		\ keep size of larger block on stack
			swap  @
	repeat	drop ;

: total-mem  ( -- u )					\ return total bytes of memory on PC
	mhigh ;

: alloc-mem  ( -- u )					\ return total bytes allocateABLE mem
	mhigh mlow - ;

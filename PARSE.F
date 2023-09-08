\ BenOS v1.0 input buffer parsing (c) Benjamin Hoyt 1997

code skip  ( char "chars" -- )			\ moves >in past any chars in input buf
	mov		eax, ebx					\ eax = char
	mov		ebx, [ebp]
	add		ebp, # 4
	mov		edi, src cell+
	add		edi, >in					\ edi -> parse area
	mov		ecx, src
	sub		ecx, >in					\ ecx = # chars left in tib
	jz		short 1 @@					\ no chars left in tib?
	cmp		al, # $20					\ char space = skip whitespace?
	je		short 2 @@					\ no, just skip a normal char
	mov		ebx, ecx
	repe	scasb						\ scan string while chars equal
	je		short 3 @@					\ did we only skip?
	sub		ebx, ecx					\ calculate # chars skipped
	dec		ebx
3 @@:
	add		>in , ebx					\ adjust >in by # chars skipped
1 @@:
	next
2 @@:
	mov		al, [edi]					\ get a char and increment edi
	inc		edi
	test	byte chtypes [eax], # chwhite
	jz		short 1 @@					\ nope, it's not whitespace
	inc		dword >in					\ yep, whitespace, increment >in
	dec		ecx
	jnz		short 2 @@					\ loop till end of string
	next
end-code

( parse ccc delimited by the char, return the address and count of the parsed
  string within the input buffer )
code parser  ( char "ccc<char>" -- c-addr u )
	mov		eax, ebx					\ eax = char
	mov		edi, src cell+
	add		edi, >in					\ edi -> parse area
	sub		ebp, # 4
	mov		[ebp], edi					\ store c-addr on stack
	mov		ecx, src
	sub		ecx, >in					\ ecx = # chars left in tib
	mov		ebx, ecx
	jz		short 1 @@					\ tib empty?
	cmp		al, # $20					\ parse till whitespace?
	je		short 2 @@
	repne	scasb						\ scan string while chars not equal
	je		short 3 @@
	sub		ebx, ecx
	add		>in , ebx					\ adjust >in by # chars
1 @@:
	next
3 @@:
	sub		ebx, ecx
	add		>in , ebx					\ adjust >in by # chars + delim
	dec		ebx							\ return u
	next
2 @@:
	mov		al, [edi]					\ get a char and increment edi
	inc		edi
	test	byte chtypes [eax], # chwhite
	jnz		short 4 @@
	dec		ecx
	jnz		short 2 @@					\ loop till end of string
	sub		ebx, ecx
	add		>in , ebx					\ adjust >in by # chars
	next
4 @@:
	sub		ebx, ecx					\ ebx = # chars parsed
	lea		eax, 1 [ebx]				\ adjust >in by # chars parsed + delim
	add		>in , eax
	next
end-code

( parse ccc delimited by the char, return the address and count of the parsed
  string within input buffer, and store c-addr u in last-parse )
: parse  ( char "ccc<char>" -- c-addr u )
	parser  2dup last-parse 2! ;

: parse-word  ( "name" -- c-addr u )	\ parse name c-addr u
	bl skip  bl parse ;					\ skip initial whitespace and parse

( skip chars and return parsed counted string c-addr delimited by char )
: word  ( char "<chars>ccc<char>" -- c-addr )
	dup skip parse  255 umax			\ skip chars and parse, max 255 chars
	word-buf @ place					\ place counted string in WORD buffer
	word-buf @  bl  over count +  c! ;	\ put BL on end of string (obselete)

: name?  ( u -- u | )					\ throw if string length u = 0
	dup 0=  -16 and throw ;				\ tried to use 0 length string as name

: name  ( "name" -- c-addr u )			\ parse name and check zero length
	parse-word name? ;

: init-tib  ( -- )						\ initialise tib and token-buf
	#key-tib mallocate  key-tib !
	#word-buf mallocate  word-buf ! ;

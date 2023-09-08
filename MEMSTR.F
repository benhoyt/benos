\ BenOS v1.0 memory and string (c) Benjamin Hoyt 1997

( Byte-indexed table that returns a byte whose bits describe the given
  character. The bit values returned are given in the docs. )
create chtypes  ( -- c-addr )  hex
	61 c, 60 c, 60 c, 60 c, 60 c, 60 c, 60 c, E0 c,
	E0 c, E1 c, E1 c, E1 c, E1 c, E1 c, 60 c, 60 c,
	60 c, 60 c, 60 c, 60 c, 60 c, 60 c, 60 c, 60 c,
	60 c, 60 c, 60 c, 60 c, 60 c, 60 c, 60 c, 60 c,
	41 c, 40 c, 40 c, 40 c, 40 c, 40 c, 40 c, 40 c,
	40 c, 40 c, 40 c, 40 c, 40 c, 40 c, 40 c, 40 c,
	42 c, 42 c, 42 c, 42 c, 42 c, 42 c, 42 c, 42 c,
	42 c, 42 c, 40 c, 40 c, 40 c, 40 c, 40 c, 40 c,
	40 c, 4C c, 4C c, 4C c, 4C c, 4C c, 4C c, 48 c,
	48 c, 48 c, 48 c, 48 c, 48 c, 48 c, 48 c, 48 c,
	48 c, 48 c, 48 c, 48 c, 48 c, 48 c, 48 c, 48 c,
	48 c, 48 c, 48 c, 40 c, 40 c, 40 c, 40 c, 40 c,
	40 c, 54 c, 54 c, 54 c, 54 c, 54 c, 54 c, 50 c,
	50 c, 50 c, 50 c, 50 c, 50 c, 50 c, 50 c, 50 c,
	50 c, 50 c, 50 c, 50 c, 50 c, 50 c, 50 c, 50 c,
	50 c, 50 c, 50 c, 40 c, 40 c, 40 c, 40 c, 60 c,
	here  80 allot  80 0 fill			\ all high ASCII chars are zeroes

01 constant chwhite  ( -- char )		\ character type constants for chtypes
02 constant chdigit  ( -- char )
04 constant chhex  ( -- char )
08 constant chupper  ( -- char )
10 constant chlower  ( -- char )
20 constant chctrl  ( -- char )
40 constant chascii  ( -- char )
80 constant chvctrl  ( -- char )

( Byte-indexed table that returns the uppercase of any character given. If the
  character is not a lowercase ASCII character it is left alone. )
create uctable  ( -- c-addr )
	00 c, 01 c, 02 c, 03 c, 04 c, 05 c, 06 c, 07 c,
	08 c, 09 c, 0A c, 0B c, 0C c, 0D c, 0E c, 0F c,
	10 c, 11 c, 12 c, 13 c, 14 c, 15 c, 16 c, 17 c,
	18 c, 19 c, 1A c, 1B c, 1C c, 1D c, 1E c, 1F c,
	bl c, '! c, '" c, '# c, '$ c, '% c, '& c, '' c,
	'( c, ') c, '* c, '+ c, ', c, '- c, '. c, '/ c,
	'0 c, '1 c, '2 c, '3 c, '4 c, '5 c, '6 c, '7 c,
	'8 c, '9 c, ': c, '; c, '< c, '= c, '> c, '? c,
	'@ c, 'A c, 'B c, 'C c, 'D c, 'E c, 'F c, 'G c,
	'H c, 'I c, 'J c, 'K c, 'L c, 'M c, 'N c, 'O c,
	'P c, 'Q c, 'R c, 'S c, 'T c, 'U c, 'V c, 'W c,
	'X c, 'Y c, 'Z c, '[ c, '\ c, '] c, '^ c, '_ c,
	'` c, 'A c, 'B c, 'C c, 'D c, 'E c, 'F c, 'G c,
	'H c, 'I c, 'J c, 'K c, 'L c, 'M c, 'N c, 'O c,
	'P c, 'Q c, 'R c, 'S c, 'T c, 'U c, 'V c, 'W c,
	'X c, 'Y c, 'Z c, '{ c, '| c, '} c, '~ c, 7F c,
	80 c, 81 c, 82 c, 83 c, 84 c, 85 c, 86 c, 87 c,
	88 c, 89 c, 8A c, 8B c, 8C c, 8D c, 8E c, 8F c,
	90 c, 91 c, 92 c, 93 c, 94 c, 95 c, 96 c, 97 c,
	98 c, 99 c, 9A c, 9B c, 9C c, 9D c, 9E c, 9F c,
	A0 c, A1 c, A2 c, A3 c, A4 c, A5 c, A6 c, A7 c,
	A8 c, A9 c, AA c, AB c, AC c, AD c, AE c, AF c,
	B0 c, B1 c, B2 c, B3 c, B4 c, B5 c, B6 c, B7 c,
	B8 c, B9 c, BA c, BB c, BC c, BD c, BE c, BF c,
	C0 c, C1 c, C2 c, C3 c, C4 c, C5 c, C6 c, C7 c,
	C8 c, C9 c, CA c, CB c, CC c, CD c, CE c, CF c,
	D0 c, D1 c, D2 c, D3 c, D4 c, D5 c, D6 c, D7 c,
	D8 c, D9 c, DA c, DB c, DC c, DD c, DE c, DF c,
	E0 c, E1 c, E2 c, E3 c, E4 c, E5 c, E6 c, E7 c,
	E8 c, E9 c, EA c, EB c, EC c, ED c, EE c, EF c,
	F0 c, F1 c, F2 c, F3 c, F4 c, F5 c, F6 c, F7 c,
	F8 c, F9 c, FA c, FB c, FC c, FD c, FE c, FF c,
	decimal

code >upper  ( char1 -- char2 )			\ convert char1 to uppercase
	mov		bl, addr> uctable [ebx]		\ just use char as index into uctable
	next
end-code

code >lower  ( char1 -- char2 )			\ convert char1 to lowercase
	test	byte addr> chtypes [ebx], # chupper
	jz		short 1 @@
	add		bl, # 'a 'A -				\ if upper change to lower
1 @@:
	next
end-code

code count  ( c-addr1 -- c-addr2 u )	\ convert counted string to char string
	sub		ebp, # 4
	inc		ebx
	mov		[ebp], ebx
	mov		bl, -1 [ebx]
	and		ebx, # $FF
	next
end-code

( move char string c-addr1 u1 along by n chars )
code /string  ( c-addr1 u1 n -- c-addr2 u2 )
	add		4 [ebp], ebx
	mov		eax, [ebp]
	sub		eax, ebx
	mov		ebx, eax
	add		ebp, # 4
	next
end-code

( remove trailing white space from string c-addr u1 giving string c-addr u2 )
code -trailing  ( c-addr u1 -- c-addr u2 )
	mov		ecx, ebx
	jecxz	short 1 @@
	mov		edi, [ebp]
	lea		edi, -1 [edi] [ecx]
	xor		eax, eax
2 @@:
	mov		al, [edi]
	test	byte addr> chtypes [eax], # chwhite
	jz		short 1 @@
	dec		edi
	loop	2 @@
1 @@:
	mov		ebx, ecx
	next
end-code

( compare string c-addr1 u1 to string c-addr2 u2 with case sensitivity, return
  0 if strings are equal, -1 if string1 < string2, or 1 if string1 > string2 )
code compare  ( c-addr1 u1 c-addr2 u2 -- -1 | 0 | 1 )
	push	esi
	mov		esi, 8 [ebp]				\ esi = c-addr1, edi = c-addr2
	mov		edi, [ebp]
	mov		ecx, 4 [ebp]				\ ecx = u1
	add		ebp, # 12					\ adjust stack pointer
	xor		eax, eax					\ default = 0 (strings equal)
	cmp		ecx, ebx					\ compare lengths
	je		short 2 @@					\ lengths equal, leave default = 0
	ja		short 1 @@
	mov		eax, # -1		 	 		\ if len1 < len2 default = -1
	jmp		short 2 @@
1 @@:
	mov		eax, # 1					\ if len1 > len2 default = 1
	mov		ecx, ebx					\ and use shorter length in compare
2 @@:
	\ note: flags must be same as above CMP here else null strings don't work
	repe	cmpsb						\ compare strings to length of shorter
	je		short 4 @@					\ equal to shorter, return default
	jns		short 3 @@					\ string1 > string2, return 1
	mov		ebx, # -1					\ -1 means string1 < string2
	pop		esi
	next
3 @@:
	mov		ebx, # 1					\ 1 means string1 > string2
	pop		esi
	next
4 @@:
	mov		ebx, eax					\ return default (currently in eax)
	pop		esi
	next
end-code

( compare string c-addr1 u1 to string c-addr2 u2 without case sensitivity, give
  0 if strings are equal, -1 if string1 < string2, or 1 if string1 > string2 )
code icompare  ( c-addr1 u1 c-addr2 u2 -- -1 | 0 | 1 )
	push	esi
	mov		esi, 8 [ebp]				\ esi = c-addr, edi = c-addr2
	mov		edi, [ebp]
	mov		ecx, 4 [ebp]				\ ecx = u1
	mov		edx, ebx					\ edx = u2
	add		ebp, # 12					\ adjust stack here and now
	xor		ebx, ebx					\ default = 0 (length equal) for now
	cmp		ecx, edx					\ compare lengths
	je		short 2 @@					\ lengths equal, leave default = 0
	ja		short 1 @@
	dec		ebx							\ if len1 < len2 default = -1
	jmp		short 2 @@
1 @@:
	inc		ebx							\ if len1 > len2 default = 1
	mov		ecx, edx					\ and use shorter length in compare
2 @@:
	jecxz	3 @@						\ if u1 or u2 = 0 return default now
	xor		eax, eax					\ eax and edx = 0 for zero extend
	xor		edx, edx
6 @@:
	mov		al, [esi]					\ eax = char from c-addr1
	inc		esi
	mov		al, addr> uctable [eax]		\ case INsensitive, convert to UPPER
	mov		dl, [edi]					\ edx = char from c-addr2
	inc		edi
	cmp		al, addr> uctable [edx]		\ compare the two chars
	ja		short 4 @@					\ char1 > char2?
	jb		short 5 @@					\ char1 < char2?
	dec		ecx							\ chars equal, loop to do next char
	jnz		short 6 @@
3 @@:
	pop		esi							\ equal to length of shorter,
	next								\ leave default on stack
5 @@:
	mov		ebx, # -1					\ -1 means string1 < string2
	pop		esi
	next
4 @@:
	mov		ebx, # 1					\ 1 means string1 > string2
	pop		esi
	next
end-code

( case sensitive search of str c-addr1 u1 for substr c-addr2 u2, if true match
  found at c-addr3 with u3 chars remaining, if false c-addr3 u3 = c-addr1 u1 )
code search  ( c-addr1 u1 c-addr u2 -- c-addr3 u3 flag )
	push	esi
	mov		edi, 8 [ebp]				\ edi = string addr
	mov		ecx, 4 [ebp]				\ ecx = string length
	jecxz	short 3 @@					\ string zero length?
	or		ebx, ebx					\ pattern zero length?
	jz		short 3 @@
1 @@:
	mov		esi, [ebp]					\ esi -> pattern
	lodsb								\ look for first pattern char in string
	repne	scasb
	jne		short 3 @@					\ first char not found, no match
	dec		ebx							\ only one char in pattern?
	jz		short 4 @@
	cmp		ebx, ecx					\ pattern longer than chars left?
	ja		short 3 @@
	push	edi							\ save addr and remaining # chars
	push	ecx
	mov		ecx, ebx					\ pattern length-1
	inc		ebx							\ restore pattern length
	repe	cmpsb						\ does rest of pattern match?
	pop		ecx
	pop		edi
	jne		short 1 @@					\ no match, so keep searching
4 @@:
	dec		edi							\ back up to match location
	inc		ecx
	add		ebp, # 4
	mov		4 [ebp], edi				\ match addr
	mov		[ebp], ecx					\ # of chars remaining in string
	mov		ebx, # -1					\ match found, true
	pop		esi
	next
3 @@:
	mov		eax, 8 [ebp]				\ no match, give c-addr1 u1 false
	mov		ecx, 4 [ebp]
	add		ebp, # 4
	mov		4 [ebp], eax
	mov		[ebp], ecx
	xor		ebx, ebx
	pop		esi
	next
end-code

( case insensitive search of c-addr1 u1 for substr c-addr2 u2, if true match
  found at c-addr3 with u3 chars remaining, if false c-addr3 u3 = c-addr1 u1 )
code isearch  ( c-addr1 u1 c-addr u2 -- c-addr3 u3 flag )
	push	esi
	mov		edi, 8 [ebp]				\ edi = str address
	mov		ecx, 4 [ebp]				\ ecx = string length
	jecxz	short 3 @@					\ string zero length?
	or		ebx, ebx					\ pattern zero length?
	jz		short 3 @@
	xor		eax, eax
	xor		edx, edx
1 @@:
	mov		esi, [ebp]					\ esi -> pattern
	lodsb
	test	byte addr> chtypes [eax], # chupper chlower or
	jz		short 5 @@					\ use scasb if it's punctuation etc
	mov		al, addr> uctable [eax] 	\ convert pattern char to upper case
4 @@:
	mov		dl, [edi]					\ next string char
	inc		edi
	cmp		al, addr> uctable [edx] 	\ case insensitive compare
	je		short 2 @@
	dec		ecx
	jnz		short 4 @@
3 @@:
	mov		eax, 8 [ebp]				\ no match found, give: c-addr u1 false
	mov		ecx, 4 [ebp]
	add		ebp, # 4
	mov		4 [ebp], eax
	mov		[ebp], ecx
	xor		ebx, ebx
	pop		esi
	next
2 @@:
	dec		ecx
	jmp		short 6 @@
5 @@:
	repne	scasb
	jne		short 3 @@					\ first pattern char not found
6 @@:
	dec		ebx
	jz		short 9 @@					\ done
	cmp		ebx, ecx					\ pattern longer than str left?
	ja		short 3 @@
	push	edi							\ save addr and remaining # chars
	push	ecx
	mov		ecx, ebx					\ pattern length-1
	inc		ebx							\ restore pattern length
7 @@:
	lodsb								\ get pattern char
	mov		al, addr> uctable [eax]		\ force to upper case
	mov		dl, [edi]					\ get string char
	inc		di
	cmp		al, addr> uctable [edx]		\ upper case compare
	jne		short 8 @@
	dec		ecx
	jnz		short 7 @@
8 @@:
	pop		ecx
	pop		edi
	jne		short 1 @@					\ no match, so keep searching
9 @@:
	dec		edi							\ back up to match location
	inc		ecx
	add		ebp, # 4
	mov		4 [ebp], edi				\ match addr
	mov		[ebp], ecx					\ # of chars remaining in string
	mov		ebx, # -1					\ match found, true
	pop		esi
	next
end-code

( moves u characters from c-addr1 to c-addr2, starting from lowest addresses )
code cmove  ( c-addr1 c-addr2 u -- )
	push	esi
	mov		esi, 4 [ebp]				\ esi = c-addr1
	mov		edi, [ebp]					\ edi = c-addr2
	mov		ecx, ebx					\ ecx = u
	rep		movsb						\ must move char by char to be standard
	mov		ebx, 8 [ebp]
	add		ebp, # 12
	pop		esi
	next
end-code

( moves u characters from c-addr1 to c-addr2, starting from highest addresses )
code cmove>  ( c-addr1 c-addr2 u -- )
	push	esi
	mov		esi, 4 [ebp]				\ esi = c-addr1
	mov		edi, [ebp]					\ edi = c-addr2
	mov		ecx, ebx					\ ecx = u
	lea		edi, -1 [edi] [ecx]			\ move from highest addr to lowest
	lea		esi, -1 [esi] [ecx]
	std									\ backwards
	rep		movsb						\ must move char by char to be standard
	cld
	mov		ebx, 8 [ebp]
	add		ebp, # 12
	pop		esi
	next
end-code

code fill  ( c-addr u char -- )			\ fill u characters at c-addr with char
	mov		eax, ebx					\ al = char
	mov		ecx, [ebp]					\ ecx = u
	mov		edi, 4 [ebp]				\ edi = c-addr
	mov		ebx, 8 [ebp]
	add		ebp, # 12
	jecxz	short 3 @@
2 @@:
	test	edi, # 3					\ dest addr dword aligned?
	jz		short 1 @@
	stosb								\ no, fill a byte
	loop	2 @@
3 @@:
	next
1 @@:
	mov		ah, al						\ get char in all bytes of eax
	mov		edx, eax
	shl		eax, # 16
	mov		ax, dx
	mov		edx, ecx
	shr		ecx, # 2
	rep		stosd						\ fast fill with dwords
	and		edx, # 3
	mov		ecx, edx
	rep		stosb						\ and do remaining bytes
	next
end-code

: erase  ( c-addr u -- )				\ fill u chars at c-addr with zeroes
	0 fill ;

: blank  ( c-addr u -- )				\ fill u chars at c-addr with blanks
	bl fill ;

( move u address units from c-addr1 to c-addr2, regardless of overlap )
code move  ( addr1 addr2 u -- )
	push	esi
	mov		esi, 4 [ebp]				\ esi = addr1
	mov		edi, [ebp]					\ edi = addr2
	mov		ecx, ebx					\ ecx = u
	mov		ebx, 8 [ebp]
	add		ebp, # 12
	cmp		edi, esi
	jbe		short 1 @@					\ c-addr1 > c-addr2 so use "cmove"
	lea		eax, [esi] [ecx]
	cmp		edi, eax
	jae		short 1 @@					\ c-addr1+u <= c-addr2 so use "cmove"
	lea		edi, -1 [edi] [ecx]			\ else move from highest addr to lowest
	lea		esi, -1 [esi] [ecx]
	std
	rep		movsb						\ move bytes backwards
	cld
	pop		esi
	next
1 @@:
	jecxz	short 3 @@					\ if u = zero exit
4 @@:
	test	esi, # 3
	jz		short 5 @@
	movsb
	loop	4 @@						\ loop until aligned or done
3 @@:
	pop		esi
	next
5 @@:
	mov		edx, ecx
	shr		ecx, # 2
	rep		movsd						\ move dwords for speed
	and		edx, # 3
	mov		ecx, edx
2 @@:
	rep		movsb						\ move remaining bytes
	pop		esi
	next
end-code

( places char string c-addr u as counted string at address dest )
: place  ( c-addr u dest -- )
	2dup 2>r							\ we must move before c!
	char+ swap  chars move				\ in case c-addr and dest overlap
	2r> c! ;							\ store u (string length) at dest

( scans char string c-addr u1 for character, if flag is true u2 is the
  position in c-addr at which char was found, else u2 is equal to u1 )
code cscan  ( c-addr u1 char -- u2 flag )
	mov		edi, 4 [ebp]				\ edi = c-addr
	mov		edx, edi					\ save addr for later
	mov		ecx, [ebp]					\ ecx = u1
	mov		eax, ebx					\ al = char
	add		ebp, # 4
	xor		ebx, ebx					\ flag initially false
	jecxz	short 1 @@
	repne	scasb						\ scan while not = to char
	jne		short 1 @@					\ not found so return false
	dec		edi
	dec		ebx							\ change flag to true
1 @@:
	sub		edi, edx					\ calculate u2
	mov		[ebp], edi
	next
end-code

( if char is one of type in the character type table chtypes, return true )
code chtype  ( char type -- flag )
	mov		ecx, ebx					\ ecx = type
	mov		eax, [ebp]					\ eax = char
	add		ebp, # 4					\ test bits
	test	byte addr> chtypes [eax], cl
	jz		short 1 @@					\ are any bits set?
	mov		ebx, # -1					\ yep, return true
	next
1 @@:
	xor		ebx, ebx					\ nope, flag = false
	next
end-code

: isdigit?  ( char -- flag )			\ is char a digit from 0-9?
	chdigit chtype ;

: isalpha?  ( char -- flag )			\ is char from A-Z or a-z?
	[ chupper chlower or ] literal  chtype ;

: isctrl?  ( char -- flag )				\ is char a control char < bl?
	chctrl chtype ;

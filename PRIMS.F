\ BenOS v1.0 code primitives (c) Benjamin Hoyt 1997

( some miscellaneous constants for later use )
$20 constant bl  ( -- char )			\ character value for space
  4 constant cell  ( -- n )				\ size of one cell in bytes
 -1 constant true  ( -- true )			\ a true flag
  0 constant false  ( -- false )		\ a false flag

code !  ( x a-addr -- )					\ store x at a-addr
	mov		eax, [ebp]					\ eax = x
	mov		[ebx], eax					\ store at a-addr
	mov		ebx, 4 [ebp]
	add		ebp, # 8
	next
end-code

code (c")  ( -- c-addr )				\ return addr of inline counted string
	pop		edi							\ get return addr
	sub		ebp, # 4
	mov		[ebp], ebx
	mov		ebx, edi					\ push c-addr
	mov		al, [edi]					\ movzx eax, byte [edi]
	and		eax, # $FF
	lea		edi, 1 [edi] [eax]
	jmp		edi							\ skip to just past end of string
end-code

' (c") xt!> t(c")						\ store target compiler's (c") xt

( set up do ... loop with n1|u1 = limit and n2|u2 = start )
code (do)  ( n1|u1 n2|u2 -- ) ( r: -- loop-sys )
	mov		edi, [esp]					\ edi = return address
	mov		eax, [edi]					\ end of loop addr
	mov		edx, ebx					\ edx = starting loop count
	mov		ecx, [ebp]					\ ecx = loop count limit
	mov		ebx, 4 [ebp]
	add		ebp, # 8
	sub		esp, # 8					\ allow for 3 cells on return stack
	mov	 	8 [esp], eax				\ push end of loop addr on r:
	add		ecx, # $80000000
	mov		4 [esp], ecx				\ push limit on r:
	sub		edx, ecx
	mov		[esp], edx					\ push start on r:
	add		edi, # 4					\ return to after inline address
	jmp		edi
end-code

' (do) xt!> t(do)						\ store target compiler's (do) xt

( set up ?do ... loop with n1|u1 = limit and n2|u2 = start )
code (?do)  ( n1|u1 n2|u2 -- ) ( r: -- | loop-sys )
	cmp		ebx, [ebp]
	jne		short ' (do)				\ n1|u1 <> n2|u2 so do the loop
	mov		ebx, 4 [ebp]				\ drop n1|u1 and n2|u2
	add		ebp, # 8
	pop		edi							\ edi = return address
	jmp		dword [edi]					\ skip to just past end of loop
end-code

' (?do) xt!> t(?do)						\ store target compiler's (?do) xt

code (s")  ( -- c-addr u )				\ return c-addr u of inline string
	pop		edi							\ get return addr
	sub		ebp, # 8
	mov		4 [ebp], ebx
	lea		eax, 1 [edi]
	mov		[ebp], eax					\ push c-addr
	mov		bl, [edi]					\ movzx ebx, byte [edi]
	and		ebx, # $FF					\ push u
	lea		edi, 1 [edi] [ebx]
	jmp		edi							\ skip to just past end of string
end-code

' (s") xt!> t(s")						\ store target compiler's (s") xt

code *  ( n1 n2 -- n3 )					\ multiply n1 by n2
	mov		eax, [ebp]					\ eax = n1
	mul		ebx
	mov		ebx, eax					\ ebx = n1*n2
	add		ebp, # 4
	next
end-code

code */  ( n1 n2 n3 -- n4 )				\ multiply n1 by n2, then divide by n3
	mov		eax, 4 [ebp]
	imul	dword [ebp]					\ edx:eax = double n1*n2
	idiv	ebx
	mov		ebx, eax					\ ebx = n4
	add		ebp, # 8
	next
end-code

code */mod  ( n1 n2 n3 -- n4 n5 )		\ same as */ but n4 = rem, n5 = quo
	mov		eax, 4 [ebp]
	imul	dword [ebp]					\ edx:eax = double n1*n2
	idiv	ebx							\ edx = remainder, eax = quotient
	add		ebp, # 4
	mov		[ebp], edx					\ n4 = remainder
	mov		ebx, eax					\ n5 = quotient
	next
end-code

code +  ( n1 n2 -- n3 )					\ add n1 to n2
	add		ebx, [ebp]					\ ebx = n1+n2
	add		ebp, # 4
	next
end-code

code +!  ( n a-addr -- )				\ add n to contents of a-addr
	mov		eax, [ebp]					\ eax = n
	add		[ebx], eax					\ add to contents of a-addr
	mov		ebx, 4 [ebp]
	add		ebp, # 8
	next
end-code

code -  ( n1 n2 -- n3 )					\ subtract n2 from n1
	sub		[ebp], ebx
	mov		ebx, [ebp]					\ ebx = n1-n2
	add		ebp, # 4
	next
end-code

code -!  ( n a-addr -- )				\ subtract n from contents of a-addr
	mov		eax, [ebp]					\ eax = n
	sub		[ebx], eax					\ subtract from contents of a-addr
	mov		ebx, 4 [ebp]
	add		ebp, # 8
	next
end-code

code -rot  ( x1 x2 x3 -- x3 x1 x2 )		\ rotate top three cells backwards
	mov		ecx, [ebp]					\ ecx = x2
	mov		edx, 4 [ebp]				\ edx = x1
	mov		4 [ebp], ebx				\ store x3 as third item
	mov		[ebp], edx					\ store x1 as second item
	mov		ebx, ecx					\ store x2 as first item
	next
end-code

code /  ( n1 n2 -- n3 )					\ divide n1 by n2
	mov		eax, [ebp]
	cdq
	idiv	ebx							\ eax = quotient, edx = remainder
	mov		ebx, eax
	add		ebp, # 4
	next
end-code

code /mod  ( n1 n2 -- n3 n4 )			\ same as / but n3 = rem, n4 = quo
	mov		eax, [ebp]
	cdq
	idiv	ebx
	mov		[ebp], edx
	mov		ebx, eax
	next
end-code

code 0<  ( n -- flag )					\ return true if n < 0
	shl		ebx, # 1					\ shift sign bit into cf
	sbb		ebx, ebx
	next
end-code

code 0<=  ( n -- flag )					\ return true if n <= 0
	or		ebx, ebx
	jle		short 1 @@
	xor		ebx, ebx
	next
1 @@:
	mov		ebx, # -1
	next
end-code

code 0<>  ( x -- flag )					\ return true if x <> 0
	xor		eax, eax
	sub		eax, ebx
	neg		eax							\ cf set if <> 0
	sbb		ebx, ebx
	next
end-code

code 0=  ( x -- flag )					\ return true if n = 0
	sub		ebx, # 1					\ cf set if = 0
	sbb		ebx, ebx
	next
end-code

code 0>  ( n -- flag )					\ return true if n > 0
	or		ebx, ebx
	jg		short 1 @@
	xor		ebx, ebx
	next
1 @@:
	mov		ebx, # -1
	next
end-code

code 0>=  ( n -- flag )					\ return true if n >= 0
	or		ebx, ebx
	jge		short 1 @@
	xor		ebx, ebx
	next
1 @@:
	mov		ebx, # -1
	next
end-code

code 1+  ( n1 -- n2 )					\ add one to n1
	inc		ebx
	next
end-code

code 1-  ( n1 -- n2 )					\ subtract one from n1
	dec		ebx
	next
end-code

code 2!  ( x1 x2 a-addr -- )			\ store x2 at a-addr and x1 next cell
	mov		eax, [ebp]
	mov		[ebx], eax					\ store x2 at a-addr
	mov		eax, 4 [ebp]
	mov		4 [ebx], eax				\ store x1 at a-addr + 4
	mov		ebx, 8 [ebp]
	add		ebp, # 12
	next
end-code

code 2*  ( n1 -- n2 )					\ multiply n1 by two
	add		ebx, ebx
	next
end-code

code 2+  ( n1 -- n2 )					\ add two to n1
	add		ebx, # 2
	next
end-code

code 2-  ( n1 -- n2 )					\ subtract two from n1
	sub		ebx, # 2
	next
end-code

code 2/  ( n1 -- n2 )					\ divide n1 by two
	sar		ebx, # 1
	next
end-code

code 2@  ( a-addr -- x1 x2 )			\ fetch x2 from a-addr and x1 next
	sub		ebp, # 4
	mov		eax, 4 [ebx]
	mov		[ebp], eax
	mov		ebx, [ebx]
	next
end-code

code 2>r  ( x1 x2 -- ) ( r: -- x1 x2 )	\ move cell pair x1 x2 to return stack
	pop		edx
	push	dword [ebp]
	push	ebx
	mov		ebx, 4 [ebp]
	add		ebp, # 8
	jmp		edx
end-code  restrict

code 2drop  ( x1 x2 -- )				\ drop cell pair x1 x2
	mov		ebx, 4 [ebp]
	add		ebp, # 8
	next
end-code

code 2dup  ( x1 x2 -- x1 x2 x1 x2 )		\ duplicate cell pair x1 x2
	mov		eax, [ebp]
	sub		ebp, # 8
	mov		[ebp], eax
	mov		4 [ebp], ebx
	next
end-code

( copy cell pair x1 x2 to TOS )
code 2over  ( x1 x2 x3 x4 -- x1 x2 x3 x4 x1 x2 )
	mov		ecx, 8 [ebp]
	mov		edx, 4 [ebp]
	sub		ebp, # 8
	mov		4 [ebp], ebx
	mov		[ebp], ecx
	mov		ebx, edx
	next
end-code

code 2r>  ( -- x1 x2 ) ( r: x1 x2 -- )	\ move x1 x2 from return stack
	pop		edx
	sub		ebp, # 8
	mov		4 [ebp], ebx
	pop		ebx
	pop		dword [ebp]
	jmp		edx
end-code  restrict

( copy cell pair x1 x2 from return stack )
code 2r@ ( -- x1 x2 ) ( r: x1 x2 -- x1 x2 )
	sub		ebp, # 8
	mov		4 [ebp], ebx
	mov		eax, 8 [esp]
	mov		[ebp], eax
	mov		ebx, 4 [esp]
	next
end-code

( rotate top three cell pairs )
code 2rot  ( x1 x2 x3 x4 x5 x6 -- x3 x4 x5 x6 x1 x2 )
	mov		edx, 4 [ebp]
	xchg	edx, 12 [ebp]
	xchg	edx, ebx
	mov		4 [ebp], edx				\ now x2, x4 and x6 are correct
	mov		eax, 16 [ebp]
	mov		ecx, 8 [ebp]
	mov		edx, [ebp]
	mov		16 [ebp], ecx
	mov		8 [ebp], edx
	mov		[ebp], eax					\ now x1, x3, and x5 are done too
	next
end-code

( swap cell pair x1 x2 and x3 x4 )
code 2swap  ( x1 x2 x3 x4 -- x3 x4 x1 x2 )
	mov		eax, 8 [ebp]				\ swap x1 and x3
	mov		ecx, [ebp]
	mov		8 [ebp], ecx
	mov		[ebp], eax
	mov		eax, 4 [ebp]				\ now swap x2 and x4
	mov		ecx, ebx
	mov		4 [ebp], ecx
	mov		ebx, eax
	next
end-code

code <  ( n1 n2 -- flag )				\ return true if n1 < n2
	cmp		[ebp], ebx
	lea		ebp, 4 [ebp]				\ don't use add, it'll change flags!
	jl		short 1 @@
	xor		ebx, ebx
	next
1 @@:
	mov		ebx, # -1
	next
end-code

code <=  ( n1 n2 -- flag )				\ return true if n1 <= n2
	cmp		[ebp], ebx
	lea		ebp, 4 [ebp]
	jle		short 1 @@
	xor		ebx, ebx
	next
1 @@:
	mov		ebx, # -1
	next
end-code

code <>  ( x1 x2 -- flag )				\ return true if x1 <> x2
	sub		ebx, [ebp]					\ code equivalent to: - 0<>
	add		ebp, # 4
	neg		ebx
	sbb		ebx, ebx
	next
end-code

code =  ( x1 x2 -- flag )				\ return true if x1 = x2
	sub		ebx, [ebp]					\ code equivalent to: - 0=
	add		ebp, # 4
	sub		ebx, # 1
	sbb		ebx, ebx
	next
end-code

code >  ( n1 n2 -- flag )				\ return true if n1 > n2
	cmp		[ebp], ebx
	lea		ebp, 4 [ebp]
	jg		short 1 @@
	xor		ebx, ebx
	next
1 @@:
	mov		ebx, # -1
	next
end-code

code >=  ( n1 n2 -- flag )				\ return true if n1 >= n2
	cmp		[ebp], ebx
	lea		ebp, 4 [ebp]
	jge		short 1 @@
	xor		ebx, ebx
	next
1 @@:
	mov		ebx, # -1
	next
end-code

code ?dup  ( x -- 0 | x x )				\ duplicate x if nonzero
	or		ebx, ebx
	jz		short 1 @@
	sub		ebp, # 4
	mov		[ebp], ebx
1 @@:
	next
end-code

code >r  ( x -- ) ( r: -- x )			\ move cell x to return stack
	pop		edx
	push	ebx
	mov		ebx, [ebp]
	add		ebp, # 4
	jmp		edx
end-code  restrict

code @  ( a-addr -- x )					\ fetch x from a-addr
	mov		ebx, [ebx]
	next
end-code

code abs  ( n -- +n )					\ return absolute value of n
	or		ebx, ebx
	jge		short 1 @@
	neg		ebx
1 @@:
	next
end-code

code aligned  ( addr -- a-addr )		\ align addr on cell boundary
	add		ebx, # 3
	and		ebx, # $FFFFFFFC
	next
end-code

code and  ( x1 x2 -- x3 )				\ and x1 with x2
	and		ebx, [ebp]
	add		ebp, # 4
	next
end-code

( set up start and limit for a do ... loop, limit = start+count )
code bounds  ( start count -- limit start )
	mov		eax, [ebp]
	add		eax, ebx
	mov		ebx, [ebp]
	mov		[ebp], eax
	next
end-code

code c!  ( char c-addr -- )				\ store char at c-addr
	mov		al, [ebp]
	mov		[ebx], al
	mov		ebx, 4 [ebp]
	add		ebp, # 8
	next
end-code

code c@  ( c-addr -- char )				\ fetch char from c-addr
	mov		bl, [ebx]
	and		ebx, # $FF
	next
end-code

code cell+  ( a-addr1 -- a-addr2 )		\ add size of a cell to a-addr1
	add		ebx, # 4
	next
end-code

code cell-  ( a-addr1 -- a-addr2 )		\ subtract size of a cell from a-addr1
	sub		ebx, # 4
	next
end-code

code cell/  ( n1 -- n2 )				\ n2 = number of cells in n1 addr units
	sar		ebx, # 2
	next
end-code

code cells  ( n1 -- n2 )				\ return size of n1 cells
	shl		ebx, # 2
	next
end-code

code char+  ( c-addr1 -- c-addr2 )		\ add size of a char to c-addr1
	inc		ebx
	next
end-code

code chars  ( n1 -- n2 )				\ return size of n chars
	next
end-code immediate

code d+  ( d1 d2 -- d3 )				\ add d1 to d2
	mov		eax, [ebp]
	add		8 [ebp], eax
	adc		ebx, 4 [ebp]
	add		ebp, # 8
	next
end-code

code d-  ( d1 d2 -- d3 )				\ subtract d2 from d1
	mov		eax, [ebp]
	sub		8 [ebp], eax
	sbb		4 [ebp], ebx
	mov		ebx, 4 [ebp]
	add		ebp, # 8
	next
end-code

code d0<  ( d -- flag )					\ return true if d < 0
	add		ebp, # 4					\ discard low cell
	shl		ebx, # 1					\ and flag true if high cell < 0
	sbb		ebx, ebx
	next
end-code

code d0=  ( xd -- flag )				\ return true if xd = 0
	or		ebx, [ebp]					\ code equivalent to: or 0=
	add		ebp, # 4
	sub		ebx, # 1
	sbb		ebx, ebx
	next
end-code

code d2*  ( d1 -- d2 )					\ multiply d1 by two
	shl		dword [ebp], # 1
	rcl		ebx, # 1
	next
end-code

code d2/  ( d1 -- d2 )					\ divide d1 by two
	sar		ebx, # 1
	rcr		dword [ebp], # 1
	next
end-code

code d<  ( d1 d2 -- flag )				\ return true if d1 < d2
	cmp		4 [ebp], ebx				\ compare the two high cells
	je		short 1 @@					\ they're equal, test two low cells
	jg		short 3 @@					\ or d1 > d2
2 @@:
	add		ebp, # 12					\ else d1 < d2
	mov		ebx, # -1
	next
1 @@:
	mov		eax, 8 [ebp]
	cmp		eax, [ebp]
	jb		short 2 @@
3 @@:
	add		ebp, # 12
	xor		ebx, ebx
	next
end-code

code d=  ( xd1 xd2 -- flag )			\ return true if xd1 = xd2
	mov		ecx, 8 [ebp]				\ code equivalent to: d- d0=
	mov		edx, 4 [ebp]
	sub		ecx, [ebp]
	sbb		edx, ebx
	or		ecx, edx
	add		ebp, # 12
	sub		ecx, # 1
	sbb		ebx, ebx
	next
end-code

code d>s  ( d -- n )					\ convert d to single
	mov		ebx, [ebp]					\ just discard high cell
	add		ebp, # 4
	next
end-code

code decr  ( a-addr -- )				\ subtract one from contents of a-addr
	dec		dword [ebx]
	mov		ebx, [ebp]
	add		ebp, # 4
	next
end-code

code dmax  ( d1 d2 -- d3 )				\ return greater of d1 and d2
	cmp		4 [ebp], ebx				\ compare the two high cells first
	je		short 1 @@					\ they're equal, check two low cells
	jg		short 2 @@					\ d1 > d2, leave d1 on stack
3 @@:
	mov		eax, [ebp]					\ d2 > d1, leave d2 on stack
	add		ebp, # 8
	mov		[ebp], eax
	next
1 @@:
	mov		eax, 8 [ebp]				\ test two low cells
	cmp		eax, [ebp]
	jb		short 3 @@					\ d2 > d1
2 @@:
	mov		ebx, 4 [ebp]				\ d1 > d2, leave d1 on stack
	add		ebp, # 8
	next
end-code

code dmin  ( d1 d2 -- d3 )				\ return lesser of d1 and d2
	cmp		4 [ebp], ebx				\ compare the two high cells first
	je		short 1 @@					\ they're equal, check two low cells
	jl		short 2 @@					\ d1 < d2, leave d1 on stack
3 @@:
	mov		eax, [ebp]					\ d2 < d1, leave d2 on stack
	add		ebp, # 8
	mov		[ebp], eax
	next
1 @@:
	mov		eax, 8 [ebp]				\ test two low cells
	cmp		eax, [ebp]
	ja		short 3 @@					\ d2 < d1
2 @@:
	mov		ebx, 4 [ebp]				\ d1 < d2, leave d1 on stack
	add		ebp, # 8
	next
end-code

code dnegate  ( d1 -- d2 )				\ negate d1
	neg		dword [ebp]
	adc		ebx, # 0
	neg		ebx
	next
end-code

code dabs  ( d -- +d )					\ return absolute value of d
	or		ebx, ebx
	jl		short ' dnegate
	next
end-code

code drop  ( x -- )						\ drop x
	mov		ebx, [ebp]
	add		ebp, # 4
	next
end-code

code du<  ( ud1 ud2 -- flag )			\ return true if ud1 < ud2
	cmp		4 [ebp], ebx				\ compare the two high cells
	je		short 1 @@					\ they're equal, test two low cells
	ja		short 3 @@					\ or ud1 > ud2
2 @@:
	add		ebp, # 12					\ else ud1 < ud2
	mov		ebx, # -1
	next
1 @@:
	mov		eax, 8 [ebp]
	cmp		eax, [ebp]
	jb		short 2 @@
3 @@:
	add		ebp, # 12
	xor		ebx, ebx
	next
end-code

code dup  ( x -- x x )					\ duplicate x
	sub		ebp, # 4
	mov		[ebp], ebx
	next
end-code

code execute  ( i*x xt -- j*x )			\ execute word identified by xt
	mov		eax, ebx
	mov		ebx, [ebp]
	add		ebp, # 4
	jmp		eax							\ jump directly to the execution token
end-code

( floored divide of d1 by n1, n2 is the remainder and n3 the quotient )
code fm/mod  ( d1 n1 -- n2 n3 )
	mov		edx, [ebp]					\ edx = high d1 (numerator)
	add		ebp, # 4
	mov		eax, edx					\ eax = edx for testing sign
	xor		eax, ebx					\ test against denominator
	jns		short 1 @@					\ jump if signs differ
	mov		eax, [ebp]					\ eax = low d1 (numerator)
	idiv	ebx							\ do the actual divide
	or		edx, edx					\ is remainder zero?
	jz		short 2 @@					\ yep, go straight to finish line
	add		edx, ebx					\ add divisor to remainder
	dec		eax							\ subtract one from quotient
	mov		[ebp], edx					\ store n2 (remainder)
	mov		ebx, eax					\ store n3 (quotient)
	next
1 @@:
	mov		eax, [ebp]					\ eax = low d1 (numerator)
	idiv	ebx							\ just do the divide
2 @@:
	mov		[ebp], edx					\ store n2 (remainder)
	mov		ebx, eax					\ store n3 (quotient)
	next
end-code

code i  ( -- n|u )						\ return innermost loop index
	sub		ebp, # 4
	mov		[ebp], ebx
	mov		ebx, 4 [esp]
	add		ebx, 8 [esp]
	next
end-code  restrict

code incr  ( a-addr -- )				\ add one to contents of a-addr
	inc		dword [ebx]
	mov		ebx, [ebp]
	add		ebp, # 4
	next
end-code

code invert  ( x1 -- x2 )				\ inverts all bits of x1
	not		ebx
	next
end-code

code j  ( -- n|u )						\ return next innermost loop index
	sub		ebp, # 4
	mov		[ebp], ebx
	mov		ebx, 16 [esp]
	add		ebx, 20 [esp]
	next
end-code  restrict

code lshift  ( x1 u -- x2 )				\ shift x1 left u bits
	mov		cl, bl
	mov		ebx, [ebp]
	add		ebp, # 4
	shl		ebx, cl
	next
end-code

code m*  ( n1 n2 -- d )					\ multiply n1 by n2
	mov		eax, [ebp]
	imul	ebx							\ edx:eax = d
	mov		[ebp], eax
	mov		ebx, edx
	next
end-code

code m*/  ( d1 n1 +n2 -- d2 )			\ multiply d1 by n1, divides by +n2
	push	esi
	xor		ecx, ecx					\ setup ecx with result's sign
	cmp		4 [ebp], # 0				\ is d1 negative?
	jge		short 1 @@					\ nope
	neg		dword 8 [ebp]				\ yes, negate d1
	adc		dword 4 [ebp], # 0
	neg		dword 4 [ebp]
	dec		ecx							\ and change sign flag
1 @@:
	cmp		dword [ebp], # 0			\ is n1 negative?
	jge		short 2 @@					\ nope
	neg		dword [ebp]					\ yes, negate n1
	inc		ecx							\ and change sign flag
2 @@:
	mov		eax, 8 [ebp]				\ first multiply d1 by n1
	mul		dword [ebp]
	mov		esi, edx
	mov		edi, eax
	mov		eax, 4 [ebp]				\ produce triple cell intermed. product
	mul		dword [ebp]					\ .. in edx:esi:edi
	add		esi, eax
	adc		edx, # 0
	mov		eax, edx					\ now divide by +n2
	xor		edx, edx
	div		ebx
	mov		eax, esi
	div		ebx
	mov		esi, eax
	mov		eax, edi
	div		ebx							\ quotient now in esi:eax
	jecxz	short 3 @@					\ and put sign on result if needed
	neg		eax
	adc		esi, # 0
	neg		esi
3 @@:
	add		ebp, # 8					\ push final result on stack
	mov		[ebp], eax
	mov		ebx, esi
	pop		esi
	next
end-code

code m+  ( d1 n -- d2 )					\ add n to double d1
	mov		eax, ebx					\ code equivalent to: s>d d+
	shl		ebx, # 1
	sbb		ebx, ebx					\ ebx:eax = n s>d
	add		eax, 4 [ebp]
	adc		ebx, [ebp]
	add		ebp, # 4
	mov		[ebp], eax
	next
end-code

code m-  ( d1 n -- d2 )					\ subtract n from double d1
	mov		eax, ebx					\ code equivalent to: s>d d-
	shl		ebx, # 1
	sbb		ebx, ebx					\ ebx:eax = n s>d
	mov		ecx, 4 [ebp]
	mov		edx, [ebp]					\ edx:ecx = d1
	sub		ecx, eax
	sbb		edx, ebx					\ edx:ecx = d2
	add		ebp, # 4
	mov		[ebp], ecx
	mov		ebx, edx
	next
end-code

code max  ( n1 n2 -- n3 )				\ return greater of n1 and n2
	mov		eax, [ebp]
	add		ebp, # 4
	cmp		eax, ebx					\ compare the two values
	jng		short 1 @@					\ n2 < n1
	mov		ebx, eax					\ n1 < n2 so swap the values
1 @@:
	next
end-code

code min  ( n1 n2 -- n3 )				\ return lesser of n1 and n2
	mov		eax, [ebp]
	add		ebp, # 4
	cmp		eax, ebx					\ compare the two values
	jnl		short 1 @@					\ n2 > n1
	mov		ebx, eax					\ n1 > n2 so swap the values
1 @@:
	next
end-code

code mod  ( n1 n2 -- n3 )				\ return remainder of n1 divided by n2
	mov		eax, [ebp]
	cdq
	idiv	ebx							\ eax = quotient, edx = remainder
	mov		ebx, edx
	add		ebp, # 4
	next
end-code

code mu/mod  ( ud1 u1 -- u2 ud2 ) 		\ divide ud1 by u1, u2 = rem, ud2 = quo
	mov		eax, [ebp]					\ eax:edi = ud1
	mov		edi, 4 [ebp]
	xor		edx, edx
	div		ebx							\ divide high cell by u1
	xchg	edi, eax
	div		ebx							\ divide low cell by u1
	mov		4 [ebp], edx				\ store u2 remainder
	mov		[ebp], eax					\ store edi:eax = quotient
	mov		ebx, edi
	next
end-code

code mud*  ( ud1 u -- ud2 ) 			\ multiply ud1 by u
	mov		eax, [ebp]
	mul		ebx							\ multiply u by high cell of ud1
	mov		ecx, edx					\ save product in ecx temporarily
	mov		eax, 4 [ebp]
	add		ebp, # 4
	mul		ebx							\ multiply u by low cell of ud1
	add		edx, ecx					\ final product in edx:eax
	mov		[ebp], eax
	mov		ebx, edx
	next
end-code

code negate  ( n1 -- n2 )				\ negate n1
	neg		ebx
	next
end-code

code nip  ( x1 x2 -- x2 )				\ remove x1 from stack
	add		ebp, # 4
	next
end-code

code noop  ( -- )						\ no operation (for misc stuff)
	next
end-code immediate

code on  ( a-addr -- )					\ set contents of a-addr to true
	mov		dword [ebx], # -1
	mov		ebx, [ebp]
	add		ebp, # 4
	next
end-code

code off  ( a-addr -- )					\ set contents of a-addr to false
	mov		dword [ebx], # 0
	mov		ebx, [ebp]
	add		ebp, # 4
	next
end-code

code or  ( x1 x2 -- x3 )				\ or x1 with x2
	or		ebx, [ebp]
	add		ebp, # 4
	next
end-code

code over  ( x1 x2 -- x1 x2 x1 )		\ copy x1 to TOS
	sub		ebp, # 4
	mov		[ebp], ebx
	mov		ebx, 4 [ebp]
	next
end-code

code pc!  ( byte port -- )				\ send byte to port
	mov		edx, ebx					\ dx = port
	mov		al, [ebp]					\ al = data byte
	out		dx, al						\ send it
	mov		ebx, 4 [ebp]
	add		ebp, # 8
	next
end-code

code pc@  ( port -- byte )				\ receive byte from port
	mov		edx, ebx					\ dx = port
	xor		eax, eax
	in		al, dx						\ receive byte
	mov		ebx, eax					\ ebx = byte
	next
end-code

( copy xu to top of stack )
code pick  ( xu ... x1 x0 u -- xu ... x1 x0 xu )
	$8B c, $5C c, $9D c, $00 c,			\ mov ebx, [ebp] [ebx*4]
	next								\ but 486asm has a bug
end-code

code r>  ( -- x ) ( r: x -- )			\ move x from return stack
	pop		edx
	sub		ebp, # 4
	mov		[ebp], ebx
	pop		ebx
	jmp		edx
end-code  restrict

code r@  ( -- x ) ( r: x -- x )			\ copy x from return stack
	sub		ebp, # 4
	mov		[ebp], ebx
	mov		ebx, 4 [esp]
	next
end-code

( rotate u cells on the stack, leaving xu on top )
code roll ( xu xu-1 ... x0 u -- xu-1 ... x0 xu )
	push	esi
	lea		edi, -4 [ebp] [ebx*4]		\ destination for move on stack
	lea		esi, -4 [edi]				\ source for move on stack
	mov		ebx, [edi]					\ pick xu from stack
	add		ebp, # 4
	std
	rep		movsd						\ move dwords backwards
	cld
	pop		esi
	next
end-code

code rot  ( x1 x2 x3 -- x2 x3 x1 )		\ rotate top three stack cells
	mov		ecx, 4 [ebp]				\ on a 486 xchg is slower
	mov		edx, [ebp]
	mov		[ebp], ebx
	mov		4 [ebp], edx
	mov		ebx, ecx
	next
end-code

code rp!  ( a-addr -- )					\ set return stack pointer to a-addr
	pop		edx
	mov		esp, ebx
	mov		ebx, [ebp]
	add		ebp, # 4
	jmp		edx
end-code  restrict

code rp@  ( -- a-addr )					\ fetch the return stack pointer
	sub		ebp, # 4
	mov		[ebp], ebx
	lea		ebx, 4 [esp]
	next
end-code

code rshift  ( x1 u -- x2 )				\ shift x1 right u bits zero filled
	mov		cl, bl
	mov		ebx, [ebp]
	add		ebp, # 4
	shr		ebx, cl
	next
end-code

code s>d  ( n -- d )					\ convert n to double
	sub		ebp, # 4
	mov		[ebp], ebx
	shl		ebx, # 1					\ cf = sign bit
	sbb		ebx, ebx
	next
end-code

( symmetric divide of d1 by n2, n2 is the remainder and n3 the quotient )
code sm/rem  ( d1 n1 -- n2 n3 )
	mov		edx, [ebp]
	mov		eax, 4 [ebp]
	idiv	ebx
	add		ebp, # 4
	mov		[ebp], edx
	mov		ebx, eax
	next
end-code

code sp!  ( a-addr -- )					\ set stack pointer to a-addr
	lea		ebp, -4 [ebx]
	mov		ebx, [ebp]
	add		ebp, # 4
	next
end-code

code sp@  ( -- a-addr )					\ fetch the stack pointer
	sub		ebp, # 4
	mov		[ebp], ebx
	lea		ebx, 4 [ebp]
	next
end-code

code swap  ( x1 x2 -- x2 x1 )			\ swap top two stack cells
	mov		eax, [ebp]
	mov		[ebp], ebx
	mov		ebx, eax
	next
end-code

code tuck  ( x1 x2 -- x2 x1 x2 )		\ tuck x2 under x1
	mov		eax, [ebp]
	sub		ebp, # 4
	mov		4 [ebp], ebx
	mov		[ebp], eax
	next
end-code

code u<  ( u1 u2 -- flag )				\ return true if u1 < u2
	cmp		[ebp], ebx
	lea		ebp, 4 [ebp]
	sbb		ebx, ebx
	next
end-code

code u<=  ( u1 u2 -- flag )				\ return true if u1 <= u2
	cmp		[ebp], ebx
	lea		ebp, 4 [ebp]
	jbe		short 1 @@
	xor		ebx, ebx
	next
1 @@:
	mov		ebx, # -1
	next
end-code

code u>  ( u1 u2 -- flag )				\ return true if u1 > u2
	cmp		ebx, [ebp]
	lea		ebp, 4 [ebp]
	sbb		ebx, ebx
	next
end-code

code u>=  ( u1 u2 -- flag )				\ return true if u1 >= u2
	cmp		[ebp], ebx
	lea		ebp, 4 [ebp]
	jae		short 1 @@
	xor		ebx, ebx
	next
1 @@:
	mov		ebx, # -1
	next
end-code

code um*  ( u1 u2 -- ud )				\ multiply u1 by u2
	mov		eax, [ebp]
	mul		ebx							\ edx:eax = ud
	mov		[ebp], eax
	mov		ebx, edx
	next
end-code

code um/mod  ( ud u1 -- u2 u3 )			\ divide ud by u1, u2 = rem, u3 = quo
	mov		edx, [ebp]
	mov		eax, 4 [ebp]
	div		ebx
	add		ebp, # 4
	mov		[ebp], edx
	mov		ebx, eax
	next
end-code

code umax  ( u1 u2 -- u3 )				\ return lesser of u1 and u2
	mov		eax, [ebp]
	add		ebp, # 4
	cmp		eax, ebx					\ compare the two values
	jna		short 1 @@					\ u2 < u1
	mov		ebx, eax					\ u1 < u2 so swap the values
1 @@:
	next
end-code

code umin  ( u1 u2 -- u3 )				\ return lesser of u1 and u2
	mov		eax, [ebp]
	add		ebp, # 4
	cmp		eax, ebx					\ compare the two values
	jnb		short 1 @@					\ u2 > u1
	mov		ebx, eax					\ u1 > u2 so swap the values
1 @@:
	next
end-code

code under+  ( n1 x n2 -- n3 x )		\ add n2 to n1 giving n3
	add		4 [ebp], ebx
	mov		ebx, [ebp]
	add		ebp, # 4
	next
end-code

code w!  ( word w-addr -- )				\ store 16 bit word to w-addr
	mov		eax, [ebp]					\ ax = word
	mov		[ebx], ax
	mov		ebx, 4 [ebp]
	add		ebp, # 8
	next
end-code

code w@  ( w-addr -- word )				\ fetch 16 bit word from w-addr
	mov		bx, [ebx]
	and		ebx, # $FFFF
	next
end-code

( return true if n2|u2 <= n1|u1 < n3|u3 )
code within  ( n1|u1 n2|u2 n3|u3 -- flag )
	mov		ecx, [ebp]					\ ecx = n2
	mov		eax, 4 [ebp]				\ eax = n1
	add		ebp, # 8					\ ebx = n3
	sub		ebx, ecx
	sub		eax, ecx
	cmp		eax, ebx
	sbb		eax, eax
	mov		ebx, eax
	next
end-code

code xor  ( x1 x2 -- x3 )				\ xor x1 with x2
	xor		ebx, [ebp]
	add		ebp, # 4
	next
end-code

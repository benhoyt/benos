\ BenOS v1.0 startup code (c) Benjamin Hoyt 1997

defer throw								\ forward references
defer catch
defer init-forth

$8000 constant code-base				\ *** testing ***
$40000 constant code-size

create idtr								\ interrupt descriptor table register
	$7FF w,  code-base ,

create gdtr								\ global descriptor table register
	$3F w,  code-base $800 + ,

$B8000 value *debug*
code debug  ( -- )						\ *** debugging ***
	mov		eax, addr> *debug*
	mov		dword [eax], # $47624F41
	add		dword addr> *debug* , # 8
	mov		ecx, # 10000000
1 @@:
	loop	1 @@
	next
end-code

$B8D20 value *h.*
code h.  ( n -- )					 	\ *** debug display n in hex ***
	mov		edx, ebx
	mov		ecx, # 8
	mov		edi, addr> *h.*
	mov		ah, # $4E
1 @@:
	rol		edx, # 4
	mov		al, dl
	and		al, # $F
	cmp		al, # 9
	jbe		short 2 @@
	add		al, # 7
2 @@:
	add		al, # '0
	stosw
	loop	1 @@
	add		dword addr> *h.* , # 18
	mov		ebx, [ebp]
	add		ebp, # 4
	mov		ecx, # 5000000
3 @@:
	loop	3 @@
	next
end-code

user tnext								\ pointers to next & previous tasks
user tprev
user return								\ task's "return" execution address
user sp									\ sleeping task's current sp
user rp									\ sleeping task's current rp
user sp0								\ task data stack bottom address
user rp0								\ task return stack bottom address
user /dstack							\ total bytes on data stack
user /rstack							\ total bytes on return stack

$90000 constant ftid					\ the main Forth tid

code cold  ( -- )						\ initialise the BenOS Forth
	lidt	addr> idtr					\ we know where they point,
	lgdt	addr> gdtr					\ this is just for reference

	mov		esi, # ftid					\ esi -> task's user table
	mov		user@ tnext [esi], esi		\ set next and prev tasks to itself
	mov		user@ tprev [esi], esi

	mov		esp, # $A0000				\ esp = rp0
	mov		user@ rp0 [esi], esp		\ store in user table
	mov		ebp, # $9F000				\ ebp = sp0
	mov		user@ sp0 [esi], ebp		\ store in user table
	mov		dword user@ /rstack [esi], # $1000
	mov		dword user@ /dstack [esi], # $1000

	jmp		' init-forth				\ jump to task's code
end-code

' cold $841 code-base + t!				\ store initial jump address

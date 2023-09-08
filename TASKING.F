\ BenOS v1.0 multitasking (c) Benjamin Hoyt 1998

code this-task  ( -- tid )				\ return tid of current task
	sub		ebp, # 4
	mov		[ebp], ebx
	mov		ebx, esi					\ TOS (ebx) = esi = this task's tid
	next
end-code

code to-task  ( tid -- )				\ go straight to task tid (in EBX)
	mov		esi, ebx					\ esi -> tid
	mov		ebp, user@ sp [esi]			\ setup stack pointer & EBX cache
	mov		ebx, [ebp]
	add		ebp, # 4
	mov		esp, user@ rp [esi]			\ setup return stack pointer
	jmp		dword user@ return [esi]	\ start task execution
end-code

code sleep  ( -- )						\ switch to next task in tasks chain
	sub		ebp, # 4
	mov		[ebp], ebx					\ push stack "cache" EBX into memory
	mov		user@ sp [esi], ebp			\ save data stack pointer
	pop		dword user@ return [esi]	\ save current task's return address
	mov		user@ rp [esi], esp			\ save return stack pointer
	mov		ebx, user@ tnext [esi]		\ ebx -> next task in chain
	jmp		short ' to-task				\ switch to task ebx
end-code

: stop-task  ( tid -- )					\ stop tid running and free it
	dup  dup user@ tnext + @			\ get forward and backward links
	swap user@ tprev + @  2dup
	swap user@ tprev + !				\ update prev
	user@ tnext + !						\ update next
	mfree ;								\ free memory used by task structure

: stop-this  ( -- )						\ stop current task and sleep
	tnext @								\ get next task's tid
	this-task stop-task					\ stop/free this task
	to-task ;							\ then switch to next task

( create and allocate memory for a new task and return tid, xt is the word to
  be executed when the task is started, return-cells is # cells for return
  stack, data-cells is # cells for data stack )
: make-task  ( xt return-cells data-cells -- tid )
	1+ cells swap						\ # cells + 1 for EBX in task switch
	1+ cells							\ # cells + 1 for "stop-this" xt
	2dup + user-ofs @ +  mallocate >r	\ allocate mem for stacks & user vars
	cell-  2dup  user-ofs @ + r@ +		\ calculate rp0
	dup  r@ user@ rp0 + !				\ set task's rp0
	['] stop-this over !				\ so task will return to stop-this
	dup  r@ user@ rp + !				\ rp
	cell+ +  dup r@ user@ sp0 + !		\ sp0
	r@ user@ sp + !						\ sp
	r@ user@ /rstack + !				\ bytes/return stack
	cell-  r@ user@ /dstack + !			\ bytes/data stack
	r@ user@ return + !					\ "return" execution address
	r> ;								\ leave tid on stack

( allocate/initialise task and get it up and running: insert it into chain )
: start-task  ( xt return-cells data-cells -- tid )
	make-task  dup						\ allocate/initialise, return tid
	ftid user@ tprev + @ >r				\ get prev
	dup ftid user@ tprev + !			\ link backward to tid
	dup r@ user@ tnext + !				\ link forward to tid
	ftid over user@ tnext + !			\ link tid to next
	r> swap user@ tprev + ! ;			\ link tid to prev

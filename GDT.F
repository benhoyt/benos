\ BenOS v1.0 GDT and IDT source code (c) Benjamin Hoyt 1997

( the interrupt descriptor table )
there  256 2* tcells  dup tallot		\ space for 256 entry IDT
0 tfill									\ zero all entries of IDT

( the 3-entry global descriptor table )
0 t, 0 t,								\ first entry is always NULL
$0000FFFF t, $00CF9A00 t,				\ 32 bit 4gb readable code segment
$0000FFFF t, $00CF9200 t,				\ 32 bit 4gb read/write data segment
$0000FFFF t, $00009A00 t,				\ 16 bit 64k r/o code base = 0
$0000FFFF t, $00009200 t,				\ 16 bit 64k r/w data base = 0
0 t, 0 t,  0 t, 0 t,  0 t, 0 t,			\ reserved for future use

( jump to start of Forth loader code )
$B8 tc, 0 t,							\ mov eax, # jump-addr
$FF tc, $E0 tc,							\ jmp eax

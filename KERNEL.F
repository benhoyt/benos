\ BenOS v1.0 Forth and operating system kernel (c) Benjamin Hoyt 1997

.( Creating BenOS executable image... )

cr.( BenOS startup code                 cold init-forth )
include startup.f

cr.( Code primitives                    + /mod drop lshift xor )
include prims.f

cr.( Memory and string                  >upper count compare move )
include memstr.f

cr.( Data structures and variables      type.immediate current >in state )
include data.f

cr.( Memory allocation                  allocate free mfree mem-avail )
include malloc.f

cr.( Multitasking                       tasks make-task start-task )
include tasking.f

cr.( Timer control                      ms tone beep )
include timer.f

cr.( Video output                       at-xy cursor-on type emit spaces )
include video.f

cr.( Keyboard driver                    key key? ekey accept )
include key.f

cr.( Parallel port driver               init-lpt lpt-emit )
include parallel.f

cr.( CPU interrupts                     int! int@ init-ints )
include intcode.f

cr.( Real mode interface                >ax >bp rmode-int )
include realmode.f

cr.( Number conversion                  # hold . .s >number number? )
include number.f

cr.( Search order and word find         search-wordlist set-current get-order )
include find.f

cr.( Input buffer parsing               parse word name )
include parse.f

cr.( Dictionary compiling               , literal allot header unused )
include comma.f

cr.( Forth exception handling           catch throw abort )
include except.f

cr.( BIOS disk I/O                      init-drive sread swrite )
include disk.f

cr.( Screen and block I/O               block update list )
include block.f

cr.( Forth interpreter and compiler     compiler quit : ; exit if then begin )
include interp.f

cr.( Miscellaneous                      .state .s order dump status-prompt )
include misc.f

cr.( Forth startup code                 BenOS main )
include main.f

cr cr .( Saving executable image on drive A... ) cr
save BenOS.bin  bye

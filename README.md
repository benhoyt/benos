
# BenOS: a 32-bit Forth operating system

I wrote this little 32-bit Forth "operating system" when I was 16 (in 1998), and am now putting it online for anyone interested. I'm releasing it under a permissive MIT license.

It includes a Forth cross-compiler (stolen from Gforth), the OS's "subroutine threaded" Forth interpreter, and simple device drivers written in a combination of Forth and 386 assembly. Oh, and the boot sector code, written in 8086 assembly.

See the `*.TXT` files for documentation. Some interesting ones:

* [`FIND.TXT`](https://github.com/benhoyt/benos/blob/master/FIND.TXT): describes the Forth word find routines and data structures
* [`KEY.TXT`](https://github.com/benhoyt/benos/blob/master/KEY.TXT): discusses the keyboard driver code
* [`MALLOC.TXT`](https://github.com/benhoyt/benos/blob/master/MALLOC.TXT): describes the (very simple) memory allocation routines
* [`PRIMS.TXT`](https://github.com/benhoyt/benos/blob/master/PRIMS.TXT): talks about the primitive Forth words and the threading and register model
* [`TASKING.TXT`](https://github.com/benhoyt/benos/blob/master/TASKING.TXT): briefly describes the OS's cooperative mulitasking routines

Related projects:

* [Third](https://github.com/benhoyt/third), my 16-bit Forth compiler for DOS
* [FE](https://github.com/benhoyt/fe), my Dad's Forth Editor that I wrote all this code in

Original `README.TXT` copied below:

----------------------------------------------------------------------

```
BenOS v1.0aaa (c) Benjamin Hoyt 1998 -- triple alpha trial release

To install BenOS on a floppy disk insert a 1.44mb disk into drive A
and type DODISK. This will copy the necessary stuff onto the floppy,
and if a bunch of success messages are displayed, you are ready to
boot. Simply keep the disk in the drive and reset your machine!

The BenOS project was started in the latter part of the nineteen
hundred and ninety-seventh year after the birth of Christ, and now
over half a year later it is FAR from complete. The aforementioned
designer and programmer (yours truly) is a 16 year old who has coded
this beast in spare time.  Basically the project is a laughable
learning experience for the author. Coded in the author's own 32 bit
Forth target compiler and assembler, BenOS is designed for speed and
simplicity. For more information about the author or about BenOS,
contact him via the email address given below.

You are very welcome to give this package to any friends who may wish
a copy. Be sure you include all seven of these files!

Please note: NO guarantees come with this triple alpha trial release
package. If you or your computer suddenly internally combust the
author does not want to know about it (but don't worry, they say
internal combustion is a very quick and painless process). If
anything you think are my bugs occur please inform me about them.

Thank you!

Ben Hoyt   email: <see my homepage for up-to-date contact info>
```

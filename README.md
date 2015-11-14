
MS-DOS COM to Text Converts
===========================

Copyright 2000-2015 Joergen Ibsen

<http://www.ibsensoftware.com/>

 
About
-----

The MS-DOS 16-bit [COM file](https://en.wikipedia.org/wiki/COM_file) format
is a very simple executable format containing no headers at all.

`c2t1` and `c2t2` convert such an executable file into a plain text file that
remains executable. This is done by encoding the bytes of the original file
in a process similar to Base64, and adding a decoder that is carefully craftet
to only contain x86 opcodes that happen to be text characters.

There were a number of such tools around, and I wrote this one just to see
how it was done.

Recently someone requested a decoder, so I dug out the source and wrote one,
and figured I might as well put the source on GitHub.


Usage
-----

You can assemble the encoder sources using [NASM](http://www.nasm.us/):

    nasm c2t1.asm -fbin -o c2t1.com
    nasm c2t2.asm -fbin -o c2t2.com

Note that recent versions of Windows no longer support running COM files, so
you may need to use a virtual machine to actually use them.

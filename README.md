
MS-DOS COM to Text Converters
=============================

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

There were a number of such tools around, and I wrote this one back in 2000,
just to see how it was done.

Recently someone requested a decoder, so I dug out the source and made one,
and figured I might as well put it on GitHub.


Encoding
--------

`c2t1` transforms each byte into two characters by encoding 4 bit values in
`[0..15]` as ASCII characters between `k` (0x6B) and `z` (0x7A).

`c2t2` encodes 6 bit values into two distinct character ranges. Values in
`[0..5]` are encoded as ASCII characters between `(` (0x28) and `-` (0x2D),
and values in `[6..63]` as ASCII characters between `A` (0x41) and `z` (0x7A).

The bottom two bits of three consecutive bytes are stored as a separate
encoded 6 bit tag value.

`handler1.asm` and `handler2.asm` contain commented source of the handler code
which performs the decoding.


How to Build
------------

You can assemble the encoder sources using [NASM](http://www.nasm.us/):

    nasm c2t1.asm -fbin -o c2t1.com
    nasm c2t2.asm -fbin -o c2t2.com

Note that recent versions of Windows no longer support running COM files, so
you may need to use a virtual machine to actually use them.

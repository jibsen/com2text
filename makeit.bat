@ECHO OFF
tasm /zn /m9 c2t1.asm
tlink /t /3 /x c2t1.obj
tasm /zn /m9 c2t2.asm
tlink /t /3 /x c2t2.obj

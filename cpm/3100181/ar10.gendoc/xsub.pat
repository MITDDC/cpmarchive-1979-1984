The following patch to XSUB.COM will eliminate its nasty
habit of inserting extra line feeds after each command
line which it displays on the console.  After installation
of the patch, console output will look just like it would
if it were actually typed in, instead of double-spaced.
     Do the following:
 
 A>DDT XSUB.COM     ;Load old file to memory
 DDT VERS 2.2       ;Program signs on with version
 NEXT  PC
 0400 0100          ; and displays size
 -S2CF              ;Substitute at 2CFH
 02CF 0A 24         ;Confirm that 0A is the old value!
 02D0 23 .          ;Confirm that 23 is the next value!
 -^C                ;Reboot with CTRL-C.
 A>SAVE 3 XSUB.COM  ;Save new file from memory.
 
 That's it.
 Enjoy.
 


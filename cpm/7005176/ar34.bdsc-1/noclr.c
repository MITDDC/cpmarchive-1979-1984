
noclrex()
/*

	NOCLREX - Do not clear externals.

	11/15/82 - David A. Gewirtz

	This function is used to hack up version 1.5 of Leor's	

BDS C compiler. The C.CCC runtime package automatically clears 

the external data area before executing the compiled program.  

For most programs, this is fine, but for a program like CHDIR, 

which writes itself back out and counts on preinitialized 

externals, it is no good at all. So the noclrex() hack is used to 

cause C.CCC to bypass the 'clear externals' phase of the run-time 

initialization.  As C.CCC may be different for each version this 

routine should be checked.  The following code is part of the 

'init' subroutine of the C.CCC runtime package:

 0447 2A1B01    	LHLD	FRERAM	;CLEAR EXTERNALS
 044A EB        	XCHG
 044B 2A1501    	LHLD	EXTRNS
 044E CDFA02    	CALL 	CMH
 0451 19        	DAD	D	;HL NOW HOLDS SIZE OF EXTERNAL DATA AREA
 0452 7C        CLREX:	MOV 	A,H	;CLEAR ENTIRE EXTERNAL AREA
 0453 B5        	ORA	L
 0454 CA5E04    	JZ	CLREX2
 0457 1B        	DCX	D
 0458 2B        	DCX	H
 0459 AF        	XRA	A
 045A 12        	STAX	D
 045B C35204    	JMP	CLREX
                
 045E AF        CLREX2:	XRA	A

	This function puts a JMP CLREX2 at location 0x447,
	thereby effectively bypassing the clearing mechanisms
	for programs based on this image.

	For those who believe in the sanctity of the original 
program, as well as thos who really don't wish to see awful
and unglamorous hacks, I have not put this in the original programs.
	
	If you have a need for it, simply compile this function
and make a call of the form:

	noclrex();

and all will be well.

	Finally, please realize this this in no way affects the
currently running program, only the program created from the
current image.  

*/
{
	poke(0x447,0xc3);	/* The JMP instruction */
	poke(0x448,0x5e);	/* low order address */
	poke(0x449,0x04);	/* high order */

	/* That's it ... just remember to change this whenever
	   C.CCC is changed or a new version is used */
}


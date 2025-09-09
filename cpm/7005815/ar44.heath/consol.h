		
/*
 *	console.h - Contains functions that deal with the console.
 *			chmode() - puts TT: in the character mode, no echo
 *			lnmode() - puts TT: in the line mode with echo
 *			rawmode() - puts TT: in the raw mode,no echo
 *			width()  - sets the width of a line in TT:
 *			clrcon() - clears the TT: type ahead buffer
 */

chmode() {
#asm
	XRA	A
	LXI	B,201205A
	SCALL	6
#endasm
}

lnmode() {
#asm
	XRA	A
	LXI	B,000205A
	SCALL	6
#endasm
}

rawmode() {
#asm
	XRA	A
	LXI	B,205205A
	SCALL	6
#endasm
}

width(num)
int	num; {
#asm
	LXI	H,2
	DAD	SP
	CALL	h.
	MOV	B,L
	MVI	C,377Q
	MVI	A,3
	SCALL	6
#endasm
}

clrcon() {
#asm
	SCALL	7
#endasm
}

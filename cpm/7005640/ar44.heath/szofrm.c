	
/*
 *	szofram - return the maximum number of bytes that
 *		  alloc() could allow.
 */

szofram() {
#asm
	LHLD	$LM##
	CALL	c.neg##
	DAD	SP
	LXI	D,-500
	DAD	D
#endasm
}

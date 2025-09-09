;>>:yam8.asm 9-30-81
;
;CRCK is a program to read any CP/M file and print
;a CYCLIC-REDUNDANCY-CHECK number based on the
;CCITT standard polynominal:
;   X^16 + X^15 + X^13 + X^7 + X^4 + X^2 + X + 1
;
;Useful for checking accuracy of file transfers.
;More accurate than a simple checksum.
;
;**************************************************
;
;	unsigned crck(buffer, bufsize, oldcrc)
;
;	At start of packet, oldcrc is set to 0
;
;	crc is accumulated by:
;		oldcrc=crck(buffer, bufsize, oldcrc);
;
;	crck for file is final value of oldcrc
;
;	A Short Hostory of this function and crckfile() in yam7.c"
;
;	1.  First version used getc and called crck once per char.
;	this took 39.2 seconds to crck all the yam C files (12357)
;
;	2.  Then crckfile was recoded to use read() instead of getc.
;	Time: 19.1 seconds
;
;	3.  Several small changes in crckfile were unsuccessful in
;	reducing this time.
;
;	4.  crck and crckfile recoded to call crck once per sector.
;	This reduced time to 11.7 seconds, same as crck itself.
;	That is the current version.  Note that the CRC polynomial used
;	here is somewhat unusual; the only thing I know sure is that
;	the answers agree with those given by the CRCK program -hence the
;	function name.
;
	maclib bds
	maclib cmac

	direct
	define crck
	enddir

	prelude crck

	call	arghak
	push	b
bytlop:	lhld	arg1
	mov	c,m
	inx	h		;fetch (next) byte from buffer
	shld	arg1
	lhld	arg3		; get accumulated checksum
;
;---------------------------------------------
;An 8080 routine for generating a CYCLIC-
;REDUNDANCY-CHECK.  Character leaves that
;character in location REM.  By Fred Gutman.
;From 'EDN' magazine, June 5, 1979 issue, page 84.
;
DIVP:
	MOV	A,H
	ANI	128	;Q-BIT MASK
	PUSH	PSW	;SAVE STATUS
	DAD	H	;2 X R(X)
	mov	a,c
	ADD	L
	MOV	L,A
	POP	PSW
	reloc	JZ,QB2	;IF Q-BIT IS ZERO
	MOV	A,H
	XRI	0A0H	;MS HALF OF GEN. POLY
	MOV	H,A
	MOV	A,L
	XRI	97H	;LS HALF OF GEN. POLY
	MOV	L,A
QB2:
	shld	arg3	;store in accumulator
	lhld	arg2
	dcx	h
	shld	arg2	;count number of bytes in buffer
	mov	a,h
	ora	l
	reloc	jnz,bytlop
	lhld	arg3	;return with accumulated crck in HL
	pop	b	;pull up ur shorts
	RET

	postlude crck

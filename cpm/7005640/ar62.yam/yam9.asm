;>>:yam9.asm 9-30-81
;************************************************************************
;* CRCSUBS (Cyclic Redundancy Code Subroutines) version 1.20		*
;* 8080 Mnemonics							*
;*									*
;*     	This subroutine will compute and check a true 16-bit		*
;*	Cyclic Redundancy Code for a message of arbitrary length.	*
;*									*
;*	The  use  of this scheme will guarantee detection of all	*
;*	single and double bit errors, all  errors  with  an  odd	*
;*	number  of  error bits, all burst errors of length 16 or	*
;*	less, 99.9969% of all 17-bit error bursts, and  99.9984%	*
;*	of  all  possible  longer  error bursts.  (Ref: Computer	*
;*	Networks, Andrew S.  Tanenbaum, Prentiss-Hall, 1981)		*
;*									*
;*									*
;************************************************************************
;*									*
;*	From: CRCSUB12.ASM						*
;*	Designed & coded by Paul Hansknecht, June 13, 1981		*
;*									*
;*									*
;*	Copyright (c) 1981, Carpenter Associates			*
;*			    Box 451					*
;*			    Bloomfield Hills, MI 48013			*
;*			    313/855-3074				*
;*									*
;*	This program may be freely reproduced for non-profit use.	*
;*									*
;************************************************************************
;
;	unsigned updcrc(char, oldcrc)
;
;	At start of packet, oldcrc is set to initial value
;		oldcrc=0;
;
;	crc is accumulated by:
;		oldcrc=updcrc(char, oldcrc);
;
;	at end of packet,
;		oldcrc=updcrc(0,updcrc(0,oldcrc));
;		send(oldcrc>>8); send(oldcrc);
;
;	on receive, the return value of updcrc is checked after the
;	last call (with the second CRC byte); 0 indicates no error detected
;

	maclib bds
	maclib cmac

	direct
	define updcrc
	enddir

	prelude updcrc

	push	b		;save stack frame
	call	ma2toh		;get char
	mov	c,a
	call	ma3toh		;and olde crc value
	MVI	B,8
UPDLOOP:MOV	A,C
	RLC
	MOV	C,A
	MOV	A,L
	RAL
	MOV	L,A
	MOV	A,H
	RAL
	MOV	H,A
	reloc	JNC,SKIPIT
	MOV	A,H		; The generator is X^16 + X^12 + X^5 + 1
	XRI	10H		; as recommended by CCITT.
	MOV	H,A		; An alternate generator which is often
	MOV	A,L		; used in synchronous transmission protocols
	XRI	21H		; is X^16 + X^15 + X^2 + 1. This may be
	MOV	L,A		; used by substituting XOR 80H for XOR 10H
SKIPIT:	DCR	B		; and XOR 05H for XOR 21H in the adjacent code.
	reloc	JNZ,UPDLOOP
	POP	B
	RET			; return with latest crc in hl

	postlude updcrc

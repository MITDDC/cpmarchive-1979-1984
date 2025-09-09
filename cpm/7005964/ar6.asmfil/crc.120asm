;************************************************************************
;* CRCSUBS (Cyclic Redundancy Code Subroutines) version 1.20		*
;* 8080 Mnemonics							*
;*									*
;*     	These subroutines will compute and check a true 16-bit		*
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
;*	There are four entry points, which are used as follows:		*
;*									*
;*	CLRCRC - A call to this entry resets the CRC accumulator.	*
;*		 It must be called at the start of each message.	*
;*									*
;*		 Entry Parameters: None.				*
;*									*
;*		 Exit Conditions:  CRC accumulator cleared.		*
;*				   All registers preserved.		*
;*									*
;*									*
;*	UPDCRC - A call to this entry updates the CRC accumulator.	*
;*		 It must be called once for each byte in the		*
;*		 message for which the CRC is being calculated.		*
;*									*
;*		 Entry Parameters: (A) = a byte to be included		*
;*					 in the CRC calculation.	*
;*									*
;*		 Exit Conditions:  CRC accumulator updated.		*
;*				   All registers preserved.		*
;*									*
;*									*
;*	FINCRC - A call to this entry finishes the CRC calculation	*
;*		 for a message which is to be TRANSMITTED. It must	*
;*		 be called after the last byte of the message has	*
;*		 been passed thru UPDCRC. It returns the calculated	*
;*		 CRC bytes, which must be transmitted as the final	*
;*		 two bytes of the message (first D, then E).		*
;*									*
;*		 Entry Parameters: None.				*
;*									*
;*		 Exit Conditions:  (DE) = calculated CRC bytes.		*
;*				   All other registers preserved.	*
;*									*
;*									*
;*	CHKCRC - A call to this routine checks the CRC bytes of		*
;*		 a RECEIVED message and returns a code to indicate	*
;*		 whether the message was received correctly. It must	*
;*		 be called after the message AND the two CRC bytes	*
;*		 have been received AND passed thru UPDCRC.		*
;*									*
;*		 Entry Parameters: None.				*
;*									*
;*		 Exit Conditions:  (A) =  0 if message ok.		*
;*				   (A) = -1 if message garbled.		*
;*				   All other registers preserved.	*
;*									*
;************************************************************************
;*									*
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
;	ENTRY	CLRCRC,UPDCRC,FINCRC,CHKCRC
;
CLRCRC:	EQU	$		; Reset CRC Accumulator for a new message.
	PUSH	H
	LXI	H,0
	SHLD	CRCVAL
	POP	H
	RET
;
UPDCRC:	EQU	$		; Update CRC Accumulator using byte in (A).
	PUSH	PSW
	PUSH	B
	PUSH	H
	MVI	B,8
	MOV	C,A
	LHLD	CRCVAL
UPDLOOP:MOV	A,C
	RLC
	MOV	C,A
	MOV	A,L
	RAL
	MOV	L,A
	MOV	A,H
	RAL
	MOV	H,A
	JNC	SKIPIT
	MOV	A,H		; The generator is X^16 + X^12 + X^5 + 1
	XRI	10H		; as recommended by CCITT.
	MOV	H,A		; An alternate generator which is often
	MOV	A,L		; used in synchronous transmission protocols
	XRI	21H		; is X^16 + X^15 + X^2 + 1. This may be
	MOV	L,A		; used by substituting XOR 80H for XOR 10H
SKIPIT:	DCR	B		; and XOR 05H for XOR 21H in the adjacent code.
	JNZ	UPDLOOP
	SHLD	CRCVAL
	POP	H
	POP	B
	POP	PSW
	RET
;
FINCRC:	EQU	$		; Finish CRC calc for outbound message.
	PUSH	PSW
	XRA	A
	CALL	UPDCRC
	CALL	UPDCRC
	PUSH	H
	LHLD	CRCVAL
	MOV	D,H
	MOV	E,L
	POP	H
	POP	PSW
	RET
;
CHKCRC:	EQU	$		; Check CRC bytes of received message.
	PUSH	H
	LHLD	CRCVAL
	MOV	A,H
	ORA	L
	POP	H
	RZ
	MVI	A,-1
	RET
;
;
CRCVAL	DW	0
;
	END

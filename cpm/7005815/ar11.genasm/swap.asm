;		SWAP.ASM ver. 1.0
;	    by Keith Petersen, W8SDZ
;		  Oct. 3, 1982
;
;The purpose of this program is to temporarily swap
;CP/M's CONSOLE and LIST outputs so that programs
;which normally cannot output to the list device may
;be made to do so.  The function is a "flip-flop" so
;to "un-do" the swap simply execute SWAP.COM again.
;
	ORG	100H
;
	LHLD	1	;GET POINTER TO CBIOS JMP TABLE
	LXI	D,10	;READY TO ADD 10
	DAD	D	;HL=ADRS OF LSB OF JMP ADRS
	PUSH	H	;SAVE ADRS
	MOV	E,M	;SAVE LSB OF JMP IN E
	INX	H	;HL=ADRS OF MSB OF JMP ADRS
	MOV	D,M	;SAVE MSB IN D
	INX	H	;SKIP OVER JMP INSTRUCTION
	INX	H	;HL=ADRS OF LSB OF JMP ADRS
	MOV	C,M	;SAVE LSB IN C
	MOV	M,E	;PUT NEW LSB THERE
	INX	H	;HL=ADRS OF MSB OF JMP ADRS
	MOV	B,M	;SAVE MSB IN B
	MOV	M,D	;PUT NEW MSB THERE
	POP	H	;HL=ADRS OF LSB OF CONOUT JMP
	MOV	M,C	;PUT NEW LSB THERE
	INX	H	;HL=ADRS OF MSB OF CONOUT JMP
	MOV	M,B	;PUT NEW MSB THERE
	RET		;RETURN TO CCP
;
	END

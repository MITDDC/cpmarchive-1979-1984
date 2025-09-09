 TITLE '//SKIP.ASM Transfer control in Submit file'
VERSION	EQU	1$0
;
@MSG	SET	9
@OPN	SET	15
@CLS	SET	16
@DEL	SET	19
;
CPMBASE	EQU	0
BOOT	SET	CPMBASE
BDOS	SET	BOOT+5
TBUFF	EQU	BOOT+80H
TPA	EQU	BOOT+100H
CTRL	EQU	' '-1		;Ctrl char mask
CR	SET	CTRL AND 'M'
LF	SET	CTRL AND 'J'
;
CPM	MACRO	FUNC,OPERAND
	IF	NOT NUL OPERAND
	LXI	D,OPERAND
	ENDIF		;;of not nul operand
	IF	NOT NUL FUNC
	MVI	C,@&FUNC
	ENDIF
	CALL	BDOS
	ENDM
;
FCBS2	EQU	14
FCBRC	EQU	15
FCBR0	EQU	33	;Offsets into File Control Blocks
FCBR1	EQU	34
FCBR2	EQU	35
;
SKIPROG ORG	TPA
;
	JMP	PASTC
	DB	' Ver:'
	DB	VERSION/10+'0'
	DB	'.'
	DB	VERSION MOD 10+'0'
	DB	' Copyright (c) 1982 Gary P. Novosielski '
	DB	CTRL AND 'Z'
PASTC:	LXI	H,0		;Clear HL
	DAD	SP		;Get Stack Pointer value
	LXI	SP,LCLSTAK	;Set up local stack
	PUSH	H		;Save old SP on new stack
;
	LXI	H,TBUFF		;point to Command Buffer
	MOV	A,M		;get count
	INR	A		;Point past end of string
	CALL	HLXA		;Index the pointer
	MVI	M,0		;Insist on null terminator
;
	LXI	H,TBUFF+1	;base of command buffer
	CALL	SCNB		;scan to first non-blank
	ORA	A		;An argument present?
	JNZ	EVALARG		;Yes, evaluate it.
	LXI	H,1		;Else default to one
	JMP	EVALEXIT	;Don't do the loop
EVALARG:
	XCHG			;Scan pointer to DE
	LXI	H,0		;initialize value
EVALOOP:
	LDAX	D		;Get character
	ORA	A		;Terminator?
	JZ	EVALEXIT	;exit loop
;
	CALL	ISNUM		;Test range 0-9 ASCII
	JC	NOTNUM		;argument not numeric
	SUI	'0'		;Make it binary
;
;	Multiply current value in HL by 10
	CALL	HMULT10
;
;	Add in new value from A
	CALL	HLXA
;
	INX	D		;bump argument pointer
	JMP	EVALOOP
;
EVALEXIT:
	;Range test.  Must be 1-127
	LXI	D,1
	CALL	DCMP
	JC	EXIT		;Skip 0 lines=do nothing
	LXI	D,128
	CALL	DCMP
	JNC	RANGERR
;
; OK so far. Now skip over (L) lines in the .SUB file
;
	PUSH	H		;Save the value
	CPM	OPN,SUBFILE	;Open the $$$.SUB file.
	POP	D		;Restore the value
;
	INR	A		;Test return code.
	JZ	SUBERR		;Not within a .SUB file??
	LDA	SUBFILE+FCBRC	;Record counter for the extent
	MOV	L,A		;Get the record counter to HL
	MVI	H,0
;
	CALL	DSUB
	JC	NELERR		;Not enough lines remaining
;
	MOV	A,L		;The new counter value
	STA	SUBFILE+FCBRC	;goes back into the FCB
	XRA	A		;And a zero goes into
	STA	SUBFILE+FCBS2	;the S2 byte (traditionally)
	CPM	CLS,SUBFILE	;Write change to directory.
	INR	A		;Trouble?
	JZ	SUBERR
EXIT:				;Ok, all finished.
	POP	H		;Old SP
	SPHL			;Restore Stack
	RET			;to Console Command Processor
;
SUBERR:
	CALL	ABEND
	DB	'Error accessing .SUB file.'
	DB	'$'
;
NOTNUM	;Argument is not numeric
	CALL	ABEND
	DB	'//SKIP argument not numeric.'
	DB	'$'
;
RANGERR:
NELERR:
	CALL	ABEND
	DB	'//SKIP argument exceeds file size.'
	DB	'$'
;
ABEND:
	POP	D		;Message address
	CPM	MSG		;Send to console
	CPM	DEL,SUBFILE	;Abort the jobstream
	CPM	MSG,CANCEL
	JMP	BOOT
CANCEL:
	DB	'...CANCELED'
	DB	'$'
;
;
; Utility subroutines
;
HLXA:	;Index HL by the value of A. Returned flags not defined
	ADD	L
	MOV	L,A
	ADC	H
	SUB	L
	MOV	H,A
	RET
;
SCNB:	;Scan over leading blanks. Return char in A
	MOV	A,M
	CPI	' '
	RNZ
	INX	H
	JMP	SCNB
;
DCMP:	;Set borrow as for (HL)-(DE)
	MOV	A,H
	CMP	D
	RNZ
	MOV	A,L
	CMP	E
	RET
;
DSUB:	;Do HL:=(HL)-(DE). Return meaningful borrow flag
	MOV	A,L
	SUB	E
	MOV	L,A
	MOV	A,H
	SBB	D
	MOV	H,A
	RET
;
ISNUM:	;Return carry set if not ASCII decimal char 0-9.
	CPI	'0'
	RC
	CPI	'9'+1
	CMC
	RET
;
HMULT10:;Multiply HL by 10. Clobbers BC.
	MOV	B,H
	MOV	C,L
	DAD	B	;*2
	DAD	H	;*4
	DAD	B	;*5
	DAD	H	;*10
	RET
;
SUBFILE:	
	DB	1		;Drive A:
	DB	'$$$     SUB'
	DB	0,0,0,0
	DS	SUBFILE-$+36
;
	DS	20
LCLSTAK	EQU	$
;
	END	SKIPPROG

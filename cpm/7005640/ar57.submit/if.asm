 TITLE '//IF.ASM Conditional Processor for Submit'
VERSION	EQU	1$0
;
@MSG	SET	9
@VER	SET	12
@OPN	SET	15
@CLS	SET	16
@DEL	SET	19
@FRD	SET	20
@CUR	SET	25
@DMA	SET	26
@SIZ	SET	35
;
CPMBASE	EQU	0
BOOT	SET	CPMBASE
BDOS	SET	BOOT+5
TFCB	EQU	BOOT+5CH
TFCB1	EQU	TFCB
TFCB2	EQU	TFCB+16
TBUFF	EQU	BOOT+80H
TPA	EQU	BOOT+100H
CTRL	EQU	' '-1		;Ctrl char mask
CR	SET	CTRL AND 'M'
LF	SET	CTRL AND 'J'
TAB	SET	CTRL AND 'I'
FALSE	SET	0
TRUE	SET	NOT FALSE
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
;--------------------------------------------------------------
IFPROG:	ORG	TPA
	JMP	PASTC
	DB	' Ver:'
	DB	VERSION/10+'0'
	DB	'.'
	DB	VERSION MOD 10+'0'
	DB	' Copyright (c) 1982 Gary P. Novosielski '
	DB	CTRL AND 'Z'
PASTC:	LXI	H,0		;Clear HL
	DAD	SP		;Get stack pointer value
	LXI	SP,LCLSTAK	;Set local stack
	PUSH	H		;Save old SP on new stack.
;
; Scan the command buffer to find the option list
; which is defined as everything following the last
; colon on the line which is preceded by a space.
;
	LXI	H,TBUFF		;Point to command buffer
	MOV	A,M		;Get the count byte
	INR	A		;Character after the last...
	MOV	C,A		;(save in c)
	ADD	L		;...use as index into buffer
	MOV	L,A
	ADC	H
	SUB	L
	MOV	H,A
;
	MVI	M,0		;Insist on 0 terminator.
;				 It's there already, but
;				 not documented.
SRCHOP:	;Check for option list.
	DCR	C		;Out of characters?
	JZ	NOLIST		;No option list found.
	DCX	H		;Next previous character.
	MOV	A,M		;To accumulator
	CPI	':'		;Is it a colon?
	CZ	SRCH1		;If yes, check preceding space.
	JZ	FNDOPS		;Ok, found the option list.
	JMP	SRCHOP		;Else keep trying.
;
NOLIST:	MVI	A,TRUE
	STA	OPTN		;Treat as an option
	JMP	FINSCN
;
SRCH1:	;Check for preceding space.
	MOV	A,C		;Index to register A
	SUI	2		;At position 2 or better?
	RC			;Leading colon? Very strange.
	DCX	H		;Point to preceding character
	MOV	A,M		;Get it
	INX	H		;Point back to colon
	CPI	' '		;Was it a space?
	RET			;Return the flags
;
;
FNDOPS:	;The option list has been located.
	;Scan off the options and set bytes accordingly
SCNOPS:
	INX	H		;Point to next option char
	MOV	A,M		;Move it to A
	ORA	A		;if it's a zero...
	JZ	FINSCN		;there are no more
;
;	Check and set valid options
	CPI	'A'		;Try first possibility
	JNZ	NOTA		;Nope
	STA	OPTA		;Yes, set option flag
	JMP	SCNOPS		;Do remaining options.
NOTA:
	CPI	'C'		;Try next possibility
	JNZ	NOTC		;Nope
	STA	OPTC		;Yes, set option flag
	JMP	SCNOPS		;Do remaining options.
NOTC:
	CPI	'D'		;Try next possibility
	JNZ	NOTD		;Etc.
	STA	OPTD
	JMP	SCNOPS
NOTD:
	CPI	'E'
	JNZ	NOTE
	STA	OPTE
	JMP	SCNOPS
NOTE:
	CPI	'M'
	JNZ	NOTM
	STA	OPTM
	JMP	SCNOPS
NOTM:
	CPI	'P'
	JNZ	NOTP
	STA	OPTP
	JMP	SCNOPS
NOTP:
	CPI	'U'
	JNZ	NOTU
	STA	OPTU
	JMP	SCNOPS
NOTU:
	CPI	'0'
	JNZ	NOT0
	STA	OPT0
	JMP	SCNOPS
NOT0:
	CPI	'1'
	JNZ	NOT1
	STA	OPT1
	JMP	SCNOPS
NOT1:
	CPI	'2'
	JNZ	NOT2
	STA	OPT2
	JMP	SCNOPS
NOT2:
INVALID:
	STA	BADOPT		;Save the offender
	CPM	MSG,BADMSG	;Print the message
ABEND:
	CPM	DEL,SUBFILE	;Cancel the Jobstream
	CPM	MSG,CANMSG	;Print cancel message
	JMP	BOOT		;Boot the system
BADMSG:
	DB	'Option "'
BADOPT:	DB	0
	DB	'" not valid.'
	DB	'$'
CANMSG:
	DB	'...CANCELED'
	DB	'$'
;
FINSCN:	;The option list has been scanned
	;Now check the active ones in a logical order.
	LDA	OPTD		;Option D
	ORA	A		;if set means 
	CNZ	DRVSUB		;Drive substitution.
;
	LDA	OPTA		;Option A
	ORA	A		;if set means
	CNZ	CHKA		;Ambiguous spec required.
	JC	EVALFLS		;(false condition if not met)
;
	LDA	OPTU		;Option U
	ORA	A		;if set means
	CMC
	CNZ	CHKA		;Unambiguous spec required.
	JNC	EVALFLS		;(false if ambiguous)
;
	LDA	OPT0		;Option 0
	ORA	A		;if set means
	CNZ	CHK0		;drives must match
	JC	EVALFLS
;
	LDA	OPT1		;Option 1
	ORA	A		;if set means
	CNZ	CHK1		;names must match
	JC	EVALFLS
;
	LDA	OPT2		;Option 2
	ORA	A		;if set means
	CNZ	CHK2		;extensions (types) must match
	JC	EVALFLS
;
	LDA	OPTC		;Option C
	ORA	A		;if set means
	CNZ	CHKC		;Contents are required
	JC	EVALFLS
;
	LDA	OPTE		;Option E
	ORA	A		;if set means
	CNZ	CHKE		;Must be empty (or missing)
	JC	EVALFLS
;
	LDA	OPTP		;Option P
	ORA	A
	CNZ	CHKP		;Presence required (C or E)
	JC	EVALFLS
;
	LDA	OPTM		;Option M
	ORA	A
	CMC
	CNZ	CHKP		;must be Missing (not P)
	JNC	EVALFLS
;
	LDA	OPTN		;No option list means
	ORA	A
	CNZ	CHKN		;Any parm ok except blank
	JC	EVALFLS
EVALTRU:
	;The tests have all evaluated true.
	;Do the next line in the submit file
	;In other words, do nothing.
	;
EXIT:
	POP	H	;Old stack pointer
	SPHL		;Reset to entry stack
	RET		;Return to CCP
;
EVALFLS:
	;At least one test failed. Remove the next line from
	;the submit file.
	;
	CPM	OPN,SUBFILE	;Open the $$$.SUB file.
	INR	A		;Test return code.
	JZ	SUBERR		;Not within a .SUB file??
	LXI	H,SUBFILE+FCBRC	;Record counter for the extent
	DCR	M		; decreases by one.
	JM	SUBERR		;No following line??
 	DCX	H		;The S2 byte just below it
	MVI	M,0		; is zeroed. (traditionally)
	CPM	CLS,SUBFILE	;Write change to directory.
	INR	A		;Trouble?
	JZ	SUBERR
	JMP	EXIT		;Ok, all finished.
;
SUBERR:	;Something is wrong with the $$$.SUB file.
	;
	CPM	MSG,SUBMSG	;Inform user
	JMP	ABEND		;bail out.
SUBMSG:
	DB	'Error accessing .SUB file.'
	DB	'$'
;
;
; Here are the routines which do the actual condition checks.
; All of them return with the zero flag set if the condition
; tested is true, and with the carry flag set if false.
;
RETCY:	XRA	A
	SUI	1
	RET
;
DRVSUB:	;Not really a test, just move drive spec from
	;parm1 to parm2 for use in other tests
	;lda	tfcb1
	;sta	tfcb1
	;ret			;leave zero flag set
;
CHKA:	;see if parm1 is ambiguous
	LXI	H,TFCB1+1	;start at name
	MVI	A,'?'		;check for "?". No need to
				; check for * since CCP
				; has done expansion.
	MVI	C,8+3		;'xxxxxxxxyyy'
CHKA01:	CMP	M		;is this one a wildcard?
	RZ			;True return
	INX	H		;Point to next one
	DCR	C		;count down
	JNZ	CHKA01		;Keep testing till done.
	JMP	RETCY		;False return
;
CHK0:	;see if drives match.
	CPM	CUR		;Find out current default
	INR	A		;Drive A becomes 1
	MOV	D,A		;Default in D
	LDA	TFCB1
	ORA	A		;See if Parm1 says default
	JNZ	CHK001
	MOV	A,D		;Substitute current default
CHK001:	MOV	B,A		;Save Parm1 drive in B
	LDA	TFCB2
	ORA	A		;See if Parm2 says default
	JNZ	CHK002
	MOV	A,D
CHK002:	CMP	B		;compare with Parm 1
	RZ			;return true
	JMP	RETCY		;return false
;
CHK1:	;Compare name fields for a match.
	;
	LXI	H,TFCB1+1
	LXI	D,TFCB2+1
	MVI	C,8
CHK101: LDAX	D		;get parm2 char
	CPI	'?'		;chk wild
	JZ	CHK102		;treat as match
	MOV	B,A
	MOV	A,M		;get parm1 char
	CPI	'?'		;chk wild
	JZ	CHK102		;treat as match
	CMP	B		;compare 1 with 2
	JNZ	RETCY		;Return false
CHK102:	INX	D
	INX	H
	DCR	C
	JNZ	CHK101		;Ok so far, keep going
	XRA	A		;clear carry, set zero
	RET
;
CHK2:	;Compare filetypes as above
	;
	LXI	H,TFCB1+1+8
	LXI	D,TFCB2+1+8
	MVI	C,3		;Shorter length
	JMP	CHK101		; otherwise same algorithm
;
;
CHKP:	;Check directory for file
	;
	CPM	OPN,TFCB
	INR	A		;test return code
	JZ	RETCY		;return false 
	XRA	A		;else
	RET			;return true
;
CHKC:	;Check file contents
	;
	CALL	CHKA		;Ambiguity is meaningless
	JZ	RETCY
	CALL	CHKP		;Must be present, of course
	RC
CHKC01:	CPM	VER		;check version
	CPI	20H		;2.0 or better?
	JC	CHKC14		;No, can't use size function
CHKC20:	XRA	A
	STA	TFCB+FCBR2	;Clear high record byte
	CPM	SIZ,TFCB	;Compute file size
	LXI	H,TFCB+FCBR0
	MOV	A,M
	INX	H
	ORA	M
	INX	H
	ORA	M		;zero set if empty
	JZ	RETCY		;return false
 	XRA	A		;return true
	RET
CHKC14:	;Version 1.4 or older CP/M.  Just do a read.
	CPM	DMA,TBUFF
	CPM	FRD,TFCB	;Read Sequential
	ORA	A		;Test code
	RZ			;return true
	STC			;return false
	RET
;
CHKE:	;Check for empty file
	;
	CALL	CHKA		;Still must be unambiguous
	JZ	RETCY
	CALL	CHKP		;If missing, call it empty
	JC	RETZRO
	CALL	CHKC01		;check for contents
	JZ	RETCY		;return false (not empty)
	XRA	A
	RET			;return true  (empty)
;
CHKN:	;check for any hint of a parm1 entry
	;
	LDA	TFCB		;Point to drive spec
	ORA	A
	JNZ	RETZRO		;Return true for any drive
	LDA	TFCB+1	
	CPI	' '
	JNZ	RETZRO		;Return true for any name
	CPI	' '
	JZ	RETCY		;No type either.  False
RETZRO:	XRA	A
	RET
;
;+------------------------------+
;|	Working Storage		|
;+------------------------------+
;
OPTA:	DB	0
OPTC:	DB	0
OPTD:	DB	0
OPTE:	DB	0
OPTM:	DB	0
OPTN:	DB	0
OPTP:	DB	0
OPTU:	DB	0
OPT0:	DB	0
OPT1:	DB	0
OPT2:	DB	0
;
SUBFILE:
	;File Control Block for submit file.
	DB	1		;Drive A:
	DB	'$$$     SUB'
	DB	0,0,0,0
	DS	SUBFILE-$+36	;Remainder of 36 bytes
;
	;Local Stack area
	DS	20
LCLSTAK EQU	$
;
	END	IFPROG

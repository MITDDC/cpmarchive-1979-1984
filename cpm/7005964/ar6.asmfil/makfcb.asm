;++++++++++++++++++++++++++++++++++++++++++++++
;
; MAKE CP/M FILE CONTROL BLOCK
;
; MAKEFCB.LIB  -  Version 0.2  -  28 OCT 77
;
; JEFFREY W. SHOOK
; P.O. BOX 185
; ROCKY POINT, NEW YORK 11778
; (516) 744 7133
;
;++++++++++++++++++++++++++++++++++++++++++++++


; Create a CP/M file control block  from
; a command string at the address in HL
; and place it at the address in DE.  Return
; with the carry set if an error occurs.


; DEFINITIONS

FCBSIZ:	EQU	33
FNMLEN:	EQU	11	; File name length


MTFCB:	PUSH	H	; Save cmd string ptr
	PUSH	D	; Save FCB address
	
	LXI	B,FCBSIZ; Clear entire FCB area
	MVI	A,0	;
	CALL	FILLB	;

	POP	D	; Fill file name with spaces
	PUSH	D	;
	INX	D	;
	LXI	B,FNMLEN;
	MVI	A,' '	;
	CALL	FILLB	;

	POP	D	; Restore pointers
	POP	H	;

	CALL	SKIPS	; Skip leading spaces

	INX	H	; Check for disk code
	MOV	A,M	;
	DCX	H	;
	CPI	':'	;
	JNZ	MTFCB1	; Jump on no code

	MOV	A,M	; Test if disk code good
	INX	H	;
	INX	H	;
	SBI	'@'	;
	RC		; Make error return if bad
	CPI	'Z'+1	;
	CMC		;
	RC		;

	STAX	D	; Store disk code at FCB + 0
MTFCB1:	INX	D	;

	MVI	C,8	; Process file name field
	CALL	GETNAM	;

	MOV	A,M	; Test for file type separator
	INX	H	;
	CPI	'.'	;
	JNZ	MTFCB2	;

	MVI	C,3	; Process file type field
	CALL	GETNAM	;
	MOV	A,M	;
	INX	H	;

MTFCB2:	CALL	TERMT	; Test for corect terminator

	RET


; PROCESS NAME FIELD

GETNAM:	MOV	A,M	; Get char from cmd str
	INX	H	;

	CPI	'?'	; Allow ambig reference char
	JZ	GETNA1	;

	CPI	'*'	; Fill rest with ?
	JZ	GETNA2	;

	CALL	VALCHR	; Test for allowed char in name
	JC	GETNA3	;

GETNA1:	STAX	D	; Store char in TFCB
	INX	D	;

	DCR	C	; Check name size
	JNZ	GETNAM	;
	RET		;


GETNA2:	MVI	A,'?'	; Fill rest of field with ?
	MVI	B,0	;
	JMP	FILLB	;

GETNA3:	INX	D	; Move FCB ptr to end of field
	DCR	C	;
	JNZ	GETNA3	;
	DCX	H	;
	RET		;


; TEST FOR VALID CHAR IN  NAME FIELD
; Return with carry set if invalid.

VALCHR:	CPI	'*'
	CMC
	RZ

	CPI	','
	CMC
	RC

	CPI	'.'
	CMC
	RZ

	CPI	' '
	RC

	CPI	'^'+1
	CMC
	RC

	CPI	':'
	CMC
	RNC

	CPI	'@'
	RET


; TEST FOR VALID FILENAME TERMINATOR CHAR
; Return with carry set if invalid.

TERMT:	CPI	' '
	RZ

	CPI	','
	RZ

	CPI	CR
	RZ

	CPI	';'
	RZ

	STC
	RET


; SKIP SPACES IN CMD STRING

SKIPS:	MVI	A,' '
SKIPS1:	CPI	M
	RNZ
	INX	H
	JMP	SKIPS1


; FILL BLOCK WITH VALUE

; Enter with:
; A  = value for fill
; DE = start of block
; BC = length of block

CLRB:	MVI	A,0

FILLB:	INR	B
	DCR	B
	JNZ	FILLB1
	INR	C
	DCR	C
	RZ

FILLB1:	STAX	D

	INX	D
	DCX	B

	JMP	FILLB

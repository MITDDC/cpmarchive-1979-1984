;
;	Pass - Command to enable priviledged use of a ZCPR system
;		running under secure mode.
;		By Paul S. Traina -- OxGate Node 001 Sysop
;
;		Version 1.0 - 3/6/82
;
;	To run pass do the following:
;		A>PASS <password>  -  To enable wheel mode
;		A>PASS<cr>	   -  To enable wheel mode without
;		Password: <password>     any echo of password
;		A>PASS -	   -  To disable wheel mode manually
;
CR	EQU	0DH		;termination character
PSTRING	EQU	09H		;BDOS Print a string
ENABLE	EQU	0FFH		;this is poked into WHEEL
FCB	EQU	005CH		;file control block+1
BDOS	EQU	0005H		;bdos location
WHEEL	EQU	003EH		;location of wheel byte

	ORG	100H
;
SELECT:	LDA	FCB+1		;see what we are supposed to do
	CPI	' '		;don't echo pasword (someone looking over
	JZ	GETPASS		;your shoulder?)
	CPI	'-'		;disable wheel mode (become humble again)
	JZ	DISABLE
				;No, we have a JCL, so let's read it in...
COMPARE:
	LXI	H,PASSWD	;set up all the pointers
	LXI	D,FCB+1		;location of password buffer
	MVI	B,PRGEND-PASSWD	;number of characters of real password
CKPASS:	LDAX	D		;trial password to A
	CMP	M		;check for a match
	RNZ			;return to CCP (beware of skewed stacks)
	INX	H		;HL=HL+1
	INX	D		;DE=DE+1
	DCR	B		;B=B-1
	JNZ	CKPASS		;if B>0 then CKPASS
	MVI	A,ENABLE	;Set enable flag
PWOUT:	STA	WHEEL
	RET			;return to CCP (watch stack or else...)
;
DISABLE:
	XRA	A
	JMP	PWOUT
;
GETPASS:
	MVI	C,9
	LXI	D,PMSG
	CALL	BDOS
	LXI	H,FCB+1		;ok, use the fcb as a buffer
GETLOOP:
	PUSH	H		;save HL
LOOP1:	MVI	C,6		;use direct console i/o
	MVI	E,0FFH		;input a character
	CALL	BDOS		;get character into A
	ORA	A		;set flags
	JZ	LOOP1		;no character found, try again
	POP	H		;restore HL
	ANI	95		;lowercase to uppercase (indiscriminate but
				;effective)
	CPI	CR		;is it a <cr>?
	JZ	COMPARE
	MOV	M,A		;store character in fcb
	INX	H		;increment pointers
	JMP	GETLOOP		;loop until we get a <cr>
;
PMSG:	DB	'Password? $'
PASSWD:	DB	'YOURPW'	;Password shouldn't be more than 10 chars
				;or somethings may die exotically.
PRGEND:
;
	END

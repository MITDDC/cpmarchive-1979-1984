;
;	USER.ASM vers. 1.2
;	  by Ron Fowler
;	     Westland, Mich.
;
;
;	  revised 8/7/80
;
;     (FOR USE WITH CP/M-2.x ONLY)
; This program is used to restrict access
; to the higher user areas while  leaving
; the lower user areas public.	The high-
; est available public user area  is  de-
; fined by "MAXUSER".
;
;08/07/80 CORRECTED TO MAINTAIN REQUESTED
;	  USER NUMBER EVEN AFTER WARM BOOT.
;	  AND TO ALLOW NUMBERS HIGHER THAN
;	  9.  By Keith Petersen, W8SDZ.
;
;08/07/80 Replaced RAL instructions with RLC to 
;	  eliminate drive select error caused by
;	  rotating carry bit into accumulator.
;	  By Dave Hardy and Bruce Levison
;
;08/08/80 Modified for improved response time
;	 by calling the setusr function after
;	 modifying the drive byte at loc 4,
;	 bypassing the need to warm boot
;		By Ron Fowler
;
;
DFCB	EQU	5CH 
MAXUSER EQU	0	;for example
SETUSR	EQU	32	;set user in bdos
DRIVE	EQU	4
BDOS	EQU	5
;
	ORG	100H
;
	LXI	H,DFCB+1 ;POINT TO ORIGINATING USER # IN CMD LINE
	MVI	E,0
NUMLUP:
	MOV	A,M	;GET CHARACTER
	INX	H	;BUMP CHAR POINTER
	SUI	'0'	;REMOVE ASCII BIAS
	JC	NUMDONE
	CPI	10	;CHECK IF PAST 9
	JNC	NUMDONE ;ANY INVALID CHAR ENDS NUMBER
	MOV	D,A
	MOV	A,E	;GET ACCUMULATED NUMBER
	ADD	A	;TIMES TWO
	ADD	A	;TIMES FOUR
	ADD	E	;TIMES FIVE
	ADD	A	;TIMES TEN
	ADD	D	;PLUS NEW DIGIT
	MOV	E,A	;SAVE ACCUMULATION
	JMP	NUMLUP	;LOOP BACK FOR NEXT CHAR
;
NUMDONE:
	MOV	A,E	;GET ACCUMULATED NUMBER
	ORA	A	;BELOW ZERO OR ABOVE 127?
	JM	HUH	;INVALID CHARACTER ENTERED
	CPI	MAXUSER+1
	JNC	HUH	;RESTRICT ACCESS
	RLC ! RLC ! RLC ! RLC	;MOVE TO UPPER NIBBLE
	MOV	B,A	;SAVE REQUESTED USER NUMBER
	LDA	DRIVE	;GET CURRENT USER/DRIVE
	ANI	0FH	;STRIP OFF OLD USER NUMBER
	ORA	B	;GET NEW USER NUMBER
	STA	DRIVE	;SET NEW USER NUMBER
	MVI	C,SETUSR ;SET THE USER FOR NOW
	JMP	BDOS	;SET IT AND EXIT
;
HUH:	LXI	D,MSG
	MVI	C,9	;PRINT STRING FUNCTION
	JMP	BDOS	;PRINT & EXIT 
;
MSG:	DB	'Only USER 0-'
	DB	MAXUSER+30H
	DB	' available.$'
;
	END

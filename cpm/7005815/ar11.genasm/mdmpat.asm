;		MODEMPAT.ASM ver 1.0
;	      by Keith Petersen, W8SDZ
;		  (revised 4/25/82)
;
;This program moves alternate console and list
;drivers into high memory and then patches CP/M
;to use them instead of the regular CBIOS routines.
;These routines include poling of both the normal
;console port and an external serial port, allowing
;a modem to be connected to the system as a second
;console.  This program is not intended for automatic
;operation - just as a way to give temporary control
;of the system to the modem.  The patches will remain
;intact until the next cold boot.
;
;------------------------------------------------
;Change the following equate to an area in your high
;memory where the alternate console and list drivers
;may be located without interference to or from CP/M.
;
DEST	EQU	0FB80H	;RUNNING LOCATION OF CODE
;
;------------------------------------------------
;
;Define I/O ports and status bits
;
CRTS	EQU	20H	;CRT STATUS PORT
CRTD	EQU	21H	;CRT DATA PORT
CRTTBE	EQU	04H	;CRT TRANS. BUF. EMPTY
;
KBDS	EQU	0EH	;KBD STATUS PORT
KBDD	EQU	0CH	;KBD DATA PORT
KBDRDA	EQU	01H	;KBD RECEIVE DATA AVAIL.
;
MODSTA	EQU	02H	;MODEM STATUS PORT
MODDAT	EQU	03H	;MODEM DATA PORT
MODTBE	EQU	80H	;MODEM TRANS. BUF. EMPTY
MODRDA	EQU	40H	;MODEM RECEIVE DATA AVAIL.
;
NRNULL	EQU	9	;NUMBER OF NULLS NEEDED FOR MODEM
;
CR	EQU	0DH	;CARRIAGE RETURN
LF	EQU	0AH	;LINE FEED
NULL	EQU	00H	;NULL CHARACTER
BDOS	EQU	0005H	;BDOS ENTRY ADRS
;
	ORG	100H
;
;Move the console and list drivers up to high RAM
;
MOVEUP:	LXI	B,PEND-START+1		;NUMBER OF BYTES TO MOVE
	LXI	H,DEST+PEND-START+1	;END OF MOVED CODE
	LXI	D,SOURCE+PEND-START	;END OF SOURCE CODE
;
MVLP:	LDAX	D	;GET BYTE
	DCX	H	;BUMP POINTERS
	MOV	M,A	;NEW HOME
	DCX	D
	DCX	B	;BUMP BYTE COUNT
	MOV	A,B	;CHECK IF ZERO
	ORA	C
	JNZ	MVLP	;IF NOT, DO SOME MORE
;
;Now patch CP/M to use the new drivers
	LHLD	1		 ;GET CP/M JUMP TABLE ADRS
	LXI	D,4		 ;READY TO ADD 4
	DAD	D		 ;HL = CONSTAT + 1
;
	MVI	M,CSTAT AND 0FFH ;PATCH LSB OF JMP ADRS
	INX	H
	MVI	M,CSTAT SHR 8	 ;PATCH MSB JMP ADRS
;
	INX	H
	INX	H		 ;HL = CONIN + 1
	MVI	M,CONIN AND 0FFH ;PATCH LSB OF JMP ADRS
	INX	H
	MVI	M,CONIN SHR 8	 ;PATCH MSB JMP ADRS
;
	INX	H
	INX	H		 ;HL = CONOUT + 1
	MVI	M,CONOUT AND 0FFH ;MODIFY LSB JMP ADRS
	INX	H
	MVI	M,CONOUT SHR 8	 ;MODIFY MSB JMP ADRS
;
	INX	H
	INX	H		 ;HL = LISTOUT + 1
	MVI	M,LISOUT AND 0FFH ;MODIFY LSB JMP ADRS
	INX	H
	MVI	M,LISOUT SHR 8	 ;MODIFY MSB JMP ADRS
;
;Print message saying what has been done, then exit to CP/M
	LXI	D,MSG	;POINT TO MESSAGE
	MVI	C,9	;BDOS PRINT STRING FUNCTION
	JMP	BDOS	;PRINT MSG THEN RETURN TO CCP
;
MSG:	DB	'++Dual CONSOLE and MODEM '
	DB	'drivers now patched++',CR,LF,'$'
;
SOURCE	EQU	$	;BOUNDARY MEMORY MARKER
;
OFFSET	EQU	DEST-SOURCE	;RELOC AMOUNT
;-----------------------------------------------;
;	The following code gets moved		;
;	to high RAM located at "DEST"		;
;-----------------------------------------------;
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XX   C A U T I O N :  If modifying anything 	XX
;XX 	in this program from here on: 		XX
;XX  	A-L-L  labels MUST be of the form:	XX
;XX	LABEL	EQU	$+OFFSET		XX
;XX	in order that the relocation to high   	XX
;XX	RAM work successfully.  Forgetting to	XX
;XX	specify '$+OFFSET' will cause the pro-	XX
;XX	gram to JMP into whatever is currently	XX
;XX	in low memory, with unpredictable	XX
;XX	results.  Be careful....		XX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;
START	EQU	$+OFFSET
;
;This is the new dual console status routine
CSTAT	EQU	$+OFFSET
	IN	MODSTA	;GET MODEM STATUS
	ANI	MODRDA	;CHARACTER WAITING?
	MVI	A,0FFH	;IN CASE ONE IS
	RNZ		;RETURN IF CHAR WAITING
	IN	KBDS	;GET KEYBOARD STATUS
	ANI	KBDRDA	;CHARACTER WAITING?
	MVI	A,0
	RZ		;NO, RETURN WITH 0
	CMA		;ELSE MAKE IT 0FFH
	RET
;
;This is the new console input routine
CONIN	EQU	$+OFFSET
	IN	KBDS	;GET KEYBOARD STATUS
	ANI	KBDRDA	;CHARACTER WAITING?
	JZ	MDMIN	;NO, GO CHECK MODEM
	IN	KBDD	;GET CHARACTER
	ANI	7FH	;STRIP PARITY
	JZ	CONIN	;IGNORE NULLS
	RET
;
;This is the new modem input routine
MDMIN	EQU	$+OFFSET
	IN	MODSTA	;GET MODEM STATUS
	ANI	MODRDA	;CHARACTER WAITING?
	JZ	CONIN	;NO, LOOP AND WAIT
	IN	MODDAT	;GET CHARACTER
	ANI	7FH	;STRIP PARITY
	JZ	CONIN	;IGNORE NULLS
	RET
;
;This is the new console output routine
CONOUT	EQU	$+OFFSET
	IN	CRTS	;GET CRT STATUS
	ANI	CRTTBE	;READY FOR CHARACTER?
	JZ	CONOUT	;NO, LOOP AND WAIT
	MOV	A,C	;GET CHARACTER
	ANI	7FH	;STRIP PARITY
	RZ		;IGNORE NULLS
	CPI	7FH	;RUBOUT?
	RZ		;YES, IGNORE IT
	OUT	CRTD	;ELSE SEND TO CRT
;
;This is the new modem output routine
MDMOUT	EQU	$+OFFSET
	IN	MODSTA	;GET MODEM STATUS
	ANI	MODTBE	;READY FOR CHARACTER?
	JZ	MDMOUT	;NO, LOOP AND WAIT
	MOV	A,C	;GET CHARACTER
	ANI	7FH	;STRIP PARITY
	OUT	MODDAT	;SEND TO MODEM
	CPI	LF	;WAS IT A LINE FEED?
	RNZ		;NO, RETURN
;
;Send NULL to modem to allow time for carriage to return
	PUSH	B	;SAVE LINE FEED
	MVI	B,NRNULL ;NUMBER OF NULLS
;
NULOOP	EQU	$+OFFSET
	MVI	C,NULL	;GET A NULL
	CALL	MDMOUT	;SEND IT TO MODEM
	DCR	B	;ANY MORE TO SEND?
	JNZ	NULOOP	;YES, GO SEND MORE
	POP	B	;RESTORE LINE FEED
	RET
;
LISOUT	EQU	$+OFFSET
	RET		;LIST OUTPUT DISABLED
;
PEND	EQU	$+OFFSET ;END OF RELOCATED CODE
;
ENDMARK	EQU	$+OFFSET ;! IGNORE ERROR MESSAGE
;
	END

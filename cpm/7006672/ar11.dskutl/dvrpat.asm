;		DVRPATCH.ASM ver 1.0
;	      by Keith Petersen, W8SDZ
;		  (revised 3/14/81)
;
;This program moves alternate console and list
;drivers into high memory and then patches CP/M
;to use them instead of the regular CBIOS routines.
;The patches will remain intact until the next
;cold boot.
;
;Why this is useful: if your console and/or list
;drivers are too long to fit into your CBIOS, this
;program can be used to patch them in after CP/M is
;booted.  Another use might be when some special
;drivers are temporarily needed, such as allowing
;a modem port to be patched in so it is the console
;or the list device.
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
CRTRDY	EQU	04H	;CRT TRANS. BUF. EMPTY
KBDS	EQU	0EH	;KBD STATUS PORT
KBDD	EQU	0CH	;KBD DATA PORT
KBDRDY	EQU	01H	;KBD RECEIVE DATA AVAIL.
LISTS	EQU	02H	;LIST STATUS PORT
LISTD	EQU	03H	;LIST DATA PORT
LISRDY	EQU	80H	;LIST TRANS. BUF. EMPTY
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
MSG:	DB	'++Alternate CONSOLE and LIST '
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
;This is the new console status routine
CSTAT	EQU	$+OFFSET
	IN	KBDS	;GET KEYBOARD STATUS
	ANI	KBDRDY	;CHARACTER WAITING?
	MVI	A,0
	RZ		;NO, RETURN WITH 0
	CMA		;ELSE MAKE IT 0FFH
	RET
;
;This is the new console input routine
CONIN	EQU	$+OFFSET
	IN	KBDS	;GET KEYBOARD STATUS
	ANI	KBDRDY	;CHARACTER WAITING?
	JZ	CONIN	;NO, LOOP AND WAIT
	IN	KBDD	;GET CHARACTER
	ANI	7FH	;STRIP PARITY
	JZ	CONIN	;IGNORE NULLS
	RET
;
;This is the new console output routine
CONOUT	EQU	$+OFFSET
	IN	CRTS	;GET CRT STATUS
	ANI	CRTRDY	;READY FOR CHARACTER?
	JZ	CONOUT	;NO, LOOP AND WAIT
	MOV	A,C	;GET CHARACTER
	ANI	7FH	;STRIP PARITY
	RZ		;IGNORE NULLS
	CPI	7FH	;RUBOUT?
	RZ		;YES, IGNORE IT
	OUT	CRTD	;ELSE SEND TO CRT
	RET
;
;This is the new list output routine
LISOUT	EQU	$+OFFSET
	IN	LISTS	;GET LIST STATUS
	ANI	LISRDY	;READY FOR CHARACTER?
	JZ	LISOUT	;NO, LOOP AND WAIT
	MOV	A,C	;GET CHARACTER
	ANI	7FH	;STRIP PARITY
	OUT	LISTD	;SEND TO PRINTER
	CPI	LF	;WAS IT A LINE FEED?
	RNZ		;NO, RETURN
;
;Send NULL to printer to allow time for carriage to return
	MVI	C,NULL	;GET A NULL
	CALL	LISOUT	;SEND IT TO PRINTER
	MVI	C,LF	;RESTORE LINE FEED
	RET
;
PEND	EQU	$+OFFSET ;END OF RELOCATED CODE
;
	END

;		    FILTER.ASM ver 1.1
;		 by Keith Petersen, W8SDZ
;	     	     (revised 1/27/81)
;
;This program copies any ASCII file and filters out (ignores)
;all control characters except CR, LF, and TAB.  It also sets
;the high order bit of all characters to zero so that files
;created with WordStar or other text processing programs can
;be read by MBASIC.  The filtered copy of the of the file is
;created as 'FILTER.FIL' on the default drive.  The source
;file is left intact.  If the original file's EOF (1AH) is
;not at the physical end of the last sector, this program
;will pad the last sector with EOF's.  This is useful for
;'cleaning up' a file which was originally created by MBASIC
;or text editors which do not pad the last sector with EOF's.
;
;Command: FILTER [drive:]<filename.filetype>
;
;Define write buffer size
;
BSIZE	EQU	1024*16	;<--NOW SET FOR 16k
;
;BDOS equates
;
WBOOT	EQU	0	;WARM BOOT ENTRY ADRS
WRCON	EQU	2	;WRITE CHARACTER TO CONSOLE
BDOS	EQU	5	;CP/M BDOS ENTRY ADRS
PRINT	EQU	9	;PRINT STRING (DE) UNTIL '$'
OPEN	EQU	15	;OPEN DISK FILE
READ	EQU	20	;READ SEQUENTIAL FILE
STDMA	EQU	26	;SET DMA ADDRESS
FCB	EQU	5CH	;DEFAULT FILE CONTROL BLOCK
;
;Program starts here
;
	ORG	100H
;
	MACLIB	SEQIO	;NAME OF MACRO LIBRARY USED
;
START:	LXI	SP,STACK  ;SET STACK POINTER
	CALL	ILPRT	;PRINT:
	DB	CR,LF,'FILTER ver 1.1 - '
	DB	'ASCII file filter utility',CR,LF,CR,LF,0
	LDA	FCB+1
	CPI	' '	;FILENAME THERE?
	JNZ	OPENIT	;YES, GO OPEN IT
	CALL	EXIT	;PRINT MSG THEN EXIT
	DB	'Usage: FILTER [drive:]<filename.filetype>',CR,LF
	DB	CR,LF,'       [ ] = optional, < > = required$'
;
;Open source file
;
OPENIT:	LXI	D,FCB
	MVI	C,OPEN
	CALL	BDOS
	INR	A	;CHECK FOR NO OPEN
	JNZ	DECFIL	;NO ERROR, CONTINUE
	CALL	EXIT
	DB	'++SOURCE FILE NOT FOUND++$'
;
;'Declare' output file
;
DECFIL:	FILE	OUTFILE,OUTPUT,,FILTER,FIL,BSIZE
	CALL	ILPRT	;PRINT:
	DB	'Input and output files open',CR,LF,CR,LF,0
;
;Read sector from source file
;
READLP:	LXI	D,80H
	MVI	C,STDMA
	CALL	BDOS
	LXI	D,FCB
	MVI	C,READ
	CALL	BDOS
	ORA	A	;READ OK?
	JZ	WRDISK	;YES, SEND IT TO OUTPUT
	CPI	1	;END-OF-FILE?
	JZ	TDONE	;TRANSFER DONE, CLOSE, EXIT
	CALL	ERXIT
	DB	'++SOURCE FILE READ ERROR++$'
;
;Write sector to output file (with buffering)
;
WRDISK:	LXI	H,80H	;READ BUFFER ADRS
;
WRDLOP:	MOV	A,M	;GET BYTE FROM READ BUFFER
	CPI	1AH	;END OF FILE MARKER ?
	JZ	TDONE	;TRANSFER DONE, CLOSE, EXIT
	ANI	7FH	;STRIP PARITY BIT
	CPI	7FH	;DEL (RUBOUT) ?
	JZ	IGNORE	;YES, IGNORE IT
	CPI	' '	;SPACE OR ABOVE?
	JNC	PUTCHR	;YES GO WRITE IT
	CPI	CR	;CARRIAGE RETURN ?
	JZ	PUTCHR	;YES GO WRITE IT
	CPI	LF	;LINE FEED ?
	JZ	PUTCHR	;YES GO WRITE IT
	CPI	TAB	;TAB CHARACTER ?
	JZ	PUTCHR	;YES, GO WRITE IT
;
;Ignore character and add one to ignore count
IGNORE:	PUSH	H	;SAVE INPUT BUFFER ADRS
	LHLD	DCOUNT	;GET DELETE COUNTER
	INX	H	;ADD ONE
	SHLD	DCOUNT	;SAVE NEW COUNT
	POP	H	;GET INPUT BUFFER ADRS BACK
	JMP	TSTEND	;IGNORE CHARACTER AND CONTINUE
;
;Write character to output buffer
;
PUTCHR:	PUSH	H	;SAVE INPUT BUFFER ADRS
	PUT	OUTPUT	;SEND TO DISK WRITE BUFFER
	POP	H	;GET INPUT BUFFER ADRS BACK
;
TSTEND:	INR	L	;DONE WITH SECTOR?
	JNZ	WRDLOP	;NO, GET ANOTHER BYTE
	JMP	READLP	;GO GET ANOTHER SECTOR
;
;Transfer is done - close destination file
;
TDONE:	FINIS	OUTPUT	;FLUSH BUFFERS, CLOSE
	CALL	ILPRT	;PRINT:
	DB	'Function complete - ',0
	LHLD	DCOUNT	;GET DELETED CHAR COUNT
	CALL	DECOUT	;PRINT IT
	CALL	EXIT	;PRINT MSG THEN EXIT
	DB	' characters deleted$'
;
;Erase the incomplete output file, then exit
;
ERXIT:	FINIS	OUTPUT	;CLOSE INCOMPLETE FILE
	ERASE	OUTPUT	;THEN ERASE IT
;
;Print message then exit to CP/M warm boot
;
EXIT:	POP	D	;GET MSG ADRS
	MVI	C,PRINT	;PRINT MESSAGE
	CALL	BDOS
	CALL	ILPRT	;PRINT CRLF
	DB	CR,LF,0
	JMP	WBOOT	;ASSURES UPDATE OF BIT MAP
;
;Inline print routine - prints string pointed to
;by stack until a zero is found.  Returns to caller
;at next address after the zero terminator.
;
ILPRT:	XTHL		;SAVE HL, GET MSG ADRS
;
ILPLP:	MOV	A,M	;GET CHAR
	CALL	TYPE	;OUTPUT IT
	INX	H	;POINT TO NEXT
	MOV	A,M	;TEST
	ORA	A	;..FOR END
	JNZ	ILPLP
	XTHL		;RESTORE HL, RET ADDR
	RET		;RET PAST MSG
;
;Send character in A register to console
;
TYPE:	PUSH	B
	PUSH	D
	PUSH	H
	MOV	E,A	;CHAR TO E FOR CP/M
	MVI	C,WRCON	;WRITE TO CONSOLE
	CALL	BDOS
	POP	H
	POP	D
	POP	B
	RET
;
;Decimal output - print HL as decimal
;number with leading zero suppression
;
DECOUT:	PUSH	B
	PUSH	D
	PUSH	H
	LXI	B,-10
	LXI	D,-1
;
DECOU2:	DAD	B
	INX	D
	JC	DECOU2
	LXI	B,10
	DAD	B
	XCHG
	MOV	A,H
	ORA	L
	CNZ	DECOUT
	MOV	A,E
	ADI	'0'
	CALL	TYPE
	POP	H
	POP	D
	POP	B
	RET
;
DCOUNT:	DW	0	;DELETED CHARACTER COUNTER
	DS	100	;ROOM FOR STACK
STACK	EQU	$	;STACK POINTER SET HERE
;
;Org write buffer to even page boundry
	ORG	($+255) AND 0FF00H
BUFFERS	EQU	$	;WRITE BUFFER STARTS HERE
;
	END

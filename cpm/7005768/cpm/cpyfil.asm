;
;		   COPYFILE.ASM ver 1.5
;		 by Keith Petersen, W8SDZ
;	     	     (revised 10/18/80)
;
;This program will copy files of any length from one drive to
;another, with up to 16k buffering.  It was created for very
;long files (megabyte length), which are not properly handled
;by CP/M 2.x PIP.  This version offers selective copying of
;files - something not available with PIP.  The destination
;files will have NO attributes set, which is useful for
;copying from CP/M 2.x to 1.4 disks.
;
;10/18/80 Modified to strip attributes from file name before
;	  creating new file (to eliminate BDOS error on R/O
;	  files on CP/M 2.x).  Corrected error in stack
;	  location.  (KBP)
;
;10/10/80 Modified to make compatible with CP/M 1.4 or 2.x.
;	  Added: echo to prompt input, allow upper or lower
;	  case answer, reask if improper answer, more comments
;	  to file. (KBP)
;
;10/09/80 Modified to allow operator to scan and select which
;	  files will be transfered if wildcard options are used.
;	  This will allow transfer of selected file from a full
;	  disk without having to transfer all files and then
;	  erase the ones that were not to be transfered.  Also
;	  modified to have transfers default to DIR files only
;	  and if files with SYS attribute are to be transfered the
;	  use of the /S option is required. (by Robert Arrington)
;
;COMMANDS:
;	COPYFILE [drive:]<filename.filetype> <destination drive:>[/S]
;;	Requires the use of the /S option if transfer
;	of files with SYS attribute is wanted.
;
;EXAMPLES:
;	COPYFILE MYFILE.ASM B:
;		gets MYFILE.ASM from default disk and copies to B:
;	COPYFILE A:MYFILE.ASM B:
;		gets MYFILE.ASM from A: and copies to B:
;	COPYFILE B:*.* A:
;		gets all files from B: and copies to A:
;		
;All normal ambiguous file names are allowed.
;
;DEFINE WRITE BUFFER SIZE
;	(presently set for 16k.  If you have less space
;	available in the TPA, reduce accordingly).
;
BSIZE	EQU	16*1024	;<--NOW SET FOR 16k
;
;BDOS/CBIOS EQUATES
;
WBOOT	EQU	0	;WARM BOOT ENTRY ADRS
RDCON	EQU	1	;READ CONSOLE (WITH ECHO)
WRCON	EQU	2	;WRITE CHARACTER TO CONSOLE
BDOS	EQU	5	;CP/M BDOS ENTRY ADRS
PRINT	EQU	9	;PRINT STRING (DE) UNTIL '$'
OPEN	EQU	15	;OPEN DISK FILE
SRCHF	EQU	17	;SEARCH DIR FOR FIRST OCCUR.
SRCHN	EQU	18	;SEARCH DIR FOR NEXT OCCUR.
READ	EQU	20	;READ SEQUENTIAL FILE
CDISK	EQU	25	;RETURN CURRENT DISK
STDMA	EQU	26	;SET DMA ADDRESS
FCB	EQU	5CH	;DEFAULT FILE CONTROL BLOCK
FCBEXT	EQU	FCB+12	;EXTENT BYTE IN FCB
FCBRNO	EQU	FCB+32	;RECORD NUMBER IN FCB
FCB2	EQU	6CH	;DEFAULT 2ND FILE CONTROL BLOCK
;
;	Program starts here
;
	ORG	100H
;
	MACLIB	SEQIO	;NAME OF MACRO LIBRARY USED
;
START:	LDA	FCB+1
	CPI	' '	;SEE IF FILENAME THERE
	JNZ	SIGNON
	CALL	ILPRT	;PRINT:
	DB	CR,LF,'++NO FILE NAME SPECIFIED++',0
	RET		;EXIT TO CP/M
;
SIGNON:	LXI	SP,STACK  ;SET STACK POINTER
	CALL	ILPRT	;PRINT:
	DB	CR,LF,'COPYFILE ver 1.5',CR,LF
	DB	'multiple file copy program',CR,LF,0
	LDA	FCB	;GET DRIVE NAME
	ORA	A	;SEE IF DEFAULT DRIVE
	CZ	GETDRV	;IF DEFAULT, GET DRIVE NAME
	STA	SRCDRV	;SAVE FOR LATER
	MOV	B,A	;SAVE FOR LATER COMPARE
	LDA	FCB2+2	;GET OPTION REQUEST
	CPI	'S'	;SYS FILES WANTED?
	JNZ	SNDDRV	;NO, SKIP SYS FLAG SET
	STA	SYS	;SET SYS FLAG
;
SNDDRV:	LDA	FCB2	;GET SECOND DRIVE NAME
	STA	DESTDR	;SAVE IT FOR LATER
	ORA	A	;SEE IF DEFAULT DRIVE
	JZ	ABORT	;DEFAULT NOT ALLOWED
	CMP	B	;SEE IF DRIVE NAMES THE SAME
	JNZ	MORE	;NOT THE SAME, CONTINUE
;
ABORT:	CALL	EXIT
	DB	'++DRIVE NAME ERROR++$'
;
GETDRV:	MVI	C,CDISK	;CURRENT DISK NAME REQUEST
	CALL	BDOS	;GET IT
	INR	A	;ADJUST FOR USE IN FCB
	RET
;
;Get file name from directory and put in FCB
;
MORE:	CALL	MFNAME	;SEE IF FILE IS IN DIRECTORY
	JNC	SYSTST	;ANOTHER FILE FOUND, GET IT
	LDA	MFFLG1	;NOTHING FOUND, CHECK...
	ORA	A	;... FIRST TIME FLAG
	JZ	DONE	;AT LEAST ONE WAS FOUND
	CALL	EXIT
	DB	'++FILE NOT FOUND++$'
;
DONE:	CALL	EXIT
	DB	CR,LF,'DONE$'
;
;Check if SYS files wanted
;
SYSTST:	LDA	SYS	;GET SAVED SYS FLAG
	CPI	'S'	;SYS WANTED?
	JZ	MOVNAM	;YES, CONTINUE
	LDA	SYSAT	;GET SYS ATTRIBUTE
	ANI	80H	;ISOLATE ATTR BIT
	JNZ	MORE	;IT'S SYS, IGNORE IT
;
;Move filename from FCB to FNAME and print it
;
MOVNAM:	LXI	H,FCB+1
	LXI	D,FNAME
	MVI	B,8	;8 CHARS IN FILE NAME
	CALL	MOVER
	LXI	H,FCB+9
	LXI	D,FNAME+9
	MVI	B,3	;3 CHARS IN FILE TYPE
	CALL	MOVER
	CALL	ILPRT	;PRINT:
	DB	CR,LF,'--> FILE: '
FNAME:	DB	'XXXXXXXX.XXX',CR,LF,0
	LDA	CFLAG	;GET CONTINUOUS MODE FLAG
	CPI	'C'	;IS IT SET?
	JZ	DCOUT	;YES, SKIP OPTION REQUEST
;
;Ask for options
;
REASK:	CALL	ASK	;PRINT:
	DB	'(T)ransfer, (S)kip, (Q)uit, (C)ontinuous ? $'
;
ASK:	POP	D	;GET MSG ADRS
	MVI	C,PRINT
	CALL	BDOS	;PRINT MSG
	MVI	C,RDCON	;GET ANSWER AND ECHO IT
	CALL	BDOS
	PUSH	PSW	;SAVE IT
	CALL	CRLF	;TURN UP A NEW LINE
	POP	PSW	;GET ANSWER BACK
	ANI	5FH	;MAKE IT UPPER CASE
	CPI	'T'	;TRANSFER?
	JZ	DCOUT	;YES, GO DO ONE
	CPI	'S'	;SKIP?
	JZ	MORE	;YES, IGNORE THIS FILE
	CPI	'C'	;CONTINUOUS?
	JZ	SETCM	;YES, SET CONTINOUS MODE
	CPI	'Q'	;QUIT?
	JNZ	REASK	;NONE OF ABOVE, ASK AGAIN
	CALL	EXIT
	DB	'++QUITTING++$'
;
;Set continuous mode
;
SETCM:	STA	CFLAG	;SAVE CONTINUOUS REQUEST
;
;'Declare' output file using FCB2
;
DCOUT	FILE	OUTFILE,DESTINATION,,2,,BSIZE
	CALL	ILPRT	;PRINT:
	DB	'File open on destination disk',0
;
;Open source file
;
	LXI	D,FCB
	MVI	C,OPEN
	CALL	BDOS
	INR	A	;CHECK FOR NO OPEN
	JNZ	READLP	;NO ERROR, CONTINUE
	CALL	ERXIT
	DB	'++CAN''T OPEN SOURCE FILE++$'
;
;Read sector from source disk
;
READLP:	LXI	D,80H
	MVI	C,STDMA
	CALL	BDOS
	LXI	D,FCB
	MVI	C,READ
	CALL	BDOS
	ORA	A	;READ OK?
	JZ	WRDISK	;YES, SEND IT TO DESTINATION
	CPI	1	;END-OF-FILE?
	JZ	TDONE	;TRANSFER DONE, CLOSE, EXIT
	CALL	ERXIT
	DB	'++FILE READ ERROR++$'
;
;Write sector to destination disk (with buffering)
;
WRDISK:	LXI	H,80H	;READ BUFFER ADRS
;
WRDLOP:	MOV	A,M	;GET BYTE FROM READ BUFFER
	PUSH	H
	PUT	DESTINATION ;SEND TO DISK WRITE BUFFER
	POP	H
	INR	L	;DONE WITH SECTOR?
	JNZ	WRDLOP	;NO, GET ANOTHER BYTE
	JMP	READLP	;GO GET ANOTHER SECTOR
;
;Transfer is done - close destination file,
;then go look for more files
;
TDONE:	FINIS	DESTINATION ;FLUSH BUFFERS, CLOSE
	CALL	ILPRT	;PRINT:
	DB	'File closed on destination disk now',0
	JMP	MORE	;GET ANOTHER FILE
;
;Erase the incomplete output file, then exit
;
ERXIT:	ERASE	DESTINATION
;
;Print message then exit to CP/M warm boot
;
EXIT:	POP	D	;GET MSG ADRS
	MVI	C,PRINT	;PRINT MESSAGE
	CALL	BDOS
	CALL	CRLF	;PRINT CRLF
	JMP	WBOOT
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
	CALL	CRLF	;TURN UP A NEW LINE
	XTHL		;RESTORE HL, RET ADDR
	RET		;RET PAST MSG
;
;Turn up a new line
;
CRLF:	MVI	A,CR	;CARRIAGE RETURN
	CALL	TYPE
	MVI	A,LF	;LINE FEED, FALL INTO 'TYPE'
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
;Multi-file access subroutine.  Allows processing
;of multiple files (i.e. *.ASM) from disk.  This
;routine builds the proper name in the FCB each
;time it is called. Carry is set if no more names
;can be found. The routine is commented in Pseudo
;code, each Pseudo code statement is in <<...>>
;
MFNAME:	;<<init DMA address and FCB>>
	MVI	C,STDMA
	LXI	D,80H
	CALL	BDOS
	XRA	A
	STA	FCBEXT
	STA	FCBRNO
;<<if first time>>
	LDA	MFFLG1
	ORA	A
	JZ	MFN01
;<<save the requested name>>
;Save original request
	LXI	H,FCB
	LXI	D,MFREQ
	MVI	B,12
	CALL	MOVER
	LDA	FCB
	STA	MFCUR	;SAVE DISK IN CURR FCB
;<<SRCHF requested name>>
	MVI	C,SRCHF
	LXI	D,FCB
	CALL	BDOS
;<<else>>
	JMP	MFN02
;
MFN01:	;<<SRCHF current name>>
	LXI	H,MFCUR
	LXI	D,FCB
	MVI	B,12
	CALL	MOVER
	MVI	C,SRCHF
	LXI	D,FCB
	CALL	BDOS
;<<SRCHN requested name>>
	LXI	H,MFREQ
	LXI	D,FCB
	MVI	B,12
	CALL	MOVER
	MVI	C,SRCHN
	LXI	D,FCB
	CALL	BDOS
;<<endif>>
MFN02:	;<<return carry if not found>>
	INR	A
	STC
	RZ
;<<move name found to CURR>>
	DCR	A
	ANI	3
	ADD	A
	ADD	A
	ADD	A
	ADD	A
	ADD	A
	ADI	81H
	MOV	L,A
	MVI	H,0
	PUSH	H	;SAVE NAME POINTER
	LXI	D,9	;READY TO ADD 9 TO...
	DAD	D	;...POINT TO SYS ATTR
	MOV	A,M	;GET IT
	STA	SYSAT	;SAVE FOR LATER
	POP	H	;GET NAME POINTER BACK
	PUSH	H	;SAVE IT AGAIN
	LXI	D,MFCUR+1
	MVI	B,11
	CALL	MOVER
;<<move name found to FCB>>
	POP	H
	LXI	D,FCB+1
	MVI	B,11
	CALL	MOVER
;<<make copy of name found to FCB2>>
	LXI	H,FCB+1
	LXI	D,FCB2+1
	MVI	B,11
	CALL	MOVER
;<<setup FCB>>
	XRA	A
	STA	FCBRNO	;ZERO RECORD NUMBER
	STA	FCBEXT	;ZERO EXTENT NUMBER
	STA	MFFLG1	;TURN OFF 1ST TIME SW
	LDA	SRCDRV	;GET SOURCE DRIVE NAME
	STA	FCB	;PUT IT IN FCB1
	LDA	DESTDR	;GET DESTINATION DRIVE NAME
	STA	FCB2	;PUT IT IN FCB2
;<<return>>
	RET
;------------------------------------------------
;
;Move subroutine - move (B) bytes from (HL) to (DE)
;
MOVER:	MOV	A,M
	ANI	7FH	;STRIP ATTRIBUTES
	STAX	D
	INX	H
	INX	D
	DCR	B
	JNZ	MOVER
	RET
;
CFLAG:	DB	0	;CONTINUOUS TRANSFER FLAG
SYS:	DB	0	;SYS FILE FLAG
SYSAT:	DB	0	;FILE SYS ATTRIBUTE STORED HERE
SRCDRV:	DB	0	;SOURCE DRIVE NAME SAVED HERE
DESTDR:	DB	0	;AND DESTINATION DRIVE NAME HERE
;
;Multi-file access work area
;
MFFLG1:	DB	1	;1ST TIME SW
MFREQ:	DS	12	;REQ NAME
MFCUR:	DS	12	;CURR NAME
;
	DS	100	;ROOM FOR STACK
STACK:	EQU	$	;STACK POINTER SET HERE
;
;Org write buffer to even page boundry
	ORG	($+255) AND 0FF00H
BUFFERS:EQU	$	;WRITE BUFFER STARTS HERE
;
	END
    
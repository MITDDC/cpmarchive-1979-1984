;		    MLIST.ASM - V4.2
;	       MULTIPLE FILE LIST UTILITY
;		by Keith Petersen, W8SDZ
;		   (revised 1/12/81)
;
;NOTE: REQUIRES 'MAC' AND SEQIO.LIB TO ASSEMBLE
;
;This program lists any size ASCII file by name, reading
;up to 16k of the file into memory at one time, in order
;to minimize disk activity during printout.  The output
;is "filtered" to trap out all control characters other
;than CR, LF, and TAB.  If optional 'P' command used,
;output also goes to list device (this is especially
;useful under submit).  Any form feeds in the file are
;passed on to the list device.
;
;Allows listing of multiple files by using normal CP/M
;ambiguous file names.  Before each file is printed, the
;FILENAME.TYPE is displayed.  If a non-printable file is
;encountered (such as .COM or .OBJ), skips to next file.
;
;Commands: MLIST B:MYFILE.DOC	;lists specified file
;	   MLIST *.ASM		;lists all ASM files
;	   MLIST *.ASM P	;same, also goes to list device
;
;Use CTL-S to pause, CTL-X to skip to next file, CTL-C to abort.
;Other characters are ignored.
;
;This program allows CP/M 1.4 users to have protected
;ASCII files on a remote system, provided that the CCP
;'REN' (rename) and 'TYPE' functions have been changed
;to some other characters and MLIST.COM has been renamed
;to TYPE.COM.  To protect a file, rename it so the last
;character of the file type is #.  Example: MYFILE.AS#
;
;CP/M 2.x users may use 'TAG.COM' to set the f1' attribute
;of a file, which will prevent this program from listing it.
;
;Modifications/revisions, listed in reverse order
;to minimize reading time:
;
;01/12/81 Added code to allow passing form feeds to list
;	  output.  Added trap for DEL (RUBOUT). (KBP)
;
;01/10/81 Added 'P' option so files can be printed on the
;	  list device.  This now allows selective printing
;	  of hard copy while running under submit.  (KBP)
;
;01/01/81 Added CTL-X skip to next file, direct console
;	  output with tab expansion and control character
;	  filter.  (KBP)
;
;09/21/80 Added test for SYS files, moved TAG test,
;	  removed extra OPEN of file. (KBP)
;
;09/20/80 Added ILPRT routine, revised messages, added new
;	  abort routine, added CP/M 2.x f1' protect test,
;	  cleaned up file. (KBP)
;
;09/09/80 Revised check for '.COM' and '.OBJ' files so
;	  during attempt to list multiple files these
;	  would not abort the routine. Modified to
;	  issue an error message and continue with the
;	  next valid file. Added check for '#' character
;	  as the last character in the file type indicat-
;	  ing the file was not for distribution. Routine
;	  issues an error message and continues. Added
;	  check for 'first time flag' to exit routine so
;	  if no file is found meeting the requested
;	  parameters, '++NOT FOUND++' is issued to the
;	  console. NOTE: This required modifying the manner
;	  in which 'MFFLG1' was handled.  By Jim Seymour
;
;05/27/80 Revised to abort on attempting to
;	  list a CP/M .COM file.  By Thomas Churbuck
;
FORMF	EQU	0CH	;FORM FEED CHAR.
;
	ORG	100H
;
	MACLIB	SEQIO	;DEFINE MACRO LIBRARY
;
START:	JMP	START2	;JMP AROUND IDENT
	DB	'MLIST.COM ver 4.2 01/12/81'
;
START2:	LXI	H,0
	DAD	SP	;GET OLD STACK
	SHLD	STACK	;SAVE IT
	LXI	SP,STACK ;SET NEW STACK
	LHLD	1	;POINT TO CP/M'S JMP TABLE
	LXI	D,3	;READY FOR ADD
	DAD	D	;HL=CONSTAT
	SHLD	CSTSC+1	;MODIFY CALL ADRS
	DAD	D	;HL=CONIN
	SHLD	CIC+1	;MODIFY CALL ADRS
	DAD	D	;HL=CONOUT
	SHLD	VCONOT+1 ;MODIFY CALL ADRS
	DAD	D	;HL=LISTOUT
	SHLD	VLIST+1	;MODIFY CALL ADRS
	CALL	ILPRT	;PRINT:
	DB	'MLIST ver 4.2 - Multiple file lister',CR,LF
	DB	'CTL-S pauses, CTL-X skips to next file, CTL-C aborts',0
	LDA	FCB2+1	;GET OPTION, IF ANY
	STA	PFLAG	;SAVE FOR LATER
	LDA	FCB+1
	CPI	' '	;FILENAME THERE?
	JNZ	MORE	;YES, SKIP ERROR EXIT
	CALL	ILPRT	;PRINT:
	DB	'Usage: MLIST [drive:]<filename.type> [P]'
	DB	CR,LF,CR,LF
	DB	'       < > = required, [ ] = optional, P = printer'
	DB	CR,LF
	DB	'       Ambiguous file names may be used.',0
	JMP	EXIT
;
;Get file name
;
MORE:	LXI	SP,STACK ;ASSURE VALID STACK
	XRA	A	;ZERO
	STA	TABCOL	;..THE COLUMN COUNTER
	CALL	MFNAME	;GET NEXT FILE NAME
	JNC	CKFIL	;ANOTHER FILE FOUND, PRINT IT
	LDA	MFFLG1	;NOTHING FOUND, CHECK...
	ORA	A	;... FIRST TIME FLAG
	JZ	DONE	;AT LEAST ONE WAS FOUND
	CALL	ILPRT	;PRINT:
	DB	'++FILE NOT FOUND++',0
	JMP	EXIT
;
DONE:	CALL	ILPRT	;PRINT:
	DB	'DONE',0
	JMP	EXIT
;
;Check for file protected by CP/M 2.x f1' attribute
;
CKFIL:	LDA	MFCUR+1	;POINT TO TAG FILE ATTR
	ANI	80H	;IS IT TAGGED?
	JZ	CKFIL2	;IF NOT, CONTINUE
;
PROXIT:	CALL	ILPRT	;PRINT:
	DB	'++FILE NOT FOR DISTRIBUTION, SORRY++',0
	JMP	MORE	;SEE IF ANOTHER
;
CKFIL2:	LDA	MFCUR+10 ;POINT TO SYS FILE ATTR
	ANI	80H	;IS IT SYS?
	JZ	MOVNAM	;IF NOT, CONTINUE
	JMP	PROXIT	;SYS FILE, CAN'T PRINT IT
;
;Move filename from FCB+1 to FNAME
MOVNAM:	LXI	H,FCB+1
	LXI	D,FNAME
	MVI	B,8
	CALL	MOVER
;Move filetype from FCB+9 to FNAME+9
	LXI	H,FCB+9
	LXI	D,FNAME+9
	MVI	B,3
	CALL	MOVER
;Print name of file being listed
	CALL	ILPRT	;PRINT:
	DB	CR,LF,'--> LISTING FILE: '
FNAME:	DB	'XXXXXXXX.XXX'
	DB	CR,LF,0
;
;Define source file:
;
;	INFILE	= Input file mode
;	DISKIN = Internal name
;	(NUL)	= Default disk drive
;	1	= First default name (TFCB)
;	(NUL)	=   "      "    type
;	16384	= Buffer size
;	DSKBUF	= Disk buffer area
;
	FILE	INFILE,DISKIN,,1,,16384,DSKBUF
;
;Check for file protected by a '#' as the last
;character in the filetype (i.e. MYFILE.AS#).
;
	LXI	H,FCB+11 ;POINT TO LAST CHAR IN FCB
	MOV	A,M	;GET IT
	ANI	7FH	;STRIP CP/M 2.x ATTR
	CPI	'#'	;PROTECTED FILE?
	JZ	PROXIT	;PROTECTED FILE, EXIT WITH MSG
;
;Check for .COM file, which can't be printed
;
	CPI	'M'	;WAS LAST CHAR AN 'M'?
	JNZ	OBJCHK	;IF NOT, CHK FOR '.OBJ' TYPE
	DCX	H
	MOV	A,M	;CHK NEXT
	ANI	7FH	;STRIP CP/M 2.x ATTR
	CPI	'O'	;AN 'O'?
	JNZ	READLP	;IF NOT IT'S OK TO PRINT
	DCX	H
	MOV	A,M	;WAS 'O', CHK NEXT CHAR
	ANI	7FH	;STRIP CP/M 2.x ATTR
	CPI	'C'	;'C' AS IN '.COM'?
	JNZ	READLP	;IF NOT, IT'S OK TO PRINT
	CALL	ILPRT	;PRINT:
	DB	'++CAN''T LIST A .COM FILE++',0
	JMP	MORE	;MORE TO PRINT?
;
;Check for .OBJ file, which can't be printed
;
OBJCHK:	CPI	'J'	;WAS LAST CHAR AN 'J' ?
	JNZ	READLP	;IF NOT, OK TO LIST
	DCX	H
	MOV	A,M	;MIGHT BE '.OBJ', CHK NEXT CHR
	ANI	7FH	;STRIP CP/M 2.x ATTR
	CPI	'B'	;IS IT A 'B'?
	JNZ	READLP	;IF NOT, LIST
	DCX	H
	MOV	A,M	;WAS, CHK FIRST CHAR
	ANI	7FH	;STRIP CP/M 2.x ATTR
	CPI	'O'	;'O' AS IN '.OBJ'?
	JNZ	READLP	;IF NOT, PRINT THE FILE, IF SO
	CALL	ILPRT	;PRINT:
	DB	'++CAN''T LIST AN .OBJ FILE++',0
	JMP	MORE	;MORE TO PRINT?
;
;Write the file to console
;
READLP:	GET	DISKIN	;GET CHARACTER FROM FILE
	CPI	EOF	;END OF FILE?
	JZ	MORE	;YES, MORE FILES TO PRINT?
	CALL	TYPE	;SEND CHAR TO CONSOLE
	CALL	CSTS	;KEY PRESSED?
	ORA	A
	CNZ	CKKB	;CHECK WHAT KEY
	JMP	READLP
;
;Get keyboard character and check for command
;
CKKB:	CALL	CI	;GET CHAR
	CPI	'S'-40H	;PAUSE?
	CZ	CI	;YES, GET NEXT CHAR
	CPI	'C'-40H	;ABORT?
	JZ	EXITA	;YES, PRINT ABORT MSG, EXIT
	CPI	'X'-40H	;SKIP?
	RNZ		;NO, CONTINUE LISTING
	CALL	ILPRT	;PRINT:
	DB	CR,LF,'++SKIPPING TO NEXT FILE++',0
	JMP	MORE	;SKIP TO NEXT FILE
;
;Get console status from CBIOS
;
CSTS:	PUSH	B
	PUSH	D
	PUSH	H
CSTSC:	CALL	$-$	;CHANGED BY INIT
	POP	H
	POP	D
	POP	B
	RET		;FROM "CSTS"
;
;Get console input from CBIOS
;
CI:	PUSH	B
	PUSH	D
	PUSH	H
CIC:	CALL	$-$	;CHANGED BY INIT
	POP	H
	POP	D
	POP	B
	RET		;FROM "CI"
;
;Inline print routine
;
ILPRT:	CALL	CRLF	;TURN UP A NEW LINE
	XTHL		;SAVE HL, GET MSG
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
CRLF:	MVI	A,CR	;GET A CARRIAGE RETURN
	CALL	TYPE
	MVI	A,LF	;GET A LINE FEED AND FALL INTO 'TYPE'
;
;Type character in A to console (with tab expansion).
;This is done via direct CBIOS call to prevent CP/M
;from evaluating input commands.  Output also goes to
;list device if 'P' option was specified.
;
TYPE:	PUSH	B
	PUSH	D
	PUSH	H
	ANI	7FH	;STRIP PARITY BIT OF CHAR
	CPI	7FH	;DEL (RUBOUT) ?
	JZ	TYPRET	;YES, IGNORE IT
	MOV	C,A	;CHAR TO C FOR OUTPUT ROUTINE
	CPI	TAB	;TAB CHAR?
	JNZ	TYPE2	;NO, SKIP TAB STUFF
;
TYPTAB:	MVI	A,' '	;GET A SPACE
	CALL	TYPE	;PRINT IT
	LDA	TABCOL	;GET PRESENT COLUMN
	ANI	7	;8 CHAR BOUNDRY?
	JNZ	TYPTAB	;NO, OUTPUT ANOTHER SPACE
	JMP	TYPRET	;DONE WITH TAB EXPANSION
;
;Filter out control characters to
;prevent garbage during view of file
;
TYPE2:	CPI	' '	;SPACE OR ABOVE?
	JNC	CONOUT	;YES, GO OUTPUT IT
	CPI	FORMF	;FORM FEED?
	JZ	TYPLST	;YES, SEND TO LIST ONLY
	CPI	CR	;CARRIAGE RETURN?
	JZ	CONOUT	;YES, GO OUTPUT IT
	CPI	LF	;LINE FEED?
	JNZ	TYPRET	;NO, IGNORE CHARACTER
;
;Call direct to CBIOS console output
;
CONOUT:	PUSH	B	;IN CASE CBIOS CLOBBERS IT
VCONOT:	CALL	$-$	;ADDR FILLED IN BY 'INIT'
	POP	B	;GET CHAR BACK
;
;Update column used in tab expansion
	MOV	A,C	;GET CHAR
	CPI	CR	;CARRIAGE RETURN?
	JNZ	TYPNCR	;NO, SKIP COLUMN ZERO STUFF
	XRA	A	;GET A ZERO
	STA	TABCOL	;RESET COLUMN NR.
	JMP	TYPLST	;EXIT
;
TYPNCR:	CPI	' '	;CTL CHAR?
	JC	TYPLST	;..NO CHANGE IN COL
	LDA	TABCOL	;GET COLUMN NR.
	INR	A	;ADD ONE
	STA	TABCOL	;SAVE NEW COUNT
;
TYPLST:	LDA	PFLAG	;GET PRINT FLAG
	CPI	'P'	;PRINT REQUESTED?
	CZ	LIST	;FROM C REG
;
TYPRET:	POP	H
	POP	D
	POP	B
	RET
;
LIST:	PUSH	B	;SAVE REGS
	PUSH	D
	PUSH	H
VLIST:	CALL	$-$	;MODIFIED BY INIT
	POP	H
	POP	D
	POP	B
	RET
;
;Move (B) bytes from (HL) to (DE)
;
MOVER:	MOV	A,M
	STAX	D
	INX	H
	INX	D
	DCR	B
	JNZ	MOVER
	RET
;
EXITA:	CALL	ILPRT	;PRINT:
	DB	CR,LF,'++ABORTED++',0
;
EXIT:	LXI	D,80H	;SET DMA ADDRESS TO NORMAL
	MVI	C,STDMA
	CALL	BDOS
	LHLD	STACK	;GET OLD STACK
	SPHL		;RESTORE IT
	RET		;RETURN TO CP/M
;
;Multi-file access subroutine.  Allows processing
;of multiple files (i.e. *.ASM) from disk.  This
;routine builds the proper name in the FCB each
;time it is called. Carry is set if no more names
;can be found. The routine is commented in Pseudo
;Code, each Pseudo Code statement is in <<...>>
;
;<<Init DMA addrress and FCB>>
MFNAME:	MVI	C,STDMA
	LXI	D,80H
	CALL	BDOS
	XRA	A
	STA	FCBEXT
	STA	FCBRNO
;<<IF first time>>
	LDA	MFFLG1
	ORA	A
	JZ	MFN01
;<<Save the requested name>>
	LXI	H,FCB
	LXI	D,MFREQ
	MVI	B,12
	CALL	MOVER
	LDA	FCB
	STA	MFCUR	;SAVE DISK IN CURR FCB
;<<Searchfirst requested name>>
	MVI	C,SRCHF
	LXI	D,FCB
	CALL	BDOS
	JMP	MFN02
;
;<<ELSE>>
;<<Searchfirst current name>>
MFN01:	LXI	H,MFCUR
	LXI	D,FCB
	MVI	B,12
	CALL	MOVER
	MVI	C,SRCHF
	LXI	D,FCB
	CALL	BDOS
;<<Searchnext requested name>>
	LXI	H,MFREQ
	LXI	D,FCB
	MVI	B,12
	CALL	MOVER
	MVI	C,SRCHN
	LXI	D,FCB
	CALL	BDOS
;<<ENDIF>>
;
;<<Return carry if not found>>
MFN02:	INR	A
	STC
	RZ
;<<Move name found to CURR>>
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
	LXI	D,MFCUR+1
	MVI	B,11
	CALL	MOVER
;<<Move name found to FCB>>
	POP	H	;RESTORE NAME POINTER
	LXI	D,FCB+1
	MVI	B,11
	CALL	MOVER
;<<Setup FCB>>
	XRA	A
	STA	FCBEXT
	STA	FCBRNO
	STA	MFFLG1	;TURN OFF 1ST TIME SW
;<<Return>>
	RET
;
;Temporary storage area
;
TABCOL:	DB	0	;COLUMN COUNTER
PFLAG:	DB	0	;PRINT REQUEST FLAG
MFFLG1:	DB	1	;1ST TIME SW
MFREQ:	DS	12	;REQUESTED NAME
MFCUR:	DS	12	;CURRENT NAME
;
	DS	64	;ROOM FOR STACK
STACK:	DS	2	;OLD STACK POINTER SAVED HERE
;
DSKBUF:	DS	16384	;16K BUFFER
;
;BDOS equates
;
OPEN	EQU	15
SRCHF	EQU	17
SRCHN	EQU	18
STDMA	EQU	26
BDOS	EQU	5
FCB	EQU	5CH 
FCB2	EQU	6CH
FCBEXT	EQU	FCB+12
FCBRNO	EQU	FCB+32
;
	END

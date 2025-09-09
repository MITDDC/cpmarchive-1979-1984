;	  DU.ASM  V7.7	Revised 7/07/81
;	DISK UTILITY - By Ward Christensen
;
;See DU.DOC for description and detailed instructions.
;
;This version of DU is compatible with CP/M 1.4 and 2.x
;and does not require alteration for various hardware
;configurations.  It adjusts itself automatically to
;the correct number of sectors, tracks, directory size,
;etc.  It has been tested on 5-1/4" and 8" floppy, and
;10 megabyte hard disk systems.
;
;Because of the automatic adaption feature, no conditional
;assembly options are included.  The only alteration that
;needs to be done is to use DDT to set the byte at 103h
;to zero for systems using a 2 mHz clock or non-zero for
;4 mHz clock.  This only affects the time delay used in
;the 'sleep' command.
;
;*************************************************
;*						 *
;*   This program has been heavily modified	 *
;* to allow it to work without modification	 *
;* on most versions of CP/M 1.4 and, hopefully,  *
;* all versions of CP/M 2.x.			 *
;*   If you have difficulty getting this program *
;* to run, AND if you are using CP/M 2.x, AND	 *
;* if you know your BIOS to be bug-free, leave	 *
;* a message on Technical CBBS of Dearborn,	 *
;* Michigan (313)-846-6127 with a description	 *
;* of the problem and a summary of your hard-	 *
;* ware configuration.				 *
;*   One known possible problem involves the	 *
;* system tracks on some systems, and results	 *
;* from the system sectors being skewed. There	 *
;* is NO way for a program executing under CP/M  *
;* to know about this.	This program assumes the *
;* standard convention of no skew being used on  *
;: the system tracks. This usually isn't a prob- *
;* lem because the SYSGEN program can be used to *
;* get the system from the disk so that it can	 *
;* be modified. 				 *
;*   This program should work under standard	 *
;* versions of CP/M 1.4.  The only requirement	 *
;* is that the BIOS "SETSEC" routine not modify  *
;* the sector number passed to it in the B	 *
;* register.  Again, system tracks with skewed	 *
;* sectors will be a problem.			 *
;*   If you add any features or make any useful  *
;* changes to this program, please modem a copy  *
;* to the above CBBS, so the currency of the	 *
;* program can be maintained.			 *
;*						 *
;*		Ron Fowler			 *
;*						 *
;*************************************************
;
;
;07/12/81 Merged DJH vers 7.6 and Bill Ernest ver 7.6
;	  to form new vers 7.7     (RGF)
;
;07/07/81 Added "Y" command to allow sectors to be written
;	  sequentially into memory starting at 3000H, for
;	  later recovery by DDT, etc.  (DJH)
;
;04/02/81 Added * to map showing multiple group assign-
;	  ment errors.	Fixed bug in getgrp record counw
;	  (William Ernest)
;
;01/23/81 Changed SETSEC to ignore high-order result of
;	  SECTRN if SPT<256.  This fixes some translation
;	  problems where the BIOS leaves garbage in H. (BRR)
;
;01/15/81 Changed labels to be no more than 6 characters
;	  long.  Moved stack.  Cleaned up file.  (KBP)
;
;01/13/81 Updated help messages for '#' and 'N' commands.
;	  Modified sign-on message.  (RGF)
;
;01/12/81 Fixed problem with sector translation under
;	  CP/M 1.4.  (RGF)
;
;01/11/81 Fixed problem with CP/M 1.4.	Added 'N' command.
;	  Hard-code 'FASTCLOCK' as a boolean at 103h.  Add
;	  fix for sector number being 0 in system tracks,
;	  as suggested by Keith Petersen, W8SDZ. Added '#'
;	  command and memory-full check. Changed login to
;	  position to directory track at every log.  This
;	  is necessary to set up the 'FIRST0' flag.  (RGF)
;
;01/08/81 Corrected error in MAP routine that caused map
;	  to fail when >255 groups allocated.  Changed
;	  'REPEAT' to allow up to 65535 repeats.  (RGF)
;
;01/06/81 Modified to allow use with ALL systems, without
;	  conditional assembly, thru use of disk parameter
;	  block.  By Ron Fowler, Westland, Mich.
;
;01/05/81 Modified '+' and '-' commands as follows:
;		1) + at end of disk now wraps to start
;		2) - at start wraps back to end
;		3) argument for + & - now good to 65535
;				(RGF)
;
;01/03/81 Modified logic in console status test to allow
;	  any non-zero value to indicate char waiting.
;			(RGF)
;
;01/02/81 Made compatible with MACRO80 assembler (labels
;	  made unique within 6 chars, and separated multi-
;	  statement lines).  (RGF)
;
;11/14/80 Corrected missing conditional in CLCSUB routine
;	  for MICROP or DIGDBL.  Cleaned up file.  (KBP)
;
;11/04/80 Forced write type 1 (pre-read and immediate write)
;	  so deblocking BIOS's don't mess up.  Ignore bit 7
;	  in = command unless <nn> form was used.  Display
;	  unprintables as <nn> in V command.  Show user no.
;	  in M command (will always be 00 for 1.4) and only
;	  print parentheses if E5 present.  (BRR)
;
;10/30/80 Fixed bug in backspace/control-X.  Corrected more
;	  bit-7 stuff.	Added 'U' command to change user no.
;	  under CP/M 2.x.  Added pauses in help file. (BRR)
;
;10/27/80 Added Thinkertoys DBL DENS, Micromation DBL DENS,
;	  Industrial Micro Systems DBL and QUAD DENS.
;	  Fixed several bit-7 problems in MAP and DUMP logic.
;	  Added control-X (CRT erase line) to command input
;	  logic.  (Bruce R. Ratoff, ACGNJ-SIG/M)
;
;09/16/80 Fix backspace in line enter routine, add MAXDIR
;	  equate, general cleanup of ASM file. (KBP)
;
;06/22/80 Put in 'Q' command.  Fix so 'P' (printer)
;	  mode outputs L/F's.  (WLC)
;
;05/21/80 Make sector, track, be decimal, not hex.
;	  Also dis-allow a read until positioned.
;	  (DU otherwise not in sync with CP/M)	(WLC)
;
;03/24/80 Mod for Micropolis, Digital Microsystems DD,
;	  and Northstar DD CP/M.  Trap out garbage
;	  during VIEW of file.	By Keith Petersen, W8SDZ
;
;02/24/80 Mod login command to not really do log, just
;	  drive select.  (WLC)
;
;02/12/80 Mod for heath CP/M.  (WLC)
;
;01/08/80 Reposition after 'M' command.  (WLC)
;
;01/07/79 Add VIEW command.  (WLC)
;
;01/06/80 Rewrite 'F' command.	(WLC)
;
;10/10/79 Save regs in BIOS calls, translate input to upper case
;	  add commands: < save sector
;			> restore sect
;			/ repeat
;	  allow change from-thru.  (WLC)
;
;02/25/79 Put sector read into 'S' command.  (WLC)
;
;11/26/78 Add disk # to login command.	(WLC)
;
;11/12/78 Add login command.  (WLC)
;
;08/06/78 Originally written to reconstruct blown
;	  disks on CBBS via remote access.  (WLC)
;
;
;		----------------
;Sorry for the lack of comments in the code 
;portion of this program - it was just hacked
;together to satisfy my needs, but lots of
;other people found it useful.	Its external
;documentation is good, but its sadly lacking
;comments on the instructions.	(WLC)
;		----------------
;
;System equates
;
BASE	EQU	0	;SET TO 4200H FOR HEATH OR TRS-80 ALTCPM
;
FCB	EQU	BASE+5CH
BDOS	EQU	BASE+5
PRINT	EQU	9
GVERS	EQU	12
RESETDK EQU	13
SELDK	EQU	14
SRCHF	EQU	17	;SEARCH FIRST
SUSER	EQU	32
GETDSK	EQU	25
GETDPB	EQU	31
;
TRNOFF	EQU	15	;CP/M 1.4 OFFSET FROM BASE
			;OF BDOS TO SECTRAN ROUTINE
SKWOFF	EQU	1AH	;CP/M 1.4 OFFSET TO SKEW TABLE
S2OFF	EQU	14	;OFFSET INTO FCB FOR S2 BYTE
DPBOFF	EQU	3AH	;CP/M 1.4 OFFSET TO DPB WITHIN BDOS
S2MASK	EQU	0FH	;MASK FOR EXTENDED RC BITS OF S2
DPBLEN	EQU	15	;SIZE OF CP/M 2.x DISK PARM BLOCK
;
;
;Define ASCII characters
;
CR	EQU	0DH	;CARRIAGE RETURN
LF	EQU	0AH	;LINE FEED
TAB	EQU	09H	;TAB
BS	EQU	08H	;BACKSPACE
;
	ORG	BASE+100H
;
	JMP	PASTCK	;JUMP OVER CLOCK BYTE AND I.D.
;
CLOCK:	DB	0	;<---PUT NON-ZERO HERE FOR 4 MHZ CLOCK
	DB	'DU.COM ver 7.7 7/12/81'
;
PASTCK: LHLD	BDOS+1	;GET POINTER TO BDOS ENTRY
	MVI	L,0	;SET HL=BASE OF BDOS
	SPHL		;PUT STACK THERE
	SHLD	SETSTK+1 ;SAVE FOR LATER LXI SP INSTR.
	MVI	C,GVERS ;GET CP/M VERSION NR
	CALL	BDOS
	MOV	A,H	;COMBINE THE TWO BYTE...
	ORA	L	;...VERSION NR FOR A FLAG
	STA	VER2FL	;SAVE IT
	LXI	H,3000H ;INITIALIZE "Y" COMMAND MEMORY POINTER
	SHLD	YNKADR
;
;Set up local jumps to BIOS
	LHLD	BASE+1	;WARM BOOT POINTER
	LXI	D,3	;READY FOR ADD
	DAD	D	
	SHLD	VCONST+1
	DAD	D
	SHLD	VCONIN+1
	DAD	D
	SHLD	VCONOT+1
	DAD	D
	SHLD	VLIST+1
	DAD	D	;PUNCH
	DAD	D	;RDR
	DAD	D
	SHLD	VHOME+1
	DAD	D
	SHLD	VSELDK+1
	DAD	D
	SHLD	VSETRK+1
	DAD	D
	SHLD	VSTSEC+1
	DAD	D
	SHLD	SETDMA+1
	DAD	D
	SHLD	VREAD+1
	DAD	D
	SHLD	VWRITE+1
	LDA	VER2FL
	ORA	A
	JZ	DOCPM1
	DAD	D	;LISTST
	DAD	D
	SHLD	VSCTRN+1
	JMP	HELLO
;
DOCPM1: LHLD	BDOS+1
	MVI	L,0	 ;BDOS ON PAGE BOUNDARY
	PUSH	H
	LXI	D,TRNOFF ;CP/M 1.4 SECTRAN ROUTINE OFFSET
	DAD	D
	SHLD	VSCTRN+1
	POP	H
	LXI	D,SKWOFF ;CP/M 1.4 SKEW TABLE OFFSET
	DAD	D
	SHLD	SECTBL	 ;SET UP SKEW TABLE POINTER
;
HELLO:	CALL	ILPRT
	DB	CR,LF,'DISK UTILITY ver 7.7',CR,LF
	DB	'Universal Version',CR,LF
	DB	CR,LF
	DB	'Type ? for help',CR,LF
	DB	'Type X to exit'
	DB	CR,LF,0
	CALL	GETSTP	   ;SET UP PARAMETERS
	LXI	H,BASE+80H ;TO INPUT BUFF
	MOV	A,M
	ORA	A
	JZ	PRMPTR	;NO COMMAND
;
;Got initial command, set it up
	MOV	B,A	;SAVE LENGTH
	DCR	B
	JZ	PRMPTR
	LXI	D,INBUF
	INX	H	;SKIP LEN
	INX	H	;SKIP ' '
	CALL	MOVE
	MVI	A,CR
	STAX	D
	LXI	H,INBUF
	JMP	PRMPTI
;
PRMPTR: XRA	A
	STA	QFLAG
	CALL	RDBUF
;
PRMPTI: MVI	A,255
	STA	TOGO	;LOOP COUNT FOR "/"
	STA	TOGO+1
;
PROMPT	EQU	$
SETSTK: LXI	SP,$-$	;MODIFIED AT INIT
	XRA	A	;ZERO 2-UP PRINT
	STA	TWOUP	;..SWITCH
	MVI	A,1
	STA	FTSW	;TELL SEARCH NOT TO INCR
	PUSH	H
	LXI	H,BASE+100H
	SHLD	BUFAD	;FOR RDBYTE
	POP	H
	CALL	CTLCS	;ABORT?
	JZ	PRMPTR	;..YES, READ BUFFER
;
;Do we have to position in directory after find?
	LDA	FINDFL
	ORA	A
	JNZ	POSDIR	;POSITION IN DIRECTORY
	MOV	A,M
	CPI	CR
	JZ	PRMPTR
	CPI	';'	;LOGICAL CR?
	INX	H
	JZ	PROMPT
	CALL	UPCASE
	STA	DUMTYP	;TYPE OF DUMP (A,D,H)
;
;Command dispatcher
;
	CPI	'+'	
	JZ	 PLUS
;
	CPI	'-'
	JZ	MINUS
;
	CPI	'='
	JZ	SEARCH
;
	CPI	'<'
	JZ	SAVE
;
	CPI	'>'
	JZ	RESTOR
;
	CPI	'#'
	JZ	STATS
;
	CPI	'?'
	JZ	HELP
;
	CPI	'A'
	JZ	DUMP
;
	CPI	'C'
	JZ	CHG
;
	CPI	'D'
	JZ	DUMP
;
	CPI	'F'
	JZ	POSFIL
;
	CPI	'G'
	JZ	POS
;
	CPI	'H'
	JZ	DUMP
;
	CPI	'L'
	JZ	LOGIN
;
	CPI	'M'
	JZ	MAP
;
	CPI	'N'
	JZ	NEWDSK
;
	CPI	'P'
	JZ	PRNTFF
;
	CPI	'Q'
	JZ	QUIET
;
	CPI	'R'
	JZ	DOREAD
;
	CPI	'S'
	JZ	POS
;
	CPI	'T'
	JZ	POS
;
	CPI	'U'	;******CP/M 2.x ONLY******
	JZ	USER
;
	CPI	'V'
	JZ	VIEW
;
	CPI	'W'
	JZ	DORITE
;
	CPI	'X'
	JZ	BASE
;
	CPI	'Y'
	JZ	YANK
;
	CPI	'Z'
	JZ	SLEEP
;
	CPI	'/'
	JZ	REPEAT
;
WHAT:	XRA	A
	STA	QFLAG
	CALL	ILPRT
	DB	'?',0
	JMP	PRMPTR
;
;Memory full error
;
MEMFUL: XRA	A
	STA	QFLAG
	CALL	ILPRT
	DB	'+++ Out of memory +++'
	DB	CR,LF,0
	JMP	PRMPTR
;
;Print disk statistics
;
STATS:	PUSH	H
	CALL	ILPRT
	DB	'Disk Information:',CR,LF
	DB	'Tracks:',9,9,0
	LHLD	MAXTRK
	INX	H
	CALL	DEC
	CALL	ILPRT
	DB	CR,LF,'Sec/trk:',9,0
	LHLD	SPT
	CALL	DEC
	CALL	ILPRT
	DB	CR,LF,'Grpsize:',9,0
	LDA	BLM
	INR	A
	MOV	L,A
	MVI	H,0
	CALL	DEC
	CALL	ILPRT
	DB	' (sectors per group)',CR,LF
	DB	'Tot grps:',9,0
	LHLD	DSM
	CALL	DEC
	CALL	ILPRT
	DB	CR,LF,'Dir entries:',9,0
	LHLD	DRM
	INX	H
	CALL	DEC
	CALL	ILPRT
	DB	CR,LF,'Sys tracks:',9,0
	LHLD	SYSTRK
	CALL	DEC
	CALL	CRLF
	POP	H
	JMP	PROMPT
;
;The following command resets the disk
;system thru CP/M, and may be usable for
;changing the disk density or format.
;This can only be done if your BIOS resets
;the auto-density select parameters at
;every track-zero access.
;
NEWDSK: PUSH	H
	MVI	C,RESETDK
	CALL	BDOS
	LDA	DRIVE
	MOV	C,A
	POP	H
	CALL	SELECT
	JMP	PROMPT
;
;Quite mode
;
QUIET:	STA	QFLAG	;NOW QUIET
	JMP	PROMPT
;
;Repeat buffer contents
;
REPEAT: CALL	DECIN	;NN SPECIFIED?
	MOV	A,D
	ORA	E
	JZ	NNN	;NO.
	LHLD	TOGO
	INX	H	;TEST FOR FIRST TIME
	MOV	A,H
	ORA	L	;WAS IT 0FFFFH?
	JNZ	NNN	;NO: COUNTING
	XCHG		;GET COUNT
	SHLD	TOGO	;SET COUNT
;
NNN:	LHLD	TOGO
	XCHG
	LXI	H,INBUF ;READY TO REPEAT
	INX	D	;TEST FOR 0FFFFH
	MOV	A,D
	ORA	E
	JZ	PROMPT	;CONTINOUS
	DCX	D	;COUNT DOWN
	DCX	D	;MAKE UP FOR PREV INX D
	XCHG
	SHLD	TOGO
	MOV	A,H	;ALL DONE?
	ORA	L
	XCHG		;GET BACK INBUF PTR
	JNZ	PROMPT	;NO, KEEP GOING
	JMP	PRMPTR	;ALL DONE
;
;Set CP/M 2.x user number
;
USER:	LDA	VER2FL
	ORA	A
	JZ	WHAT
	CALL	DECIN		;GET REQUESTED USER NO.
	MOV	A,E
	CPI	32		;VALID?
	JNC	WHAT
	MOV	A,D
	ORA	A
	JNZ	WHAT
	MVI	C,SUSER
	PUSH	H		;SAVE CHAR POINTER
	CALL	BDOS		;SET USER NO.
	POP	H
	JMP	PROMPT
;
;Toggle print flag
;
PRNTFF: LDA	PFLAG
	XRI	1
	STA	PFLAG
	JMP	PROMPT
;
;Sleep routine, in tenths of a sec
;
SLEEP:	CALL	HEXIN	;GET COUNT IF ANY
	MOV	A,E	;ANY?
	ORA	A
	JNZ	SLEPLP
	MVI	E,10
;
SLEPLP: LXI	B,8000	;APPROX .1 SEC @ 2MHz
	LDA	CLOCK
	ORA	A
	JZ	SLEEP2
	LXI	B,16000 ;APPROX .1 SEC @ 4 MHz
;
SLEEP2: DCX	B
	MOV	A,B
	ORA	C
	JNZ	SLEEP2
	PUSH	D
	CALL	CTLCS
	POP	D
	JZ	PRMPTR
	DCR	E
	JNZ	SLEPLP
	JMP	PROMPT
;
;Check for control-C or S
;
CTLCS:	CALL	CONST
	ORA	A
	JNZ	GETC
	ORI	1	;NO CHAR, RETN NZ
	RET
;
GETC:	CALL	CONIN
	ANI	1FH	;ALLOW ASCII
	CPI	'S'-40H
	CZ	CONIN
	CPI	'C'-40H
	RET		;0 SET IF CTL-C
;
;Find our way at initialization
;
GETSTP: MVI	C,GETDSK
	CALL	BDOS	;GET CURNT DSK
	MOV	C,A	;  WE HAVE TO SELECT
	JMP	SELECT	;  TO GET THE DPH
;
LOGIN:	CALL	DOLOG
	JMP	PROMPT
;
DOLOG:	MOV	A,M	;DISK REQ?
	LXI	D,0
	CPI	CR
	JZ	LGNODK
	CPI	';'
	JZ	LGNODK
	CALL	UPCASE
	INX	H
	SUI	'A'
	MOV	C,A
;
SELECT: PUSH	H
	MOV	A,C
	STA	DRIVE	;REMEMBER LATER WHERE WE ARE
;
VSELDK: CALL	$-$	;ADDR FILLED IN BY 'INIT'
	LDA	VER2FL
	ORA	A	;IF NOT CP/M 2.x ...
	JZ	SELSKP	;..THEN SKIP THIS JUNK
	MOV	A,H
	ORA	L
	JZ	WHAT	;SELECT ERROR
	MOV	E,M	;GET THE SECTOR TABLE PNTR
	INX	H
	MOV	D,M
	INX	H
	XCHG
	SHLD	SECTBL
	LXI	H,8	;OFFSET TO DPBPTR
	DAD	D
	MOV	A,M	;PICK UP DPB POINTER
	INX	H	;  TO USE
	MOV	H,M	;  AS PARAMETER
	MOV	L,A	;  TO LOGIT
;
SELSKP: CALL	LOGIT
	LHLD	SYSTRK	;RESET TRACK AND SECTOR
	XCHG		;  TO DIRECTORY
	CALL	SETTRK	;  ON EVERY
	LXI	D,1	;  LOGIN
	CALL	SETSEC	;  CHANGE
	LHLD	PHYSEC	;THIS LOGIC WILL TELL
	MOV	A,H	;  IF FIRST SEC
	ORA	L	;  IS PHYSICAL 0
	STA	FIRST0
	CALL	CLCSUB
	POP	H
;
LGNODK: CALL	NORITE
	RET
;
;Read in the disk directory
;
REDDIR: PUSH	H
	CALL	NORITE	;POSITIONING LOST
	LHLD	SYSTRK
	SHLD	CURTRK
	LXI	H,1
	SHLD	CURSEC
	LHLD	DRM	;GET DIR SIZE FROM DPB
	INX	H	;MAKE 1-RELATIVE
	CALL	ROTRHL
	CALL	ROTRHL	;DIVIDE BY 4 (4 NAMES/SECTOR)
	MOV	B,H
	MOV	C,L
	LXI	D,DIRECT ;DMA ADDR
;
RDIRLP: PUSH	B
	PUSH	D
	MOV	B,D
	MOV	C,E
	LDA	BDOS+2	;CHECK MEM AVAIL
	DCR	A
	CMP	D
	JC	MEMFUL
	CALL	SETDMA
	LHLD	CURTRK
	XCHG
	CALL	SETTRK
	LHLD	CURSEC
	XCHG
	CALL	SETSEC
	CALL	READ
	CALL	NXTSEC
	POP	D
	POP	B
	LXI	H,80H
	DAD	D
	XCHG
	DCX	B
	MOV	A,B
	ORA	C
	JNZ	RDIRLP
	LXI	B,BASE+80H
	CALL	SETDMA
	POP	H
	RET
;
;Map the directory
;
MAP:	CALL	REDDIR	;READ IN DIRECTORY
	MVI	C,0	;INIT START GRP #
	LDA	AL0	;READ DIR GRP BITS
	CALL	COLECT	;COLLECT COUNT OF DIR GRPS..
	LDA	AL1	;..IN REGISTER C
	CALL	COLECT
	MVI	B,0	;BC NOW HAS A DEFAULT START GRP #
	CALL	HEXIN
	PUSH	H	;SAVE INBUF PTR
	MOV	A,E	;GET START
	ORA	D	;NOTHING?
	JZ	MAPDF	;..YES, DFLT
	MOV	B,D
	MOV	C,E
;
MAPDF:	CALL	HEXB
	MVI	A,'-'
	CALL	TYPE
	MVI	A,' '
	STA	DUPFLG
	CALL	GETGRP	;GET GRP(C) TO HL
;
MAPCNT: INX	B	;NEXT GRP #
	PUSH	H
	LHLD	DSM	;GET HIGHEST GRP #
	INX	H	;PLUS 1 FOR COMPARISON
	MOV	A,L	;WHEN BC REACHES DSM+1..
	CMP	C	;..THEN WE HAVE EXCEEDED..
	JNZ	MAPC1	;..THE DISK CAPACITY..
	MOV	A,H
	CMP	B
;
MAPC1:	POP	H
	JZ	MAPEND	;..AND WE ARE DONE
	PUSH	H
	CALL	GETGRP	;GET ANOTHER
	POP	D	;SEE IF SAME
	CALL	CTLCS
	JZ	MAPND2
	MOV	A,D
	CMP	H
	JNZ	MAPDIF
	MOV	A,E
	CMP	L
	JZ	MAPCNT	;SAME, CONTINUE
;
;Different file encountered
MAPDIF: DCX	B
	CALL	HEXB
	INX	B
	XCHG
	CALL	MAPNAM
	JMP	MAPDF
;
;End of map
;
MAPEND: DCX	B	;GET LAST
	CALL	HEXB
	CALL	MAPNAM
	POP	H
	CALL	CRLF
;
;End of map - reposition to previous group
;
MAPND2: PUSH	H
	LHLD	GROUP
	XCHG
	JMP	POSGP2
;
;Print file name pointed to by HL
;
MAPNAM: CALL	SPACE
	MOV	A,H
	ORA	L	;NONE?
	JZ	NONAME
	MOV	A,M	;SEE IF ALLOC
	CPI	0E5H	;FREE?
	MVI	A,' '
	JNZ	MPNSP1
	MVI	A,'('
;
MPNSP1: CALL	TYPE
	PUSH	H	;SAVE POINTER
	MOV	A,M
	CALL	HEX	;SHOW USER NUMBER
	CALL	SPACE
	INX	H	;SKIP USER BYTE
	PUSH	B
	MVI	B,8
	CALL	MAPN2
	MVI	A,'.'
	CALL	TYPE
	MVI	B,3
	CALL	MAPN2
	LDA	DUPFLG
	CALL	TYPE	;SPACE OR STAR
	POP	B
	MOV	A,M	;GET EXT
	CALL	HEX
	POP	H
	MOV	A,M
	CPI	0E5H
	MVI	A,' '
	JNZ	MPNSP2
	MVI	A,')'
;
MPNSP2: CALL	TYPE	;")" IF ERASED FILE
	JMP	FLIP
;
NONAME: CALL	ILPRT
	DB	'    ++FREE++        ',0
;
FLIP:	LDA	TWOUP
	XRI	1
	STA	TWOUP
	JZ	CRLF
;
DELIM:	MVI	A,':'
	CALL	TYPE
	JMP	SPACE
;
;Print name, length in B
;
MAPN2:	MOV	A,M
	ANI	7FH	;STRIP POSSIBLE 2.x ATTRIBUTE BIT
	INX	H
	CPI	' '	;PRINTABLE?
	JC	MAPN2H	;..NO, IN HEX
	CPI	7EH	;7E IS LEADIN ON SOME CRTS
	JC	MAPN2A
;
MAPN2H: CALL	BHEX
	JMP	MAPN2Z
;
MAPN2A: CALL	TYPE
;
MAPN2Z: DCR	B
	JNZ	MAPN2
	RET
;
;Find which file group (BC) belongs to
;
GETGRP: LHLD	DRM	;MAX DIR ENTRY #
	INX	H	;MAKE 1-RELATIVE
	SHLD	FILECT
	LXI	H,0
	SHLD	MFPTR
	LXI	H,DIRECT
;
GETGLP: PUSH	H	;SAVE POINTER TO NAME
	MOV	A,M	;PICK UP DN BYTE
	CPI	0E5H
	JZ	GETGNF
	LXI	D,14	;NOW GET RECORD COUNT
	DAD	D	;  S2 PORTION ..
	MOV	A,M	;  IS 0 IN CP/M 1.4
	ANI	0FH
	MOV	E,A
	INX	H
	MOV	A,M
	ORA	E
	JZ	GETGNF
	MVI	E,16	;FIRST SET FOR 8-BIT GRPS
	LDA	DSM+1
	ORA	A
	JZ	SMALGP
	MVI	E,8	;NOPE, BIG GROUPS
;
SMALGP: MOV	D,A	;SAVE GRP SIZE INDICATOR
;
GETGL2: INX	H	;POINTING INTO DM FIELD
	CALL	GRPCMP	;COMPARE BC GP # AGAINST 1 DM FLD
	JNZ	NOTGOT	;JUMP IF FOUND ONE
;
;Found the file
;
	PUSH	H	;SAVE GP PTR
	LHLD	MFPTR
	MOV	A,H
	ORA	L
	POP	H
	XTHL		;GET ENTRY START & SAVE PTR
	JZ	MPFRST
	MVI	A,'*'
	STA	DUPFLG
MPFRST: SHLD	MFPTR
	XTHL		;AS THEY WERE
NOTGOT: DCR	E	;ELSE COUNT DOWN
	JNZ	GETGL2	;GO TEST SOME MORE
;
GETGNF: POP	H	;NOT THIS ONE!
	LXI	D,32	;SO GO TO NEXT
	DAD	D
	XCHG
	LHLD	FILECT	;THERE IS LIMIT TO EVERYTHING
	DCX	H
	SHLD	FILECT
	MOV	A,H
	ORA	L
	XCHG		;RE-ALIGN
	JNZ	GETGLP
;
;Get the allocation address, if {ny
	LHLD	MFPTR
	RET
;
;Yank the current sector into memory at location YNKADR
;
YANK:	LDA	7	;GET TOP BYTE OF CCP POINTER
	MOV	B,A
	LDA	YNKADR+1	;GET TOP BYTE OF MEMORY POINTER
	CMP	B
	JNC	YMFULL	;IF MEMORY FULL, THEN SAY SO AND ABORT YANK
	LDA	WRFLG	;CHECK IF A READ HAS BEEN DONE
	ORA	A
	JZ	BADW	;IF NO READ, THEN CAN'T YANK, SO ABORT YANK
	PUSH	H
	LHLD	YNKADR	;MOVE SECTOR INTO YANK MEMORY
	XCHG
	LXI	H,BASE+80H
	MVI	B,128
	CALL	MOVE
	CALL	ILPRT	;TELL WHERE LAST BYTE IS
	DB	'LAST ADDR=',0
	LHLD	YNKADR	;CALCULATE LAST BYTE
	LXI	B,80H
	DAD	B
	SHLD	YNKADR	;SAVE LAST BYTE+1 FOR NEXT YANK
	DCX	H
	MOV	A,H
	CALL	HEX
	MOV	A,L
	CALL	HEX
	CALL	ILPRT
	DB	CR,LF,0
	POP	H
	JMP	PROMPT
;
YMFULL: XRA	A	;MEMORY FULL, SO SAY SO
	STA	QFLAG	;SET TO NOT QUIET MODE FIRST
	CALL	ILPRT
	DB	'++YANK MEMORY FULL'
	DB	CR,LF,0
	JMP	PROMPT
;
;Save the current sector
;
SAVE:	LDA	WRFLG
	ORA	A
	JZ	BADW	;NONE TO SAVE
	PUSH	H
	LXI	H,BASE+80H
	LXI	D,SAVBUF
	MVI	B,128
	CALL	MOVE
	MVI	A,1	;..SHOW
	STA	SAVEFL	;..SAVED EXISTS
	POP	H
	JMP	PROMPT
;
;Restore the current sector
;
RESTOR: LDA	SAVEFL
	ORA	A
	JZ	NOSAVE	;NONE TO SAVE
	PUSH	H
	LXI	H,SAVBUF
	LXI	D,BASE+80H
	MVI	B,128
	CALL	MOVE
	POP	H
	JMP	PROMPT
;
NOSAVE: XRA	A
	STA	QFLAG
	CALL	ILPRT
	DB	'++NO "<" SAVE COMMAND ISSUED'
	DB	CR,LF,0
	JMP	PRMPTR
;
;Move (HL) to (DE) length in B
;
MOVE:	MOV	A,M
	STAX	D
	INX	H
	INX	D
	DCR	B
	JNZ	MOVE
	RET
;
NORITE: XRA	A	;GET 0
	STA	WRFLG	;CAN'T WRITE NOW
	RET
;
;No match in search, try next char
;
SRNOMT: POP	H
	CALL	CTLCS	;ABORT?
	JNZ	SEARCH	;..YES
	LXI	H,INBUF
	MVI	M,CR
	JMP	CLCGRP	;SHOW WHERE STOPPED
;
;Search for character string
;
SEARCH: PUSH	H	;SAVE STRING POINTER
;
SRCHL:	CALL	RDBYTE	;GET A BYTE
	MOV	B,A	;SAVE IT
	MOV	A,M	;CHECK NEXT MATCH CHAR.
	CPI	'<'	;WILL IT BE HEX?
	MOV	A,B	;RESTORE DISK CHAR
	JZ	SRCHL1
	ANI	7FH	;NEXT CHAR IS ASCII...STRIP BIT 7
;
SRCHL1: PUSH	PSW
	CALL	GETVAL	;GET SEARCH VALUE
	MOV	B,A
	POP	PSW
	CMP	B	;MATCH?
	JNZ	SRNOMT	;NO MATCH
	INX	H
	MOV	A,M	;DONE?
	CPI	CR
	JZ	SREQU
	CPI	';'
	JNZ	SRCHL
;
;Got match
SREQU:	XRA	A
	STA	QFLAG
	CALL	ILPRT
	DB	'= AT ',0
	LDA	BUFAD
	ANI	7FH
	CALL	HEX
	CALL	CRLF
	JMP	CLCGRP
;
;Get value from input buffer
;
GETVAL: MOV	A,M
	CPI	'<'	;HEX ESCAPE?
	RNZ		;NO, RETURN
;"<<" means one "<"
	INX	H
	MOV	A,M
	CPI	'<'
	RZ
;Got hex
	PUSH	D
	CALL	HEXIN	;GET VALUE
	CPI	'>'	;PROPER DELIM?
	MOV	A,E	;GET VALUE
	POP	D
	JNZ	WHAT	;ERROR
	RET
;
;Read a byte at a time
;
RDBYTE: PUSH	H
	LDA	FTSW	;FIRST READ?
	ORA	A
	JNZ	READ1
	LHLD	BUFAD
	MOV	A,L
	ORA	A	;IN BUFFER?
	JM	NORD	;YES, SKIP READ
;
;Have to read
	CALL	NXTSEC
;
READ1:	XRA	A
	STA	FTSW	;NOT FIRST READ
	LHLD	CURSEC
	XCHG
	CALL	SETSEC
	LHLD	CURTRK
	XCHG
	CALL	SETTRK
	CALL	READ
	CALL	CLCSUB
	LXI	H,BASE+80H
;
NORD:	MOV	A,M
	INX	H
	SHLD	BUFAD
	POP	H
	RET
;
;View the file in ASCII starting at
;current sector, stepping thru the disk
;
VIEW:	LDA	WRFLG
	ORA	A
	JZ	BADDMP
	CALL	HEXIN	;GET DISPL IF ANY
	PUSH	H
	MOV	A,E
	ORA	A
	JNZ	VIEWLP
	INR	E	;DFLT=1
;
VIEWLP: LXI	H,BASE+80H ;TO DATA
;
VEWCHR: CALL	CTLCS
	JZ	VEWEND
	MOV	A,M
	CPI	1AH
	JZ	VEWEOF
	ANI	7FH
	CPI	7EH
	JNC	VIEWHX	;SHOW RUBOUT AND TILDE AS HEX
	CPI	' '
	JNC	VIEWPR
	CPI	CR
	JZ	VIEWPR
	CPI	LF
	JZ	VIEWPR
	CPI	TAB
	JZ	VIEWPR
;
VIEWHX: MOV	A,M	;NOT ASCII...PRINT AS <NN>
	CALL	BHEX
	JMP	VIEWNP
;
VIEWPR: CALL	TYPE
;
VIEWNP: INR	L
	JNZ	VEWCHR
	DCR	E
	JZ	VEWEND
	PUSH	D	;SAVE COUNT
	CALL	NXTSEC
	LHLD	CURSEC
	XCHG
	CALL	SETSEC	
	LHLD	CURTRK
	XCHG
	CALL	SETTRK
	CALL	READ
	POP	D	;RESTORE COUNT
	JMP	VIEWLP
;
VEWEOF: CALL	ILPRT
	DB	CR,LF,TAB,'++EOF++',CR,LF,0
;
VEWEND: POP	H
	CALL	CRLF
	JMP	CLCGRP
;
;Dump in hex or ASCII
;
DUMP:	LDA	WRFLG
	ORA	A
	JNZ	DUMPOK
;
BADDMP: XRA	A
	STA	QFLAG
	CALL	ILPRT
	DB	'++Can''t dump, no sector read.',CR,LF,0
;
EXPL:	XRA	A
	STA	QFLAG
	CALL	ILPRT
	DB	'Use G command following F,',CR,LF
	DB	'or R or S following T',CR,LF,0
	JMP	PRMPTR
;
DUMPOK: MOV	A,M
	CPI	';'
	JZ	DUMPDF	;DFLT
	CPI	CR
	JNZ	DMPNDF
;
;Use default
DUMPDF: LXI	B,BASE+80H
	LXI	D,0FFH
	JMP	DUMP1
;
DMPNDF: CALL	DISP
	MOV	B,D
	MOV	C,E
	CPI	CR
	JZ	DUMP1
	CPI	';'
	JZ	DUMP1
	INX	H	;SKIP ','
	CALL	DISP
;
;BC = start, DE = end
;
DUMP1:	PUSH	H	;SAVE COMMAND POINTER
	MOV	H,B
	MOV	L,C
;
DUMPLP: MOV	A,L
	ANI	7FH
	CALL	HEX
	CALL	SPACE
	CALL	SPACE
	LDA	DUMTYP
	CPI	'A'
	JZ	DUMPAS
	PUSH	H	;SAVE START
;
DHEX:	MOV	A,M
	CALL	HEX
	MOV	A,L
	ANI	3
	CPI	3
	CZ	SPACE
	MOV	A,L
	ANI	7
	CPI	7
	CZ	SPACE
	MOV	A,E
	CMP	L
	JZ	DPOP
	INX	H
	MOV	A,L
	ANI	0FH
	JNZ	DHEX
;
DPOP:	CALL	CTLCS
	JZ	PRMPTR
	LDA	DUMTYP
	CPI	'H'
	JZ	DNOAS	;HEX ONLY
	POP	H	;GET START ADDR
;
DUMPAS: CALL	ASTER
;
DCHR:	MOV	A,M
	ANI	7FH
	CPI	' '
	JC	DPER
	CPI	7EH
	JC	DOK
;
DPER:	MVI	A,'.'
;
DOK:	CALL	TYPE
	MOV	A,E
	CMP	L
	JZ	DEND
	INX	H
	MOV	A,L
	ANI	0FH
	JNZ	DCHR
;
DEND:	CALL	ASTER
	CALL	CRLF
	PUSH	D
	CALL	CTLCS
	POP	D
	JZ	PRMPTR
	MOV	A,E
	CMP	L
	JNZ	DUMPLP
	POP	H
	JMP	PROMPT
;
DNOAS:	POP	B
	CALL	CRLF
	MOV	A,E
	CMP	L
	JNZ	DUMPLP
	POP	H
	JMP	PROMPT
;
;Position
;
POS:	PUSH	PSW
	MOV	A,M
	CPI	';'
	JZ	POSINQ
	CPI	CR
	JNZ	POSOK
;
POSINQ: POP	PSW
	JMP	INQ
;
POSOK:	POP	PSW
	CPI	'T'
	JZ	POSTKD
	CPI	'S'
	JZ	POSSCD
	CPI	'G'
	JZ	POSGPH
	JMP	WHAT
;
POSTKD: CALL	DECIN
;
POSTRK: PUSH	H
	LHLD	MAXTRK
	CALL	SUBDE
	POP	H
	JC	OUTLIM
	CALL	SETTRK
	CALL	NORITE	;TRACK DOESN'T READ
	MVI	A,1
	STA	NOTPOS	;SHOW NOT POSITIONED
	JMP	CLCGRP
;
POSSCD: CALL	DECIN
	MOV	A,D
	ORA	E
	JZ	WHAT	;DON'T ALLOW SECTOR 0
;
POSSEC: PUSH	H
	LHLD	SPT
	CALL	SUBDE
	POP	H
	JC	WHAT
	CALL	SETSEC
	CALL	READ
	XRA	A
	STA	NOTPOS	;POSITIONED OK
;
CLCGRP: CALL	CLCSUB
	JMP	INQ
;
;Calculate group from track and sector
;
CLCSUB: PUSH	H
	LHLD	SYSTRK
	XCHG
	LHLD	CURTRK
	CALL	SUBDE
	XCHG
	LHLD	SPT
	CALL	MULT
	XCHG
	LHLD	CURSEC
	DCX	H
	DAD	D
	LDA	BLM
	MOV	B,A
	MOV	A,L
	ANA	B
	STA	GRPDIS
	LDA	BSH
	MOV	B,A
;
CLCLOP: CALL	ROTRHL
	DCR	B
	JNZ	CLCLOP
	SHLD	GROUP
	POP	H
	RET
;
;Position in the directory after a find
;(Does not work in CP/M-2.x)
;
POSDIR: PUSH	H	;SAVE INBUF
	LHLD	BSH
	XRA	A
	STA	FINDFL	;CANCEL POS REQ
	LDA	DIRPOS	;GET POSITION
	RAR
	RAR
	PUSH	PSW
	ANA	H
	STA	GRPDIS
	POP	PSW
;
POSDLP: RAR
	DCR	L
	JNZ	POSDLP
	ANI	1	;GET GROUP
	MOV	L,A	;SETUP FOR POSGP2
	MVI	H,0
	SHLD	GROUP
	XCHG
	JMP	POSGP2	;POSITION TO IT
;
POSGPH: CALL	HEXIN
;
POSGRP: PUSH	H
	LHLD	DSM
	CALL	SUBDE
	POP	H
	JC	OUTLIM
	XCHG
	SHLD	GROUP
	XCHG
	XRA	A
	STA	GRPDIS
	PUSH	H
;
POSGP2: CALL	GTKSEC
	CALL	SETTRK
	XCHG
	CALL	SETSEC
	CALL	READ
	XRA	A
	STA	NOTPOS	;NOW POSITIONED
	POP	H
	JMP	INQ
;
GTKSEC: MOV	H,D
	MOV	L,E
	LDA	BSH
;
GLOOP:	DAD	H
	DCR	A
	JNZ	GLOOP
	LDA	GRPDIS
	ADD	L	;CAN'T CARRY
	MOV	L,A
;
;Divide by nr of sectors, quotient=track, remainder=sector
;
	XCHG
	LHLD	SPT
	CALL	NEG
	XCHG
	LXI	B,0
;
DIVLP:	INX	B
	DAD	D
	JC	DIVLP
	DCX	B
	XCHG
	LHLD	SPT
	DAD	D
	PUSH	H
	LHLD	SYSTRK
	DAD	B
	XCHG
	POP	H
	INX	H
	RET
;
POSFIL: CALL	NORITE
	MVI	A,1
	STA	FINDFL	;SO WE POSITION LATER
	LXI	D,FCB
	XRA	A	;LOGGED IN DISK
	STAX	D
	INX	D
	MVI	B,8
	CALL	MVNAME
	MVI	B,3
	CALL	MVNAME
	LXI	D,FCB
	MVI	C,SRCHF
	PUSH	H
	CALL	BDOS
	INR	A
	JNZ	FLOK
	STA	DIRPOS	;GRP 0 IF NOT FOUND
	CALL	ILPRT
	DB	'++FILE NOT FOUND',CR,LF,0
	POP	H
	JMP	PROMPT
;
FLOK:	DCR	A
	STA	DIRPOS	;SAVE POS. IN DIR
	ANI	3
	MOV	L,A
	MVI	H,0
	DAD	H	;X32 BYTES/ENTRY
	DAD	H
	DAD	H
	DAD	H
	DAD	H
	LXI	D,BASE+80H
	DAD	D	;HL POINTS TO ENTRY
	LXI	D,32
	XCHG
	DAD	D
	XCHG
	MVI	A,'D'
	STA	DUMTYP
	JMP	DUMPLP	;WHICH POPS H
;
MVNAME: MOV	A,M
	CPI	'.'
	JZ	MVIPAD
	CPI	CR
	JZ	PAD
	CPI	';'
	JZ	PAD
	CALL	UPCASE
	STAX	D
	INX	H
	INX	D
	DCR	B
	JNZ	MVNAME
	MOV	A,M
	CPI	CR
	RZ
	CPI	';'
	RZ
	INX	H
	CPI	'.'
	RZ
	JMP	WHAT
;
MVIPAD: INX	H
;
PAD:	MVI	A,' '
	STAX	D
	INX	D
	DCR	B
	JNZ	PAD
	RET
;
PLUS:	LXI	D,1	;DFLT TO 1 SECT
	MOV	A,M	;GET NEXT CHAR
	CPI	CR	;CR?
	JZ	PLUSGO	;..YES, DFLT TO 1
	CPI	';'
	JZ	PLUSGO
	CALL	HEXIN	;GET #
	MOV	A,D
	ORA	E
	JZ	WHAT
;
PLUSGO: CALL	NXTSEC
	DCX	D	;MORE TO GO?
	MOV	A,D
	ORA	E
	JNZ	PLUSGO	;..YES
;
;Ok, incremented to sector.  Setup and read
;
PLUSMI: PUSH	H
	LHLD	CURSEC
	XCHG
	CALL	SETSEC
	LHLD	CURTRK
	XCHG
	CALL	SETTRK
	POP	H
	CALL	READ
	JMP	CLCGRP
;
MINUS:	LXI	D,1	;SET DFLT
	MOV	A,M	;GET CHAR
	CPI	CR	;CR?
	JZ	MINGO	;..YES, DFLT=1
	CPI	';'
	JZ	MINGO
	CALL	HEXIN	;..NO, GET ##
	MOV	A,D
	ORA	E
	JZ	WHAT
;
MINGO:	PUSH	H
	LHLD	CURSEC
	DCX	H
	MOV	A,H
	ORA	L
	JNZ	MINOK
	LHLD	CURTRK
	MOV	A,H
	ORA	L
	JNZ	SEASH
	LHLD	MAXTRK	;WRAP TO END OF DISK
	SHLD	CURTRK
	LHLD	MAXSEC
	JMP	MINOK
;
SEASH:	DCX	H
	SHLD	CURTRK
	LHLD	SPT
;
MINOK:	SHLD	CURSEC
	POP	H
	DCX	D
	MOV	A,D
	ORA	E
	JNZ	MINGO
	JMP	PLUSMI
;
;Go to next sector
;
NXTSEC: PUSH	H
	PUSH	D
	LHLD	CURSEC
	INX	H
	XCHG
	LHLD	SPT
	CALL	SUBDE
	XCHG
	JNC	NEXTOK
	LHLD	CURTRK
	INX	H
	XCHG
	LHLD	MAXTRK
	CALL	SUBDE
	JNC	TRASK
	LXI	D,0	;WRAP TO START OF DISK
;
TRASK:	XCHG
	SHLD	CURTRK
	LXI	H,1
;
NEXTOK: SHLD	CURSEC
	POP	D
	POP	H
	RET
;
;Tell what group, displacement, track, sector, physical sector
;
INQ:	CALL	INQSUB
	JMP	PROMPT
;
;Position inquiry subroutine
;Executed via: G S or T (with no operands)
;
INQSUB: PUSH	H
	LHLD	SYSTRK
	XCHG
	LHLD	CURTRK
	CALL	SUBDE
	JC	NOGRP
	CALL	ILPRT
	DB	'G=',0
	LHLD	GROUP
	MOV	B,H
	MOV	C,L
	CALL	HEXB
	MVI	A,':'
	CALL	TYPE
	LDA	GRPDIS
	CALL	HEX
	MVI	A,','
	CALL	TYPE
;
NOGRP:	CALL	ILPRT
	DB	' T=',0
	LHLD	CURTRK
	CALL	DEC
	CALL	ILPRT
	DB	', S=',0
	LHLD	CURSEC
	CALL	DEC
	CALL	ILPRT
	DB	', PS=',0
	LHLD	PHYSEC
	CALL	DEC
	CALL	CRLF
	POP	H
	RET
;
CHG:	MOV	A,M	;GET TYPE (HEX, ASCII)
	CALL	UPCASE
	PUSH	PSW	;SAVE "H" OR "A"
	INX	H
	CALL	DISP	;GET, VALIDATE DISP TO DE
	INX	H
	LXI	B,0	;SHOW NO 'THRU' ADDR
	CPI	'-'	;TEST DELIM FR. DISP
	JNZ	CHGNTH	;NO THRU
	PUSH	D	;SAVE FROM
	CALL	DISP	;GET THRU
	INX	H	;SKIP END DELIM
	MOV	B,D
	MOV	C,E	;BC = THRU
	POP	D	;GET FROM
	JMP	CHGAH
;
CHGNTH: CPI	','
	JNZ	WHAT
;
CHGAH:	POP	PSW
	CPI	'H'
	JZ	CHGHEX
	CPI	'A'
	JNZ	WHAT
;
;Change ASCII
CHGALP: MOV	A,M
	CPI	CR
	JZ	PROMPT
	CPI	';'
	JZ	PROMPT
	LDAX	D
	CPI	' '
	JC	CHGAHX
	CPI	7EH
	JNC	CHGAHX
	JMP	CHGA2
;
CHGAHX: CALL	BHEX
	JMP	CHGA3
;
CHGA2:	CALL	TYPE
;
CHGA3:	SHLD	BACK	;IN CASE "THRU"
	CALL	GETVAL	;ASCII OR <HEX>
	STAX	D	;UPDATE CHAR
	INX	H	;TO NEXT INPUT CHAR
;See if 'THRU' requested
	MOV	A,C
	ORA	A
	JZ	CHANTH
	CMP	E	;DONE?..
	JZ	PROMPT	;..YES
	LHLD	BACK
;
CHANTH: INR	E
	JNZ	CHGALP
	MOV	A,M
	CPI	CR
	JZ	PROMPT
	CPI	';'
	JZ	PROMPT
	JMP	WHAT
;
;Change hex
;
CHGHCM: INX	H
;
CHGHEX: MOV	A,M
	CPI	CR
	JZ	PROMPT
	CPI	';'
	JZ	PROMPT
	CPI	','	;DELIM?
	JZ	CHGHCM
	PUSH	D
	SHLD	HEXAD	;IN CASE 'THRU'
	CALL	HEXIN	;POSITIONS TO DELIM
	MOV	A,E	;GET VALUE
	POP	D	;..ADDR
	PUSH	PSW	;SAVE VALUE
	LDAX	D	;GET OLD
	CALL	HEX	;ECHO IN HEX
	POP	PSW	;GET NEW
	STAX	D	;SAVE NEW
	MOV	A,C	;SEE IF 'THRU'
	ORA	A
	JZ	CHHNTH	;..NO.
	CMP	E	;..YES, DONE?
	JZ	PROMPT
	LHLD	HEXAD	;..NO: MORE
;
CHHNTH: INR	E
	JNZ	CHGHEX
	MOV	A,M
	CPI	CR
	JZ	PROMPT
	CPI	';'
	JZ	PROMPT
	JMP	WHAT
;
DOREAD: LDA	NOTPOS
	ORA	A
	JNZ	CANTRD
	CALL	READ
	JMP	PROMPT
;
CANTRD: XRA	A
	STA	QFLAG	;NOT QUIET
	CALL	ILPRT
	DB	'++Can''t read - not positioned',CR,LF
	DB	'Position by:',CR,LF
	DB	9,'Track then Sector, or',CR,LF
	DB	9,'Group',CR,LF,0
	JMP	PROMPT
;
DORITE: CALL	WRITE
	JMP	PROMPT
;
BHEX:	PUSH	PSW
	MVI	A,'<'
	CALL	TYPE
	POP	PSW
	CALL	HEX
	MVI	A,'>'
	CALL	TYPE
	RET
;
HEXB:	LDA	DSM+1
	ORA	A
	JZ	HEXX
	MOV	A,B
	CALL	HEX
;
HEXX:	MOV	A,C
;
HEX:	PUSH	PSW
	RAR
	RAR
	RAR
	RAR
	CALL	NIBBL
	POP	PSW
;
NIBBL:	ANI	0FH
	CPI	10
	JC	HEXNU
	ADI	7
;
HEXNU:	ADI	'0'
	JMP	TYPE
;
;Decimal output routine
;
DEC:	PUSH	B
	PUSH	D
	PUSH	H
	LXI	B,-10
	LXI	D,-1
;
DECOU2: DAD	B
	INX	D
	JC	DECOU2
	LXI	B,10
	DAD	B
	XCHG
	MOV	A,H
	ORA	L
	CNZ	DEC
	MOV	A,E
	ADI	'0'
	CALL	TYPE
	POP	H
	POP	D
	POP	B
	RET
;
SPACE:	MVI	A,' '
	JMP	TYPE
;
ASTER:	MVI	A,'*'
	JMP	TYPE
;
;Inline print routine
;
ILPRT:	XTHL
;
ILPLP:	CALL	CTLCS	;ABORT?
	JZ	PRMPTR
	MOV	A,M
	CPI	1	;PAUSE?
	JNZ	ILPOK
	CALL	CONIN
	CPI	3	;ABORT?
	JZ	PRMPTR
	JMP	ILPNX
;
ILPOK:	CALL	TYPE
;
ILPNX:	INX	H
	MOV	A,M
	ORA	A
	JNZ	ILPLP
	INX	H
	XTHL
	RET
;
;DISP calls HEXIN, and validates a sector
;displacement, then converts it to an address
;
DISP:	CALL	HEXIN
	PUSH	PSW	;SAVE DELIMITER
	MOV	A,D
	ORA	A
	JNZ	BADISP
	MOV	A,E
	ORA	A
	JM	BADISP
	ADI	80H	;TO POINT TO BUFFER AT BASE+80H
	MOV	E,A
	MVI	D,BASE/256
	POP	PSW	;GET DELIM
	RET
;
BADISP: XRA	A
	STA	QFLAG
	CALL	ILPRT
	DB	'++BAD DISPLACEMENT (NOT 0-7F)'
	DB	CR,LF,0
	JMP	PRMPTR
;
HEXIN:	LXI	D,0
	MOV	A,M
	CPI	'#'	;DECIMAL?
	JZ	HDIN	;MAKE DECIMAL
;
HINLP:	MOV	A,M
	CALL	UPCASE
	CPI	CR
	RZ
	CPI	';'
	RZ
	CPI	','
	RZ
	CPI	'-'	;'THRU'?
	RZ
	CPI	'>'
	RZ
	INX	H
	CPI	'0'
	JC	WHAT
	CPI	'9'+1
	JC	HINNUM
	CPI	'A'
	JC	WHAT
	CPI	'F'+1
	JNC	WHAT
	SUI	7
;
HINNUM: SUI	'0'
	XCHG
	DAD	H
	DAD	H
	DAD	H
	DAD	H
	ADD	L
	MOV	L,A
	XCHG
	JMP	HINLP
;
HDIN:	INX	H	;SKIP '.'
;
DECIN:	LXI	D,0
;
DINLP:	MOV	A,M
	CALL	UPCASE
	CPI	CR
	RZ
	CPI	';'
	RZ
	CPI	','
	RZ
	CPI	'-'	;'THRU'?
	RZ
	INX	H
	CPI	'0'
	JC	WHAT
	CPI	'9'+1
	JNC	WHAT
	SUI	'0'
	PUSH	H
	MOV	H,D
	MOV	L,E
	DAD	H	;X2
	DAD	H	;X4
	DAD	D	;X5
	DAD	H	;X10
	ADD	L
	MOV	L,A
	MOV	A,H
	ACI	0
	MOV	H,A
	XCHG
	POP	H
	JMP	DINLP
;
;Read in a console buffer full
;
RDBUF:	CALL	ILPRT
	DB	CR,LF,':',0
;
RDBF1:	LXI	H,INBUF
	MVI	B,0
;
RDBLP:	CALL	CONIN
	MOV	C,A	;SAVE FOR BS TEST
;
;Evaluate control characters
;
	CPI	'U'-40H
	JZ	RDCTLU
;
	CPI	CR
	JZ	RDCR
;
	CPI	'H'-40H
	JZ	RDBS
;
	CPI	7FH
	JZ	RDBS
;
	CPI	'R'-40H
	JZ	RDCTLR
;
	CPI	'X'-40H
	JZ	RDCTLX
;
	CPI	' '
	JC	RDBLP
;
	MOV	M,A
	INX	H
	INR	B
	JM	FULL
	CALL	TYPE
	JMP	RDBLP
;
FULL:	DCR	B
	DCX	H
	MVI	A,'*'	;SIGNAL WE'RE FULL
	CALL	TYPE
	JMP	RDBLP
;
;Got CR
;
RDCR:	MOV	M,A	;SAVE IT
	CALL	TYPE	;ECHO IT
	MVI	A,LF	;ECHO..
	CALL	TYPE	;..LF
	LXI	H,INBUF
	RET
;
;Got DELETE or BS, echo if BS
;
RDBS:	XRA	A	;AT FRONT..
	ORA	B	;..OF LINE?
	JZ	RDCTLU	;..YES, ECHO ^U
	DCX	H
	DCR	B
	MOV	A,C
	CPI	'H'-40H ;BS?
	JZ	BACKUP	;ECHO THE BS
	MOV	A,M	;ECHO..
	CALL	TYPE	;..DELETED CHAR
	JMP	RDBLP
;
BACKUP: CALL	WIPER
	JMP	RDBLP
;
RDCTLX: INR	B
;
RDCX1:	DCR	B
	JZ	RDBF1
	CALL	WIPER
	JMP	RDCX1
;
WIPER:	PUSH	B
	PUSH	D
	PUSH	H
	LXI	D,BSMSG ;BACKSPACE, SPACE, BACKSPACE
	MVI	C,PRINT
	CALL	BDOS
	POP	H
	POP	D
	POP	B
	RET
;
BSMSG:	DB	BS,' ',BS,'$'
;
;Got CTL-R, retype
;
RDCTLR: MVI	M,CR
	CALL	CRLF
	LXI	H,INBUF
	MVI	B,0
;
RDCRL:	MOV	A,M
	CPI	CR
	JZ	RDBLP
	CALL	TYPE
	INR	B
	INX	H
	JMP	RDCRL
;
;Got CTL-U or backup to beginning of line.
;
RDCTLU: MVI	A,'^'
	CALL	TYPE
	MVI	A,'U'
	CALL	TYPE
	JMP	RDBUF
;
CRLF:	MVI	A,CR
	CALL	TYPE
	MVI	A,LF
	JMP	TYPE
;
UPCASE: CPI	60H
	RC
	ANI	5FH	;MAKE UPPER CASE
	RET
;
CONST:	PUSH	B
	PUSH	D
	PUSH	H
VCONST: CALL	$-$	;ADDR FILLED IN BY 'INIT'
	POP	H
	POP	D
	POP	B
	RET
;
CONIN:	PUSH	B
	PUSH	D
	PUSH	H
VCONIN: CALL	$-$	;ADDR FILLED IN BY 'INIT'
	POP	H
	POP	D
	POP	B
	RET
;
;Console out with TAB expansion
;
TYPE:	PUSH	B
	PUSH	D
	PUSH	H
	MOV	C,A	;FOR OUTPUT ROUTINE
	CPI	TAB
	JNZ	TYPE2
;
TYPTAB: MVI	A,' '
	CALL	TYPE
	LDA	TABCOL
	ANI	7
	JNZ	TYPTAB
	JMP	TYPRET
;
;Filter out control characters to
;prevent garbage during view of file
;
TYPE2:	CPI	' '
	JNC	TYPEQ
	CPI	CR
	JZ	TYPEQ
	CPI	LF
	JNZ	TYPNCR
;
TYPEQ:	LDA	QFLAG
	ORA	A

VCONOT: CZ	$-$	;ADDR FILLED IN BY 'INIT'
;
;Update column used in tab expansion
	MOV	A,C	;GET CHAR
	CPI	CR
	JNZ	TYPNCR
	MVI	A,0
	STA	TABCOL
	JMP	TYPLST
;
TYPNCR: CPI	' '	;CTL CHAR?
	JC	TYPLST	;..NO CHANGE IN COL
	LDA	TABCOL
	INR	A
	STA	TABCOL
;
TYPLST: LDA	PFLAG
	ANI	1
	CNZ	LIST	;FROM C REG.
;
TYPRET: POP	H
	POP	D
	POP	B
	RET
;
LIST:	PUSH	B	;SAVED REGS
	PUSH	D
	PUSH	H
VLIST:	CALL	$-$	;ADDR FILLED IN BY 'INIT'
	POP	H
	POP	D
	POP	B
	RET
;
HOME:	PUSH	H
VHOME:	CALL	$-$	;ADDR FILLED IN BY 'INIT'
	POP	H
	RET
;
;Set track # in DE
;
SETTRK: PUSH	H
	LHLD	MAXTRK
	CALL	SUBDE
	POP	H
	JC	OUTLIM
	XCHG
	SHLD	CURTRK
	XCHG
	MOV	B,D
	MOV	C,E
	PUSH	H
VSETRK: CALL	$-$	;ADDR FILLED IN BY 'INIT'
	POP	H
	RET
;
SETSEC: PUSH	H
	PUSH	D
	LHLD	SYSTRK
	XCHG
	SHLD	CURSEC
	LHLD	CURTRK
	CALL	SUBDE
	POP	B
	MOV	H,B
	MOV	L,C
	JNC	NOTSYS
	LDA	FIRST0	;SEE IF FIRST SEC 0
	ORA	A
	JNZ	GSTSEC	;NO, JUMP AWAY
	DCX	H	;YES, SO DECREMENT
	JMP	GSTSEC	;  REQUESTED, THEN GO
;
NOTSYS: LHLD	SECTBL
	XCHG
	DCX	B
VSCTRN: CALL	$-$	;ADDR FILLED IN BY 'INIT'
	LDA	SPT+1	;IF SPT<256 (HI-ORD = 0)
	ORA	A	; THEN FORCE 8-BIT TRANSLATION
	JNZ	VSCTR1	; ELSE KEEP ALL 16 BITS
	MOV	H,A
;
VSCTR1: LDA	VER2FL	;SEE IF VERSION 2.x
	ORA	A	;SET FLAGS
	JNZ	GSTSEC	;JUMP IF CP/M 2.x
	MVI	H,0	;CP/M 1.4 GOOD TO ONLY 8 BITS
	MOV	L,C	;MOST BIOS'S RETURN THE
			;  PHYSICAL SEC # IN REG C
GSTSEC: SHLD	PHYSEC	;THIS MAY BE REDUNTANT IN
			; MOST 1.4 VERSIONS, BUT
			; SHOULD CAUSE NO PROBLEMS
	MOV	B,H
	MOV	C,L
VSTSEC: CALL	$-$	;ADDR FILLED IN BY 'INIT'
	POP	H
	RET
;
OUTLIM: XRA	A
	STA	QFLAG
	CALL	ILPRT
	DB	'++not within tracks 0-',0
	PUSH	H
	LHLD	MAXTRK
	CALL	DEC
	POP	H
	CALL	ILPRT
	DB	'++'
	DB	CR,LF,0
	CALL	NORITE
	JMP	PRMPTR
;
SETDMA: JMP	$-$	;ADDR FILLED IN BY 'INIT'
;
READ:	MVI	A,1
	STA	WRFLG
	PUSH	H
VREAD:	CALL	$-$	;ADDR FILLED IN BY 'INIT'
	ORA	A
	JZ	READOK
	XRA	A
	STA	QFLAG
	CALL	ILPRT
	DB	'++READ failed, sector may be invalid++'
	DB	CR,LF,0
;
READOK: POP	H
	RET
;
WRITE:	LDA	WRFLG
	ORA	A
	JNZ	PWRITE
;
BADW:	XRA	A
	STA	QFLAG
	CALL	ILPRT
	DB	'++CANNOT WRITE UNLESS READ ISSUED'
	DB	CR,LF,0
	JMP	EXPL
;
PWRITE: PUSH	H
	MVI	C,1	;FORCE WRITE TYPE 1 IN CASE 2.x DEBLOCK USED
VWRITE: CALL	$-$	;ADDR FILLED IN BY 'INIT'
	ORA	A
	JZ	WRITOK
	XRA	A
	STA	QFLAG
	CALL	ILPRT
	DB	'++WRITE failed++',CR,LF,0
;
WRITOK: POP	H
	RET
;
;Help
;
HELP:	CALL	ILPRT
	DB	'Operands in brackets [...] are optional'
	DB	CR,LF
	DB	'Numeric values: ''n'' are decimal, ''x'' hex'
	DB	CR,LF,CR,LF
	DB	'+[n]   step in [n] sectors;'
	DB	CR,LF
	DB	'-[n]   step out [n] sectors'
	DB	CR,LF
	DB	'#      print disk parameters for curr drive.'
	DB	CR,LF
	DB	'=xxx   search for ASCII xxx from curr sector.'
	DB	CR,LF
	DB	'       Caution: upper/lower case matters.'
	DB	CR,LF
	DB	'       Use <xx> for hex:'
	DB	CR,LF
	DB	'       To find "IN 0" use: =<db><0>     or'
	DB	CR,LF
	DB	'       "(tab)H,0(CR)(LF)" use: =<9>H,0<D><A>'
	DB	CR,LF
	DB	'<      save current sector into mem. buff.'
	DB	CR,LF
	DB	'>      restore saved sector'
	DB	CR,LF
	DB	'?      give help'
	DB	CR,LF
	DB	'A[ff,tt] ASCII dump'
	DB	CR,LF,CR,LF
	DB	'(Type any char. to continue)'
	DB	1,CR,LF,CR,LF
	DB	'C      Change:'
	DB	CR,LF
	DB	'       CHaddr,byte,byte... (hex)'
	DB	CR,LF
	DB	'  or   CAaddr,data...  (Ascii)'
	DB	CR,LF
	DB	'       <xx> Allowed for imbedded hex.'
	DB	CR,LF
	DB	'  or   CHfrom-thru,byte  e.g. ch0-7f,e5'
	DB	CR,LF
	DB	'  or   CAfrom-thru,byte'
	DB	CR,LF
	DB	'D[ff,tt] Dump (hex+ASCII)'
	DB	CR,LF
	DB	'Fn.t   Find file'
	DB	CR,LF
	DB	'Gnn    CP/M Allocation Group nn'
	DB	CR,LF
	DB	'H[ff,tt]       hex dump'
	DB	CR,LF
	DB	'L      Log in drive'
	DB	CR,LF
	DB	'Lx     Log in drive x'
	DB	CR,LF
	DB	'M[nn]  Map [from group nn]'
	DB	CR,LF,CR,LF
	DB	'(Type any char. to continue)'
	DB	1,CR,LF,CR,LF
	DB	'N      New disk'
	DB	CR,LF
	DB	'P      Toggle printer switch'
	DB	CR,LF
	DB	'Q      Quiet mode (no msgs)'
	DB	CR,LF
	DB	'R      Read current sector'
	DB	CR,LF
	DB	'Snn    Sector nn'
	DB	CR,LF
	DB	'Tnn    Track nn'
	DB	CR,LF
	DB	'Unn    Set User nn for Find command (CP/M-2 only)'
	DB	CR,LF
	DB	'V[nn]  View [nn] ASCII sectors'
	DB	CR,LF
	DB	'W      Write current sector'
	DB	CR,LF
	DB	'X      Exit program'
	DB	CR,LF
	DB	'Y      Yank current sector into sequential memory'
	DB	CR,LF
	DB	'Z[nn]  Sleep [nn tenths]'
	DB	CR,LF
	DB	'/[nn]  Repeat [nn (decimal) times]'
	DB	CR,LF,CR,LF
	DB	'(Type any char. to continue)'
	DB	1,CR,LF,CR,LF
	DB	'Cancel a function with C or Ctl-C.'
	DB	CR,LF
	DB	'Suspend output with S or Ctl-S.'
	DB	CR,LF
	DB	'Separate commands with ";".'
	DB	CR,LF
	DB	'       Example: g0'
	DB	CR,LF
	DB	'       +;d;z#20;/'
	DB	CR,LF
	DB	'       would step in, dump, sleep 2 sec, '
	DB	CR,LF
	DB	'       and repeat until control-c typed.'
	DB	CR,LF
	DB	'All "nn" usage except "/", "T", and "S" are'
	DB	CR,LF
	DB	'        HEX.  Use #nn for decimal.'
	DB	CR,LF,CR,LF
	DB	'See DU.DOC for complete examples.'
	DB	CR,LF,CR,LF,0
	JMP	PROMPT
;
;********************************
;*				*
;*    Utility Subroutines	*
;*				*
;********************************
;
GRPCMP: MOV	A,C
	INR	D
	DCR	D
	JZ	CMP8
	CMP	M
	INX	H
	RNZ
	MOV	A,B
;
CMP8:	CMP	M
	RET
;
;2's complement HL ==> HL
;
NEG:	MOV	A,L
	CMA
	MOV	L,A
	MOV	A,H
	CMA
	MOV	H,A
	INX	H
	RET
;
;HL/2 ==> HL
;
ROTRHL: ORA	A
	MOV	A,H
	RAR
	MOV	H,A
	MOV	A,L
	RAR
	MOV	L,A
	RET
;
;Collect the number of '1' bits
;in A as a count in C
;
COLECT: MVI	B,8
;
COLOP:	RAL
	JNC	COSKIP
	INR	C
;
COSKIP: DCR	B
	JNZ	COLOP
	RET
;
;HL-DE ==> HL
;
SUBDE:	MOV	A,L
	SUB	E
	MOV	L,A
	MOV	A,H
	SBB	D
	MOV	H,A
	RET
;
;Quick Kludge multiply
;HL=DE ==> HL
;
MULT:	PUSH	B
	PUSH	D
	XCHG
	MOV	B,D
	MOV	C,E
	MOV	A,B
	ORA	C
	JNZ	MULCON
	LXI	H,0	;FILTER SPECIAL CASE
	JMP	MLDONE	;  OF MULTIPLY BY 0
;
MULCON: DCX	B
	MOV	D,H
	MOV	E,L
;
MULTLP: MOV	A,B
	ORA	C
	JZ	MLDONE
	DAD	D
	DCX	B
	JMP	MULTLP
;
MLDONE: POP	D
	POP	B
	RET
;
;Routine to fill in disk params
;with every drive change
;
LOGIT:	LDA	VER2FL
	ORA	A	;IF NOT CP/M 2.x THEN
	JZ	LOG14	;	DO IT AS 1.4
	LXI	D,DPB	;   THEN MOVE TO LOCAL
	MVI	B,DPBLEN ;  WORKSPACE
	CALL	MOVE
	JMP	LOGCAL
;
LOG14:	LHLD	BDOS+1	;FIRST FIND 1.4 BDOS
	MVI	L,0
	LXI	D,DPBOFF ;THEN OFFSET TO 1.4'S DPB
	DAD	D
	MVI	D,0	;SO 8 BIT PARMS WILL BE 16
	MOV	E,M	;NOW MOVE PARMS
	INX	H
	XCHG
	SHLD	SPT
	XCHG
	MOV	E,M
	INX	H
	XCHG
	SHLD	DRM
	XCHG
	MOV	A,M
	INX	H
	STA	BSH
	MOV	A,M
	INX	H
	STA	BLM
	MOV	E,M
	INX	H
	XCHG
	SHLD	DSM
	XCHG
	MOV	E,M
	INX	H
	XCHG
	SHLD	AL0
	XCHG
	MOV	E,M
	XCHG
	SHLD	SYSTRK
;
LOGCAL: LXI	H,GRPDIS
	MOV	A,M
	PUSH	PSW
	LDA	BLM
	MOV	M,A
	PUSH	H
	LHLD	DSM
	XCHG
	CALL	GTKSEC
	SHLD	MAXSEC
	XCHG
	SHLD	MAXTRK
	POP	H
	POP	PSW
	MOV	M,A
	RET
;
;Temporary storage area
;
BUFAD:	DW	BASE+100H ;FORCES INITIAL READ
HEXAD:	DW	0	;TO RE-FETCH A VALUE
TOGO:	DW	0FFFFH	;REPEAT COUNT (FFFF=CONT)
TWOUP:	DB	0
PFLAG:	DB	0	;1=PRINT
GROUP:	DW	0
GRPDIS: DB	0
SAVEFL: DB	0
CURTRK: DW	0
CURSEC: DW	1
PHYSEC: DW	1
TABCOL: DB	0
FILECT: DW	0
DIRPOS: DB	0
FINDFL: DB	0	;1=MUST POSITION AFTER FIND
FTSW:	DB	1	;SEARCH W/O INCREMENT
NOTPOS: DB	1	;INITIALLY NOT POSITIONED
WRFLG:	DB	0	;MAY NOT WRITE UNTIL '+', '-',
;			 OR 'G' COMMAND
QFLAG:	DB	0	;QUIET? (0=NO)
FIRST0: DB	0	;SETS TO 0 IF FIRST SEC # IS 0
DRIVE:	DB	0
MAXTRK: DW	0
MAXSEC: DW	0
VER2FL: DB	0
SECTBL: DW	0	;POINTER TO SECTOR SKEW TABLE
MFPTR:	DW	0
DUPFLG: DB	0
YNKADR: DW	0	;POINTER TO CURRENT YANK ADDRESS
;
BACK:	DS	2	;TO BACK UP IN "CA0-7F,X"
DUMTYP: DS	1
;
;--------------------------------------------------
;The disk parameter block
;is moved here from CP/M
;
DPB	EQU	$	;DISK PARAMETER BLOCK (COPY)
SPT:	DS	2
BSH:	DS	1
BLM:	DS	1
EXM:	DS	1
DSM:	DS	2
DRM:	DS	2
AL0:	DS	1
AL1:	DS	1
CKS:	DS	2
SYSTRK: DS	2
;
;End of disk parameter block
;--------------------------------------------------
;
SAVBUF: DS	128
INBUF:	DS	128
;
;Directory read in here; also search work area
;
WORK	EQU	$
DIRECT	EQU	$
;
	END

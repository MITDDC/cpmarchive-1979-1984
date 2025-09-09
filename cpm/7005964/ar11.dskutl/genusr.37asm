;**********************************************************
;							  *
;	       HORIZON USER MODULE  -- 1/12/82		  *
;							  *
;			R. L. PLOUFFE 			  *
;							  *
MSIZE	EQU	62		;MEMORY SIZE THIS VERS	  *
				;CHANGE TO YOUR SIZE HERE *
OVERLAY	EQU	OVERLAY		;COMPUTED SYSGEN OVERLAY  *
;							  *
; Requires North Star Horizon, PMMI modem, H19 terminal,  *
; and Computime T102 clock. Can be adapted for others.    *
;							  *
; This version can be assembled with ASM.COM		  *
;**********************************************************
;
;		   GENEUSER  VERSION 3.7
;
;	1/10/82 vers 3.6, cleaned up the code
;
;	12/30/81 vers 3.5, added H89 mode so that H89
;	games that use a 16 bit counter at 000BH inc-
;	remented by a clock interrupt will work properly.
;	The H89 command sets this mode and provides a prompt
;	for entry of the game file name.  It auto resets at
;	end of game, on a warm boot, or whenever CCP prompts.
;	This mode is used if you have a H19, or Z19 terminal.
;	Also added PARTYLN mode to the CCP-included 'BYE'
;	command to require ring back. (conditional assy.)
;	In all cases now, when the 'BYE' code is executed a
;	prompt of  *> appears indicating that the system is
;	in auto-answer mode.  The local console can get to
;	CP/M by hitting the ESC key.
;
;	12/14/81 vers 3.0, major revision to bring
;	GENEUSER up to date with XTCPM vers 1.5
;	Major difference from previous release is that
;	transients may have 3 levels of password pro-
;	tection (none, level 1, & level 2) just by
;	placing them in USER 13, 14, or 15 respectively.
;	Transients so placed will be universal in all
;	user areas only on drive A depending on password
;	level achieved.
;		    *** RESTRICTION ***
;	Do not change file attributes (R/W R/O DIR SYS)
;	with STAT on your sytem disk in the 'A' drive unless
;	you know the file is in the user area that you are
;	logged to,  otherwise the file will now be owned
;	by the new user area. For that reason also, don't
;	use wild card changes to file attributes on A drive.
;	Once you make up your system disk with the files you
;	wish at password levels 0, 1, and 2 placed in users
;	13, 14, and 15 respectively, change file attributes
;	if you wish one file at a time and while logged to
;	the user area the file is in.  Then write-protect
;	your system disk.
;			Also, you can now log to a drive
;	and user area on one command line. i.e, B: 3 will
;	log you to drive B, user 3.
;
;
;	NOTE: Requires HELP.COM..See GENEHELP.ASM.
;	or use HELP20.ASM  Place HELP.COM in user 13
;	and the .HLP files in user 0, both on A drive.
;
;	FOR USE WITH CP/M VERS 1.45, 2.01, 2.2, 2.21A
;	AND 2.22 ON NORTH STAR DISK WITH LIFEBOAT BIOS.
;
;	THIS MODULE NOW PROVIDES FOR N ADDITIONAL CCP
;	COMMANDS INTEGRATED WITH THE ORIGINAL CCP. LOOK
;	AT THE FILE TO DISCOVER THEM ALL. 'BYE' IS ONE
;	OF THE INCLUDED CCP COMMANDS AND INCLUDES AN
;	'ANSWR' COMMAND THAT CAN BE USED LOCALLY TO GO
;	TO IMMEDIATE ANSWER TONE OR FROM A REMOTE TO
;	CHANGE BAUD RATE, SINCE IT WAITS FOR C/R'S OR
;	CONTROL-C'S TO SENSE NEW BAUD RATE. ALSO INCLUD-
;	ED IS AN 'ORIG' COMMAND THAT DEFAULTS TO 300 BAUD
;	OR ORIGINATES AT 110, 300, 450, OR 600 BAUD
;	BY ENTERING A 1, 3, 4, OR 6 ON THE COMMAND LINE
;	WITH 'ORIG', INITIATE CALL MANUALLY AND THEN
;	ENTER 'ORIG [X]' TO GO ON LINE. THE CCP COMMANDS
;	ARE DIVIDED INTO PUBLIC AND PRIVATE COMMANDS
;	WITH PASSWORD ENTRY FROM 'BYE' AND AN ADDITIONAL
;	PASSWORD REQUIRED FOR PRIVILEGED COMMANDS AND
;	USER AREAS ABOVE MAXUSER. 
;
;	THE MODULE ALSO INCLUDES A BACKGROUND MEMORY
;	TEST THAT CONSTANTLY RUNS WHENEVER THE CURRENT
;	CONSOLE IS AWAITING INPUT. ALSO, AN INTERRUPT
;	IS USED TO DISCONNECT THE LINE WHENEVER CARRIER
;	IS LOST. IT WILL ALSO TURN OFF THE COMPUTER
;	IF THE PMMI AUXILIARY INTERFACE IS IMPLEMENTED.
;	THE INTERRUPT IS INITIATED BY THE HORIZON REAL
;	TIME CLOCK EVERY 3.328 MS. TO IMPLEMENT, CONNECT
;	PIN 12 TO 13 ON THE CLOCK HEADER (10A) AND PIN
;	7 TO 16 ON THE INTERRUPT HEADER (1A). THE 'ID'
;	JUMPER AT LOC 7E ON THE Z80 BOARD MUST ALSO BE
;	CUT SO AS TO ENABLE INTERRUPTS. IN THE H89 MODE,
;	A COUNTER AT 000BH WILL BE INCREMENTED EVERY 3.33
;	MS.  THE TEST TO DISCONNECT THE LINE IF CARRIER IS
;	LOST USES THE SAME CLOCK INTERRUPT BUT IS DONE ONLY
;	ONCE EVERY 1000H INTERVALS (SO ONCE EVERY 13 SECS.).
;
;	THESE FEATURES ARE AVAILABLE ONLY WITH THE S201, S22
;	OR S22X CONDITIONAL ASSEMBLY AND NOT WITH S145
;	ASSEMBLY NOT CHECKED FOR CPM145.
;	
;	AS DISTRIBUTED HERE, ALL OF THE FEATURES ARE
;	AVAILABLE WITH ONLY ONE KILOBYTE OF SPACE ABOVE
;	CP/M. THUS, YOU CAN RUN A CP/M 62K SYSTEM IF YOUR
;	CONTROLLER PROM IS AT FC00H.
;
;	THE UTILITY, GENESYS.COM, IS USED TO GEN THE SYSTEM
;	TO OBTAIN THE ADDITIONAL 1KB RESIDENT ON THE NORTH
;	STAR SYSTEM DISK TRACKS. THE NEW VERSION, GENSYS32,
;	NOW WORKS WITH LIFEBOAT VERS 2.22 BIOS AS WELL AS
;	PREVIOUS VERSIONS (1.45, 2.01, 2.2, 2.21A). BE SURE
;	TO READ GENEUSYS.DOC FOR INSTRUCTIONS.
;
***********************************************************
;
;		SYSTEM EQUATES
;
FALSE	EQU	0
TRUE	EQU	NOT FALSE	;SEE OPTIONS BLOCK
				;TO SELECT ALL OPTIONS
; must select one, and only one, of these TRUE
S145	EQU	FALSE
S201	EQU	FALSE
S22	EQU	FALSE
S22X	EQU	TRUE	;TRUE FOR 2.21A & 2.22
;
;
	IF	S201 OR S22 OR S22X
BIOS	EQU	(MSIZE*1024)-0D00H	;BASE OF BIOS
CCP	EQU	BIOS-1600H		;BASE OF CCP
USER1	EQU	BIOS+0700H		;BASE OF THIS MODULE
USER2	EQU	MSIZE*1024		;BASE 2ND USER AREA
PROMLOC	EQU	BIOS+6F5H		;LOC OF PROMHI BYTE
OVERLAY	EQU	2000H-BIOS		;COMPUTED OVERLAY
	ENDIF
	;
	IF	S145
BIOS	EQU	(MSIZE*1024)-200H	;BASE OF BIOS
CCP	EQU	BIOS-1500H		;BASE OF CCP
USER1	EQU	BIOS+500H		;BASE OF THIS MODULE
USER2	EQU	MSIZE*1024+800H		;BASE OF 2ND USER AREA
PROMLOC	EQU	CCP-100H+0CH		;LOC OF PROMHI BYTE.
					;PLACED HERE BY COLD
					;BOOT LOADER PATCHED
					;IN BY GENESYS.COM
OVERLAY	EQU	2400H-USER1		;COMPUTED OVERLAY
	ENDIF
	;
BDOS	EQU	CCP+800H		;BASE OF BDOS
	;
	IF	S22 OR S22X
STACK	EQU	BDOS+341H		;ROOM IN SYSTEM FOR A
					;A 24 LEVEL STACK. 12 REQ.
	ENDIF
	;
	IF	S201
STACK	EQU	BIOS+6DDH		;24 LEVEL STACK
	ENDIF
	;
COMBUF	EQU	CCP+7H			;LOC OF CMD BUFFER
;
IOBYTE	EQU	0003H			;I/O BYTE ADDRESS
INIT	EQU	CCP-900H		;ORG FOR INIT CODE
DRIVE	EQU	0004H			;LOC OF CURR DRV BYTE
HOLE4	EQU	CCP+1F5H		;20 BYTES
INTCNTR	EQU	1000H			;INTERRUPT COUNTER VALUE
;
;**********************************************************
;**********************************************************
;
;		SYSTEM OPTIONS
;	ALL OPTIONS ARE IN THIS BLOCK.
;
IOBYT	EQU	00000001B	;VALUE OF IOBYTE
		; ; ; ;---------;CONSOLE IS TTY:	00
		; ; ;		;	    CRT:	01
		; ; ;		;	    BAT:	10
		; ; ;		;	    UC1:	11
		; ; ;-----------;READER IS  TTY:	00
	 	; ;		;	    RDR:	01 
		; ;		;	    UR1:	10 
		; ;		;	    UR2:	11 
		; ;-------------;PUNCH IS   TTY:	00 
		;		;	    PUN:	01 
		;		;	    UP1:	10 
		;		;	    UP2:	11  
		;---------------;LIST IS    TTY:	00 
				;	    CRT:	01 
				;	    LPT:	10 
				;	    UL1:	11 
;							   
PASBYT	EQU	00100100B	;PASSWORD BYTE	   
		  ;  ;----------;PASSWORD 2 REQUIRED	   
		  ;-------------;PASSWORD 1 REQUIRED	   
;
	ORG	HOLE4
;These are the passwords for entry to CP/M from BYE	   
;and to USER area and command privileges above MAXUSER	   
;repectively. Passwords must be exactly 10 characters, and   
;may be filled out to this value with spaces. The password
;checking routine sets bit 7 of the char it gets from the
;console (including remote) high, so add 80H to each char
;of the password (including any spaces) that will be entered.
;Fill out passwords shorter than 10 chars w/spaces without
;bit 7 set high.  This prevents the ASCII characters from
;being visible with a monitor.  They look like code instead.		   
;
PAS1:	DB	'P'+80H		; 1  PASSWORD1
	DB	'A'+80H		; 2
	DB	'S'+80H		; 3
	DB	'S'+80H		; 4
	DB	'W'+80H		; 5
	DB	'O'+80H		; 6
	DB	'R'+80H		; 7
	DB	'D'+80H		; 8
	DB	'1'+80H		; 9
	DB	' '		; 10
	;
PAS2:	DB	'P'+80H		; 1  PASSWORD2
	DB	'A'+80H		; 2
	DB	'S'+80H		; 3
	DB	'S'+80H		; 4
	DB	'W'+80H		; 5
	DB	'O'+80H		; 6
	DB	'R'+80H		; 7
	DB	'D'+80H		; 8
	DB	'2'+80H		; 9
	DB	' '		; 10	
;							   
			;20 BYTES AVAILABLE AT HOLE4
;
;							   
PARTYLN	EQU	FALSE	;WANT PARTY LINE OPERATION? 
			;NOTE - IF PARTYLN IS SET TRUE
			;AND ALL OTHER OPTIONS ARE TRUE,
			;THEN U WILL NEED MORE THAN 1K
			;RESERVED ABOVE CP/M. 
RUNHELP	EQU	TRUE	;WANT TO RUN HELP.COM WHEN PHONE
			;IS ANSWERED BY 'BYE'?
PARITY	EQU	TRUE	;WANT TO SET PARITY MEMORY	   
SCRCLR	EQU	TRUE	;WANT TO CLEAR SCREEN ON BOOT      
CLOCK	EQU	TRUE	;WANT TIME FROM CLOCK BOARD        
;							   
FASTCLK EQU	TRUE	;SET TRUE FOR 4 MHZ CLOCK	   
;							   
MAXUSER	EQU	2	;FOR EXAMPLE..MAX PUBLIC USER AREA 
;							   
	IF	S201 OR S22 OR S22X
	ORG	USER1-8H				   
CONFG:	DB	00000000B	;SAME AS IN NORTH STAR DOS 
				;BITS 0,1,2,3 SET INDICATE 
				;FASTSTEPPING IN ORDER A,  
				;B,C,D. BITS 7,6,5,4 SET   
				;INDICATE DOUBLE SIDED IN  
				;ORDER A,B,C,D.		   
	ORG	USER1-13H				   
	JMP	WINIT		;REPLACE THE JMP WITH RET  
				;IF YOU DO NOT WANT THE    
				;WINIT RTNE.		   
;							   
JOFTEN:	RET			;REPLACE WITH A JMP	   
	DW	0000H		;PATCH IN ADDR OF YOUR RTNE
	ENDIF						   
;							   
	IF	S145
	ORG	USER1-4H				   
DENSITY:						   
	DB	10101010B	;BITS 1,3,5,7 DD ON A,B,C,D
BUFFER:							   
	DW	USER1+100H	;BIOS BUFFER LOCATION	   
				;YOU CAN CHANGE THIS IF YOU 
				;WISH BUT IN 1K INCREMENTS 
	ENDIF						   
;							   
	ORG	USER1-1H				   
MODE:	DB	RAW+EIBIT+CAUTO	;MODE BYTE	   
;							   
	ONEDRV	EQU	80H	;BIT 7=1 INDICATES 1 DRIVE 
	RAW	EQU	40H	;SET READ AFTER WRITE      
	EIBIT	EQU	10H	;ENABLE INTERRUPTS AFTER   
				;DISK ACCESS		   
	NMOUNT	EQU	8	;USE DRVPAR PARAMETERS	   
	WAUTO	EQU	2	;WARM BOOT AUTO FUNCTION   
	CAUTO	EQU	1	;COLD BOOT AUTO FUNCTION   
;							   
;END OF OPTIONS BLOCK					   
;***********************************************************
;***********************************************************
;
;		HORIZON I/O PORT ASSIGNMENTS
;
;Be sure to check memory, modem, and clock port assignments
;for your system.
;
PARAL	EQU	0	;PARALLEL I/O PORT
SER1D	EQU	2	;LEFT SERIAL PORT DATA
SER1ST	EQU	3	;LEFT SERIAL PORT STATUS
SER2D	EQU	4	;RIGHT SERIAL PORT DATA
SER2ST	EQU	5	;RIGHT SERIAL PORT STATUS
MOTHER	EQU	6	;MOTHERBOARD COMMAND/STATUS
MEMORY	EQU	0C0H	;PARITY MEMORY PORT
MODEM	EQU	0E0H	;PMMI MODEM BASE PORT
CLKBRD	EQU	0CH	;DATA PORT FOR COMPUTIME BOARD
;
;**********************************************************
;START OF USER1 CODE
;
;		JUMP TABLE LINKS BIOS TO GENEUSER
;		The rest of the jumps are at base
;		of the BIOS.
;
;DO NOT CHANGE THE NUMBER OF BYTES FROM HERE TO 'CONOUT:'.
;
;**********************************************************
	ORG	USER1
	JMP	INITIAL		;USER INIT ROUTINE
	IF	S22X
	JMP	WINIT		;USED BY 221A & HIGHER ONLY
	ENDIF
;
CRTIN:	IN	SER1D	;GET DATA
STRPRET: ANI	7FH	;STRIP PARITY
	RET
PASBYTE: DB	0	;BUFFER FOR PASSWORD BYTE
;
;***********************************************************
;
;		IOBYTE PROCESSOR
;	INCLUDING SCANNER OF MODEM & CONSOLE
;
;***********************************************************
;
CONOUT:
	LDA	MDMBYT		;MODEM MODE?
	ORA	A
DB	JRNZ,	CONOUT0-$-1	;IF NOT ,SKIP MODEM CHK
	;
	IN	TPORT
	ANI	P0TBMT		;XMIT BUFFER EMPTY?
DB	JRZ,	CONOUT-$-1 AND 0FFH
	;
	MOV	A,C
	OUT	DPORT
	;	
CONOUT0: ;CONSOLE OUTPUT ROUTINE
	CALL	CONSOL		;COMMON ROUTINE
	DW	TTYOUT		;TTY OUTPUT
	DW	CRTOUT		;CRT OUTPUT
	DW	LIST		;LIST OUTPUT 
	DW	UC1OUT		;USER CONSOLE OUTPUT
;
CONSOL:
	MVI	A,CONCNT	;SHIFT COUNTER
;
DISPAT:	;I/O DISPATCHER - TO MAP LOGICAL TO PHYSICAL
	XTHL	 		;GET RETURN ADDR & SAVE HL
	PUSH	B		;SAVE BC
	PUSH	D		;SAVE DE
 	MOV	B,A		;PUT COUNTER VALUE IN B
	LDA	IOBYTE		;GET THE IO BYTE
	;
DISPAT1:
	DCR	B		;SHIFT IOBYTE UNTIL
DB	JRZ,	DISPAT2-$-1	;COUNT IN B=0
	RRC
	RRC
DB	JR,	DISPAT1-$-1 AND 0FFH ;SHIFT NEXT TWO BYTES
	;
DISPAT2:
	ANI	03H		;MASK OUT BITS 0,1
	RLC			;DOUBLE
	MVI	D,0		;CLEAR D
	MOV	E,A		;
	DAD	D		;H,L POINTS TO ENTRY
	MOV	A,M		;GET LOW BYTE
	INX	H		;POINT TO HIGH BYTE
	MOV	H,M		;GET HIGH BYTE
	MOV	L,A		;H,L POINTS TO SUBR.
	POP	D		;RESTORE DE
	POP	B		;RESTORE BC
	XTHL			;RSTR HL & PUT RET ON STACK
	RET
;
CONST:
	LDA	MDMBYT		;GET MODEM BYTE
	ORA	A		;ZERO?
DB	JRNZ,	CONST0-$-1	;IF NOT, SKIP MODEM CHECK
	;
;CHECK FOR MODEM CHAR READY
	IN	TPORT		;GET MODEM STATUS
	ANI	P0DAV		;DATA AVAILABLE?
DB	JRZ,	CONST0-$-1	;NO, TEST KEYBOARD
	;
;GOT CHAR FROM MODEM
	MVI	A,0FFH		;SHOW TRUE
	ORA	A		;RESET FLAGS
	RET
	;
CONST0:	;CONSOLE STATUS, RETURN 0FFH IF READY ,0 IF NOT
	CALL	CONSOL		;COMMON ROUTINE
	DW	TTYST		;TTY STATUS
	DW	CRTST		;CRT STATUS
	DW	RDRST		;READER STATUS 
	DW	UC1ST		;USER CONSOLE STATUS
;
CONIN:	CALL	TEST		;BACKGROUND MEMORY TEST
	CALL	CONST
	ORA	A		;SET CC
DB	JRZ,	CONIN-$-1 AND 0FFH
;TEST KEYBOARD FIRST
	CALL	CONST0
	ORA	A		;SET CC
DB	JRZ,	KEYNK-$-1	;NO KEYBOARD CHAR
	;
;GOT KEYBOARD CHAR
CONIN0:	;CONSOLE INPUT ROUTINE
	CALL	CONSOL		;COMMON CONSOLE ROUTINE
	DW	TTYIN		;TTY INPUT
	DW	CRTIN		;CRT INPUT
	DW	READER		;READER INPUT 
	DW	UC1IN		;USER CONSOLE INPUT
	;
KEYNK:	;GET CHAR FROM MODEM IF READY
	LDA	MDMBYT
	ORA	A
	MVI	A,0FFH		;RET FF IF NO CARRIER
	RNZ
	;
	IN	TPORT		;STATUS
	ANI	P0DAV		;RECEIVE CHAR?
DB	JRZ,	CONIN-$-1 AND 0FFH ;NO MODEM CHAR
	IN	DPORT		;GET DATA
	JMP	STRPRET		;STRIP PARITY & RETURN
;
READER0: CALL TEST		;BACKGROUND MEM TEST
READER:	;READER INPUT ROUTINE
	MVI	A,RDRCNT	;SHIFT COUNTER
	CALL	DISPAT		;GO TO LOOKUP ROUTINE
	DW	TTYRDR		;READER IS TTY KBD.
	DW	HSRIN		;IS HIGH SPEED READER
	DW	UR1IN		;USER READER ONE
	DW	UR2IN		;USER READER TWO
;
PUNCH:	;PUNCH OUTPUT ROUTINE
	MVI	A,PCHCNT	;SHIFT COUNTER
	CALL	DISPAT		;LOOK UP ROUTINE
	DW	TTYOUT		;PUNCH IS TTY
	DW	PUNOUT		;HIGH SPEED PUNCH
	DW	UP1OUT		;USER PUNCH ONE
	DW	UP2OUT		;USER PUNCH TWO
;
LIST:	;LIST OUTPUT ROUTINE
	MVI	A,LSTCNT	;SHIFT COUNTER
	CALL	DISPAT		;GO TO DISPATCHER
	DW	TTYOUT		;LIST DEVICE IS TTY
	DW	CRTOUT		;LIST DEVICE IS CRT
	DW	LPTOUT		;LINE PRINTER
	DW	UL1OUT		;USER LIST DEVICE
;
LISTST:	;LIST DEVICE STATUS ROUTINE
	MVI	A,LSTCNT	;SHIFT COUNTER
	CALL	DISPAT		;LOOK UP ROUTINE
	DW	TTYST		;RETURN TTY STATUS
	DW	CRTST		;RETURN CRT STATUS
	DW	LPTST		;LINE PRINTER STATUS
	DW	UL1ST		;USER LIST DEVICE STATUS
;
;**********************************************************
;
;	       NORTH STAR HORIZON I/O DRIVERS
;
;**********************************************************
;
;		CRT DRIVERS (LEFT SERIAL PORT)
;
CRTST:	;CRT STATUS
	IN 	SER1ST	;GET SERIAL ZERO STATUS
DB	JR,	TSTSTAT-$-1
;
CRTOUT:	;CRT OUTPUT
	IN	SER1ST	;GET STATUS FOR LEFT SERIAL
	ANI	OUTRDY	;READY TO RECEIVE DATA?
DB	JRZ,	CRTOUT-$-1 AND 0FFH	;NO, LOOP TIL READY
	MOV	A,C	;GET DATA
      	OUT	SER1D	;SEND TO DATA PORT
	RET
;
;		TTY DRIVERS (RIGHT SERIAL PORT)
;
TTYST:		;TTY INPUT STATUS
	IN	SER2ST	;GET SERIAL TWO STATUS
DB	JR,	TSTSTAT-$-1
;
TTYRDR:	;TTY KEYBOARD AS READER
	IN	SER2ST
	ANI	INRDY
	JZ	READER0
TTYIN:	IN	SER2D	;GET DATA
	JMP	STRPRET	
;
TTYOUT:	;TTY OUTPUT
	IN	SER2ST	;GET STATUS FOR SERIAL PORT 1
	ANI	OUTRDY	;READY FOR DATA?
DB	JRZ,	TTYOUT-$-1 AND 0FFH	;NO, WAIT TIL READY
	MOV	A,C	;GET DATA
	OUT	SER2D	;SEND TO SERIAL 2 DATA PORT
	RET
;
;		READER DRIVER (PARALLEL INPUT PORT)
;
RDRST:				;READER STATUS
	IN	MOTHER		;GET STATUS
TSTSTAT:
	ANI	INRDY		;MASK FOR READY
	RRC			;SHIFT TO LSB
DCRCMA:
	DCR	A		;IF ZERO, MAKE FF
	CMA			;COMPLEMENT THE ACC.
	RET

HSRIN:				;HIGH-SPEED READER INPUT 
	IN	MOTHER		;GET STATUS
	ANI	INRDY		;READY WITH DATA?
	JZ	READER0		;LOOP UNTIL PI FLAG
	IN	PARAL		;GET PARALLEL INPUT DATA
	ANI	07FH		;STRIP PARITY
	MOV	B,A		;SAVE
	MVI	A,30H		;LOAD COMMAND BYTE TO A
	OUT	MOTHER		;RESET PI FLAG
	MOV	A,B		;RECOVER DATA
	RET
;
;		PUNCH DRIVER (PARALLEL OUTPUT PORT)
;
PUNOUT:				;HIGH-SPEED PUNCH OUTPUT 
LPTOUT:				;LINE PRINTER OUT
	;PUNOUT AND LPTOUT ARE SAME ROUTINE
	IN	MOTHER		;GET STATUS
	ANI	OUTRDY		;READY FOR DATA
DB	JRZ, 	LPTOUT-$-1 AND 0FFH	;NO, WAIT TIL READY
	MOV	A,C		;GET DATA
	OUT	PARAL		;SEND TO PARALLEL PORT
	MVI	A,20H		;COMMAND BYTE
	OUT	MOTHER		;RESET PO FLAG
	MOV	A,C		;GET DATA AGAIN
	RET
;
LPTST:				;LINE PRINTER STATUS 
	IN	MOTHER		;GET STATUS
	ANI	OUTRDY		;READY TO RECEIVE CHAR
DB	JR,	DCRCMA-$-1 AND 0FFH
;
;**********************************************************
;
;	USER WARM INITIALIZATION ROUTINE
;		
;**********************************************************
;
WINIT:
PRNTIM:
	IF	NOT CLOCK
	CALL	ILPRT2
	DB	ESC,EXGRAPH,0
	RET
	ENDIF
;
	IF 	CLOCK AND NOT S145
	CALL	TIME
	DCX	B
	DCX	B
	JMP	PRNSTR1
	ENDIF
	;
;
;**********************************************************
;This patch which is called from the CCP provides for a
;report of USER number at the prompt....i.e. A2> for USER 2,
;'A' drive.
;
	IF	NOT S145
UPATCH:	CALL	GETUSR		;GET USER NUMBER
	ANI	0FH		;KILL UNWANTED BITS
DB	JRZ,	UPA2-$-1	;IF USER 0, DON'T REPORT
	CPI	10
DB	JRC,	UPA1-$-1	;JIF USER NUM = 0 THRU 9
	SUI	10		;USER NUM = 10 THRU 15
	PUSH	PSW
	MVI	C,'1'
	CALL	CONOUT		;PRINT A '1'
	POP	PSW
	;
UPA1:	ADI	'0'
	MOV	C,A
	CALL	CONOUT		;PRINT DIGIT
	;
UPA2:	MVI	C,'>'
	CALL	CONOUT		;PRINT '>', EXIT
	LDA	H89FLG
	ORA	A		;H89 MODE?
	CNZ	DARMCLK		;DISARM REAL TIME CLOCK
	XRA	A
	STA	TRAPBYT		;CLEAR THE TRAPS
	STA	H89FLG		;SET H89 MODE TO FALSE
	JMP	RSTPRMS		;RESET PARAMETERS & RETURN
;
;**********************************************************
;The password checking routine- uses string comparator
;that is contained in the CCP.
;
CKPASS0: LXI	H,PASBYTE
DW	BIT2M
DB	JRZ,	OK-$-1
	LXI	H,PAS2
	SHLD	STRPTR
	LXI	H,PASTBL2
	SHLD	CMDPTR
DB	JR,	CKPASS-$-1
	;
PASSINT: CALL	LOGTST
DB	JRZ,	OK-$-1
	LXI	H,PAS1
	SHLD	STRPTR
	LXI	H,PASTBL1
	SHLD	CMDPTR
	;
CKPASS:	MVI	A,1
	STA	CMDCNT
	MVI	A,10
	STA	CMDLEN
	MVI	C,4	;GIVES 4 TRIES
	PUSH	B
	;
CKAGIN:	CALL	ILPRT
	DB	'Password:  ',0
	POP	B
	MVI	B,14	;TO KEEP HIM FROM CLOBBERING
			;THE CODE
	LXI	H,FCBFN
DRCON:
	CALL	CONIN
DW	SET7A		;SET BIT 7 OF PASSWORD CHAR HIGH
	CPI	CR+80H
DB	JRNZ,	DRCN2-$-1
	MVI	A,20H
	MVI	B,1
DRCN2:	MOV	M,A
	INX	H
	DCR	B
DB	JRNZ,	DRCON-$-1 AND 0FFH	
	;
	DCR	C
	JZ	RELOG0
	PUSH	B
	JMP	SRCHCMD
	;
;**********************************************************
;Routine to set 2nd password bit so that entry of 2nd
;password is required again.
;
LOCK:	LXI	H,PASBYTE
DW	SET2M
	;
;fall through
***********************************************************
;Say ok.
OK:	CALL	ILPRT
	DB	'Ok',0
	JMP	RETCCP
;
;**********************************************************
;ROUTINE TO SET UP THE MODEM UART PARAMETERS.
;
SETUP:	MOV	A,M
	ORA	A
DB	JRNZ,	SETURT-$-1
	LXI	H,UART
SETURT:	LXI	D,BAUDRT
	LXI	B,5
DW	LDIR
	RET
;
;**********************************************************
;ROUTINE TO CHECK EXIT REQUEST FROM A LOOP
;
REQEXIT: CALL	CONST
	ORA	A
	RZ
	CALL	CONIN
	RET
;
	ENDIF
;
;**********************************************************
;Print hex subroutines used in the background memory test.
;
PRTHX:	PUSH	PSW
	RRC
	RRC
	RRC
	RRC
	CALL	PRTHX1
	POP	PSW
;
PRTHX1:	ANI	0FH
	CPI	10
DB	JRC,	PRTHX2-$-1
	ADI	7
;
PRTHX2:	ADI	'0'
	MOV	C,A
	JMP	CONOUT
;
;**********************************************************
;DISARM CLOCK INTERRUPT BEFORE RETURNING TO CCP
;
CCPRET:	XRA	A
	STA	PASBYTE
	MVI	A,P3CLEAR
	OUT	CPORT	;BE SURE PHONE LINE DISCONNECTED
	;
	CALL	DARMCLK	;IN CASE RETURNING TO CCP
	JMP	RELOG0
;
USR1END: EQU	$		;END OF USER1 CODE FOR NOW
USR1SIZE EQU	USR1END-USER1	;MUST NOT EXCEED SPACE 
				;ALLOCATED IN USER1
;
;**********************************************************
;
;	THIS IS THE INIT ROUTINE.  IT WILL RUN AT CCP-900H
;	AND WILL MOVE THE USER2 CODE JUST ABOVE CPM WHERE
;	YOU MUST HAVE RESERVED EITHER 1 OR 2K, SIZING YOUR
;	SYSTEM ACCORDINGLY. THE INIT CODE IS NOT MOVED
;	AND WILL BE OVERWRITTEN BY TRANSIENT PROGRAMS.
;
	ORG	INIT
;
INITIAL:
	LXI	H,SOURCE	;SOURCE OF USER2 CODE
	LXI	D,USER2		;DEST OF USER2 CODE
	LXI	B,USR2END-USER2	;# OF BYTES TO MOVE
DW	LDIR			;MOVE THEM
;
	MVI	A,IOBYT		;THE VALUE
	STA	IOBYTE		;THE LOCATION
;
	XRA	A		;SET TO CLEAR MOTHERBOARD
	OUT	MOTHER
	OUT	MOTHER		;EXTRAS FOR TIMING, 
	OUT	MOTHER
	OUT	MOTHER		;DON'T ASK
	OUT	CPORT
	OUT	TPORT
;
	MVI	A,40H		;DISABLE PARITY LOGIC
	OUT	MEMORY		;BEFORE READING RAM
	;
	LHLD	PROMLOC-1	;POINT TO LOC OF PROMHI.
				;AT 0CH OF CLDBT FOR 1.45.
				;AT BIOS+6F5H FOR 2.0,2.2,
				;&2.21A 
	MVI	L,0		;ZERO L
	;
	IF	PARITY		;WANT PARITY SETTING CODE?
	MOV	D,H
	MOV	E,L
	LXI	B,-1023		;NUMBER OF BYTES TO CLEAR
DW	LDDR			;SET PARITY ON ALL RAM
	MVI	A,41H		;PARITY ENABLE CODE
	OUT	MEMORY		;REARM PARITY LOGIC
	ENDIF
	;
	LXI	H,MODE		;POINT TO MODE BYTE
DW	SET4M			;SET MODE BYTE SO THAT
				;INTERRUPTS ARE ENABLED
				;AFTER DISK ACCESS
	MVI	A,USER2/256	;PAGE ADDR OF PARITY ERROR
				;ROUTINE
DW	MOVIVA			;PUT HI BYTE IN IV REGISTER
DW	IM2			;SET INTERRUPT MODE 2
	EI
;
	MVI	A,0CEH		;INITIALIZE UARTS
				;2 STOPS, 16X CLOCK
				;8 BITS, NO PARITY
	OUT	SER1ST
	OUT	SER2ST
;
	MVI	A,37H		;COMMAND: RTS, ER,
				;RXF, DTR, TXEN
	OUT	SER1ST
	OUT	SER2ST
;
;
	IN	DPORT		;CLEAR MODEM PORT
	IN	SER1D		;CLEAR INPUT BUFFER
	IN	SER2D		;CLEAR INPUT BUFFER
	IN	PARAL		;CLEAR PARALLEL PORT
	MVI	A,PASBYT
	STA	PASBYTE
;
DB	JR,	TINU-$-1
;
; ***THIS IS A SPECIAL ORG FOR THE LIFEBOAT FORMAT BYTE****
; BE SURE THAT PRECEEDING CODE DOES NOT OVERWRITE THIS LOC.
	ORG	INIT+5CH
	DS	1		;STORAGE FOR FORMAT BYTE
;
TINU:	MVI	A,0C3H
	STA	52H
	LXI	H,TIME
	SHLD	53H
	MVI	A,30H		;RESET PI FLAG
	OUT	MOTHER
	RET
;
INITEND:EQU	$
INITSIZE EQU	INITEND-INIT
;
;**********************************************************
; USER2 code starts here. Will be relocated to just above
; CP/M by the INIT code.
;
SOURCE:	EQU	$		;SOURCE OF USER2 CODE
OFFSET:	EQU	USER2-SOURCE	;OFFSET FOR USER2 CODE
FR:	EQU	-1-OFFSET	;FORWARD RELATIVE
BR:	EQU	FR+0FFH+1	;BACKWARD RELATIVE
;
;**********************************************************
; THIS IS RAM PARITY ERROR ROUTINE FOR USE WITH NORTH STAR
; PARITY MEMORY BOARDS. INITIALIZATION IN INIT MUST BE TO
; Z80 INTERRUPT MODE 2 AND PARITY ERROR SHOULD ACTIVATE INT-
; ERRUPT VECTOR 5 BY JUMPERING ON MEMORY BOARDS. DO NOT 
; CHANGE THE ORG FOR THIS CODE + SEE THE WARNING BELOW AT
; LABEL 'STORE'.
;
PERR:	EQU	$+OFFSET
	PUSH	PSW
	CALL	ILPRT
	DB	'Ram parity error',0
	MVI	A,40H
	OUT	MEMORY		;DISARM PARITY LOGIC
	POP	PSW
	;
;**********************************************************
;Routines to disconnect the line upon clock interrupt and
;carrier not detected. The routines are peculiar to the
;North Star Horizon hardware. Provide your own service
;routines for other hardware. This routine also provides for
;incrementing a counter at 000BH every 3.33 ms. for the use
;of some H89 games. Carrier checking is done only one out of
;every 1000H interrupts which are provided by the real time
;clock every 3.33 ms.
;
DISCONN: EQU	$+OFFSET
	PUSH	PSW
	PUSH	H
	LHLD	COUNTER
	DCX	H		;DECREMENT COUNTER
	MOV	A,H		;TO TEST FOR ZERO
	ORA	L		;
	SHLD	COUNTER
	PUSH	PSW
	LDA	H89FLG
	ORA	A
DB	JRZ,	NOTH89-$+FR
	LHLD	000BH
	INX	H
	SHLD	000BH
NOTH89:	EQU	$+OFFSET
	CALL	RSTCLK
	POP	PSW
DB	JRNZ,	DUN-$+FR
	LXI	H,INTCNTR
	SHLD	COUNTER
	LDA	H89FLG
	ORA	A
DB	JRNZ,	DUN-$+FR
	CALL	CHECK
DUN:	EQU	$+OFFSET
	POP	H
	POP	PSW
	RET
;
ARMCLK:	EQU	$+OFFSET
	DI
	LXI	H,INTCNTR
	SHLD	COUNTER
	MVI	A,0C0H	;ARM CLOCK INTERRUPT
	OUT	MOTHER
	;
RSTCLK:	EQU	$+OFFSET
	MVI	A,50H
	OUT	MOTHER
	EI
	RET
;
;**********************************************************
;Computime T-102 clock routine
;
	IF	CLOCK
TIME:	EQU	$+OFFSET 	;DISPAYS DATE AND TIME
	IN	CLKBRD		;CLOCK STATUS
	INR	A		;NO CLOCK BOARD?
	LXI	D,NOCLOCK
	RZ			;SAY NO CLOCK BOARD
	;
	LXI	H,HHMM		;POINT TO START OF HR.,MIN.
	XRA	A		;TO GET THE HR. TENS
	CALL	GETDIG		;GET THE DIGITS
	LXI	H,MMDD		;POINT TO DATE DIGITS
	MVI	A,8		;TO GET MONTH TENS
	CALL	READ		;READ IT
	CPI	63		;TEST TO SUPPRESS LEADING 0
DB	JRNZ,	NOBLNK-$+FR
	MVI	A,20H		;SUPPRESS WITH A BLANK
NOBLNK:	EQU	$+OFFSET
	MOV	M,A		;PUT IN MEMORY
	INX	H		;POINT TO NEXT DIGIT
	MVI	A,9		;SET TO READ MONTH UNITS
	CALL	GETDIG		;GET IT
	LXI	D,DTMSG		;POINT TO DATE/TIME MSG
				;SUPPLY YOUR OWN OUT ROUTINE
	PUSH	D
	XCHG
	POP	D
	PUSH	D
	POP	B		;NOTE, THAT BC, DE, & HL ALL
				;CONTAIN ADDRESS OF DATE/TIME
				;MESSAGE FOR THE CONVENIENCE
				;OF YOUR APPLICATIONS. 
				;string terminator is 0 or '$'
	RET
;
READ:	EQU	$+OFFSET 	;READ A DIGIT, CONV TO ASCII
	OUT	CLKBRD		;SEND FUNCT # TO CLOCK BOARD
	CALL	CLKDLY
	IN	CLKBRD		;DIGIT RETURNED IN A
	ANI	0FH		;MASK
	ADI	30H		;CHANGE TO ASCII
	RET
;
GETDIG:	EQU	$+OFFSET 	;GET A DIGIT AND STORE IT
	CPI	12		;DONE WITH DATE?
	RZ
	CPI	6		;DONE WITH TIME?
	RZ
	MOV	B,A		;SAVE A FOR AWHILE
	CALL	READ		;GET DIGIT FROM CLOCK
	MOV	C,A		;SAVE FOR AWHILE
	MOV	A,M		;READ CHAR IN MEMORY
	CPI	2FH		;IS IT / ?
DB	JRNZ,	SKIP1-$+FR
	INX	H		;IF SO GO INCREMENT POINTER
SKIP1:	EQU	$+OFFSET
	CPI	3AH		;IS IT : ?
DB	JRNZ,	SKIP2-$+FR	;ADVANCE POINTER TO SKIP
	INX	H
SKIP2:	EQU	$+OFFSET
	MOV	M,C		;PUT DIGIT IN MEMORY
	MOV	A,B		;GET SAVE CLOCK FUNCT VALUE
	INX	H		;POINT TO NEXT DIGIT
	INR	A		;ADVANCE TO NEXT FUNCTION
	JMP	GETDIG		;AND GET ANOTHER DIGIT
;
	DB	ESC,EXGRAPH
DTMSG:	EQU	$+OFFSET 	;DATE/TIME STORAGE LOCATION
	DB	'Time '
HHMM:	EQU	$+OFFSET
	DB	'HH:MM:'
SECX10:	EQU	$+OFFSET
	DB	'S'
SECX1:	EQU	$+OFFSET
	DB	'S'
;
DATE:	EQU	$+OFFSET
	DB	'  Date '
MMDD:	EQU	$+OFFSET
	DB	'MM/DD/'
YY:	EQU	$+OFFSET
	DB	'1982'
	DB	0,'$'
;
	DB	ESC,EXGRAPH
NOCLOCK:	EQU	$+OFFSET
	DB	'NoClk',0,'$'
	ENDIF
;
;**********************************************************
;LOSS OF CONNECTION TEST
;
CARCK:	EQU	$+OFFSET
;
;THE PMMI MODEM AUTOMATICALLY HANGS UP THE PHONE AFTER
;15 SECONDS OF LOSS OF CARRIER, PROVIDING YOU OUTPUT TO
;PORT 0 TO ALLOW IT (WHICH THIS PROGRAM DOES).
;
;..SO, THIS ROUTINE FIRST CHECKS IF THE MODEM HAS HUNG UP,
;AND IF SO, RETURNS WITH CARRY SET.  IF NOT, IT CHECKS FOR
;CARRIER AND RETURNS IF CARRIER IS ON; OTHERWISE WAITS FOR
;CARRIER WHILE STILL TESTING FOR DISCONNECT.
;
;IT TESTS THE PMMI "CTS" (CLEAR TO SEND) BIT
;WHICH IS 0 WHEN THERE IS CARRIER.
;
	IN	RPORT	;GET STATUS
	ANI	P2CONN	;CONNECTED?
	STC		;(IN CASE NOT)
	RNZ		;HUNG UP.
;STILL CONNECTED, CHECK FOR CARRIER
	CALL	CKCTS	;SEE IF CLEAR TO SEND
	RZ
;LOOP UNTIL EITHER CONNECTION LOST, OR CARRIER RETURNS
DB	JR,	CARCK-$+BR
;
;**********************************************************
;DELAY ROUTINES
;
; .1 SEC DELAY
ANSDLY:	EQU	$+OFFSET
	PUSH	B
	;
	IF	FASTCLK
	LXI	B,16667	;4 MHZ
	ENDIF
	;
	IF	NOT	FASTCLK
	LXI	B,8334	;2 MHZ
	ENDIF
	;
	JMP	DELAY1
	;
;**********************************************************
;The values at TABLE and TABLE1 must be at 0EFH and 0F7H
;respectively in this page.  They are the addresses of the
;parity error message and phone disconnect service routines.
;Those addresses are called by the Z80 mode 2 interrupt 
;when a parity error is detected on a north star memory 
;board and phone line disconnect with a PMMI modem using 
;interrupts 5 and 6 respectively.
;
STORE:	EQU	$+OFFSET
	DS	USER2+00EFH-$-OFFSET
;
;**************************************
;	*****WARNING*****	      *
; IF YOU ADD CODE IN USER2 ABOVE THIS *
; POINT, BE CERTAIN THAT THE LOCATION *
; OF THE FOLLOWING TABLE ADDRESS IS   *
; EQUAL TO OR > THAN THE ADDRESS      *
; AT 'STORE' AND THAT THE LO BYTE IS  *
; 0EFH IN THIS PAGE OR ELSE THE RAM   *
; PARITY ERROR MESSAGE WON'T WORK.    *
;**************************************
;
TABLE:	EQU	$+OFFSET	;THIS ADDRESS MUST BE AT 
				;0EFH IN SAME PAGE AS PERR
	DW	PERR
;
;Routine to check carrier
;
CKCTS:	EQU	$+OFFSET
	IN	RPORT	;LOOK AT STATUS
	ANI	P2CTS	;GET CARRIER DETECT BIT
	RET
	DB	0		;SPARE, DO NOT REMOVE
;
TABLE1: EQU	$+OFFSET	;THIS ADDRESS MUST BE AT 
				;0F7H IN THIS PAGE
	DW	DISCONN		;ADDR OF ROUTINE TO HANGUP
				; THE LINE
;
H89FLG:	EQU	$+OFFSET
	DB	0	;INITIAL VALUE
;
***********************************************************
; 2 MSEC DELAY
;
CLKDLY:	EQU	$+OFFSET
	PUSH	B
	;
	IF	FASTCLK
	LXI	B,333
	ENDIF
	;
	IF	NOT FASTCLK
	LXI	B,167
	ENDIF
	;
DELAY1:	EQU	$+OFFSET
	DCX	B
	MOV	A,B
	ORA	C
DB	JRNZ,	DELAY1-$+BR
	POP	B
	RET
;
;**********************************************************
	IF	(S201 OR S22 OR S22X)
;This is Ward's 'BYE' program modified to run as CCP-includ-
;ed command. It comes up in auto-answer mode and requires a
;password using the CCP-included LOGIN command routine. You
;may exit locally to the system by hitting the ESCape key.
;You can also enter the command ANSWR after you are in the
;system to give an immediate answer tone. (The remote can
;then send a few C/R's to set to his baud rate and will get
;in without requiring a password.)  After the remote is in,
;he may enter the ANSWR command, return to his system to 
;change his speed, and then come back with C/R's to change 
;the answer baud rate. In each case, a second password must 
;be entered to obtain CCP privilege to higher USER areas and 
;CCP command/transients using the PASS command. 
;
BYE:	EQU	$+OFFSET
	CALL	PRNTIM
	CALL	ILPRT	;PRINT THIS MSG:
	DB	'Goodbye, call again',CR,LF,0
	;
HANGUP: EQU	$+OFFSET
;
;SET BIT 7, PMMI AUX INTERFACE, CAUSING POWER TO GO OFF
;(has no effect if aux interface is not implemented)
	MVI	A,OFFPWR
	OUT	CPORT	
	;
OFF:	EQU	$+OFFSET
	MVI	A,PASBYT
	STA	PASBYTE
	CALL	RSTMDM	;TO RESET THE MODEM BYTE
	;
;CLEAR DTR CAUSING PHONE TO HANG UP
	MVI	A,P3CLEAR
	OUT	CPORT
	CALL	ARMCLK
	CALL	ILPRT2
	DB	CR,'*>',0
SETPRMS: EQU	$+OFFSET
	CALL	RSTPRMS
;
;AWAIT RINGING
RINGWT:	EQU	$+OFFSET
;
;CHECK LOCAL KEYBOARD FOR 'ESC' EXIT REQUEST.
	CALL	REQEXIT
	CPI	ESC
	JZ	CCPRET  ;YES, --EXIT-- TO CP/M
	IN	RPORT	;GET THE STATUS
	ANI	P2RDET	;RINGING?
DB	JRNZ,	RINGWT-$+BR	;NO, WAIT
;
	IF	PARTYLN
	CALL	DARMCLK
;NOW WAIT UNTIL RING IS FINISHED
ENDRING: EQU	$+OFFSET
	CALL	ANSDLY		;.1 SEC DELAY FOR DEBOUNCE
	IN	RPORT		;GET STATUS
	ANI	P2RDET		;STILL RINGING?
DB	JRZ,	ENDRING-$+BR	;WAIT UNTIL RING FINISHED
;
;PHONE IS RINGING
;
;      THIS ROUTINE MINIMIZES THE COMPUTER'S INTERFERENCE
;      WITH NORMAL HOUSEHOLD PHONE USE BY HAVING COMPUTER
;      FOLK DIAL, LET THE PHONE RING ONCE, HANG UP AND 
;      THEN DIAL AGAIN.  WHEN THE PHONE RINGS ONLY ONCE IT
;      ALERTS THE COMPUTER WHICH THEN WAITS FOR AND ANSWERS
;      ANY RING WHICH OCCURS WITHIN THE NEXT 40 SECONDS.
;
	MVI	L,45		;DELAY 4.5 SECONDS FOR NEXT RING
WAITNX:	EQU	$+OFFSET
	CALL	ANSDLY		;WAIT .1 SECONDS
	DCR	L		;MORE TO GO?
DB	JRNZ,	WAITNX-$+BR	;YES?...LOOP
	IN	RPORT		;GET THE STATUS
	ANI	P2RDET		;RINGING AGAIN?
DB	JRNZ,	EXPECT-$+FR	;NO?...ITS FOR ME
;CALL NOT FOR COMPUTER - WAIT UNTIL RINGING DONE, THEN RESET
WAITNR:	EQU	$+OFFSET
	MVI	L,100		;WAIT FOR 10 SECS NO RINGING
WAITNRL: EQU	$+OFFSET
	CALL	ANSDLY 		;DELAY .1 SECONDS
	IN	RPORT		;GET THE STATUS
	ANI	P2RDET		;STILL RINGING?
DB	JRZ,	WAITNR-$+BR	;YES, WAIT 10 MORE SECONDS
	DCR	L		;NO RING, MAYBE WE'RE DONE
DB	JRNZ,	WAITNRL-$+BR	;NO, LOOP SOME MORE
DB	JR,	HANGUP-$+BR
;
EXPECT:	EQU	$+OFFSET
	LXI	H,400		;40 SECONDS TO REDIAL
LOOKAGN: EQU	$+OFFSET
	IN	RPORT
	ANI	P2RDET		;RINGING AGAIN?
DB	JRZ,	ANSWER-$+FR
	CALL  	ANSDLY
	DCX	H
	MOV	A,H
	ORA	L
DB	JRNZ,	LOOKAGN-$+BR
	JMP	HANGUP
	ENDIF
;
DB	JR,	ANSWER-$+FR
;	
MDMBYT:	EQU	$+OFFSET
	DB	0FFH	;MODEM BYTE, 0FFH=OFF
;
DARMCLK: EQU	$+OFFSET
	MVI	A,40H	;DISARM CLOCK INTERRUPT
	OUT	MOTHER
	RET
;
;SETUP MODEM
ANSWR:	EQU	$+OFFSET ;IMMEDIATE ANSWER TONE
	LXI	H,PASBYTE ;POINT TO PASSWORD BYTE
DW	RES5M		;NO 1RST PASSWORD REQUIRED
	;
ANSWER:	EQU	$+OFFSET
	CALL	ARMCLK
	LXI	H,UART
	CALL	SETMDM	;SET MODEM BYTE
SYNCH:	EQU	$+OFFSET
	LDA	DTR	;TURN ON DTR
	OUT	CPORT	;.. AND SET FILTER VALUE
	CALL	ANSDLY	;TIME TO TURN ON
	MVI	A,P0110+P0ANSW
	OUT	TPORT	;ANSWER PHONE
	CALL	ANSDLY
	LDA	UARTWD
	OUT	TPORT
	IN	DPORT	;..CLEAR MODEM
	IN	DPORT	;..MAKE SURE IT'S CLEAR
	LDA	BAUDRT
	OUT	RPORT	;SET BAUD RATE DIVISOR
	CALL	CONIN	;GET CHARACTER FROM MODEM
	CPI	CR	;IF A CARRIAGE RETURN...
DB	JRZ,	WELCOME-$+FR 
	CPI	LF	;LINE FEED?
DB	JRZ,	WELCOME-$+FR
	CPI	'C'-40H	;IF A CONTROL-C
DB	JRZ,	WELCOME-$+FR  ;YES, EXIT
	CALL	SETUP
DB	JR,	SYNCH-$+BR ;TEST MORE - INVALID BAUD RATE
;
UART:	EQU	$+OFFSET
	DB	B300,P3TODTR,P0NOPY+P08BIT,'30'
	DB	B450,P3TODTR-20H,P0NOPY+P08BIT,'45'
	DB	B110,P3TODTR,P0NOPY+P08BIT+P0TSB,'11'
	DB	B600,P3TODTR-20H,P0NOPY+P08BIT,'60'
;	DB	B520,P3TODTR-20H,P0NOPY+P08BIT,'52'
;	DB	B220,P3TODTR,P0NOPY+P08BIT,'22'
;	DB	B710,P3TODTR-20H,P0NOPY+P08BIT,'71'
	DB	0
BAUDRT:	EQU	$+OFFSET
	DB	B600
DTR:	EQU	$+OFFSET
	DB	P3TODTR-20H
UARTWD:	EQU	$+OFFSET
	DB	P0NOPY+P08BIT
RATE:	EQU	$+OFFSET
	DB	'600 baud',0
;
WELCOME: EQU	$+OFFSET
	LXI	B,RATE
	CALL	PRNSTR1	;SHOW THE BAUD RATE
	CALL	PRNTIM
	LXI	H,SIGNON
	CALL	PRNSTR2	;SHOW SIGN-ON STRING W/O SCRCLR
	;
	IF	RUNHELP
	JMP	GETCMD	;RUN 'HELP'
	ENDIF
	;
	IF	NOT RUNHELP
	JMP	RETCCP
	ENDIF	
	;
;**********************************************************
;Routines to trap transient files if they are resident
;on drive A.  If DIR.COM not present, then the CCP code for
;the DIR command will be executed. If TYPE.COM not present,
;then the CCP code for the TYPE command will be executed.
;This trapping is useful for SD.COM and MLIST.COM re-named
;to DIR.COM and TYPE.COM respectively.
;**NOTE**  Do not use a Directory transient that scans user
;areas such as SD-21 or SD-22. KDIR is ok.  You can use SD-42
;if you set AOPT to FALSE and add an IF AOPT and ENDIF around
;the [lda,newusr; cmp m; jnz mordir] sequence at the label,
;SYSFOK. Otherwise you will defeat the universal user area
;features in this program so far as directories are concerned,
;although the universallity will still apply to execution and
;finding of files in users 13, 14, and 15.
;
DIR1:	EQU	$+OFFSET
	LXI	H,TRAPBYT
DW	SET0M			;SET DIR TRAP
	JMP	GETRANS
	;
TYPE1:	EQU	$+OFFSET
	LXI	H,TRAPBYT
DW	SET1M
	JMP	GETRANS
	;
HUH0:	EQU	$+OFFSET
	LXI	H,TRAPBYT
DW	BIT0M			;SEE IF DIR TRAP SET
	JNZ	DIR		;CCP DIR CODE IF NOT
DW	BIT1M			;SEE IF TYPE TRAP SET
DW	RES1M
	JNZ	TYPE		;CCP TYPE CODE IF NOT
	CALL	ILPRT
	DB	'No, ',BELL,0
	CALL	LOGTST
	JNZ	RELOG
	JMP	HUH+3		
	;
;**********************************************************
;Routine for ORIG(inate) command.
;
ORIG:	EQU	$+OFFSET
	LDA	MDMBYT
	ORA	A
	JZ	HUH
	CALL	WRFCB
ORIG1:	EQU	$+OFFSET
	LXI	H,UART
ROTATE:	EQU	$+OFFSET
	CALL	SETUP
	JZ	HUH
	PUSH	H
	LXI	H,BAUDRT+3
	LDA	FCBFN
	CPI	20H
DB	JRNZ,	COMPR-$+FR
	MVI	A,'3'	;DEFAULT TO 300 BAUD
COMPR:	EQU	$+OFFSET
	CMP	M
	POP	H
DB	JRNZ,	ROTATE-$+BR
	MVI	A,P3CLEAR
	OUT	CPORT
	LXI	B,RATE
	CALL	PRNSTR1
	MVI	A,P0ORIG
	OUT	TPORT
	LDA	DTR
	OUT	CPORT
WTCTS:	EQU	$+OFFSET
	CALL	REQEXIT
	CPI	'E'-40H
	JZ	CCPRET
	CALL	CKCTS
DB	JRNZ,	WTCTS-$+BR
	LDA	BAUDRT
	OUT	RPORT
	LDA	UARTWD
	OUT	TPORT
COMLOOP: EQU	$+OFFSET
	IN	TPORT
	ANI	P0DAV
DB	JRZ,	NOMDAT-$+FR
	IN	DPORT
	ANI	7FH
	MOV	C,A
	CALL	CONOUT
NOMDAT:	EQU	$+OFFSET
	CALL	CONST
	ORA	A
DB	JRZ,	COMLOOP-$+BR
	CALL	CONIN
	OUT	DPORT
	CPI	'D'-40H
	JZ	CCPRET
	CPI	'E'-40H
	JZ	RETCCP
DB	JR,	COMLOOP-$+BR
;
;**********************************************************
;This is the command string which is divided into private
;and public sections. Do not use more than five letters for
;the name of any command/transient and fill out each string
;to exactly five characters by using spaces below. Strings
;must occur at 5 character intervals.  If you use some
;other string length such as 4 as in the original CCP, just
;change string lengths below and change the LENCMD equate
;from 5 to 4.  I use 5 below so that LOGIN can fit.
;
CMDSTR2: EQU	$+OFFSET
	DB	'ERA  REN  SAVE H89  LOCK BOOT '
CMDSTR1: EQU	$+OFFSET
	DB	'TYPE USER PASS DIR  ANSWRORIG '
CMDSTR0: EQU	$+OFFSET
	DB	'DIR  LOGINOFF  BYE  QUIT '
;
;**********************************************************
;This is the command address table which is divided into
;private and public areas. The address of the routine to be
;jumped to must be here for CCP-included code as well as
;any that you put in your customized BIOS.
;You can expand the table to any extent that you have space
;and the command string above must be expanded in synchronism.
;
CMDTBL2: EQU	$+OFFSET
	DW	ERA	;ERA....PRIVATE COMMANDS
	DW	REN	;REN
	DW	SAVE	;SAVE
	DW	H89	;SET H89 MODE (temporarily)
	DW	LOCK	;SET 2ND PASSWORD TO REQUIRED
	DW	BOOT	;RE- BOOT THE SYSTEM
CMDTBL1: EQU	$+OFFSET
	DW	TYPE1	;TYPE..In case MLIST.COM renamed
			;to 'TYPE.COM'. Put the transient
			;in USER 14 on drive A.
	DW	USER	;USER
	DW	CKPASS0	;PASS(word) to gain access to
			;private user areas.
	DW	DIR1	;DIR....If you wish to use SD or
			;KDIR as a CCP transient instead of
			;the CCP DIR code, just change the
			;name of your transient to DIR.COM
			;and put it in USER 14 on drive A.
			;The transient will run only if 1rst
			;password level has been achieved.
			;If transient not present then CCP
			;'DIR' code will run.
	DW	ANSWR	;ANSWR routine
	DW	ORIG	;ORIGinate routine
;These commands will be the only ones allowed until the user
;logs in to the system with LOGIN.
CMDTBL0: EQU	$+OFFSET
	DW	DIR	;WILL RUN THE CCP 'DIR' CODE
	DW	PASSINT	;LOGIN
	DW	OFF	;
	DW	BYE	;BYE
	DW	BYE	;QUIT
GETRAN0: EQU	$+OFFSET ;This must be last entry in table.
	DW	GETRANS	;GET THE TRANSIENT AND EXECUTE OR
			;RETURN TO CCP W/HUH MESSAGE IF NOT
			;ON DISK.
;
;**********************************************************
;Routines to reset parameters for string matching and other
;purposes.
;
RSTPRMS: EQU	$+OFFSET
	MVI	A,LENCMD
	STA	CMDLEN
	LXI	H,PASBYTE
DW	BIT5M
DB	JRNZ,	RST0-$+FR
DW	BIT2M
DB	JRNZ,	RST1-$+FR
	;
RST2:	EQU	$+OFFSET
	LXI	H,CMDSTR2
	SHLD	STRPTR
	MVI	A,(GETRAN0-CMDTBL2)/2
	STA	CMDCNT
	LXI	H,CMDTBL2
	SHLD	CMDPTR
	MVI	A,16
	STA	TSTUSR
	RET
	;
RST1:	EQU	$+OFFSET
	LXI	H,CMDSTR1
	SHLD	STRPTR
	MVI	A,(GETRAN0-CMDTBL1)/2
	STA	CMDCNT
	LXI	H,CMDTBL1
	SHLD	CMDPTR
	MVI	A,MAXUSER+1
	STA	TSTUSR
	RET
	;
RST0:	EQU	$+OFFSET
	MVI	A,(GETRAN0-CMDTBL0)/2
	STA	CMDCNT
	LXI	H,CMDSTR0
	SHLD	STRPTR
	LXI	H,CMDTBL0
	SHLD	CMDPTR
	MVI	A,1
	STA	TSTUSR
	RET
;
;**********************************************************
;This routine will make USER 13, 14, and/or 15 universal on
;drive A only depending on password level. Files placed in
;user 13 will be universal without any password. Files placed
;in user 14 will additionally be universal on drive A at the
;first password level, and files placed in user 15 will be
;universal at the second password level in addition to those
;in users 13 and 14.
;	***** WARNING *****
;NEVER have two files by the same name & extension on the
;same disk (one in USER 15 and the other in some other
;USER) because CP/M will take which ever one comes first
;in the directory.
;
UNIV:	EQU	$+OFFSET
	MOV	A,B		;duplicate instruction overlayed
	ORA	A		;check pointer for zero byte
DB	JRNZ,	UNIV1-$+FR	;skip if not zero byte of fcb
	;
	LDA	CURDSK		;get current disk
	ANI	0FH		;mask out high nibble
	CPI	0		;is it drive A? (may be changed
				;to any drive. 0,1,2.. = A,B,C..)
DB	JRNZ,	UNIV1-$+FR	;skip if not
	;
	LDAX	D		;get fcb first byte
	CPI	0E5H		;check for erased
DB	JRZ,	UNIV1-$+FR	;skip if erased
	;
	LDA	PASBYTE
DW	BIT5A
DB	JRNZ,	DFU13-$+FR
DW	BIT2A
DB	JRNZ,	DFU14-$+FR
	;
	MOV	A,M
	CPI	15		;and check for user 15
DB	JRZ,	MATCH0-$+FR	;jump if zero
	;
DFU14:	EQU	$+OFFSET
	MOV	A,M
	CPI	14		;check for user 14
DB	JRZ,	MATCH0-$+FR
	;
DFU13:	EQU	$+OFFSET
	MOV	A,M
	CPI	13		;check for user 13
MATCH0:	EQU	$+OFFSET
	JZ	MATCH
	;
UNIV1:	EQU	$+OFFSET
	MOV	A,B		;duplicate instuction overlayed
	CPI	0DH		;	"	"	"
	JMP	TINUSRCH	;and return where routine left off
	;
;**********************************************************
;This is the in-line print subroutine.
;
ILPRT:	EQU	$+OFFSET
DB	EXX	
	CALL	CRLF
DB	EXX
ILPRT2:	EQU	$+OFFSET
	XTHL		;SAVE HL, GET MSG
	;
ILPLP:	EQU	$+OFFSET
	MOV	C,M	;GET CHAR
	CALL	CONOUT	;OUTPUT IT
	INX	H	;POINT TO NEXT
	MOV	A,M	;TEST
	ORA	A	;..FOR END
DB	JRNZ,	ILPLP-$+BR
	XTHL		;RESTORE HL, RET ADDR
	RET		;RET PAST MSG
;
;***********************************************************
;ROUTINE TO TEST LOG IN
;
LOGTST:	EQU	$+OFFSET
	LXI	H,PASBYTE
DW	BIT5M
	RET
;
;**********************************************************
;ROUTINE TO CHECK FOR CARRIER LOST
;
CHECK:	EQU	$+OFFSET
	CALL	CARCK	;SEE IF CARRIER STILL ON
	RNC		;ALL OK
	;
;CARRIER IS LOST
	LXI	SP,STACK
	JMP	HANGUP
;
;**********************************************************
;This routine, which is exercised by the H89 command, sets
;H89 mode to on. Each return to the CCP prompt will set the
;H89 flag to zero and disable the clock interrupt if the
;H89 flag indicates that the mode is on.  Invoke H89 games
;by entering: H89 and then when the prompt 'Game: ' appears
;enter the name of the game to run it.
;
H89:	EQU	$+OFFSET
	LDA	MDMBYT
	ORA	A
	JZ	HUH
	MVI	A,0FFH
	STA	H89FLG
	CALL	ARMCLK
	CALL	ILPRT
	DB	'Game: ',0	
	JMP	GETCMD-3
	;
COUNTER: EQU	$+OFFSET
	DW	INTCNTR	;INITIAL VALUE
;
;**********************************************************
;Routine to reboot the system. Can be invoked only by local
;terminal and only at highest password level.
;
BOOT:	EQU	$+OFFSET
	LDA	MDMBYT
	ORA	A
	JZ	HUH
	LHLD	PROMLOC-1
	MVI	L,0
	PCHL
;
;**********************************************************
;This is a background memory test that runs whenever the
;current console (including remote) is waiting for an input
;character to be typed.
;
;TEST ROUTINE TO CONSTANTLY TEST MEMORY
;
TEST:	EQU	$+OFFSET
	DI
	PUSH	H
	LHLD	TSTPT
	INX	H
	MOV	A,H
	CPI	($+OFFSET)/100H
DB	JRNZ,	TEST1-$+FR
	LXI	H,0
;
TEST1:	EQU	$+OFFSET
	SHLD	TSTPT
	MOV	A,M
	CMA
	MOV	M,A
	CMP	M
DB	JRZ,	TEST2-$+FR
	XRA	M
	PUSH	PSW
	PUSH	H
	CALL	CRLF
	POP	H
	POP	PSW
	PUSH	PSW
	CALL	PRTHX
	CALL	ILPRT2
	DB	'H Bits bad: ',0
	MOV	A,H
	CALL	PRTHX
	MOV	A,L
	CALL	PRTHX
	POP	PSW
;
TEST2:	EQU	$+OFFSET
	CMA
	MOV	M,A
	POP	H
	EI
	RET
	ENDIF
;
;END OF CONSTANT MEMORY TEST
;**********************************************************
;
;		USER DEFINED I/O DEVICE DRIVERS
;
;**********************************************************
;
UC1ST:	EQU	$+OFFSET	;USER CONSOLE 1 STATUS
UL1ST:	EQU	$+OFFSET	;USER LIST DEVICE STATUS
	MVI	A,0FFH		;ALWAYS READY
	RET
;
UC1OUT:	EQU	$+OFFSET	;USER CONSOLE 1 IN (NULL)	
UP1OUT:	EQU	$+OFFSET	;USER PUNCH ONE OUT (NULL)
UP2OUT:	EQU	$+OFFSET	;USER PUNCH TWO OUTPUT "
UL1OUT:	EQU	$+OFFSET	;USER LIST OUTPUT (NULL)
	MOV	A,C		;CHARACTER INTO A
	RET
;
UC1IN:	EQU	$+OFFSET	;USER CONSOLE 1 IN (NULL)
UR1IN:	EQU	$+OFFSET	;USER READER ONE INPUT
UR2IN:	EQU	$+OFFSET	;USER READER TWO INPUT
	MVI	A,EOF		;END OF FILE FOR NOW
	RET
;
USR2END: EQU	$+OFFSET	;END OF USER2 CODE FOR NOW
INITSIZE EQU	INITSIZE	;
USR2SIZE EQU	USR2END-USER2	;DO NOT EXCEED SPACE ALLOCAT-
				;ED ABOVE YOUR RUNNING CP/M. 
				;WHEN MAKING A 2KB USER2 AREA,
				;THE SPACE OCCUPIED BY INIT-
				;SIZE WILL BE AVAILABLE AS
				;SCRATCH AREA ABOVE USER2 AND
				;REDUCES THE CODE THAT IS ACT-
				;UAL USER2 CODE BY THAT AMOUNT.
				;GOOD PLACE TO PUT YOUR STACK.
;
;**********************************************************
;	EQUATES FOR CCP PATCHES
LENCMD	EQU	5		;LENGTH OF CCP CMD STRINGS
BUFSIZE	EQU	CCP+6H		;LOC. OF CMD BUF SIZE BYTE
GETUSR	EQU	CCP+113H	;GET USER #
SETUSR	EQU	CCP+115H	;SET USER #
TSTUSR	EQU	CCP+692H	;TEST USER #
USRSAV	EQU	CCP+118H
CCPPASS	EQU	CCP+7CH		;LOCATION OF CCP PASSWORD
UPATCH0	EQU	CCP+390H
UPATCH1	EQU	CCP+393H
HUH	EQU	CCP+209H	;CCP HUH RESPONSE
CRLF	EQU	CCP+98H		;CCP CR/LF FUNCTION
RCCPNL	EQU	CCP+789H	;RSTRT CCP W/O LOG OF DFLT DRV
RETCCP  EQU	CCP+382H	;RE-ENTRY TO CCP
GETCMD0	EQU	CCP+37BH	;CK IF CMD ENTERED AND GET IT
GETCMD	EQU	CCP+398H	;GET THE ENTERED COMMAND
SRCHCMD	EQU	CCP+3B1H	;ENTRY TO SEARCH OF COMMANDS
BUFPTR	EQU	CCP+88H		;LOC OF CMD BUFFER POINTER
CMDPTR	EQU	CCP+3B5H	;LOC OF CMD ADDR TBL PTR
GETRPTR	EQU	CCP+3AFH	;LOC OF GET TRANS PTR
STRPTR	EQU	CCP+32FH	;POINTER TO CCP CMD STRINGS
CMDCNT	EQU	CCP+335H	;BYTE VALUE = # OF COMMANDS
CMDLEN	EQU	CCP+33BH	;BYTE VALUE = LENGTH OF EACH
				;COMMAND STRING.
TSTOPN	EQU	CCP+6DCH	;TEST FILE OPEN FUNCTION
CMDDRV	EQU	CCP+7F0H	;BYTE INDICATES DRV IN CMD
CMDERR	EQU	CCP+76BH	;HUH RESPONSE IF DR #
FCBFN	EQU	CCP+7CEH	;LOC FOR FN IN FCB
XTNSN	EQU	CCP+7D6H	;STORAGE LOC FOR FILE TYPE,
				;EXT #, AND RECORD COUNT
RELOOK	EQU	CCP+6CDH	;RELOOK W/INDICATED DRIVE
TPASUB	EQU	CCP+75DH	;LOC TO SUSTITUTE BEFORE
  				;CALLING THE TPA
CONTINUE EQU	CCP+75FH	;CONTINUE AFTER CALL TO TPA
GETRANS	EQU	CCP+6A8H	;GET TRANS OR CCP COMMAND
ERA	EQU	CCP+51FH	;ADDR OF ERA ROUTINE
REN	EQU	CCP+610H	;ADDR OF REN ROUTINE
SAVE	EQU	CCP+5ADH	;ADDR OF SAVE ROUTINE
DIR	EQU	CCP+477H	;ADDR OF DIR ROUTINE
TYPE	EQU	CCP+55DH	;ADDR OF TYPE ROUTINE
USER	EQU	CCP+68EH	;ADDR OF USER ROUTINE
TPA	EQU	100H		;OR YOUR TPA ADDRESS
STKPTR1	EQU	CCP+35DH
STKPTR2	EQU	CCP+760H
STKPTR3	EQU	CCP+383H
PRNSTR1	EQU	CCP+0A7H	;PRINT STRING WITH LEADING
				;CR/LF..POINT TO IT WITH BC
PRNSTR2	EQU	CCP+0ACH	;PRINT STRING..POINT WITH HL
WRFCB	EQU	CCP+3F8H	;RTNE IN CCP TO WRITE FCB
CCPSPARE EQU	CCP+7F2H	;14 SPARE BYTES AT END CCP
BDOSPARE EQU	BDOS+0DEEH	;18 SPARE BYTES AT END BDOS
	;Addresses of holes left in CCP that are filled in
	;with patches.
HOLE1	EQU	CCP+310H	;30 BYTES
HOLE2	EQU	CCP+3C1H	;24 BYTES
HOLE3	EQU	CCP+79BH	;16 BYTES
HOLE4	EQU	CCP+1F5H	;20 BYTES
HOLE5	EQU	CCP+6A5H	;3 BYTES	
;
	IF	(S201 OR S22 OR S22X)
;**********************************************************
;	CCP patches
;**********************************************************
;Patch the turnkey start string into the CCP command buffer.
	ORG	COMBUF
TNKY:	DB	08,'OFF HELP',0            
;
	ORG	GETRPTR
	DW	GETRANS
;**********************************************************
;These two patches allow changing the user area on the
;command line after X: where X is drive letter.
;
	ORG	CCP+6C2H
	DW	USER
	ORG	CCP+69DH
	DW	RCCPNL
;
;**********************************************************
;To trap the HUH message.
;
	ORG	HUH
	JMP	HUH0
;
;**********************************************************
;To redirect the CCP stack so a larger stack is available.
;
	ORG	STKPTR1
	DW	STACK
	ORG	STKPTR2
	DW	STACK
	ORG	STKPTR3
	DW	STACK
;
;**********************************************************
; This patch is used to restrict access to the higher user
; areas while leaving the lower user areas public. The high-
; est available public user area is defined by MAXUSER.
;
	ORG	USRSAV
	DW	SAVUSR
	;
	ORG	HOLE2
SAVUSR:	MOV	A,E
	CPI	0FFH
	JZ	BDOSFNC
	RLC
	RLC
	RLC
	RLC
	MOV	B,A
	LDA	DRIVE
	ANI	0FH
	ORA	B
	STA	DRIVE
	JMP	BDOSFNC
;
	DB	0	;SPARE
			;DO NOT EXPAND
			;24 BYTES AVAILABLE AT HOLE2
;
	ORG	HOLE3
OK2:	LXI	H,PASBYTE
DW	RES2M
	;
OK1:	LXI	H,PASBYTE
DW	RES5M
	JMP	OK
;
TRAPBYT:
	DB	0
	DB	0,0	;SPARES
			;DO NOT EXPAND
			;16 BYTES AT HOLE3
;
;**********************************************************
; This patch causes user number to be reported at the cp/m
; prompt.....i.e. - A2>.  User 0 report is suppressed.
;
	ORG	UPATCH0
	MVI	C,USRFNC
	ORG	UPATCH1
	DW	UPATCH
	;the routine UPATCH is located in the USER1 area
;**********************************************************
; This patch causes the CCP of a cp/m 2.x system to look on
; drive A when you are logged into a drive other than A and
; call for a .COM file that does not exist on that drive.
; Giving an explicit drive reference overrides this feature,
; so that you can always force the file to be loaded from a
; specific drive.
;
	ORG	TSTOPN
	DW	APATCH		;REPLACES 'CMDERR'
;
	ORG	CCPSPARE
APATCH:	LXI	H,CMDDRV	;GET DRIVE FROM CURRENT CMD.
	ORA	M		;FETCHES DRIVE
	JNZ	CMDERR		;GIVE ERR IF CMD HAS DRIVE #
	INR	M		;FORCE TO DRIVE A
	LXI	D,XTNSN		;UNDO WHEN...
	JMP	RELOOK		;REENTERING CCP
;
;**********************************************************
;This patch extends the CCP to include up to N additional
;commands that are user defined. The commands may be either
;CCP-included or transient, and may be either private or
;public depending on password privilege.
;
	ORG	CMDPTR
CMDPTR:	DW	CMDTBL0
	;
	ORG	STRPTR
STRPTR:	DW	CMDSTR0		
	;
	ORG	CMDCNT
CMDCNT:	DB	(GETRAN0-CMDTBL0)/2
			 ;TO LIMIT PUBLIC ACCESS TO CCP
			 ;COMMANDS. RESET TO ALL WHEN 
			 ;PASSWORD IS ENTERED FOR USER
			 ;AREAS ABOVE MAXUSER.
	ORG	CMDLEN
CMDLEN:	DB	LENCMD	 ;LENGTH OF CCP COMMAND STRINGS
;
;The rest of this patch is in USER1 and 2 code areas.
;
;**********************************************************
;
	ORG	HOLE1
RELOG0:	CALL	CRLF
RELOG:	CALL	LOGTST
DB	JRZ,	EXIT-$-1
	CALL	ILPRT2
DB	'Login please',0
EXIT:	JMP	RETCCP
	;
	DB	0,0,0	;SPARES
			;DO NOT EXPAND
			;30 BYTES AVAILABLE AT HOLE1
;
;**********************************************************
;
BDOSPARE EQU	BDOS+0DEEH	;18 SPARE BYTES AT END BDOS
MATCH	EQU	BDOS+077CH
CURDSK	EQU	BDOS+342H
TINUSRCH EQU	BDOS+761H
;
	ORG	BDOS+75EH
	JMP	UNIV
;
	ORG	BDOSPARE
;These routines are part of the 'BYE' command stuffed here
;for convenience.
;
PASTBL1:
	DW	OK1
	DW	CKAGIN
PASTBL2:
	DW	OK2
	DW	CKAGIN
	DB	0	;SPARE
;
;SET THE MODEM BYTE TO CAUSE SCAN OF MODEM AND CONSOLE
SETMDM:	XRA	A
DB	JR,	MDMRST-$-1	
	;
;RESET THE MODEM BYTE SO ONLY CONSOLE IS LOOKED AT
RSTMDM:	MVI	A,0FFH
MDMRST:	STA	MDMBYT
	RET		;18 bytes here
;
	ORG	HOLE5
	DB	0,0,0	;SPARES -- 3 BYTES AVAIL AT HOLE5
	ENDIF
;
;**********************************************************
;BIOS patches.  This jump table overlays the table at the 
;base of the BIOS thus making it unecessary to have all of 
;the jumps in the jump table at the base of the USER1 area.
	;
	ORG	BIOS+06H
	JMP	CONST
	JMP	CONIN
	DS	3
	JMP	LIST
	JMP	PUNCH
	JMP	READER
	;
	ORG	BIOS+2DH
	JMP	LISTST
	;
	IF	NOT S201	
	ORG	BIOS+36H
	ENDIF
	IF	SCRCLR AND NOT S201
	DB	ESC,SCRN	;SEQUENCE TO CLEAR SCREEN
	ENDIF
	;	
	IF	(S22 OR S22X) 
SIGNON:
DB	CR,LF,'RLP RCPM McLean, Va.      ',CR,LF
;             ^		                 ^ DO NOT EXPAND
	ENDIF
	IF	S22X
	DB	'CP/M 2.2x ' 
;		^          ^			 "
	ENDIF
	IF	S22
	DB	'CP/M 2.2  '
;		^	   ^			 "
	ENDIF
	IF	(S22 OR S22X)
	DB	MSIZE/10+30H
	DB	MSIZE MOD 10 + 30H
	DB	'K system',CR,LF,0,'$'
;		^        ^			 "
	ENDIF
	;
	IF	S201
	ORG	BIOS+36H
	ENDIF
;
TSTPT:	DW	0
;
	IF	S201
	ORG	BIOS+0D8H
	DW	BDOS+0DB6H
	ENDIF	
	ORG	BDOS+0DB6H
	IF	S201 AND SCRCLR
	DB	ESC,SCRN
	ENDIF
	;
	IF	S201
SIGNON:
DB	CR,LF,'RLP RCPM McLean, Va.      ',CR,LF
;	      ^				 ^ ;DO NOT EXPAND
	DB	'CP/M 2.01 '
;		^	   ^	;DO NOT EXPAND
	DB	MSIZE/10+30H
	DB	MSIZE MOD 10 + 30H
	DB	'K system',CR,LF,0,'$'
;		^	 ^	;DO NOT EXPAND		
	ENDIF
;
;************************************************************
;
;		SPECIAL ASCII CODES
;
LF	EQU	0AH	; LINE FEED
CR	EQU	0DH	; CARRIAGE RETURN
EOF	EQU	1AH	; END OF FILE
BELL	EQU	07H	; DING
NULL	EQU	00H	; NOTHING
ESC	EQU	1BH	; ESCAPE - USED IN TWO CHAR COMMANDS
;the following are specific to an H19 terminal.-put yours here
LIN	EQU	6CH	; CHAR AFTER ESCAPE TO CLEAR LINE
SCRN	EQU	45H	; CHAR AFTER ESCAPE TO CLEAR SCREEN
EXGRAPH	EQU	47H	; CHAR AFTER ESCAPE TO EXIT GRAPHICS
UPCRSR	EQU	41H	; CHAR AFTER ESCAPE TO DO UP-CURSOR
;
;		STATUS MASKS
;
INRDY	EQU	02H	;INPUT READY MASK
OUTRDY	EQU	01H	;OUTPUT READY MASK
;
;	POSITION OF BIT PAIR IN IOBYTE
;
CONCNT	EQU	1	;CONSOLE BITS 0,1
RDRCNT	EQU	2	;READER  BITS 2,3
PCHCNT	EQU	3	;PUNCH   BITS 4,5
LSTCNT	EQU	4	;LIST    BITS 6,7
;
;**********************************************************
;
;		Z80 EQUATES
;
JR	EQU	18H	;JUMP RELATIVE
JRZ	EQU	28H	;JUMP RELATIVE ON ZERO
JRNZ	EQU	20H	;JUMP RELATIVE ON NOT ZERO
JRC	EQU	38H	;JUMP RELATIVE ON CARRY
JRNC	EQU	30H	;JUMP RELATIVE IF CARRY RESET
DJNZ	EQU	10H	;DECR B AND JMP REL IF B NOT=0
LDIY	EQU	21FDH	;LD 16 BIT VAL TO IY REG
CPIY	EQU	0BEFDH	;CMP MEM WITH LOC IN IY+DISPL
INCIY	EQU	23FDH	;INCREMENT IY
LDIR	EQU	0B0EDH	;MEMORY BLOCK MOVE
LDDR	EQU	0B8EDH	;MOVE BLOCK UNTIL COUNTER=0
MOVIVA	EQU	47EDH	;MOVE ACC TO INTERRUPT REGISTER
IM2	EQU	5EEDH	;SET INTERRUPT MODE 2
BIT0A	EQU	47CBH	;TEST BIT 0 IN ACC.
BIT2A	EQU	57CBH	;TEST BIT 2 IN ACC
BIT3A	EQU	5FCBH	;TEST BIT 3 IN ACC.
BIT4A	EQU	67CBH	;TEST BIT 4 IN ACC.
BIT5A	EQU	6FCBH	;TEST BIT 5 IN ACC.
BIT0M	EQU	46CBH	;TEST BIT 0 IN MEM
BIT1M	EQU	4ECBH	;TEST BIT 1 IN MEM
BIT2M	EQU	56CBH	;TEST BIT 2 IN MEM
BIT5M	EQU	6ECBH	;TEST BIT 5 IN MEM
SET0M	EQU	0C6CBH	;SET BIT 0 IN MEM
SET1M	EQU	0CECBH	;SET BIT 1 IN MEM
SET2M	EQU	0D6CBH	;SET BIT 2 IN MEM
SET4M	EQU	0E6CBH	;SET BIT 4 IN MEM
SET5M	EQU	0EECBH	;SET BIT 5 IN MEM
SET7A	EQU	0FFCBH	;SET BIT 7 IN MEM
RES0M	EQU	86CBH	;RESET BIT 0 IN MEM
RES1M	EQU	8ECBH	;RESET BIT 1 IN MEM
RES2M	EQU	96CBH	;RESET BIT 2 IN MEM
RES5M	EQU	0AECBH	;RESET BIT 5 IN MEM
MOVDM	EQU	53EDH	;MOVE BC TO MEM, DIRECT ADDR
EXX	EQU	0D9H	;EXCH REG PAIRS B, D, & H
EXAF	EQU	08H	;EXCH AF PAIRS
;
;**********************************************************
;
;	PMMI	MODEM PORT ASSIGNMENTS
;
TPORT	EQU	MODEM	;UART	CONTROL/STATUS PORT
DPORT	EQU	TPORT+1	;DATA PORT
RPORT	EQU	TPORT+2	;RATE GEN/MODEM STATUS
CPORT	EQU	TPORT+3	;MODEM CONTROL PORT
;
;**********************************************************
;
; MODEM CONTROL COMMAND WORDS
P3CLEAR	EQU	3FH	;IDLE MODE
OFFPWR	EQU	80H	;TO TURN POWER OFF THRU PMMI
			;AUXILIARY INTERFACE
;
; SET FOLLOWING TO 5FH FOR >300 BAUD
;
P3TODTR	EQU	7FH	;TURN ON DTR
;
;**********************************************************
;
; SWITCH HOOK AND MODEM COMMANDS..OUT TO TPORT
;
P0BYE	EQU	0	;ON HOOK, OR DIALING BREAK
P0ORIG	EQU	1	;OFF HOOK, ORIG
P0ANSW	EQU	2	;ANSWER PHONE
P08BIT	EQU	0CH	;8 DATA BITS
P0NOPY	EQU	10H	;NO PARITY
P0EPS	EQU	20H	;EVEN PARITY SELECT
P0TSB	EQU	40H	;2 STOP BITS
P0EI	EQU	80H	;ENABLE INTERRUPTS
P0NORM	EQU	P08BIT+P0NOPY ;8 BITS, NO PARITY
P0110	EQU	P08BIT+P0NOPY+P0TSB ;SAME W/2 STOP BITS
;
;**********************************************************
;
; MODEM STATUS, INPUT ON RPORT
;
P2DTD	EQU	1	;DIAL TONE DETECT
P2RDET	EQU	2	;RING DETECT
P2CTS	EQU	4	;CTS (CARRIER DETECT)
P2RXBRK	EQU	8	;RECEIVE BREAK
P2CONN	EQU	10H	;CONNECTED? (0=YES)
			;1=MODEM HUNG UP THE PHONE LINE
P2TMPUL	EQU	80H	;TIMER PULSES (40% UP CYCLE)
;
;**********************************************************
;
; PMMI MODEM STATUS MASKS
;
P0TBMT	EQU	1	;XMIT BUFFER EMPTY
P0DAV	EQU	2	;DATA AVAILABLE
P0TEOC	EQU	4	;TEST END OF CHAR.
P0RPE	EQU	8	;REC'D PARITY ERROR
P0ORUN	EQU	10H	;OVERRUN
P0FERR	EQU	20H	;FRAMING ERROR

TRATE	EQU	250	;VALUE FOR .1 SEC
;
B300	EQU	52	;DIVISOR FOR 300 BAUD
B110	EQU	142	;   "        110
B220	EQU	71	;   "        220
B450	EQU	35	;   "        450
B520	EQU	30	;   "	     520
B600	EQU	26	;   "        600
B710	EQU	22	;   "        710
;
;
;BDOS EQUATES
;
BDOSFNC	EQU	BDOS+6H
USRFNC	EQU	32
;
	END

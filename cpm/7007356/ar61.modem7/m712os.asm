
; M712OS.ASM  -  Osborne Overlay for MDM712.COM file - 07/27/83
;
; You will want to look this file over carefully.  There are a number of
; options that can be used to configure the program to suit your taste.
;
; Use the "SET" command to change the baudrate when desired.  It starts
; out at 300 baud when the program is first called up.
;
; NOTE:  Any programmer updating the main program should check the
;	 address:  SETUPADR -- it may have changed with your update.
;	 Alter accordingly.
;
;
;	TO USE: First edit this file filling in answers for your own
;		equipment.  Then assemble with ASM.COM or equivalent
;		assembler.  Then use DDT to overlay the the results
;		of this program to the original .COM file:
;
;		A>DDT MDM712.COM
;		DDT VERS 2.2
;		NEXT  PC
;		4300 0100
;		-IM712OS.HEX		(note the "I" command)
;		-R			(loads in the .HEX file)
;		NEXT  PC
;		4300 0000
;		-G0			(return to CP/M)
;		A>SAVE 66 MCM712.COM	(now have modified .COM file)
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
; 07/27/83 - Renamed to work with MDM712	- Irv Hoff
; 07/01/83 - Revised to work with MDM711	- Irv Hoff
; 06/22/83 - Revised to work with MDM710	- Irv Hoff
; 05/27/83 - Revised to work with MDM709	- Irv Hoff
; 05/15/83 - Revised to work with MDM708	- Irv Hoff
; 04/11/83 - Updated to work with MDM707	- Irv Hoff
; 04/04/83 - Updated to work with MDM706	- Irv Hoff
; 02/27/83 - Updated to work with MDM705	- Irv Hoff
; 02/17/83 - Updated to work with MDM704	- Irv Hoff
; 02/07/83 - Updated to work with MDM703	- Irv Hoff
; 01/27/83 - Updated to work with MDM702	- Irv Hoff
; 01/10/83 - Updated to work with MDM701	- Irv Hoff
; 11/29/82 - Overlay file for Osborne O-1	- Paul Kelley
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
; 
BELL:		EQU	07H		;bell
CR:		EQU	0DH		;carriage return
ESC:		EQU	1BH		;escape
LF:		EQU	0AH		;linefeed
;
YES:		EQU	0FFH
NO:		EQU	0
;
;
MODCTLP:	EQU	2A00H	;status register for RS232
MODDATP:	EQU	MODCTLP+1 ;data resister for RS232
MODSNDB:	EQU	2	;bit to test for ready to send
MODSNDR:	EQU	2	;modem send ready when high
MODRCVB:	EQU	1	;bit to test for received data
MODRCVR:	EQU	1	;modem receive ready when high
;
;
;
; Change CLOCK to match your equipment
;
		ORG	100H
;
		DS	3	;(for  "JMP   START" instruction)
;
PMMIMODEM:	DB	NO	;yes=PMMI S-100 Modem			103H
SMARTMODEM:	DB	NO	;yes=HAYES Smartmodem, no=non-PMMI	104H
TOUCHPULSE:	DB	'T'	;T=touch, P=pulse (Smartmodem-only)	105H
CLOCK:		DB	20	;clock speed in MHz x10, 25.5 MHz max.	106H
				;20=2 MHh, 37=3.68 MHz, 40=4 MHz, etc.
MSPEED:		DB	1	;0=110 1=300 2=450 3=600 4=710 5=1200   107H
				;6=2400 7=4800 8=9600 9=19200 default
BYTDLY:		DB	5	;0=0 delay  1=10ms  5=50 ms - 9=90 ms   108H
				;default time to send character in ter-
				;minal mode file transfer for slow BBS.
CRDLY:		DB	5	;0=0 delay 1=100 ms 5=500 ms - 9=900 ms 109H
				;default time for extra wait after CRLF
				;in terminal mode file transfer
NOOFCOL:	DB	5	;number of DIR columns shown		10AH
SETUPTST:	DB	YES	;yes=user-added Setup routine		10BH
SCRNTEST:	DB	YES	;cursor control routine 		10CH
ACKNAK:		DB	YES	;yes=resend a record after any non-ACK	10DH
				;no=resend a record after a valid NAK
BAKUPBYTE:	DB	NO	;yes=change any file same name to .BAK	10EH
CRCDFLT:	DB	YES	;yes=default to CRC checking		10FH
TOGGLECRC:	DB	YES	;yes=allow toggling of CRC to Checksum	110H
CONVBKSP:	DB	NO	;yes=convert backspace to rub		111H
TOGGLEBK:	DB	YES	;yes=allow toggling of bksp to rub	112H
ADDLF:		DB	NO	;no=no LF after CR to send file in	113H
				;terminal mode (added by remote echo)
TOGGLELF:	DB	YES	;yes=allow toggling of LF after CR	114H
TRANLOGON:	DB	YES	;yes=allow transmission of logon	115H
				;write logon sequence at location LOGON
NOSAVE:		DB	NO	;DO NOT CHANGE, MUST BE 'NO' FOR OS-1	116H
LOCONEXTCHR:	DB	NO	;yes=local command if EXTCHR precedes	117H
				;no=external command if EXTCHR precedes
TOGGLELOC:	DB	YES	;yes=allow toggling of LOCONEXTCHR	118H
LSTTST:		DB	YES	;yes=printer available on printer port	119H
XOFFTST:	DB	NO	;yes=checks for XOFF from remote while	11AH
				;sending a file in terminal mode
XONWAIT:	DB	NO	;yes=wait for XON after CR while	11BH
				;sending a file in terminal mode
TOGXOFF:	DB	YES	;yes=allow toggling of XOFF checking	11CH
IGNORCTL:	DB	YES	;yes=CTL-chars above ^M not displayed	11DH
EXTRA1:		DB	0	;for future expansion			11EH
EXTRA2:		DB	0	;for future expansion			11FH
BRKCHR:		DB	'@'-40H	;^@ = Send a 300 ma. break tone		120H
NOCONNCT:	DB	'N'-40H	;^N = Disconnect from the phone line	121H
LOGCHR:		DB	'L'-40H	;^L = Send logon			122H
LSTCHR:		DB	'P'-40H	;^P = Toggle printer			123H
UNSAVE:		DB	'R'-40H	;^R = Close input text buffer		124H
TRANCHR:	DB	'T'-40H ;^T = Transmit file to remote		125H
SAVECHR:	DB	'Y'-40H	;^Y = Open input text buffer		126H
EXTCHR:		DB	'^'-40H	;^^ = Send next character		127H
		DS	2		;				128H
;
IN$MODCTLP:	CALL	OSTAT	! RET	;get the I/O status		12AH
		DS	6
;
OUT$MODDATP:	CALL	OSOUT	! RET	;send a character to the I/O	134H
		DS	6
;
IN$MODDATP:	CALL	OSIN	! RET	;get a character from the I/O	13EH
		DS	6
;
ANI$MODRCVB:	ANI	MODRCVB ! RET	;bit to test for receive ready	148H
CPI$MODRCVR:	CPI	MODRCVR ! RET	;value of rcv. bit when ready	14BH
ANI$MODSNDB:	ANI	MODSNDB ! RET	;bit to test for send ready	14EH
CPI$MODSNDR:	CPI	MODSNDR ! RET	;value of send bit when ready	151H
		DS	12		;				156H
LOGONPTR:	DW	LOGON		;for user message.		160H
		DS	6		;				162H
JMP$GOODBYE:	JMP	GOODBYE		;				168H
JMP$INITMOD:	JMP	INITMOD		;go to user written routine	16BH
		RET  !  NOP  !  NOP	;(by-passes PMMI routine)	16EH
		RET  !  NOP  !  NOP	;(by-passes PMMI routine)	171H
		RET  !  NOP  !  NOP	;(by-passes PMMI routine)	174H
JMP$SETUPR:	JMP	SETUPR		;				177H
JMP$SPCLMENU:	JMP	SPCLMENU	;				17AH
JMP$SYSVER:	JMP	SYSVER		;				17DH
JMP$BREAK:	JMP	SENDBRK		;				180H
;
;
; Do not change the following six lines.
;
JMP$ILPRT:	DS	3		;				183H
JMP$INBUF	DS	3		;				186H
JMP$INLNCOMP:	DS	3		;				189H
JMP$INMODEM	DS	3		;				18CH
JMP$NXTSCRN:	DS	3		;				18FH
JMP$TIMER:	DS	3		;				192H
;
CLREOS:		CALL	JMP$ILPRT	;				195H
		DB	0,0,0,0,0	;O-1 has no clear EOS.		198H
		RET			;				19DH
;
CLRSCRN:	CALL JMP$ILPRT		;				19EH
		DB	1AH,0,0,0,0	;O-1 clear screen, home cursor  1A1H
		RET			;				1A6H
;
SYSVER:		CALL	JMP$ILPRT	;				1A7H
			
		DB	'Version for OSBORNE O-1'
		DB	CR,LF,0
		RET
;.....
;
;
;-----------------------------------------------------------------------
;
; NOTE:  You can change the SYSVER message to be longer or shorter.  The
;	 end of your last routine should terminate by 0400H (601 bytes
;	 available after start of SYSVER) if using the Hayes Smartmodem
;	 or by address 0C00H (2659 bytes) otherwise.
;
;-----------------------------------------------------------------------
;
; You can put in a message at this location which can be called up with
; CTL-O if TRANLOGON has been set TRUE.  You can put in several lines if
; desired.  End with a 0.
;
LOGON:		DB	'This is an OSBORNE computer',CR,LF,0
;.....
;
;
; You can put a routine here that sends a break tone to reset time-share
; computers.
;
SENDBRK:	RET
;.....
;
;
; You can put a routine here that sets DTR low and sends a break tone to
; disconnect the phone line.  End with a RET.
;
GOODBYE:	RET
;.....
;
;
; You can put any items in this area you wish to display that are of in-
; terest to those using this equipment.  If using the Hayes Smartmodem
; this is unavailable without a special address change.  End the routine
; with a RET.
;
SPCLMENU:	RET
;.....
;
;
; This is the Osborne initialization routine.
;	
INITMOD:  LDA	FINITFLG	;FLAG SET YET?
	  ORA	A
	  RNZ			;IF YES, ALREADY BEEN THIS WAY ONCE
	  INR	A		;OTHERWISE SET FLAG
	  STA	FINITFLG	;..AND INITIALIZE THIS ROUTINE
	  LHLD	0005H+1		;FIND START OF BDOS
	  LXI	D,-0100H	;GO TO FIRST PAGE AHEAD OF BDOS
	  DAD	D		;HL NOW POSITIONED ONE PAGE BELOW BDOS
	  PUSH	H		;SAVE THE ADDRESS
	  LXI	D,BDJ		;POINT TO OUR ROUTINE TO PUT THERE
	  LXI	B,CDLEN+2	;SET LENGTH OF CODE
	  XCHG
	  DB	0EDH,0B0H	;Z80 LDIR
;
	  LHLD	0005H+1		;GET BDOS ADDRESS BACK ONCE MORE
	  POP	D		;GET THE STARTING ADDRESS OFF STACK
	  PUSH	D		;PUT IT BACK ON THE STACK
	  INX	D		;POINT TO ADDRESS POSITION
	  XCHG			;PUT INTO 'HL'
	  MOV	M,E		;STORE 'LSP' ADDRESS
	  INX	H		;GET 'LSP' LOCATION
	  MOV	M,D		;STORE 'MSP' ADDRESS
	  POP	H		;GET THE ADDRESS BACK ONCE MORE
	  SHLD	0005H+1		;NEW ADDRESS TO PROTECT FOR OVERWRITE
;
	  LXI	D,OSIN-BDJ	;GET THE LENGTH OF ROUTINE TO MOVE
	  DAD	D		;COMUTE ADDRESS OF THE 'OSIN' ROUTINE
	  SHLD	IN$MODDATP+1	;PATCH CALL FOR "GET CHAR." ROUTINE
	  LXI	D,OSOUT-OSIN
	  DAD	D
	  SHLD	OUT$MODDATP+1	;PATCH CALL FOR "SEND CHAR." ROUTINE
	  LXI	D,OSTAT-OSOUT
	  DAD	D
	  SHLD	IN$MODCTLP+1	;PATCH CALL FOR "GET STATUS" ROUTINE
;
	  MVI	A,1		;MSPEED 300 baud value
	  STA	MSPEED
;
;
; SET THE INITIAL BAUD RATE TO 300
;
	  MVI	C,56H		;FOR 300 BAUD
;
STBAUD:	  PUSH	H
	  CALL	OSET
	  POP	H
	  XRA	A		;CLEAR CARRY
	  RET
;.....
;
;
OSET:	  LHLD	1		;GET BIOS+3 ADDRESS
	  MVI	L,3CH		;SPECIAL OSBORNE ROUTINE
	  PCHL			;BRANCH TO IT
;.....
;
;
; Change the baud rate with the SET command
;
SETUPR:	  PUSH	H
;
AGAIN:	  LXI	D,BAUDBUF	;POINT TO INPUT BUFFER
	  CALL	JMP$ILPRT
	  DB	'Input Baud Rate (300, 1200): ',0
	  CALL	JMP$INBUF
	  LXI	D,BAUDBUF+2
	  CALL	JMP$INLNCOMP	;COMPARE BAUDBUF+2 WITH CHARACTERS BELOW
	  DB	'300',0
	  MVI	A,1		;MSPEED 300 BAUD
	  MVI	C,56H		;OSBORNE 300 BAUD
	  JNC	OK		;GO IF GOT MATCH
;
	  CALL	JMP$INLNCOMP
	  DB	'1200',0
	  MVI	A,5		;MSPEED 1200 BAUD
	  MVI	C,55H		;OSBORNE 1200 BAUD
	  JNC	OK
	  CALL	JMP$ILPRT	;ALL MATCHES FAILED - TELL OPERATOR
	  DB	'++ Incorrect entry ++',CR,LF,BELL,0
	  JMP	AGAIN		;TRY AGAIN
;...
;
;
OK:	  STA	MSPEED		;SET MSPEED
	  POP	H
	  JMP	STBAUD
;.....
;
;
BAUDBUF:  DB	10,0
	  DS	10
;
FINITFLG: DB	0
;.....
;
;
; --- ROUTINES THAT GET PLACED JUST UNDER 'BDOS' OVERLAYING 'CCP'
;
BDJ:	JMP	$-$		;THIS GETS PATCHED TO JUMP TO BDOS ENTRY
;
OSIN:	DI			;DISABLE INTERRUPTS
	OUT	0		;SWITCH TO ALTERNATE PAGE
	LDA	MODDATP		;GET DATA BYTE
	OUT	1		;SWITCH PAGES BACK
	EI			;RE-ENABLE INTERRUPTS
	RET
;.....
;
;
OSOUT:	DI			;DISABLE INTERRUPTS
	OUT	0		;SWITDH TO ALTERNATE PAGE
	STA	MODDATP		;SEND DATA BYTE
	OUT	1		;SWITCH PAGES BACK
	EI			;RE-ENABLE INTERRUPTS
	RET
;.....
;
;
OSTAT:	DI			;DISABLE INTERRUPTS
	OUT	0		;SWITCH TO ALTERNATE PAGE
	LDA	MODCTLP		;GET STATUS BYTE
	OUT	1		;SWITCH PAGES BACK
	EI			;RE-ENABLE INTERRUPTS
	RET
;.....
;
;
CDLEN:	EQU	$-BDJ		;LENGTH OF CODE TO COPY
;
;-----------------------------------------------------------------------
;
; NOTE:  MUST TERMINATE PRIOR TO 0400H (with Smartmodem)
;				 0C00H (without Smartmodem)
;
	END
;

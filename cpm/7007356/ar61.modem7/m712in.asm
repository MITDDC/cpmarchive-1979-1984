
; M712IN.ASM -- Overlay file for the CompuPro I3/I4.  07/27/83
;
; This overlay adapts the MDM712 program to the CompuPro Interfacer 3 or
; Interfacer 4 or System Support 1 serial cards using the 2651 USART chip.
; (Note:  It is very easy to modify this file to work with the Apple CPS
; Multifunction card too.)
;
; You will want to look this file over carefully. There are a number of
; options that you can use to configure the program to suit your taste.
; This file places particular emphasis on using an external modem that
; is connected to a serial port.  This includes acoustic modems as well
; as "intelligent" modems such as the Hayes Smartmodem, Racal-Vadic, Bell
; Dataphone 212A, etc.
;
; This overlay is capable of setting the baud rate, disconnecting the
; modem, and sending breaks.
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
;		-IM712IN.HEX		(note the "I" command)
;		-R			("R" loads in the .HEX file)
;		NEXT  PC
;		4300 0000
;		-G0			(return to CP/M)
;		A>SAVE 66 MDM712.COM	(now have a modified .COM file)
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
; 07/27/83 - Renamed to work with MDM712	- Irv Hoff
; 07/11/83 - Modifed somewhat for MDM711	- Irv Hoff
; 07/08/83 - Adapted from MDM711GP.ASM		- Paul Traina
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
BELL:	EQU	07H		;bell
CR:	EQU	0DH		;carriage return
ESC:	EQU	1BH		;escape
LF:	EQU	0AH		;linefeed
;
YES:	EQU	0FFH
NO:	EQU	0
;
; Change the following to match your equipment
;
GBCI34:	EQU	YES		;true= Godbout Interfacer 3 or 4
GBCSS1:	EQU	NO		;true= Godbout SS1 board
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
	 IF	GBCI34
BASE:	EQU	010H		;base port of CompuPro I3 or I4 cards
UPORT:	EQU	BASE+7		;user (chip select) port
MDM:	EQU	6		;chip that controls modem port
	 ENDIF
;
	 IF	GBCSS1
BASE:	EQU	05CH		;base of serial section of CompuPro SS1
UPORT:	EQU	0EFH		;this should be some UNUSED port on...
MDM:	EQU	0		;...system - MDM7 will OUT the value...
	 ENDIF			;...MDM to it.
;
;
DPORT:	EQU	BASE		;data port
SPORT:	EQU	BASE+1		;status port
MPORT:	EQU	BASE+2		;mode port
CPORT:	EQU	BASE+3		;control port
;
TBMT:	EQU	01H		;transmit buffer empty
DAV:	EQU	02H		;data available
;
		ORG	100H
;
; Change the clock speed to suit your system
;
		DS	3	;(for  "JMP   START" instruction)
;
PMMIMODEM:	DB	NO	;yes=PMMI S-100 Modem			103H
SMARTMODEM:	DB	NO	;yes=HAYES Smartmodem, no=non-PMMI	104H
TOUCHPULSE:	DB	'T'	;T=touch, P=pulse (Smartmodem-only)	105H
CLOCK:		DB	60	;clock speed in MHz x10, 25.5 MHz max.	106H
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
SCRNTEST:	DB	YES	;Cursor control routine 		10CH
ACKNAK:		DB	YES	;yes=resend a record after any non-ACK	10DH
				;no=resend a record after a valid-NAK
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
SAVCCP:		DB	YES	;yes=do not overwrite CCP		116H
LOCONEXTCHR:	DB	NO	;yes=local command if EXTCHR precedes	117H
				;no=external command if EXTCHR precedes
TOGGLELOC:	DB	YES	;yes=allow toggling of LOCONEXTCHR	118H
LSTTST:		DB	YES	;yes=printer available on printer port	119H
XOFFTST:	DB	NO	;yes=checks for XOFF from remote while	11AH
				;sending a file in terminal mode
XONWAIT:	DB	NO	;yes=wait for XON after CR while	11BH
				;sending a file in terminal mode
TOGXOFF:	DB	YES	;yes=allow toggling of XOFF checking	11CH
IGNORCTL:	DB	NO	;yes=CTL-chars above ^M not displayed	11DH
EXTRA1:		DB	0	;for future expansion			11EH
EXITCHR		DB	'E'-40H	;^E = Exit to main menu			11FH
BRKCHR:		DB	'@'-40H	;^@ = Send 300 ms. break tone		120H
NOCONNCT:	DB	'N'-40H	;^N = Disconnect from the phone line	121H
LOGCHR:		DB	'L'-40H	;^L = Send logon			122H
LSTCHR:		DB	'P'-40H	;^P = Toggle printer			123H
UNSAVE:		DB	'R'-40H	;^R = Close input text buffer		124H
TRANCHR:	DB	'T'-40H	;^T = Transmit file to remote		125H
SAVECHR:	DB	'Y'-40H	;^Y = Open input text buffer		126H
EXTCHR:		DB	'^'-40H	;^^ = Send next character		127H
;
;
		DS	2		;				128H
;
IN$MODCTL1:	MVI	A,MDM		;in modem control port		12AH
		OUT	UPORT
		IN	SPORT
		RET
		DS	3

OUT$MODDATP:	PUSH	PSW		;out modem data port		134H
		MVI	A,MDM
		OUT	UPORT
		POP	PSW
		OUT	DPORT
		RET
		DS	1

IN$MODDATP:	MVI	A,MDM		;in modem data port		13EH
		OUT	UPORT
		IN	DPORT
		RET
		DS	3

ANI$MODRCVB:	ANI	DAV	! RET	;bit to test for receive ready	148H
CPI$MODRCVR:	CPI	DAV	! RET	;value of rcv. bit when ready	14BH
ANI$MODSNDB:	ANI	TBMT	! RET	;bit to test for send ready	14EH
CPI$MODSNDR:	CPI	TBMT	! RET	;value of send bit when ready	151H
		DS	6		;				156H
;
OUT$MODCTL1:	RET	! DS 2		;out modem control port #2	15AH
OUT$MODCTL2:	RET	! DS 2		;out modem control port #1	15DH
;
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
JMP$TIMER	DS	3		;				192H
;
; 
; Routine to clear to end of screen.  If using CLREOS and CLRSCRN, set
; SCRNTEST to YES at 010AH (above).
;
CLREOS:		CALL	JMP$ILPRT	;				195H
		DB	ESC,'Y',0,0,0	;				198H
		RET			;				19DH
;
CLRSCRN:	CALL	JMP$ILPRT	;				19EH
		DB	ESC,'*',0,0,0	;				1A1H
		RET			;				1A6H
	
;
SYSVER:		CALL	JMP$ILPRT	;				1A7H
		DB	'Version for CompuPro '

		IF	GBCSS1
		DB	'System Support-1'
		ENDIF

		IF	GBCI34
		DB	'Interfacer-3 or 4 (port ',MDM+'0',')'
		ENDIF

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
; CTL-O if TRANLOGON has been set TRUE.  You can use several lines if
; desired.  End with a 0.
;
LOGON:	  DB	'What is the airspeeed velocity of an'
	  DB	' unladden swallow?',CR,LF,0
;.....
;
;
; Add your own routine here to send a break tone to reset some time-
; share computers, if desired.
;
SENDBRK:  MVI	A,MDM		;select chip
	  OUT	UPORT
	  MVI	A,2FH		;send break for 300ms
	  JMP	GOODBYE1
;.....
;
;
; Add your own routine here to put DTR low and/or send a break tone.
; Check other routines such as MDM711DP.ASM which is using this feature.
;
GOODBYE:  MVI	A,MDM		;select chip
	  OUT	UPORT
	  XRA	A		;turn off DTR
;
GOODBYE1: OUT	CPORT
	  MVI	B,3		;turn off DTR for 300 ms.
	  CALL	JMP$TIMER
	  MVI	A,27H		;turn DTR back on
	  OUT	CPORT
	  RET
;.....
;
;
; You can use this area for any special initialization or setup you may
; wish to include.  Each must stop with a RET.  You can check the other
; available overlays for ideas how to write your own routines if that
; may be of some help.
;
INITMOD:  MVI	A,MDM		;select chip
	  OUT	UPORT
;
INITMOD1: MVI	A,1
	  STA	MSPEED		;show file transfer time
	  MVI	A,4EH		;select 8 data bits, no parity, 1 stop
	  OUT	MPORT
;
INITMOD2: MVI	A,35H		;select 300 baud initially
	  OUT	MPORT
	  MVI	A,27H		;turn on DTR etc.
	  OUT	CPORT
	  RET
;.....
;
;
; Use the 'SET' command to select a desired baud rate
;
SETUPR:	  LXI	D,BAUDBUF	;point to new input buffer
	  CALL	JMP$ILPRT
	  DB	'Input Baud Rate (300, 600, 1200, 4800, 9600, 19200): ',0
	  CALL	JMP$INBUF
	  LXI	D,BAUDBUF+2
	  CALL	JMP$INLNCOMP	;compare BAUDBUF+2 with characters below
	  DB	'300',0
	  JNC	OK300		;go if got match
	  CALL	JMP$INLNCOMP
	  DB	'600',0
	  JNC	OK600
	  CALL	JMP$INLNCOMP
	  DB	'1200',0
	  JNC	OK1200
	  CALL	JMP$INLNCOMP
	  DB	'4800',0
	  JNC	OK4800
	  CALL	JMP$INLNCOMP
	  DB	'9600',0
	  JNC	OK9600
	  CALL	JMP$INLNCOMP
	  DB	'19200',0
	  JNC	OK19200
	  CALL	JMP$ILPRT	;all matches failed, tell operator
	  DB	'++ Incorrect entry ++',CR,LF,BELL,0
	  JMP	SETUPR		;try again
;
OK300:	  MVI	A,1		;MSPEED 300 baud value
	  MVI	B,BD300		;get 300 baud value for 2651 in 'B'
	  JMP	LOADBD		;go load everything
;
OK600:	  MVI	A,3
	  MVI	B,BD600
	  JMP	LOADBD
;
OK1200:	  MVI	A,5
	  MVI	B,BD1200
	  JMP   LOADBD
;
OK4800:	  MVI	A,7
	  MVI	B,BD4800
	  JMP	LOADBD
;
OK9600:	  MVI	A,8
	  MVI	B,BD9600
	  JMP	LOADBD
;
OK19200:  MVI	A,9
	  MVI	B,BD19200
;
LOADBD:	  STA	INITMOD1+1	;chnage time-to-send to match baudrate
	  MOV	A,B		;get baudrate byte
	  STA	INITMOD2+1	;store in initmod
	  JMP	INITMOD		;reinitialize to new baudrate, then done
;...
;
; TABLE OF BAUDRATE PARAMETERS
;
BD300:	  EQU	35H		;300 baud
BD600:	  EQU	36H		;600 baud
BD1200:   EQU	37H		;1200 baud
BD4800:	  EQU	3CH		;4800 baud
BD9600:	  EQU	3EH		;9600 baud
BD19200	  EQU	3FH		;19200 baud
;
BAUDBUF:  DB	10,0
	  DS	10
;
;	       (END OF INITMOD AND SETUP ROUTINES)
;=======================================================================
;
;
; If using the Hayes Smartmodem this is unavailable without a special
; change.
;
SPCLMENU:  RET
;
;
; NOTE:  MUST TERMINATE PRIOR TO 0400H (with Smartmodem)
;				 0C00H (without Smartmodem)
;.....
;
	  END

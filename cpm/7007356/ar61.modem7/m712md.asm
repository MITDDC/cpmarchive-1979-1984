
; M712MD.ASM - Morrow Micro Decision overlay file for MDM712.  07/27/83
;
; You will want to look this file over carefully. There are a number of
; options that you can use to configure the program to suit your taste.
; This file adapts the Morrow Micro Decision computer to the modem pro-
; gram.  While this computer has two serial ports, one is used for the
; CRT/keyboard and the other for the printer.  To use this overlay, you
; must set the internal dip switches for 1200 baud for the printer port.
; Then connect the modem in place of the printer.
;
; Edit this file for your preferences then follow the "TO USE:" example
; shown below.
;
; Use the "SET" command to change the baudrate when desired.  It starts
; out at 300 baud when the program is first called up.
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
;		-IM712MD.HEX		(note the "I" command)
;		-R			("R" loads in the .HEX file)
;		NEXT  PC
;		4300 0000
;		-G0			(return to CP/M)
;		A>SAVE 66 MDM712.COM	(now have a modified .COM file)
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
; 07/21/83 - Renamed for use with MDM712	- Irv Hoff
; 07/01/83 - Revised for use with MDM711	- Irv Hoff
; 06/22/83 - Revised for use with MDM710	- Irv Hoff
; 06/22/83 - Altered MDM708DP for Morrow
;	     Micro Decision computers using
;	     an external modem			- Irv Hoff
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
PORT:		EQU	0FEH		;Morrow MD printer port
MODCTL1:	EQU	PORT+1		;Modem status port
MODDATP:	EQU	PORT		;Modem data port
MODCTL2:	EQU	PORT+1		;Modem control port
;
;
		ORG	100H
;
		DS	3	;(for  "JMP   START" instruction)
;
PMMIMODEM:	DB	NO	;yes=PMMI S-100 Modem			103H
SMARTMODEM:	DB	NO	;yes=HAYES Smartmodem, no=non-PMMI	104H
TOUCHPULSE:	DB	'T'	;T=Touch, P=Pulse (Smartmodem-only)	105H
CLOCK:		DB	40	;clock speed in MHz x10, 25.5 MHz max.	106H
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
SCRNTEST:	DB	NO	;Cursor control routine 		10CH
ACKNAK:		DB	YES	;yes=resend a record after any non-ACK	10DH
				;no=resend a record after a valid NAK
BAKUPBYTE:	DB	NO	;yes=change any file same name to .BAK	10EH
CRCDFLT:	DB	YES	;yes=default to CRC checking		10FH
TOGGLECRC:	DB	YES	;yes=allow toggling of CRC to Checksum	110H
CONVBKSP:	DB	NO	;yes=convert backspace to rub		111H
TOGGLEBK:	DB	NO	;yes=allow toggling of bksp to rub	112H
ADDLF:		DB	NO	;no=no LF after CR to send file in	113H
				;terminal mode (added by remote echo)
TOGGLELF:	DB	YES	;yes=allow toggling of LF after CR	114H
TRANLOGON:	DB	YES	;yes=allow transmission of logon	115H
				;write logon sequence at location LOGON
SAVCCP:		DB	YES	;yes=do not overwrite CCP		116H
LOCONEXTCHR:	DB	NO	;yes=local command if EXTCHR precedes	117H
				;no=external command if EXTCHR precedes
TOGGLELOC:	DB	YES	;yes=allow toggling of LOCONEXTCHR	118H
LSTTST:		DB	NO	;no=using modem on printer port		119H
XOFFTST:	DB	NO	;yes=checks for XOFF from remote while	11AH
				;sending a file in terminal mode
XONWAIT:	DB	NO	;yes=wait for XON after CR while	11BH
				;sending a file in terminal mode
TOGXOFF:	DB	YES	;yes=allow toggling of XOFF checking	11CH
IGNORCTL:	DB	YES	;yes=CTL-chars above ^M not displayed	11DH
EXTRA1:		DB	0	;for future expansion			11EH
EXTRA2:		DB	0	;for future expansion			11FH
BRKCHR:		DB	'@'-40H	;^@ = Send 300 ms. break tone		120H
NOCONNCT:	DB	'N'-40H	;^N = Disconnect from phone line	121H
LOGCHR:		DB	'L'-40H	;^L = Send logon			122H
LSTCHR:		DB	'P'-40H	;^P = Toggle printer			123H
UNSAVE:		DB	'R'-40H	;^R = Close input text buffer		124H
TRANCHR:	DB	'T'-40H ;^T = Transmit file to remote		125H
SAVECHR:	DB	'Y'-40H	;^Y = Open input text buffer		126H
EXTCHR:		DB	'^'-40H	;^^ = Send next character		127H
;
;
		DS	2		;				128H
;
IN$MODCTL1:	IN	MODCTL1 ! RET	;in modem control port	     	12AH
		DS	7
OUT$MODDATP:	OUT	MODDATP ! RET	;out modem data port		134H
		DS	7
IN$MODDATP:	IN	MODDATP ! RET	;in modem data port		13EH
		DS	31
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
JMP$TIMER:	DS	3		;				192H
;
; Clear sequences -- CLREOS is clear to end of screen, CLRSCRN is clear
; entire screen.  Last entry must be 0.  Any other 0's act as NOP's.
; The SCRNTST option must be set "YES" for these to work.  These are now
; set for the Freedom 50 or Freedom 100 terminal.  (Morrow occasionally
; ships the ADM-22 as well.)
;
CLREOS:		CALL	JMP$ILPRT	;				195H
		DB	ESC,59H,0,0,0	;				198H
		RET			;				19DH
;
CLRSCRN:	CALL	JMP$ILPRT	;				19EH
		DB	1EH,ESC,59H,0,0	;				1A1H
		RET			;				1A6H
;
;
SYSVER:		CALL	JMP$ILPRT	;				1A7H
		DB	'Version for Morrow Micro Decision computers'
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
; CTL-O if TRANLOGON has been set YES.  You can put in several lines if
; desired.  End with a 0.
;
;
LOGON:	  DB	'This is a Morrow MD computer',CR,LF,0
;.....
;
;
;=======================================================================
;
; This routine allows a 300 ms. break tone to be sent to reset some
; time-share computer.
;
SENDBRK:  MVI	A,1FH		;SEND BREAK TONE
	  JMP	GOODBYE1
;...
;
;
; This routine sends a 300 ms. break tone and sets DTR low for the same
; length of time to disconnect some modems such as the Bell 212A, etc.
;
GOODBYE:  MVI	A,15H		;SEND BREAK, TURN OFF DTR
;
GOODBYE1: OUT	MODCTL1		;SEND TO STATUS PORT
	  MVI	B,3		;WAIT 300 MS.
	  CALL	JMP$TIMER
	  MVI	A,07H		;NORMAL SEND/RECEIVE WITH DTR
	  OUT	MODCTL1		;SEND TO STATUS PORT
	  RET
;.....
;
;
; Morrow MD  initialization -- sets the 8251A for 8 bits, 1 stop pulse,
; DTR high, requires dip switches be set internally to 1200 baud then
; divides by 64 for 300, or by 16 for 1200 baud via "SET" command.  Set
; at present to default to 300 baud.
;
INITMOD:  MVI	A,1		;TRANSFER TIME FOR 300 BAUD
	  STA	MSPEED	
	  MVI	A,087H		;INSURE OUT OF MODE
	  OUT	MODCTL1		;MODEM STATUS PORT
	  OUT	MODCTL1		;SLIGHT EXTRA DELAY
	  MVI	A,40H		;INITIALIZE USART
	  OUT	MODCTL1		;MODEM STATUS PORT
;
INITMOD1: MVI	A,4FH		;DEFAULT TO DIVIDE BY 64 FOR 300 BAUD
	  OUT	MODCTL1		;MODEM STATUS PORT
	  MVI	A,17H		;DTR, RCV, XMT, ERROR RESET
	  OUT	MODCTL1		;MODEM STATUS PORT
	  IN	PORT		;CLEAR DATA PORT
	  RET
;.....
;
;
SETUPR:	  LXI	D,BAUDBUF	;POINT TO NEW INPUT BUFFER
	  CALL	JMP$ILPRT
	  DB	'Input Baud Rate (300, 1200): ',0
	  CALL	JMP$INBUF
	  LXI	D,BAUDBUF+2
	  CALL	JMP$INLNCOMP	;COMPARE BAUDBUF+2 WITH CHARACTERS BELOW
	  DB	'300',0
	  JNC	OK300		;GO IF GOT MATCH
	  CALL	JMP$INLNCOMP
	  DB	'1200',0
	  JNC	OK1200
	  CALL	JMP$ILPRT	;ALL MATCHES FAILED, TELL OPERATOR
	  DB	'++ Incorrect entry ++',CR,LF,BELL,0
	  JMP	SETUPR		;TRY AGAIN
;
OK300:	  MVI	A,1		;MSPEED 300 BAUD VALUE
	  MVI	B,4FH		;DIVIDE BY 64 FOR 300 BAUD
	  JMP	LOADBD		;GO LOAD THEM
;
OK1200:	  MVI	A,5
	  MVI	B,4EH		;DIVIDE BY 16 FOR 1200 BAUD
;
;
LOADBD:	  STA	INITMOD+1	;CHANGE TIME-TO-SEND TO MATCH BAUDRATE
	  MOV	A,B		;GET BAUDRATE BYTE
	  STA	INITMOD1+1	;STORE IN INITMOD
	  JMP	INITMOD		;REINITIALIZE TO NEW BAUDRATE, THEN DONE
;
;
BAUDBUF:  DB	10,0
	  DS	10
;.....
;
;
;	       (END OF INITMOD AND SETUP ROUTINES)
;=======================================================================
;		
;
; These routines can be used for your equipment, be sure to end with RET
;
SPCLMENU: RET
;		
;=======================================================================
;
;
; NOTE:  MUST TERMINATE PRIOR TO 0400H (with Smartmodem)
;				 0C00H (without Smartmodem).
;
	  END
;

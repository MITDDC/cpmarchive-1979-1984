
; M712OX.ASM -- Osborne Executive overlay file for MDM712.  07/27/83
;
; You will want to look this file over carefully. There are a number of
; options that you can use to configure the program to suit your taste.
; This file adapts the Osborne Executive computer to MDM712.
;
; Much of the information contained here is not in the MDM712.ASM file.
;
; Edit this file for your preferences then follow the "TO USE:" example
; shown below.
;
; Use the "SET" command to change the baudrate when desired.  It starts
; out at 300 baud when the program is first called up.
;
;	TO USE: First edit this file filling in answers for your own
;		equipment.  Then assemble with MAC.COM or equivalent
;		assembler.  Then use 'DDT' or 'SID' to overlay the
;		results of this program to the original .COM file:
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
; (IF USING DDT FOR CP/M 2.2)
;
;		A>DDT MDM712.COM
;		DDT VERS 2.2
;		NEXT PC
;		4300 0100
;		-IM712OX.HEX		(note the "I" command)
;		-R			("R" loads in the .HEX file)
;		NEXT PC
;		-G0
;		A>SAVE 66 MDM711.COM	(now have a modified .COM file)
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
; (IF USING SID FOR CP/M+)
;
;		A>SID MDM712.COM
;		CP/M 3 SID - Version 3.0
;		NEXT MSZE  PC  END
;		4300 4300 0100 CFFF
;		#RM712OX.HEX		("R" loads in the .HEX file)
;		NEXT MSZE  PC  END
;		???? 4300 0100 CFFF
;		#WMDM712.COM,100,42FF	(save the patched file)
;		#G0			(return to CP/M)
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
; 07/27/83 - Renamed for use with MDM712	- Irv Hoff
; 07/17/83 - Combined George Peace Osborne
;	     version with Roy Robinson Osborne
;	     version then renamed MDM711OX	- Irv Hoff
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
BELL:		EQU	07H	;Bell
CR:		EQU	0DH	;Carriage return
ESC:		EQU	1BH	;Escape
LF:		EQU	0AH	;Linefeed
;
YES:		EQU	0FFH
NO:		EQU	0
;
;
PORT:		EQU	0CH	;Osborne Executive serial output port
MODCTL1:	EQU	PORT+1	;Modem control port
MODDATP:	EQU	PORT	;Modem data port
BAUDRP:		EQU	04H	;Baud rate port
MODRCVB:	EQU	01H	;Your bit to test for receive
MODRCVR:	EQU	01H	;Your value when receive ready
MODSNDB:	EQU	04H	;Your bit to test for send
MODSNDR:	EQU	04H	;Your value when send ready		
;
LSBAUD:		EQU	80H	;default baud rate (least signif. byte)
MSBAUD:		EQU	01H	;default baud rate (most  signif. byte)
;
		ORG	100H
;
;
; Change the clock speed to suit your system
;
		DS	3	;(for  "JMP   START" instruction)
;
PMMIMODEM:	DB	NO	;yes=PMMI S-100 Modem			103H
SMARTMODEM:	DB	NO	;yes=HAYES Smartmodem, no=non-PMMI	104H
TOUCHPULSE:	DB	'T'	;T=touch, P=pulse (Smartmodem-only)	105H
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
TRANLOGON:	DB	NO	;yes=allow transmission of logon	115H
				;write logon sequence at location LOGON
SAVCCP:		DB	YES	;yes=do not overwrite CCP		116H
LOCONEXTCHR:	DB	NO	;yes=local command if EXTCHR precedes	117H
				;no=external command if EXTCHR precedes
TOGGLELOC:	DB	YES	;yes=allow toggling of LOCONEXTCHR	118H
LSTTST:		DB	YES	;yes=printer available on printer port	119H
XOFFTST:	DB	NO	;yes=check for XOFF from remote	while	11AH
				;sending a file in terminal mode
XONWAIT:	DB	NO	;yes=wait for XON after CR while	11BH
				;sending a file in terminal mode
TOGXOFF:	DB	YES	;yes=allow toggling of XOFF checking	11CH
IGNORCTL:	DB	YES	;yes=CTL-chars above ^M not displayed	11DH
EXTRA1:		DB	0	;for future expansion			11EH
EXTRA2:		DB	0	;for future expansion			11FH
BRKCHR:		DB	'\'-40H	;^\ = Send a 300 ms. break tone		120H
20H
NOCONNCT:	DB	'N'-40H	;^N = Disconnect from the phone line	121H
LOGCHR:		DB	'L'-40H	;^L = Send logon			122H
LSTCHR:		DB	'P'-40H	;^P = Toggle printer			123H
UNSAVE:		DB	'R'-40H	;^R = Close input text buffer		124H
TRANCHR:	DB	'T'-40H ;^T = Transmit file to remote		125H
SAVECHR:	DB	'Y'-40H	;^Y = Open input text buffer		126H
EXTCHR:		DB	'^'-40H	;^^ = Send next character	 	127H
;
;
		DS	2		;				128H
IN$MODCTL1:	MVI	A,10H		;channel 0, reset interrupts	12AH
		OUT	MODCTL1
		IN	MODCTL1		;get the status bits
		RET
		DS	3
;
OUT$MODDATP:	OUT	MODDATP ! RET	;out modem data port		134H
		DS	7
IN$MODDATP:	IN	MODDATP ! RET	;in modem data port		13EH
		DS	7
ANI$MODRCVB:	ANI	MODRCVB	! RET	;bit to test for receive ready	148H
CPI$MODRCVR:	CPI	MODRCVR ! RET	;value of receive bit when rdy	14BH
ANI$MODSNDB:	ANI	MODSNDB	! RET	;bit to test for send ready	14EH
CPI$MODSNDR:	CPI	MODSNDR	! RET	;value of send bit when ready	151H
		DS	6		;				154H
OUT$MODCTL1:	OUT	MODCTL1	! RET	;out modem control port #1	15AH
OUT$MODCTL2:	NOP  !	NOP	! RET	;out modem control port #2	15DH
;
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
;
; Clear sequences -- CLREOS is clear to end of screen, CLRSCRN is clear
; entire screen.  Last entry must be 0.  Any other 0's act as NOP's.
;
CLREOS:		CALL	JMP$ILPRT	;				195H
		DB	ESC,'Y',0,0,0	;				198H
		RET			;				19DH
;
CLRSCRN:	CALL	JMP$ILPRT	;				19EH
		DB	ESC,'Z',0,0,0	;				1A1H
		RET			;				1A6H
;
;
SYSVER:		CALL	JMP$ILPRT	;				1A7H
		DB	'Version for Osborne Executive serial port 0CH'
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
;
LOGON:		DB	'This is an Osborne Executive computer',CR,LF,0
;.....
;
;
; This routine allows a 300 ms. break tone to be sent to reset some
; time-shar computers.
;
SENDBRK:  MVI	A,5
	  OUT	MODCTL1
	  MVI	A,0F8H		;SEND A BREAK TONE
	  JMP	GOODBYE1
;.....
;
;
; This routine sends a 300 ms. break tone and sets DTR low for the same
; length of time to disconnect some modems such as the Bell 212A, etc.	
;
GOODBYE:  MVI	A,5
	  OUT	MODCTL1		;SEND TO THE STATUS PORT
	  MVI	A,68H		;TURN OFF DTR
;
GOODBYE1: OUT	MODCTL1
	  MVI	B,3		;WAIT FOR 300 MS.
	  CALL	JMP$TIMER
	  MVI	A,5
	  OUT	MODCTL1
	  MVI	A,0E8H		;RESTORE TO NORMAL, 8 BITS, DTR ON, ETC.
	  OUT	MODCTL1
	  RET
;.....
;
;	
; Osborne Executive initialization
;
INITMOD:  MVI	A,0		;SELECT REGISTER
	  OUT	MODCTL1
	  MVI	A,18H		;THROW OUT OF MODE
	  OUT	MODCTL1
	  MVI	A,04H		;SELECT REGISTER
	  OUT	MODCTL1
	  MVI	A,44H		;SET ASCII PARAMETERS
	  OUT	MODCTL1
	  MVI	A,03H		;SELECT REG.
	  OUT	MODCTL1
	  MVI	A,0C1H		;ENABLE RECEIVE
	  OUT	MODCTL1
	  MVI	A,05H		;SELECT REG.
	  OUT	MODCTL1
	  MVI	A,0EAH		;ENABLE SEND, 'DTR', 'RTS'
	  OUT	MODCTL1
;
INITMOD1: MVI	A,1		;DEFAULT TRANSFER TIME TO 300 BAUD
	  STA	MSPEED
;
INITMOD2: MVI	A,LSBAUD	;SET "LSP" TO BAUD RATE
	  OUT	BAUDRP
;
INITMOD3: MVI	A,MSBAUD	;SET "MSP" TO BAUD RATE
	  OUT	BAUDRP
	  RET
;.....
;
;
; Setup routine to allow changing modem speed with the SET command.
;
SETUPR:
	  LXI	D,BAUDBUF	;POINT TO NEW INPUT BUFFER
	  CALL	JMP$ILPRT
	  DB	'Input Baud Rate (300,600,1200,2400,4800,9600,19200): ',0
	  CALL	JMP$INBUF
	  LXI	D,BAUDBUF+2
	  CALL	JMP$INLNCOMP	;COMPARE BAUDBUF+2 WITH CHARACTERS BELOW
	  DB	'300',0
	  JNC	OK300		;GO IF GOT MATCH
	  CALL	JMP$INLNCOMP
	  DB	'600',0
	  JNC	OK600
	  CALL	JMP$INLNCOMP
	  DB	'1200',0
	  JNC	OK1200
	  CALL	JMP$INLNCOMP
	  DB	'2400',0
	  JNC	OK2400
	  CALL	JMP$INLNCOMP
	  DB	'4800',0
	  JNC	OK4800
	  CALL	JMP$INLNCOMP
	  DB	'9600',0
	  JNC	OK9600
	  CALL	JMP$INLNCOMP
	  DB	'19200',0
	  JNC	OK19200
	  CALL	JMP$ILPRT	;ALL MATCHES FAILED, TELL OPERATOR
	  DB	'++ Incorrect entry ++',CR,LF,BELL,0
	  JMP	SETUPR		;TRY AGAIN
;
OK300:	  MVI	A,1		;MSPEED VALUE FOR FILE TRANFER TIME
	  LHLD	BD300
	  JMP	LOADBD
;
OK600:	  MVI	A,3
	  LHLD	BD600
	  JMP	LOADBD
;
OK1200:	  MVI	A,5
	  LHLD	BD1200
	  JMP	LOADBD
;
OK2400:	  MVI	A,6
	  LHLD	BD2400
	  JMP	LOADBD
;
OK4800:	  MVI	A,7
	  LHLD	BD4800
	  JMP	LOADBD
;
OK9600:	  MVI	A,8
	  LHLD	BD9600
	  JMP	LOADBD
;
OK19200:  MVI	A,9
	  LHLD	BD19200
;
LOADBD:	  STA	INITMOD1+1	;CHANGE TIME-TO-SEND TO MATCH BAUDRATE
	  MOV	A,L		;GET "LSP" BAUD RATE BYTE
	  STA	INITMOD2+1	;SEND TO 8253 TIMER FOR NEW BAUDRATE
	  MOV	A,H		;GET "MSP" BAUD RATE BYTE
	  STA	INITMOD3+1
	  JMP	INITMOD1	;REINITIALIZE TO NEW BAUDRATE, THEN DONE
;.....
;
;
; Table of baud rate values
;
BD300:	  DW	0180H		;300 baud
BD600:	  DW	00C0H		;600 baud
BD1200:	  DW	0060H		;1200 baud
BD2400:	  DW	0030H		;2400 baud
BD4800:	  DW	0018H		;4800 baud
BD9600:	  DW	000CH		;9600 baud
BD19200:  DW	0006H		;19200 baud
;
BAUDBUF:  DB	10,0
	  DS	10
;.....
;
;
; The following routine can be used as an auxiliary menu for notes of
; interest to a particular computer, etc.  If using the Hayes Smartmodem
; this is unavailable without a special address change.
;
SPCLMENU: RET
;.....
;
;
; NOTE:   MUST TERMINATE PRIOR TO 0400H (with Smartmodem)
; 				  0C00H (without Smartmodem)
;
	  END
;

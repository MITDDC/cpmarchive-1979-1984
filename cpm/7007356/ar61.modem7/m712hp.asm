
; M712HP.ASM -- Hewlett Packard overlay file for MDM712.  07/27/83
;
; This overlay adapts the MDM712 program to the HP125 Series 100.
;
; You will want to look this file over carefully. There are a number of
; options that you can use to configure the program to suit your taste.
; You use the AIDS and SOFT KEYS to configure baud rate and other para-
; meters.
;
; The HP125 uses two Z80's one for I/O and the other for crunching.
; Needless to say HP doesn't let the number crunching Z80 talk directly
; to the I/O ports, so direct communication with the ports is out.  As
; luck would have it HP did include RDR: and PUN: routines, these rou-
; tines have been used in this implementation.  NOTE:  Special routines
; were required to device map the PUN: and RDR: to PORT 1 and to get all
; 8 bits of data in and out of the port. 
;
;***********************************************************************
;
;			  W A R N I N G
;			  - - - - - - -
;
; ALWAYS DEPART THIS PROGRAM FROM THE COMMAND LEVEL,  USING THE 'BYE'
; COMMAND SO THAT YOUR HP125 GETS RECONFIGURED TO IT'S NORMAL STATE.
;
;***********************************************************************
;
; Edit this file for your preferences then follow the "TO USE:" example
; shown below.
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
;		-IM712HP.HEX		(note the "I" command)
;		-R			("R" loads in the .HEX file)
;		NEXT  PC
;		4300 0000
;		-G0			(return to CP/M)
;		A>SAVE 66 MDM712.COM	(now have a modified .COM file)
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
; 07/20/83 - Renamed to work with MDM712	- Irv Hoff
; 07/20/83 - Revised to work with HP125		- John Bingel
; 07/01/83 - Revised to work with MDM711	- Irv Hoff
; 07/01/83 - Revised to work with MDM710	- Irv Hoff
; 05/27/83 - Updated to work with MDM709	- Irv Hoff
; 05/15/83 - Revised to work with MDM708	- Irv Hoff
; 04/11/83 - Updated to work with MDM707	- Irv Hoff
; 04/04/83 - First version of this file		- Irv Hoff
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
BDOS:		EQU	05H
BELL:		EQU	07H		;bell
CR:		EQU	0DH		;carriage return
ESC:		EQU	1BH		;escape
LF:		EQU	0AH		;linefeed
;
YES:		EQU	0FFH
NO:		EQU	0
;
;
; Change the following information to match your equipment
;
RDRST:		EQU	70FFH		;READER STATUS SFC
RDRIN:		EQU	03H		;READER INPUT SFC
PUNOUT:		EQU	04H		;PUNCH OUTPUT SFC
BITS8:		EQU	73FFH		;8 BIT SFC
BITS7:		EQU	74FFH		;RESET TO NORMAL 7 BIT SFC
JVT:		EQU	7EFFH		;JUMP VECTOR TABLE SFC
MODRCVB:	EQU	1		;BIT TO TEST FOR RECEIVE
MODRCVR:	EQU	1		;VALUE WHEN READY
MODSNDB:	EQU	0		;BIT TO TEST FOR SEND
MODSNDR:	EQU	0		;VALUE WHEN READY
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
MSPEED:		DB	5	;0=110 1=300 2=450 3=600 4=710 5=1200   107H
				;6=2400 7=4800 8=9600 9=19200 default
BYTDLY:		DB	5	;0=0 delay  1=10ms  5=50 ms - 9=90 ms   108H
				;default time to send character in ter-
				;minal mode file transfer for slow BBS.
CRDLY:		DB	5	;0=0 delay 1=100 ms 5=500 ms - 9=900 ms 109H
				;default time for extra wait after CRLF
				;in terminal mode file transfer
NOOFCOL:	DB	5	;number of DIR columns shown		10AH
SETUPTST:	DB	NO	;yes=user-added Setup routine		10BH
SCRNTEST:	DB	NO	;Cursor control routine 		10CH
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
EXTRA2:		DB	0	;for future expansion			11FH
BRKCHR:		DB	'@'-40H	;^@ = Send 300 ms. break tone		120H
NOCONNCT:	DB	'N'-40H	;^N = Disconnect from the phone line	121H
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
IN$MODCTL1:	JMP	INCTL		;in modem control port	     	12AH
		DS	7
OUT$MODDATP:	JMP	OUTDATA		;out modem data port		134H
		DS	7
IN$MODDATP:	JMP	INDATA		;in modem data port		13EH
		DS	7
ANI$MODRCVB:	ANI	MODRCVB	! RET	;bit to test for receive ready	148H

CPI$MODRCVR:	CPI	MODRCVR	! RET	;value of rcv. bit when ready	14BH
ANI$MODSNDB:	MVI	A,MODSNDB ! RET	;bit to test for send ready	14EH
CPI$MODSNDR:	CPI	MODSNDR	! RET	;value of send bit when ready	151H
		DS	6		;				156H
;
OUT$MODCTL1:	NOP !	NOP	! RET	;out modem control port #2	15AH
OUT$MODCTL2:	NOP !	NOP	! RET	;out modem control port #1	15DH
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
		DB	0,0,0,0,0	;				198H
		RET			;				19DH
;
CLRSCRN:	CALL	JMP$ILPRT	;				19EH
		DB	0,0,0,0,0	;				1A1H
		RET			;				1A6H
	
;
SYSVER:		LXI	B,BITS8		;SFC 115 SET PORT 1 TO 8 BITS
		CALL	BDOS	
		CALL	JMP$ILPRT	;				1A7H
;
;
; DEVICE MAP RDR: & PUN: TO USE PORT 1
;
		DB	1BH,'&i0s25d4M',1BH,'&i10s16d4M',CR,LF
;
;
; NOW PRINT LOGON
;
		DB	'Version for the HP125 Series 100'
		DB	CR,LF,LF,LF,'ALWAYS SIGN OFF USING ''BYE'' FROM'
 		DB	' THE COMMAND MODE',CR,LF,0
;
; NOW SET UP READER ROUTINE SO WE REALLY GET 8 BITS
;
		LXI	B,JVT		;SFC 126
		LXI	D,JBUF		;ADDRESS OF JUMP BUFFER
		CALL	BDOS		;READ JUMP TABLE INTO JBUF
		LHLD	JUMP		;GET ADDRESS RETURNED IN JBUF
		SHLD	REAL		;AND STORE AS REAL RDRIN
		LXI	H,INEIGHT	;GET ADDRESS OF 8 BIT INPUT 
		SHLD	JUMP		;AND STORE IN JBUF
		MVI	A,1		;MOVE A WRITE CODE INTO A
		STA	FLAG		;STORE IT IN JBUF
		LXI	B,JVT		;SFC 126
		LXI	D,JBUF		;ADRESS OF JUMP BUFFER
		CALL	BDOS		;WRITE JUMP TABLE FROM JBUF
		RET
;
;
; MODEM I/O PRIMITIVES
;
OUTDATA:	PUSH	B
		PUSH	D
		PUSH	H
		MOV	E,A		;MOVE OUTPUT BYTE FROM A TO E
		MVI	C,PUNOUT	;GET PUN: SFC
		CALL	BDOS		;OUTPUT BYTE
		POP	H
		POP	D
		POP	B
		RET
;
INDATA:		PUSH	B
		PUSH	D
		PUSH	H
		MVI	C,RDRIN		;GET RDR: SFC
		CALL	BDOS		;GET BYTE FROM RDR:
		POP	H
		POP	D
		POP	B
		RET
;
INEIGHT:	CALL	READIN		;BYPASS BIT 8 STRIP IN
		MOV	A,B		;RDR: ROUTINE
		RET
;
INCTL:		PUSH	B
		PUSH	D
		PUSH	H
		LXI	B,RDRST		;GET RDR: STATUS SFC
		CALL	BDOS		;GET RDR: STATUS
		POP	H
		POP	D
		POP	B
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
LOGON:		DB	'How are you today?',CR,LF,0
;.....
;
;
; Routine to send a break tone to reset some time-share computers, if
; desired.
;
SENDBRK:	MVI	A,02H
		CALL	OUTDATA
		RET
;.....
;
;
; Routine to put DTR low (to disconnect) and/or send a break tone.
;
GOODBYE:	CALL	JMP$ILPRT
		DB	1BH,'E',0	;COLD BOOT SYSTEM
		RET
;.....
;
;
READIN:		DB	0C3H	;JUMP OPCODE
REAL:		DS	2	;SAVE 2 BYTES FOR ADDRESS
JVN:		DB	7	;READER BIOS CODE
FLAG:		DB	0	;READ/WRITE CODE
OPCODE:		DS	1	;RESERVE 1 BYTE FOR JMP CODE
JUMP:		DS	2	;AND 2 BYTES FOR ADDRESS
JBUF:		EQU	JVN	;NAME ENTIRE BUFFER JBUF
;
;.....
;
;
; You can use this area for any special initialization or setup you may
; wish to include.  Each must stop with a RET.  You can check the other
; available overlays for ideas how to write your own routines if that
; may be of some help.
;
INITMOD:  RET
;
SETUPR:	  RET
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
;


; M712AC.ASM -- APPLE-CAT II overlay file for MDM712.  07/27/83
;
; You will want to look this file over carefully.  There are a number of
; options that you can use to configure the program to suit your taste.
; Much of the information contained here is not in the main file.
;
; Edit this file for your preferences then follow the "TO USE:" EXAMPLE
; shown below.
;
;
; SPECIAL NOTES FOR THE APPLE CAT II VERSION:
; ------------------------------------------
;
;      The distribution version of this file is configured for an Apple-
;   Cat II in slot 2.  If you are runing your modem in a different slot,
;   you need merely change the 'CATSLOT' equate before assembling.  (A
;   side note, if you are experiencing thermal problems with your Apple
;   try moving the Apple-Cat board away from the 80-column card.)
;
;      This overlay supports the Apple-Cat II at 300 and 1200 baud, as-
;   suming you have the 212A option board).  With this board, you must
;   use the 'slot saver' configuration.  The 'SET' command has been im-
;   plemented to allow the user to set either baud rate, and well as
;   'answer' or 'originate' mode.  It also allows the user to change
;   modem baud rate on the fly, if desired.  The 'TIM' function is set
;   automatically.
;
;      A 'quick INIT' feature has been added.  The command from the CP/M
;   level is either A>MDM 3 (300 baud) or A>MDM 2 (1200 baud).  These
;   commands will cause automatic initialization of the modem at 300 or
;   1200 baud respectively (originate mode only).  The program then falls
;   directly into the terminal mode.  Just calling up the program with:
;   A>MDM will result in the program not being initialized, so the user
;   will then need to use the 'SET' command to initialize for 300 or for
;   1200 baud.
;
; IMPORTANT NOTE REGARDING THE PRINTER BUFFER FUNCTION:
;
;     As distributed, this overlay has the printer buffer function dis-
;   abled.  This is because the Apple (Microsoft) BIOS does not support
;   the LISTST function (BIOS 14).   Thus it returns with "Printer busy"
;   status. Printer handshaking is not important if you have plenty of
;   buffering.  Some printers have 64k, although most only have 2-4k.
;   It is also of no importance, if the throughput of your printer is
;   higher than the speed of the incoming information.  For example when
;   using 300 baud (30 characters per second), nearly all printers are
;   capable of printing at this relatively slow speed.  However at 1200
;   baud, very few printers in the under-$1000 class are capable of 120
;   character/second throughput.  In this case a modest-sized buffer
;   might fill before you finished copying the information you wished to
;   print.  It would probably start to lose characters as a result.  A
;   special routine in the initialization code has been added so that
;   BIOS 14 always returns "Printer ready".  This special patch is used
;   only if the printer option LSTTST in this overlay is set to YES.  Be
;   careful about using this option if you do not have a large printer
;   buffer and frequently run at 1200 baud.
;
;	TO USE:	First edit this file filling in answers for your own
;		equipment.  Then assemble with ASM.COM or equivalent
;		assembler.  Then use DDT to overlay the results of
;		this program to the original  .COM file:
;
;		A>DDT MDM712.COM
;		DDT VERS 2.2
;		NEXT  PC
;		4300 0100
;		-IM712AP.HEX		(note the "I" command)
;		-R			("R" load in the  .HEX file)
;		NEXT  PC
;		4300 0000
;		-G0			(return to CP/M)
;		A>SAVE 66 MDM712.COM	(now have a modified .COM file)
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
; 07/27/83 - Renamed to work with MDM712	- Irv Hoff
; 07/01/83 - Revised to work with MDM711	- Irv Hoff
; 06/22/83 - Revised to work with MDM710	- Irv Hoff
; 06/07/83 - Converted GP file for APPLECAT     - Chris Hays
; 05/27/83 - Updated to work with MDM709	- Irv Hoff
; 05/15/83 - Revised to work with MDM708	- Irv Hoff
; 04/11/83 - Updated to work with MDM707	- Irv Hoff
; 04/04/83 - First version of this file		- Irv Hoff
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
BELL:		EQU	07H		;BELL
CR:		EQU	0DH		;CARRIAGE RETURN
ESC:		EQU	1BH		;ESCAPE
LF:		EQU	0AH		;LINEFEED
;
YES:		EQU	0FFH
NO:		EQU	0
;
;
; CHANGE THE FOLLOWING INFORMATION TO MATCH YOUR EQUIPMENT
;
MODCTL1:	EQU	0		;DUMMY MODEM CONTROL PORT
MODCTL2:	EQU	0		;DUMMY MODEM CONTROL PORT
;
CATSLOT		EQU	2		;SET FOR SLOT OF APPLE CAT
;
SLOT		EQU	CATSLOT*16
COM		EQU	0E08CH+SLOT
XMTBYT		EQU	0E08DH+SLOT
CON		EQU	0E08AH+SLOT
BSRBYT		EQU	0E083H+SLOT
SHBYT		EQU	0E082H+SLOT
TONBYT		EQU	0E081H+SLOT
SQUBYT		EQU	0E081H+SLOT
SWBYT		EQU	0E080H+SLOT
RECBYT		EQU	0E089H+SLOT
INDAT		EQU	0E08BH+SLOT
OUTDAT		EQU	0E08EH+SLOT
SPDBYT		EQU	0E08BH+SLOT
STATUS		EQU	0E08FH+SLOT
ACBYT		EQU	0E08DH+SLOT
DEVBYT		EQU	0E08FH+SLOT
XMTRAM		EQU	0F01BH		;TO CLEAR STATUS
;
MODDCD3		EQU	0
MODDCD12	EQU	0		;FOR 212 BOARD
MODRCVB:	EQU	2		;BIT TO TEST FOR RECEIVE
MODRCVR:	EQU	2		;VALUE WHEN READY
MODSNDB:	EQU	1		;BIT TO TEST FOR SEND
MODSNDR:	EQU	1		;VALUE WHEN READY
;
		ORG	100H
;
;
; CHANGE THE CLOCK SPEED TO SUIT YOUR SYSTEM
;
		DS	3	;(For "JMP   START" instruction)
;
PMMIMODEM:	DB	NO	;yes=PMMI S-100 Modem			103H
SMARTMODEM:	DB	NO	;yes=HAYES Smartmodem			104H
TONEPULSE:	DB	'T'	;T=tone, P=pulse (Smartmodem-only)	105H
CLOCK:		DB	20	;clock speed in MHz x10, 25.5 MHz max.	106H
				;20=2 MHz, 37=3.68 MHz, 40=4 MHz, etc.

MSPEED:		DB	1	;0=110 1=300 2=450 3=600 4=710 5=1200   107H
				;6=2400 7=4800 8=9600 9=19200 default
BYTDLY:		DB	5	;0=0 delay  1=10 ms 5=50 ms - 9=90 ms   108H
				;default time to send character in ter-
				;minal mode file transfer for slow BBS.
CRDLY:		DB	5	;0=0 delay 1=100 ms 5=500 ms - 9=900 ms 109H
				;default time for extra wait after CRLF
				;in terminal mode file transfer
NOOFCOL:	DB	5	;number of directory columns shown	10AH
SETUPTST:	DB	YES	;yes=user-added setup routine		10BH
SCRNTEST:	DB	NO	;cursor control routine			10CH
ACKNAK:		DB	YES	;yes=resend a record after a non-ACK	10DH
				;no=resend a record only after NAK
BAKUPBYTE:	DB	NO	;yes=change any file same name to .BAK	10EH
CRCDFLT:	DB	YES	;yes=default to CRC checking		10FH
TOGGLECRC:	DB	YES	;yes=allow toggling of CRC to checksum	110H
CONVBKSP:	DB	NO	;yes=convert backspace to rub		111H
TOGGLEBK:	DB	NO	;yes=allow toggling of BKSP to RUB	112H
ADDLF:		DB	NO	;no=no LF after CR to send file in	113H
				;termianl mode (added by remote echo)
TOGGLELF:	DB	YES	;yes=allow toggling of LF after CR	114H
TRANLOGON:	DB	YES	;yes=allow transmission of LOGON	115H
				;write logon sequence at location LOGON
NOCCP:		DB	NO	;MUST BE NO FOR APPLE CP/M 2.23		116H
LOCONEXTCHR:	DB	NO	;yes=local command if EXTCHR precedes	117H
				;no=external command if EXTCHR precedes	
TOGGLELOC:	DB	YES	;yes=allow toggling of LOCONEXTCHR	118H
LSTTST:		DB	NO	;yes=printer available on printer port	119H
				;(See special printer note above)
XOFFTST:	DB	NO	;yes=checks for X-OFF from remote while	11AH
				;sending a file in terminal mode
XONWAIT:	DB	NO	;yes=wait for X-ON after CR while	11BH
				;sending a file in terminal mode
TOGXOFF:	DB	YES	;yes=allow toggling of X-OFF checking	11CH
IGNORCTL:	DB	YES	;yes=CTL-chars. above ^M not displayed	11DH
EXTRA1:		DB	0	;for future expansion			11EH
EXTRA2:		DB	0	;for future expansion			11FH
BRKCHR:		DB	'@'-40H	;^@ = send a 300 ms. break tone		120H
NOCONNCT	DB	'N'-40H	;^N = disonnect from phone line		121H
LOGCHR:		DB	'L'-40H	;^L = send LOGON			122H
LSTCHR:		DB	'P'-40H	;^P = toggle printer			123H
UNSAVE:		DB	'R'-40H	;^R = close input text buffer		124H
TRANCHR:	DB	'T'-40H ;^T = transmit file to remote		125H
SAVECHR:	DB	'Y'-40H	;^Y = open input text buffer		126H
EXTCHR:		DB	'^'-40H	;^^ = send next character to modem	127H
;
;
		DS	2		;				128H
;	
IN$MODCTL1:	LDA	STATUS	! RET	;IN MODEM CONTROL PORT		12AH
		DS	6
OUT$MODDATP:	STA	OUTDAT	! RET	;OUT MODEM DATA PORT		134H
		DS	6
IN$MODDATP:	LDA	XMTRAM		;				13EH
		STA	XMTBYT
		LDA	INDAT
		RET
ANI$MODRCVB:	ANI	00001000B ! RET	;BIT TO TEST FOR RECEIVE READY	148H

CPI$MODRCVR:	CPI	00001000B ! RET	;VALUE OF RCV BIT WHEN READY	14BH
ANI$MODSNDB:	ANI	00010000B ! RET	;BIT TO TEST FOR SEND READY	14EH
CPI$MODSNDR:	CPI	00010000B ! RET	;VALUE OF SEND BIT WHEN READY	151H
		DS	6		;				154H
;
OUT$MODCTL1:	OUT	MODCTL1	! RET	;OUT MODEM CONTROL PORT #2	15AH
OUT$MODCTL2:	OUT	MODCTL2	! RET	;OUT MODEM CONTROL PORT #1	15DH
;
LOGONPTR:	DW	LOGON		;FOR USER MESSAGE.		160H
		DS	6		;				162H
JMP$GOODBYE:	JMP	GOODBYE		;				168H
JMP$INITMOD:	JMP	INITMOD		;GO TO USER WRITTEN ROUTINE	16BH
		RET  !  NOP  !  NOP	;(BY-PASSES PMMI ROUTINE)	16EH
		RET  !  NOP  !  NOP	;(BY-PASSES PMMI ROUTINE)	171H
		RET  !  NOP  !  NOP	;(BY-PASSES PMMI ROUTINE)	174H
JMP$SETUPR:	JMP	SETUPR		;				177H
JMP$SPCLMENU:	JMP	SPCLMENU	;				17AH
JMP$SYSVER:	JMP	SYSVER		;				17DH
JMP$BREAK:	JMP	SENDBRK		;				180H
;
;
; DO NOT CHANGE THE FOLLOWING SIX LINES.
;
JMP$ILPRT:	DS	3		;				183H
JMP$INBUF	DS	3		;				186H
JMP$INLNCOMP:	DS	3		;				189H
JMP$INMODEM	DS	3		;				18CH
JMP$NXTSCRN:	DS	3		;				18FH
JMP$TIMER:	DS	3		;				192H
;
; 
; ROUTINE TO CLEAR TO END OF SCREEN.  IF USING CLREOS AND CLRSCRN, SET
; SCRNTEST TO YES AT 010AH (ABOVE).
;
CLREOS:		CALL	JMP$ILPRT	;				195H
		DB	0,0,0,0,0	;				198H
		RET			;				19DH
;
CLRSCRN:	CALL	JMP$ILPRT	;				19EH
		DB	0,0,0,0,0	;				1A1H
		RET			;				1A6H
	
;
SYSVER:		CALL	JMP$ILPRT	;				1A7H
		DB	'Version for APPLE-CAT II modem'	
		DB	CR,LF,0
		RET
;.....
;
;
;-----------------------------------------------------------------------
;
; NOTE:  You can change the SYSVER message ta be longer or shorter.  The
;	end of your last routine should terminate by 0400H (601 bytes
;	available after start of SYSVER) if using the Hayes Smartmodem
;	or by address 0C00H (2659 bytes) otherwise.
;
;-----------------------------------------------------------------------
;
; You can put in a message at this location which can be called up with
; CTL-O if TRANLOGON has been set YES.  You can use several lines if
; desired.  End with a 0.
;
LOGON:	  DB	'HOW ARE YOU TODAY?',CR,LF,0
;.....
;
;
; You can add a routine here to send a 300 ms. break tone to reset some
; time-share computers.  (See examples in other overlays, such as the
; MDM710DP for Datapoint computers.
;
SENDBRK:  RET
;.....
;
;
GOODBYE:  MVI	A,0
	  STA	SHBYT
	  MVI	A,1FH
	  STA	XMTBYT
	  STA	XMTRAM
	  MVI	A,0A1H
	  STA	SQUBYT
	  RET
;.....
;
;
;
INITMOD:
;
; This routine patches the printer test in the Apple so that is always
; returns "printer ready".  (See notes at the beginning about using this
; routine.)
;
INITMOD:  LDA	LSTTST		;CHECK IF PRINT FUNCTION ENABLED
	  CPI	0
	  JZ	FIRSTIN		;DON'T PATCH BIOS IF WE AREN'T PRINTING
	  LHLD	0001
	  MOV	A,L
	  ADI	02AH
	  MOV	L,A
	  MVI	A,03EH
	  MOV 	M,A
	  INR	L
	  MVI	A,0FFH
	  MOV	M,A
	  INR	L
	  MVI	A,0C9H
	  MOV	M,A
;
;
;Now begins the actual modem initialization
;
FIRSTIN:  LDA	80H		;CHECK FOR BAUD CODE
	  CPI	0
	  JZ	NOINMSG		;DON'T INITIALIZE IF NOTHING THERE
	  LDA	5DH		;GET FIRST CHARACTER OF OBJECT
	  ANI	0FH
	  CPI	3		;ASCII 3 FOR 300 BAUD
	  JNZ	CK2
	  CALL	INIT3
	  JMP	ORIG103
;.....
;
;
CK2:	  CPI	2H		;ASCII 2 FOR 1200 BAUD
	  JNZ	NOINMSG
	  CALL	INIT2
	  JMP	ORIG212
;.....
;
;
NOINMSG:  CALL	JMP$ILPRT
	  DB	ESC,'(','NOT INITIALIZED',ESC,')',CR,LF,0
	  RET
;.....
;
;
INIT3:	  CALL	PICKUP		;PICKUP PHONE
	  MVI	A,0A1H
	  STA	RECBYT
	  MVI	A,00000011B	;8 DATA NO PARITY 1 STOP
	  STA	CON
	  MVI	A,22H
	  STA	SPDBYT
	  MVI	A,1
	  STA	MSPEED
	  RET
;.....
;
;
ORIG103:
	  MVI	A,11H		;103 ORIG, NO RING IRQ
	  STA	XMTBYT
	  STA	XMTRAM
	  MVI	A,65H
	  STA	RECBYT
	  RET
;.....
;
;
ANS103:	  MVI	A,10H
	  STA	XMTBYT
	  STA	XMTRAM
	  MVI	A,64H
	  STA	RECBYT
	  RET
;.....
;
;
INIT2:	  CALL	PICKUP
	  MVI	A,0
	  STA	SPDBYT		;1200 BAUD
	  MVI	A,18H
	  STA	XMTBYT
	  STA	XMTRAM
	  MVI	A,0AH
	  STA	DEVBYT
	  MVI	A,13H
	  STA	CON
	  MVI	A,05H
	  STA	COM
	  STA	MSPEED
	  RET
;.....
;
;
ORIG212:  MVI	A,0A1H
	  STA	SQUBYT
	  CALL	DELAY5
	  MVI	A,21H
	  STA	SQUBYT
	  RET
;.....
;
;
ANS212:	  MVI	A,81H
	  STA	SQUBYT
	  CALL	DELAY5
	  MVI	A,01
	  STA	SQUBYT
	  RET
;.....
;
;
SETORIG:  LDA	MSPEED
	  CPI	1
	  JZ	ORIG103
	  JMP	ORIG212		;SELECT 212 OR 103
;.....
;
;
SETANS:   LDA	MSPEED
	  CPI	1
	  JZ	ANS103
	  JMP	ANS212
;.....
;
;
PICKUP:	  MVI	A,0A1H
	  STA	SQUBYT
	  MVI	A,'T'
	  STA	5DH		;FORCE TERMINAL MODE AFTER INIT
	  MVI	A,2
	  STA	SHBYT
	  MVI	A,0FH
	  STA	BSRBYT
	  MVI	A,13H
	  STA	CON
	  MVI	A,05H
	  STA	COM
	  MVI	A,0
	  STA	DEVBYT
	  RET
;.....
;
;
SETUPR1:  CALL	JMP$ILPRT
	  DB	'ENTER ''O'' FOR Originate, ''A'' FOR Answer '
	  DB	'OR ''D'' FOR Disconnect:',0
	  MVI	C,1
	  CALL	0005
	  PUSH	PSW
	  CALL 	JMP$ILPRT
	  DB	CR,LF,0
	  POP	PSW
	  ANI	01011111B	;FORCE UPPER CASE AND HI BIT OFF
	  CPI	'O'
	  JZ	SETORIG
	  CPI	'A'
	  JZ	SETANS
	  CPI	'D'
	  JZ	GOODBYE
	  CALL 	JMP$ILPRT
	  DB	'INVALID: MUST BE ONE OF THE THREE',CR,LF,0
	  JMP	SETUPR1
;.....
;
;
SETUPR:	  CALL	JMP$ILPRT
	  DB	'ENTER 3 FOR 300 BAUD OR 2 FOR 1200 BAUD:',0
	  MVI	C,1
	  CALL	0005		;GET THE USER'S INPUT
	  PUSH	PSW
	  CALL	JMP$ILPRT
	  DB	CR,LF,0
	  POP	PSW
	  SUI	30H
	  CPI	3
	  JNZ	CK2A
	  CALL	INIT3
	  JMP	SETUPR1
;.....
;
;
CK2A:	  CPI	2
	  JNZ	NOT2
	  CALL	INIT2
	  JMP	SETUPR1
;.....
;
;
NOT2:	  CALL	JMP$ILPRT
	  DB	'INVALID MUST BE 2 OR 3',CR,LF,0
	  JMP	SETUPR
	  RET
;.....
;
;
SPCLMENU: CALL 	JMP$ILPRT
	  DB	'APPLECAT MODE CAN BE CHANGED WITH THE <SET>'
	  DB	'COMMAND AT THE COMMAND PROMPT',CR,LF,0
	  RET
;.....
;
;
DELAY5:	  PUSH	PSW
	  PUSH	B
	  LXI	B,1000		;5-10 MS HARDWARE DELAY
;
DELAY5A:  DCX	B
	  MOV	A,B
	  ORA	C
	  JNZ	DELAY5A
	  POP	B
	  POP	PSW
	  RET
;.....
;
;
; NOTE:  Must terminate prior to 0C00H
;.....
;
	  END
;

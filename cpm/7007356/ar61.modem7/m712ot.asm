
; M712OT.ASM -- Overlay for Otrona Attache for MDM712.  07/27/83
;
; This overlay adapts the MDM712 program to the Otrona Attache portable
; computer.  It sets the initial baud rate to equal the rate set in CMOS
; ram by the Attache set-up keys.  A patch to the BIOS is included that
; allows the use of a printer (^P) in terminal (T) mode.  (The Attache
; BIOS function 'LISTST' does not work as written).  The break key is ^\
; and it sends a 300ms break.  DO NOT TRY TO USE ^@ AS THE ATTACHE KEY-
; BOARD DECODES ^@ AS 0C8H NOT 00H.  (See the Attache technical manual
; for details.)
;
; Some Z-80 code is used in this overlay to allow it to fit inside of
; 400H.  (Start of dialing routines.)  It is included by some EQU's at
; the beginning.  DO NOT REMOVE THEM.
;
; You will want to look this file over carefully. There are a number of
; options that you can use to configure the program to suit your taste.
;
; The 'SET' command can be used to change the baud rate to a selected
; value or to a new CMOS ram value.  It comes up at the current baud
; rate that is in CMOS ram.
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
;		-IM712OT.HEX		(note the "I" command)
;		-R			("R" loads in the .HEX file)
;		NEXT  PC
;		4300 0000
;		-G0			(return to CP/M)
;		A>SAVE 66 MDM712.COM	(now have a modified .COM file)
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
; 08/25/83 - Corrected minor bugs including
;            problem with SET command. Added
;            all speeds that have MSPEED  
;            values associated with them.       - Donald Larson
; 07/27/83 - Renamed to work with MDM712	- Irv Hoff
; 07/11/83 - Revised somewhat for MDM711	- Irv Hoff
; 07/08/83 - Updated to work with MDM711	- Allen Edwards
; 06/27/83 - Adapted to Otrona Attache from
;	     MDM710GP.ASM			- Allen Edwards
;	     
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
;======================Z80 BRANCH EQUATES===============================
;
;
BNC	EQU	30H
BZ	EQU	28H
BR	EQU	18H
BC	EQU	38H
BNZ	EQU	20H
;
; EXAMPLE OF USE OF Z80 BRANCH INSTRUCTIONS
;
;		ORG	100H
;	NEXT:	DB	BR,START-NEXT-2 AND 0FFH	;branch to start:
;	START:	DB	BR,NEXT-START-2 AND 0FFH	;branch to next:
;		END	100H
;
;=======================================================================
;
;
;
BELL:		EQU	07H		;bell
CR:		EQU	0DH		;carriage return
ESC:		EQU	1BH		;escape
LF:		EQU	0AH		;linefeed
CLS:		EQU	1AH		;clear screen
;
;
; BDOS EQUATES
;
BDOS:		EQU	0005H
WRCON:		EQU	02H
RDCON:		EQU	01H
PUNCH:		EQU	04H
;
;
;
YES:		EQU	0FFH
NO:		EQU	0
;
;
;
PORT:		EQU	0F0H
MODCTL1:	EQU	PORT+1		;MODEM CONTROL PORT
MODDATP:	EQU	PORT  		;MODEM DATA IN PORT
MODDATO:	EQU	PORT  		;MODEM DATA OUT PORT
MODRCVB:	EQU	1		;BIT TO TEST FOR RECEIVE
MODRCVR:	EQU	1		;VALUE WHEN READY
MODSNDB:	EQU	4		;BIT TO TEST FOR SEND
MODSNDR:	EQU	4		;VALUE WHEN READY
;
		ORG	100H
;
;
;
		DS	3	;(for  "JMP   START" instruction)
;
PMMIMODEM:	DB	NO	;yes=PMMI S-100 Modem			103H
SMARTMODEM:	DB	YES	;yes=HAYES Smartmodem, no=non-PMMI	104H
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
SCRNTEST:	DB	YES	;Cursor control routine 		10CH
ACKNAK:		DB	YES	;yes=resend a record after any non-ACK	10DH
				;no=resend a record after a valid-NAK
BAKUPBYTE:	DB	YES	;yes=change any file same name to .BAK	10EH
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
LSTTST:		DB	YES	;yes=allow toggling of printer on/off	119H
;
;
; Change the following to match the needs of the computer you will be
; to using terminal (T) (non-protocal)
;
XOFFTST:	DB	NO	;yes=checks for XOFF from remote while	11AH
				;sending a file in terminal mode
XONWAIT:	DB	NO	;yes=wait for XON after CR while	11BH
				;sending a file in terminal mode
;
;
TOGXOFF:	DB	YES	;yes=allow toggling of XOFF checking	11CH
IGNORCTL:	DB	YES	;yes=CTL-chars above ^M not displayed	11DH
EXTRA1:		DB	0	;for future expansion			11EH
EXTRA2:		DB	0	;for future expansion			11FH
BRKCHR:		DB	'\'-40H	;^\ = Send 300 ms. break tone		120H
             			;NOTE: DO NOT CHANGE TO ^@
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
IN$MODCTL1:	IN	MODCTL1 ! RET	;in modem control port	     	12AH
		DS	7
OUT$MODDATP:	OUT	MODDATP ! RET	;out modem data port		134H
		DS	7
IN$MODDATP:	IN	MODDATP ! RET	;in modem data port		13EH
		DS	7
ANI$MODRCVB:	ANI	MODRCVB	! RET	;bit to test for receive ready	148H

CPI$MODRCVR:	CPI	MODRCVR	! RET	;value of rcv. bit when ready	14BH
ANI$MODSNDB:	ANI	MODSNDB	! RET	;bit to test for send ready	14EH
CPI$MODSNDR:	CPI	MODSNDR	! RET	;value of send bit when ready	151H
		DS	6		;				156H
;
OUT$MODCTL1:	OUT	MODCTL1	! RET	;out modem control port #1	15AH
OUT$MODCTL2:	RET  !  NOP  !  NOP	;bypass   control port #2	15DH
;
LOGONPTR:	DW	LOGON		;for user message.		160H
		DS	6		;				162H
JMP$GOODBYE:	JMP	GOODBYE		;				168H
JMP$INITMOD:	JMP	INITMOD		;go to user written routine	16BH
;
		RET  !  NOP  !  NOP	; bypass PMII routine	  	16EH
		RET  !  NOP  !  NOP	; bypass PMII routine		171H
		RET  !  NOP  !  NOP	; bypass PMII routine		174H
;
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
		DB	ESC,'J',0,0,0	;				198H
		RET			;				19DH
;
CLRSCRN:	CALL	JMP$ILPRT	;				19EH
		DB	CLS,0,0,0,0	;				1A1H
		RET			;				1A6H
	
;
SYSVER:		CALL	JMP$ILPRT	;				1A7H
		DB	CR,LF,ESC,'U',38,'OTRONA Attache',ESC,'U',32,' (w/BIOS patch)'
		DB	CR,LF,LF,0
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
; desired.  End with a 0
;
LOGON:		DB	'put your logon message here'
 		DB	CR,LF,0
;.....
;
;
; This routine allows a 300 ms. break tone to be sent to reset some
; time-share computers.
;
SENDBRK:  MVI	A,5
	  OUT	MODCTL1		;send to the status port
	  MVI	A,0FAH		;send a break tone
	  JMP	GOODBYE1
;.....
;
;
; Set DTR low for 300 ms. to disconnect some modems
;
GOODBYE:  MVI	A,5
	  OUT	MODCTL1		;send to the status port
	  MVI	A,68H		;turn off DTR	
;
GOODBYE1: OUT	MODCTL1
	  MVI	B,3		;wait for 300 ms.
	  CALL	JMP$TIMER
	  MVI	A,5
	  OUT	MODCTL1
	  MVI	A,0EAH		;restore to normal, DTR on, 8 bits, etc.
	  OUT	MODCTL1
	  RET
;.....
;
;
; The following is the initialization routine for the Otrona Attache:
;
;      1) the baud rate in CMOS ram is displayed on the CRT with PRTBAUD
;      2) an error in the BIOS of the Attache CP/M is patched to allow
;	  the ^P to toggle the 'write to the printer' in terminal mode.
;
INITMOD:  CALL 	PRTBAUD		;set baud to Attache internal rate
;.....
;
;
; The following is a patch to the BIOS in the attache.  There is an er-
; ror in the BIOS that does not return the status of the list device
; properly.  This patches it for the printer port.  It does not support
; redirected LST:  with IOBYTE thru stat.  Printer must be at the print-
; er port.  The actual patch code is at 'CODE' and is placed in the BIOS
; by this routine.
;
PATCH:    LHLD	000H+1   	;get BIOS warm boot jump vector
	  LXI	D,002AH+1	;offset to LISTST
	  DAD	D		;add offset to vector, H now points to pointer
	  SHLD	ALLEN+1 	;get pointer to LISTST
;
ALLEN:    LHLD	0D000H		;H now has pointer to LISTST
	  XCHG			;move it to D
	  LXI	B,CODE		;point to patch code with B
;
LOOP:	  LDAX	B		;get code
	  ORA	A
	  RZ	   		;return if done
	  STAX	D		;do patching
	  INX	B
	  INX	D
	  JMP	LOOP
;
CODE:	  MVI	A,10H		;this is the patch code
	  OUT	0F3H
	  IN	0F3H
	  ORI	0DBH
	  CPI	0FFH
	  RZ
	  XRA	A
	  RET
	  DB	0		;MARK END
;
;	--- END OF ATTACHE BIOS PATCH ---
;.....
;
;
; Set MSPEED to match attache CMOS ram and print baud
;
PRTBAUD:  CALL	BAUDXS		;print baud and return MSPEED
 	  STA	MSPEED
	  CALL	JMP$ILPRT
	  DB	' baud )',CR,LF,0  ;print remander of message
	  RET
;....
;
;
BAUDXS:	  CALL JMP$ILPRT   	;load baud rate from cmos ram location
	  DB	ESC,'?H',0
	  MVI	C,RDCON
	  CALL 	BDOS		;'A' now has baud rate number
	  ANI	0FH
	  MOV   B,A		;store for later use
	  CALL	JMP$ILPRT
	  DB	CR,'(',0
	  MOV	A,B		;restore 'A'
;
BAUDX1:	  CPI	1
BX1:	  DB	BNZ,BAUDX2-BX1-2 AND 0FFH
	  CALL  JMP$ILPRT
	  DB	'110',0
	  MVI	A,0
	  RET
;
BAUDX2:	  CPI	4
BX2:	  DB	BNZ,BAUDX3-BX2-2 AND 0FFH
	  CALL  JMP$ILPRT
	  DB	'300',0
	  MVI	A,1
	  RET
;
BAUDX3:	  CPI	5
BX3:	  DB	BNZ,BAUDX4-BX3-2 AND 0FFH
	  CALL  JMP$ILPRT
	  DB	'600',0
	  MVI	A,3
	  RET
;
BAUDX4:	  CPI	6
BX4:	  DB	BNZ,BAUDX5-BX4-2 AND 0FFH
	  CALL  JMP$ILPRT
	  DB	'1200',0
	  MVI	A,5
	  RET
;
BAUDX5:	  CPI	7
BX5:	  DB	BNZ,BAUD6-BX5-2 AND 0FFH
	  CALL  JMP$ILPRT
	  DB	'2400',0
	  MVI	A,6
	  RET
;
BAUD6:	  CPI	8
BX6:	  DB	BNZ,BAUD7-BX6-2 AND 0FFH
	  CALL  JMP$ILPRT
	  DB	'4800',0
	  MVI	A,7
	  RET
;
BAUD7:	  CPI   9
BX7:      DB    BNZ,BAUD8-BX7-2 AND 0FFH
          CALL  JMP$ILPRT
          DB    '9600',0
          MVI   A,8
          RET
;
BAUD8:    CPI   0AH
BX8:      DB    BNZ,BAUD9-BX8-2 AND 0FFH
          CALL  JMP$ILPRT
          DB    '19200',0
          MVI   A,9
          RET
;
BAUD9:    LDA	MSPEED		;error...don't change anything
	  RET
;-------------------------------------------------------------------------
;
;
; Setup routine to allow changing modem speed with the SET command.
;
SETUPR:	  LXI	D,BAUDBUF	;point to new input buffer
	  CALL	JMP$ILPRT
	  DB	'Input Baud Rate (110,300,600,1200,2400,4800,9600,19200): ',0
          CALL	JMP$INBUF
	  LXI	D,BAUDBUF+2
	  CALL	GETPOINT	;get pointer in B
	  MOV	A,B
	  CPI	0FFH
;
SET1:	  DB	BNZ,SET2-SET1-2 AND 0FFH  ;jmp if no error
	  CALL	PRTBAUD
	  RET
;
SET2:	  LXI	H,BD110		;get starting address of table
	  DAD	B		;add offset
	  MOV	A,M		;get nibbles from table
;
LOADBD:   ANI	0FH
	  ORI	40H		;make it some resonable value
	  STA 	BAUDOUT2	;write baud into cmos ram
	  CALL	JMP$ILPRT
	  DB	ESC,'@H'
;
BAUDOUT2: DS	1
	  DB	ESC,'<',0	;set comm prot from ram
	  MOV	A,M		;get two nibbles back
	  RAR
	  RAR
	  RAR
	  RAR
	  ANI	0FH
	  STA	MSPEED
	  RET
;.....
;
;
; Subroutine to get Baud table entry number in B
;
GETPOINT: LXI 	B,0		;first entry=0
	  CALL	JMP$INLNCOMP	;Compare BAUDBUF+2 with characters below
	  DB	'110',0
	  RNC			;go if got match
	  INX	B		;first is entry 0
	  CALL	JMP$INLNCOMP
	  DB	'300',0
	  RNC			;go if got match
;
	  INX	B
	  CALL	JMP$INLNCOMP
	  DB	'600',0
	  RNC			;go if got match
;
	  INX	B
	  CALL	JMP$INLNCOMP
	  DB	'1200',0
	  RNC			;go if got match
;
          INX   B
          CALL  JMP$INLNCOMP
          DB    '2400',0
          RNC                   ;go if got match
;
          INX   B
          CALL  JMP$INLNCOMP
          DB    '4800',0
          RNC                   ;go if got match
;
	  INX	B
	  CALL	JMP$INLNCOMP
	  DB	'9600',0
	  RNC			;go if got match
;
	  INX	B
	  CALL	JMP$INLNCOMP
	  DB	'19200',0
	  RNC			;go if got match
;
	  MVI	B,0FFH		;all matches failed
	  RET
;....
;
;
; TABLE OF BAUDRATE PARAMETERS
;
;  TABLE IS 2 NIBBLES...MSPEED (LN) ,ATTACHE RAM VALUE (RN)
;
;
BD110:	  DB	01H
BD300:	  DB	14H
BD600:	  DB	35H	
BD1200:	  DB	56H
BD2400:   DB    67H
BD4800:   DB    78H
BD9600:	  DB	89H
BD19200:  DB    9AH
;
BAUDBUF:  DB	10,0
	  DS	10
;
;.......
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
;
;	
;
;.....
;
   
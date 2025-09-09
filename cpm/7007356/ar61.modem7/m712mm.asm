
; M712MM.ASM -- Morrow Multi-I/O overlay for MDM712      07/27/83
;
; This overlay adapts the MDM712 program to use a Morrow Mult-I/O board
; and an external modem.  The Mult-I/O board supports several users at
; the same port address in a fashion similar to bank selecting main
; memory.  This program includes an initialization routine to select
; the baud rate but does not change the user (group) number which is
; set to group 1.
;
; You could look at other overlay files to see how the GOODBYE and/or
; SETUPR areas are handled.  You could then adapt one of those, if ap-
; propriate for your equipment in this overlay.  Some examples:
;
;     "DP"  Datapoint 1560 overlay using 8251 I/O and CTC timers for
;              setting baud rates
;     "H8"  Heath H89 overlay for 8250 I/O and programmable baud rates
;     "HZ"  Zenith 120 overlay for 2661B initialization and baud rates
;     "XE"  Xerox 820II overlay for Z80-SIO intialization, etc.
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
;		-IMDM712MM.HEX		(note the "I" command)
;		-R			("R" loads in the .HEX file)
;		NEXT  PC
;		4300 0000
;		-G0			(return to CP/M)
;		A>SAVE 66 MDM712.COM	(now have a modified .COM file)
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
; 07/27/83 - Renamed to work with MDM712	- Irv Hoff
; 07/07/83 - Adapted for Morrow Multi-I/O	- G. Smith
; 07/01/83 - Revised to work with MDM711	- Irv Hoff
; 07/01/83 - Revised to work with MDM710	- Irv Hoff
; 05/27/83 - Updated to work with MDM709	- Irv Hoff
; 05/15/83 - Revised to work with MDM708	- Irv Hoff
; 04/11/83 - Updated to work with MDM707	- Irv Hoff
; 04/04/83 - First version of this file		- Irv Hoff
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
BELL:		EQU	07H		;bell
CR:		EQU	0DH		;carriage return
ESC:		EQU	1BH		;escape
LF:		EQU	0AH		;linefeed
TAB:		EQU	09H		;tab
BDOS:		EQU	0005H
;
YES:		EQU	0FFH
NO:		EQU	0
;
;
; Change the following information to match your equipment
;
BASE:		EQU	0F0H		;Base address for Mult-I/O board
GROUP:		EQU	1		;Group selection code
GRP$CTL:	EQU	BASE+7		;Group selection port address
DLL:		EQU	BASE		;ACE baud rate divisor (LSB)
DLM:		EQU	BASE+1		;ACE baud rate divisor (MSB)
IER:		EQU	BASE+1		;ACE interrupt enable register
LCR:		EQU	BASE+3		;ACE line control register
LSR:		EQU	BASE+5		;ACE line status register
RBR:		EQU	BASE		;ACE receive buffer register
THR:		EQU	BASE		;ACE transmit hold register
DLAB:		EQU	80H		;Divisor latch access bit
THRE:		EQU	20H		;MODSNDB
DR:		EQU	1		;MODRCVB
WLS0:		EQU	1		;Word length select bit 0
WLS1:		EQU	2		;word length select bit 1
STB:		EQU	4		;stop bit count (2 stops)
IMASK:		EQU	0		;Interrupt mask -- disable all
;
MODDCDB:	EQU	4		;CARRIER DETECT BIT
MODDCDA:	EQU	0		;VALUE WHEN ACTIVE
MODRCVB:	EQU	1		;BIT TO TEST FOR RECEIVE
MODRCVR:	EQU	1		;VALUE WHEN READY
MODSNDB:	EQU	20H		;BIT TO TEST FOR SEND
MODSNDR:	EQU	20H		;VALUE WHEN READY
;
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
SAVCCP:		DB	NO	;no=do not save CCP			116H
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
BRKCHR:		DB	'@'-40H	;^@ = Send 300 ms. break tone		120H
NOCONNCT:	DB	'N'-40H	;^N = Disconnect from the phone line	121H
LOGCHR:		DB	'L'-40H	;^O = Send logon			122H
LSTCHR:		DB	'P'-40H	;^P = Toggle printer			123H
UNSAVE:		DB	'R'-40H	;^R = Close input text buffer		124H
TRANCHR:	DB	'T'-40H ;^T = Transmit file to remote		125H
SAVECHR:	DB	'Y'-40H	;^Y = Open input text buffer		126H
EXTCHR: 	DB	'^'-00H ; ^ = Send next character		127H
;
;
		DS	2		;				128H
;
;
IN$MODCTL1:	CALL	MOD$SEL 	;in modem control port		12AH
		IN	LSR
		RET
;.....
;
;
		DS	4
;
OUT$MODDATP:	PUSH	PSW		;out modem data port		134H
		CALL	MOD$SEL
		POP	PSW
		OUT	THR
		RET
;.....
;
;
		DS	2
;
IN$MODDATP:	CALL	MOD$SEL 	;in modem data port		13EH
		IN	RBR
		RET
;.....
;
;
		DS	4
;
ANI$MODRCVB:	ANI	MODRCVB	! RET	;bit to test for receive ready	148H

CPI$MODRCVR:	CPI	MODRCVR	! RET	;value of rcv. bit when ready	14BH
ANI$MODSNDB:	ANI	MODSNDB	! RET	;bit to test for send ready	14EH
CPI$MODSNDR:	CPI	MODSNDR	! RET	;value of send bit when ready	151H
		DS	6		;				156H
;
OUT$MODCTL1:	RET !	NOP !	NOP	;out modem control port #2	15AH
OUT$MODCTL2:	RET !	NOP !	NOP	;out modem control port #1	15DH
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
		DB	16,0,0,0,0	;Vector MT code for CLREOS	198H
		RET			;				19DH
;
CLRSCRN:	CALL	JMP$ILPRT	;				19EH
		DB	4,0,0,0,0	;Vector MT code for CLRSCRN	1A1H
		RET			;				1A6H
	
;
SYSVER:		CALL	JMP$ILPRT	;				1A7H
		DB	'Computer with Morrow MIO board -- User #1'
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
LOGON:		DB	'How are you today?',CR,LF,0
;.....
;
;
; Add your own routine here to send a break tone to reset some time-share
; computers, if desired.
;
SENDBRK:	RET
;.....
;
;
; Add your own routine here to put DTR low and/or send a break tone.
; Check other routines such as MDM709DP.ASM which is using this feature.
;
GOODBYE:	RET
;.....
;
;
; You can use this area for any special initialization or setup you may
; wish to include.  Each must stop with a RET.  You can check the other
; available overlays for ideas how to write your own routines if that
; may be of some help.
;
INITMOD:  LXI	D,BAUD$MSG	;Point to baud selection message
	  MVI	C,9		;BDOS print string cmd
	  CALL	BDOS		;Use BDOS to print baud message
	  LXI	D,BAUD$BUF	;point to 1 char input buffer
	  MVI	C,10		;BDOS cmd to fill buffer from CON:
	  CALL	BDOS
	  LDA	CHOICE		;Get the character from the buffer
	  SUI	31H		;Subtract ASCII bias
	  JC	INITMOD 	;Input must be > zero
	  CPI	4		;And less than 4
	  JNC	INITMOD 	;Now we have 0,1,2,or3 in 'A' Register.
	  RLC			;Mult by 2 for table offset
	  STA	CHOICE		;save for later
	  MVI	A,GROUP 	;select group (user) number
	  OUT	GRP$CTL
	  MVI	A,DLAB		;Set data latch access bit
	  OUT	LCR
	  LDA	CHOICE		;get back offset into baud table
	  LXI	H,INITBLE	;point to table base
	  ADD	L		;add offset
	  MOV	L,A
	  MOV	A,M		;get low order byte for baud rate
	  OUT	DLL
	  INX	H		;point to next table entry
	  MOV	A,M		;and send it to baud register
	  OUT	DLM
	  MVI	A,WLS0+WLS1+STB ;8 bit data word & 2 stop bits
	  OUT	LCR
	  IN	RBR		;clear flags
	  MVI	A,IMASK 	;set interrupt status (all disabled)
	  OUT	IER
	  RET
;.....
;
;
SETUPR:	  RET
;.....
;
;
MOD$SEL:  MVI	A,GROUP 	;Group select code
	  OUT	GRP$CTL 	;Group select register
	  MVI	A,WLS0+WLS1+STB ;make sure DLAB is clear
	  OUT	LCR
	  RET
;.....
;
;
; If using the Hayes Smartmodem this is unavailable without a special
; change.
;
SPCLMENU: RET
;
;
BAUD$MSG: DB	CR,LF,TAB,'SELECT BAUD RATE (MIO user 1)'
	  DB	CR,LF,TAB,TAB,'1. 300'
	  DB	CR,LF,TAB,TAB,'2. 1200'
	  DB	CR,LF,TAB,TAB,'3. 4800'
	  DB	CR,LF,TAB,TAB,'4. 9600','$'
;
BAUD$BUF: DB	01,00
CHOICE:   DB	00
;.....
;
;
; The initialization table is nothing more than a list of bytes to
; be send to the baud rate registers, in the same order as the choices
; in the baud message above.  Note the MSB,LSB order within each entry.
;
INITBLE:  DB	80H,01		;300 baud divisor = 0180H
	  DB	60H,0		;1200 baud divisor = 0C0H
	  DB	18H,0		;4800 baud divisor = 018H
	  DB	0CH,0		;9600 baud divisor = 00CH
;.....
;
;
; NOTE:  MUST TERMINATE PRIOR TO 0400H (with Smartmodem)
;				 0C00H (without Smartmodem)
;.....
;
	  END
;


; M712VT.ASM -- DEC VT180 overlay file for MDM712.  08/09/83
;
;			W A R N I N G
;			_ _ _ _ _ _ _
; 
; The routine that returns the reader status is VERY system dependent.
; Two addresses must be used in this routine.  The first is P232STI
; which can return the status of any of the VT180's four physical de-
; vices.  To find this address, consult your BIOS listing for an approx-
; imation of where this routine should be.  Then use DDT to find the
; actual address.  For example:  On my system these addresses differed
; by nine bytes.
;
; The second system dependent address is listed in the BIOS as T@PTRCB.
; It is the Paper Tape Reader Port Control Block.  P232STI works by
; loading the Z80's IX register with the address of the appropriate port
; control block and then jumping to the status routine.  The routine
; then returns the status in the accumulator.
;
; For modem I/O I used the BDOS.  I could have as easily used the same
; proceedure as above to communicate to the ports, but I wanted to keep
; system dependence to a minimum.  I would like to commend the author of
; the BIOS for a nice job of coding.  It's too bad few people will ever
; appreciate how nicely the I/O was handled.
;					- Michael Gwilliam
;
;***********************************************************************
;
; You will want to look this file over carefully. There are a number of
; options that you can use to configure the program to suit your taste.
; This file places particular emphasis on using an external modem that
; does not match one of the other special overlays.  You would use the
; normal CP/M "Configure" program to set the modem to whatever baud rate
; you would normally use (such as 300 or 1200, etc.)  Then perhaps just
; make a second .COM file if you need both 300 and 1200 and do not wish
; to write your own initialization or "set baud" routine.
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
;		-IM712VT.HEX		(note the "I" command)
;		-R			("R" loads in the .HEX file)
;		NEXT  PC
;		4300 0000
;		-G0			(return to CP/M)
;		A>SAVE 66 MDM712.COM	(now have a modified .COM file)
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
; 08/09/83 - Revised to work with a VT180	- Michael Gwilliam
; 07/27/83 - Renamed to work with MDM712	- Irv Hoff
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
;
YES:		EQU	0FFH
NO:		EQU	0
;
;
; Change the following information to match your equipment
;	NOTE: These routines are patched in order to use the BIOS
;
BDOS:		EQU	0005		;address of BDOS entry
PUNCH:		EQU	4		;punch function
READER:		EQU	3		;reader function
MODDCDB:	EQU	4		;carrier detect bit
MODDCDA:	EQU	0		;value when active
MODRCVB:	EQU	0FFH		;bit to test for recedive
MODRCVR:	EQU	0FFH		;value when ready
MODSNDB:	EQU	0FFH		;bit to test for send
MODSNDR:	EQU	0FFH		;value when ready
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
BADDLF:		DB	NO	;no=no LF after CR to send file in	113H
				;terminal mode (added by remote echo)
TOGGLELF:	DB	YES	;yes=allow toggling of LF after CR	114H
TRANLOGON:	DB	YES	;yes=allow transmission of logon	115H
				;write logon sequence at location LOGON
SAVCCP:		DB	NO	;yes=do not overwrite CCP		116H
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
		DS	6		;Together these do nothing	156H
;
OUT$MODCTL1:	RET ! NOP ! NOP		;out modem control port #2	15AH
OUT$MODCTL2:	RET ! NOP ! NOP		;out modem control port #1	15DH
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
SYSVER:		CALL	JMP$ILPRT	;				1A7H
		DB	'Version for DEC VT180 and external modem'
		DB	CR,LF,0
		RET
;.....
;
;
; Modem I/O primative unique to the VT180 
;
; Subroutine to output a character to the modem.
; This routine does it's own status checking.
;
OUTDATA:  PUSH	B		;save...
	  PUSH	D		;...the...
	  PUSH	H		;...registers.
	  MOV	E,A		;move output byte into E
	  MVI	C,PUNCH		;use the BDOS function
	  CALL	BDOS		;go
	  POP	H		;restore...  
	  POP	D		;...the...
	  POP	B		;...registers.
	  RET
;.....
;
;
; Subroutine to input a character from the modem.
; This routine will wait until one becomes available.
;
INDATA:	  PUSH	B		;save...
	  PUSH	D		;...the...
	  PUSH	H		;...regesters.
	  MVI	C,READER	;use the BDOS function
	  CALL	BDOS		;go
	  POP	H		;restore...
	  POP	D		;...the...
	  POP	B		;...registers.
	  RET
;.....
;
;
; This routine does returns the status of the reader port.
;	A=0 if no character ready.
;	A=FF if one or more characters are ready.
;CAUTION************
;	1) THIS ROUTINE CONTAIN PSEUDO Z80 INSTRUCTIONS
;	2) THE ADDRESSES HERE ARE *VERY* SYSTEM DEPENDENT
;		Consult your BIOS listing and then double-
;		check the addresses using the DDT.
;
PTRPCB:	  EQU	0F53FH		;PTR: port control block.
P232STI:  EQU	0F4D9H		;input status routine
;
INCTL:	  PUSH	B		;save...
	  PUSH	D		;...the...
	  PUSH	H		;...registers.
	;LD IX,PTRPCB		;Z80 neumonic
	  DB	0DDH,021H
	  DW	PTRPCB
	  CALL	P232STI
	  POP	H		;restore...  
	  POP	D		;...the...
	  POP	B		;...registers.
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
LOGON:	  DB	'How are you today?',CR,LF,0
;.....
;
;
; Add your own routine here to send a break tone to reset some time-share
; computers, if desired.
;
SENDBRK:  RET
;.....
;
;
; Add your own routine here to put DTR low and/or send a break tone.
; Check other routines such as MDM709DP.ASM which is using this feature.
;
GOODBYE:  RET
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
SPCLMENU: RET
;
;
; NOTE:  MUST TERMINATE PRIOR TO 0400H (with Smartmodem)
;				 0C00H (without Smartmodem)
;.....
;
	  END
;

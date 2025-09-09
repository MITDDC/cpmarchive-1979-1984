
; M712PM.ASM -- PMMI overlay file for MDM712.  07/27/83
;
; You will want to look this file over carefully. There are a number of
; options that you can use to configure the program to suit your taste.
; This file places particular emphasis on using PMMI S-100 modem board.
; Much of the information contained here is not in the main file.
;
; Edit this file for your preferences then follow the "TO USE:" example
; shown below.
;
; PMMI users should set PULSERATE to its proper value.
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
;		-IM712PM.HEX		(note the "I" command)
;		-R			("R" loads in the .HEX file)
;		NEXT  PC
;		4300 0000
;		-G0			(return to CP/M)
;		A>SAVE 66 MDM712.COM	(now have a modified .COM file)
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
; 07/27/83 - Renamed to work with MDM712	- Irv Hoff
; 07/01/83 - Updated to work with MDM711	- Irv Hoff
; 06/22/83 - Revised to work with MDM710	- Irv Hoff
; 05/25/83 - Revised to work with MDM709	- Irv Hoff
; 05/15/83 - Revised to work with MDM708	- Irv Hoff
; 04/11/83 - Updated to work with MDM707	- Irv Hoff
; 04/04/83 - Updated to work with MDM706	- Irv Hoff
; 02/27/83 - Updated to work with MDM705	- Irv Hoff
; 02/17/83 - Updated to work with MDM704	- Irv Hoff
; 02/07/83 - Updated to work with MDM703	- Irv Hoff
; 01/27/83 - Updated to work with MDM702	- Irv Hoff
; 01/10/83 - Updated to work with MDM701	- Irv Hoff
; 10/03/82 - First version of this file		- Irv Hoff
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
; IF YOU HAVE A PMMI YOU MAY NEED TO CHANGE THE BASE ADDRESS.
;
PORT:		EQU	0C0H		;PMMI BASE ADDRESS (OFTEN 0C0H)
MODCTL1:	EQU	PORT		;MODEM CONTROL PORT
MODDATP:	EQU	PORT+1		;MODEM DATA PORT
BAUDRP:		EQU	PORT+2		;MODEM BAUD RATE PORT
MODCTL2:	EQU	PORT+3		;MODEM STATUS PORT
;
;
; CLOCK SHOULD BE CHANGED TO SUIT YOUR SYSTEM.  (PMMI USERS SHOULD ALSO
; CHANGE PULSERATE AS NECESSARY)
;
;
		ORG	100H
;
		DS	3	;(for  "JMP   START" instruction)
;
PMMIMODEM:	DB	YES	;yes=PMMI S-100 Modem			103H
SMARTMODEM:	DB	NO	;yes=HAYES Smartmodem, no=non-Hayes	104H
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
SAVCCP:		DB	YES	;yes=do not overwrite CCP		116H
LOCONEXTCHR:	DB	NO	;yes=local command if EXTCHR precedes	117H
				;no=external command if EXTCHR precedes
TOGGLELOC:	DB	YES	;yes=allow toggling of LOCONEXTCHR	118H
LSTTST:		DB	YES	;yes=allow toggling of printer on/off	119H
XOFFTST:	DB	NO	;yes=checks for XOFF from remote while	11AH
				;sending a file in terminal mode
XONWAIT:	DB	NO	;yes=wait for XON after CR while	11BH
				;sending a file in terminal mode
TOGXOFF:	DB	YES	;yes=allow toggling of XOFF checking	11CH
IGNORCTL:	DB	YES	;yes=CTL-chars above ^M not displayed	11DH
EXTRA1:		DB	0	;for future expansion			11EH
EXTRA2:		DB	0	;for future expansion			11FH
BRKCHR:		DB	'@'-40H	;^@ = Send a 300 ms. break tone		120H
NOCONNECT:	DB	'N'-40H	;^N = Disconnect from the phone line	121H
LOGCHR:		DB	'L'-40H	;^L = Send logon			122H
LSTCHR:		DB	'P'-40H	;^P = Toggle printer			123H
UNSAVE:		DB	'R'-40H	;^R = Close input text buffer		124H
TRANCHR:	DB	'T'-40H ;^T = Transmit file to remote		125H
SAVECHR:	DB	'Y'-40H	;^Y = Open input text buffer		126H
EXTCHR:		DB	'^'-40H	;^^ = Send next character		127H
;
;
; Equates used only by PMMI routines grouped together here
;
PULSERATE:	DB	125	;125 for 20pps, 250 for 10pps on PMMI	128H
CHGBAUD:	DB	'B'-40H	;^B = Used with PMMI in terminal	129H
				;mode to change baud rate on fly
;
; (End of special PMMI routines)
;
;
IN$MODCTL1:	IN	MODCTL1 ! RET	;in modem control port	     	12AH
		DB	0,0,0,0,0,0,0	;spares if needed for non-PMMI	12DH
OUT$MODDATP:	OUT	MODDATP ! RET	;out modem data port		134H
		DB	0,0,0,0,0,0,0	;spares if needed for non-PMMI	137H
IN$MODDATP:	IN	MODDATP ! RET	;in modem data port		13EH
		DB	0,0,0,0,0,0,0	;spares if needed for non-PMMI	141H
;
		DS	12	;not changed				148H
IN$BAUDRP:	IN	BAUDRP	! RET	;in baudrate port		154H
OUT$BAUDRP:	OUT	BAUDRP	! RET	;out baudrate port		157H
OUT$MODCTL1:	OUT	MODCTL1	! RET	;out modem control port #2	15AH
OUT$MODCTL2:	OUT	MODCTL2	! RET	;out modem control port		15DH
;
;
LOGONPTR:	DW	LOGON		;for user message.		160H
		DS	30		;				162H
JMP$SPARE1:	DB	0,0,0		;				180H
;
;
; Do not change the following line as it goes to a specific location in
; the program.	
;
JMP$ILPRT:	DS	3		;				186H
;
		DS	15		;				189H

; Clear sequences -- CLREOS -- use appropriate values for your CRT then
; set SCRNTEST to YES.
;
CLREOS:		CALL	JMP$ILPRT	;				195H
		DB	0,0,0,0,0	;				198H
		RET			;				19DH
;
CLRSCRN:	CALL	JMP$ILPRT	;				19EH
		DB	0,0,0,0,0	;				1A1H
		RET			;				1A6H
;
		DS	72		;(by-pass sign-on message)	1A4H
	
;
;
;=======================================================================
;
; You can put in a message at this location which can be called up with
; CTL-O if TRANLOGON has been set YES.  You can use up to 93 bytes if
; desired.  End with a 0.  The final character must stop by 024CH.
;
LOGON:		DB	'Hello from a PMMI user',CR,LF,0
;
;.....
;
		END
;

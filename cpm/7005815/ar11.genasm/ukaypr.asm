;
;	UKAYPRO.ASM ver 1.0 as of 9/18/82
;	   by Dave Hardy
;	   From Keith Petersen's UPMMI.ASM
;
;This is the user area for BSTAM version 4.3 as used with
; the serial port on a KAYPRO via an external modem.
;
;	If you wish to use other registers such as HL,BC,DE
;	(not including SP register), be sure to push BSTAM's
;	registers onto the stack and pop them back off before
;	returning to BSTAM.  There is ample room to push all
;	registers onto BSTAM's stack, plus room for 10 levels
;	of CALLs.
;
;	There are 300 bytes of user space available to you.
;
;	THE JUMP'S CODED AT THE BEGINNING OF THIS PROGRAM
;	CANNOT BE MOVED IN ANY WAY.
;
;  Define ports and masks
KPSTAT	EQU	06H	;KayPro UART Status port
KPDATA	EQU	04H	;KayPro UART Data port
KPTBE	EQU	04H	;KayPro Transmit Buffer Empty bit in UART
KPRDA	EQU	01H	;KayPro Received Data Available bit in UART
;
;  Define ASCII characters used
CR	EQU	0DH	;Carriage Return
LF	EQU	0AH	;Linefeed
;
BEGIN:	ORG	103H
;
INITIL	JMP	INITIU	;UART/USART Initialization entry point
INSPORT JMP	INSPRU	;Status port read entry point
ERRSET	JMP	ERRSTU	;UART/USART error reset entry point
INPORT	JMP	INPRTU	;Read data port entry point
OUTPORT JMP	OUTPRU	;Write data port entry point
;
;
;	This is the UART/USART Initialization routine.
;	To be compatible with most BSTAM users, use the
;	following Initialization Guide Lines:
;	1. USE 1 STOP BIT	(OPTIONAL - 2)
;	2. USE 8 DATA BITS	(MUST)
;	3. USE 1 START BIT	(MUST)
;	4. USE 16X FOR CLOCK RATE	(MUST)
;	5. USE ASYNCHRONOUS MODE ONLY	(MUST)
;
;  NO INITIALIZATION IS DONE IN THIS VERSION OF UKAYPRO
INITIU: CALL	SIGNON	;Tell version number to user
	RET		;Return to BSTAM
;
;
;	This is the STATUS READ PORT routine.
;	When exiting this routine, BSTAM expects in register A
;	the following BITS to be set IF NEEDED:
;	1. 20 BIT SET IF FRAMING ERROR
;	2. 10 BIT SET IF OVERRUN ERROR
;	3. 08 BIT SET IF PARITY  ERROR
;	4. 04 BIT SET IF TRANSMITTER EMPTY (TEOC)
;	5. 02 BIT SET IF RECEIVER READY (DAV)
;	6. 01 BIT SET IF TRANSMITTER READY (TBMT)
;	7. DO NOT SET THE 80 BIT OR 40 BIT
;
;	Now get UART status for BSTAM.
;	In this case, we discard all error test bits
INSPRU:	PUSH	B
	MVI	C,0	;Init all flags
	IN	KPSTAT	;Get Serial UART status
	MOV	B,A	;Save it in B
	ANI	01H
	CNZ	SETRDA	;Set RDA bit
	MOV	A,B
	ANI	04H
	CNZ	SETTBE
	MOV	A,C	;Get flags into A
	POP	B
	RET
;
SETRDA	MVI	C,02H	;Set RDA flag
	RET
;
SETTBE	MOV	A,C
	ORI	05H	;Set TBE and TEOC flags
	MOV	C,A
	RET
;
;	This is the ERROR RESET FOR UART/USART routine.
;	No resetting is done in this version
ERRSTU: RET		;Return to BSTAM
;
;
;	This is the READ DATA PORT routine.
;	Before this routine is entered, the 02 BIT of
;	the STATUS READ routine MUST HAVE BEEN SET.
;	Do NOT clear the 80 BIT from the DATA INPUT port.
;	Return with REGISTER A loaded with input data.
;
INPRTU: IN	KPDATA	;Get data from port
	RET		;Return to BSTAM
;
;
;	This is the WRITE DATA PORT routine.
;	Before this routine is entered, the 04 BIT and 01 BIT
;	of STATUS READ MUST BE SET.
;	Do NOT clear the 80 BIT from the data output port.
;	REGISTER A contains the output data.
;
OUTPRU: OUT	KPDATA	;Send data to remote CPU
	RET		;Return to BSTAM
;
;
;  The SIGN-ON routine called from the INIT routines.
SIGNON:	PUSH	B
	PUSH	D
	PUSH	H
	LXI	D,MESSGE
	MVI	C,9
	CALL	5		 ;ANNOUNCE VERSION TO USER
	POP	H
	POP	D
	POP	B
	RET
;
MESSGE: DB	CR,LF,CR,LF
	DB	'KayPro serial port ver 1.0 - no initialization done,'
	DB	CR,LF,'$'
;
	END	BEGIN

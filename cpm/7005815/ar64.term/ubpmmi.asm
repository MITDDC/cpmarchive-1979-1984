;	UBPMMI.ASM ver 1.1 as of 3/24/81
;	   by Keith Petersen, W8SDZ
;
;This is the user area for BSTMS version 1.2
;for use with a PMMI MM-103 modem.
;
;If you wish to use other registers such as HL,BC,DE
;(not including  SP  register) be sure to push BSTMS'S
;registers on to stack and pop them back off before
;returning to BSTMS.  There is ample room to push all
;registers onto BSTMS's stack, plus room for 10 levels
;of calls.
;
;There are 300 bytes of user space available to you.
;
;The jumps coded at the beginning of this program
;cannot be moved in any way.
;
;Define ports
;
PMCTL1	EQU	0C0H	;PMMI UART STATUS PORT
PMDATA	EQU	PMCTL1+1 ;PMMI UART DATA PORT
PMMDMS	EQU	PMCTL1+2 ;PMMI MODEM CHIP STATUS PORT
PMCTL2	EQU	PMCTL1+3 ;PMMI MODEM CHIP CONTROL PORT
;
;Conditional assembly switch
;
FASTCLK	EQU	1	;0 = 2 MHZ, 1 = 4 MHZ SYSTEM CLOCK
;
;Define ASCII characters used
;
CR	EQU	0DH	;CARRIAGE RETURN
LF	EQU	0AH	;LINE FEED
;
BEGIN:	ORG	103H
;
INITIL	JMP	INITIU	;UART/USART INITIALIZATION ENTRY POINT
INSPORT	JMP	INSPRU	;STATUS PORT READ ENTRY POINT
ERRSET	JMP	ERRSTU	;UART/USART ERROR RESET ENTRY POINT
INPORT	JMP	INPRTU	;READ DATA PORT ENTRY POINT
OUTPORT	JMP	OUTPRU	;WRITE DATA PORT ENTRY POINT
;
;
;This is the UART/USART initialization routine.
;To be compatible with most BSTMS users use following
;initialization guide lines:
;	1. Use 1 stop bit		(optional - 2)
;	2. Use 8 data bits		(must)
;	3. Use 1 start bit		(must)
;	4. Use 16X for clock rate 	(must)
;	5. Use asynchronous mode only	(must)
;
;We will not initialize the PMMI modem.  That can be done
;with other programs like MODEM or DIAL.
;
INITIU:	CALL	SIGNON	;TELL USER WHAT'S IMPLEMENTED
	IN	PMDATA	;CLEAR INPUT PORT
	IN	PMDATA	;AGAIN TO MAKE SURE
	RET		;RETURN TO BSTMS
;
;This is the status read port routine.
;When exiting this routine BSTMS expects in register A
;the following bits to be set if needed:
;	1. 20 bit set if framing error
;	2. 10 bit set if overrun error
;	3. 08 bit set if parity  error
;	4. 04 bit set if transmitter empty (TEOC)
;	5. 02 bit set if receiver ready (DAV)
;	6. 01 bit set if transmitter ready (TBMT)
;	7. Do not set the 80 bit or 40 bit
;
;Before we do the UART status check we will check
;to see if carrier is lost.
;
INSPRU:	PUSH	B	;SAVE REGISTERS USED
	PUSH	D
;
	IF	NOT FASTCLK ;FOR 2MHZ SYSTEM CLOCK
	MVI	B,15	;WAIT UP TO 15 SECONDS
	ENDIF
;
	IF	FASTCLK	;FOR 4MHZ SYSTEM CLOCK
	MVI	B,30	;WAIT UP TO 15 SECONDS
	ENDIF
;
;One second time delay routine. Enter with desired
;number of seconds in B register.
;
ONESEC:	LXI	D,50000 ;VALUE FOR 2 MHZ CLOCK
;
TLOOP:	IN	PMMDMS	;GET MODEM CHIP STATUS
	ANI	04H	;GET CTS (CARRIER DETECT) BIT
TLPAT:	JZ	CARROK	;CARRIER NOT LOST, EXIT AND RETURN
	DCR	E	;DECREMENT TIME DELAY VALUE
	JNZ	TLOOP	;NOT DONE, DO ANOTHER LOOP
	DCR	D	;DECREMENT TIME DELAY VALUE
	JNZ	TLOOP	;NOT DONE, DO ANOTHER LOOP
	DCR	B	;DECREMENT NUMBER OF SECONDS
	JNZ	ONESEC	;NOT DONE, DO ANOTHER ONE SEC DELAY
;
;If we get to here, we have lost carrier for 15 seconds
;
	XRA	A
	OUT	PMCTL1	;CAUSE MODEM TO...
	OUT	PMCTL2	;...HANG UP
	LXI	D,LSTMSG ;POINT TO MESSAGE
	MVI	C,9
	CALL	5	;PRINT IT
	MVI	A,(JMP)	;GET OPCODE FOR JMP
	STA	TLPAT	;SET BYPASS OF CARRIER CHECK
	IN	PMDATA	;CLEAR INPUT PORT
	IN	PMDATA	;AGAIN TO MAKE SURE
	JMP	CARROK	;EXIT
;
LSTMSG:	DB	CR,LF,'    ++CARRIER LOST++'
	DB	CR,LF,'The modem is now DISCONNECTED'
	DB	CR,LF,'$'
;
;Carrier is not lost
;
CARROK:	POP	D	;RESTORE DE REGS
	POP	B
;
;Get UART status for BSTMS.  In this case we discard all error
;test bits because the PMMI modem has no way to reset the error
;flags once they are up, causing a continuous display of error
;messages in BSTMS.
;
	IN	PMCTL1	;GET PMMI UART STATUS
	ANI	07H	;STRIP ALL BUT TEOC, DAV AND TBMT BITS
	RET
;
;This is the error reset for UART/USART routine.
;The PMMI modem has no way to reset the error flags,
;so we clear the input port and return.
;
ERRSTU:	IN	PMDATA	;CLEAR INPUT PORT
	IN	PMDATA	;AGAIN TO MAKE SURE
	RET		;RETURN TO BSTMS
;
;This is the read data port routine.
;
INPRTU:	IN	PMDATA	;GET DATA FROM PORT
	ANI	7FH	;STRIP PARITY BIT
	RET		;RETURN TO BSTMS
;
;This is the write data port routine.
;
OUTPRU:	ANI	7FH	;STRIP PARITY BIT
	OUT	PMDATA	;SEND DATA TO REMOTE CPU
	RET		;RETURN TO BSTMS
;
SIGNON:	PUSH	B
	PUSH	D
	PUSH	H
	LXI	D,MESSGE
	MVI	C,9
	CALL	5		;ANNOUNCE VERSION TO USER
	POP	H
	POP	D
	POP	B
	RET
;
MESSGE:	DB	CR,LF,CR,LF
	DB	'PMMI Modem ver 1.1 - no initialization done,'
	DB	' tests for loss of carrier.'
	DB	CR,LF,'$'
;
	END

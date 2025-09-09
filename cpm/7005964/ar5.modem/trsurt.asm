;
;	INITUART.ASM
;
;Program for initiating the TRS-80 Model I UART
;(RS232C board) so that MODEM, MBOOT, MTN etc will
;work properly. You can include this in MODEM or
;MBOOT if you wish.
;
MRSPT	EQU	0E8H	;master reset port
BDRTPT	EQU	0E9H	;baud rate port
CTRLPT	EQU	0EAH	;UART control port
;
BD300	EQU	055H	;300 baud
CTWD	EQU	06DH	;8 bit word, 1 stop bit
			;no parity, set DTR
;
;The next three lines are only for information.
DTPT	EQU	0EBH	;data port
RCVMSK	EQU	O80H	;receive status mask
TRNMSK	EQU	040H	;transmit status mask
;
	ORG	04300H	;start of TPA
;
	OUT	MRSPT	;reset UART, doesn't matter
			;what is in A
	MVI	A,BD300
	OUT	BDRTPT	;set baud rate at 300
	MVI	A,CTWD
	OUT	CTRLPT	;set control port
	JMP	04200H	;do a warm boot
;
	END

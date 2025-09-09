;
;			PIPMODEM.ASM
;
;10/29/82  Written by P. L. Kelley
;
;Carefully read the file PIPMODEM.DOC for further information on the
;use of this file.
;
;The following four equates will probably be the only changes that need
;to be made. Currently set up for Heath H89.
MDAT	EQU	0D8H	;MODEM PORT FOR SENDING AND RECEIVING DATA
MSTAT	EQU	0DDH	;MODEM STATUS PORT
RCV	EQU	1	;STATUS PORT BIT TO TEST FOR A CHARACTER WAITING
RCVT	EQU	RCV	;THE OTHER POSSIBILITY FOR THIS IS 0
;
OLDSTRT	EQU	04CEH	;PIP's normal start
CTLO	EQU	0FH	;Control-O to open memory buffer
CTLZ	EQU	1AH	;Control-Z to write the file to disk
NOPAR	EQU	7FH	;no parity mask
;
	ORG	100H
;
	JMP	NEWSTRT	;go put BIOS vectors in the right places
	JMP	KSTAT	;go run the modem routine
	DS	3	;skip over the OUT: vector
BYTE	DB	0	;this is where the byte for the memory buffer goes
KSTAT	CALL	$-$	;get the status of the keyboard
	ORA	A	;A will be zero if you have not typed a key
	JZ	MODIN	;if no keypress check the modem for input
KEYIN	CALL	$-$	;OK, there is a keypress, go get it
	CPI	CTLO	;do you want to open the buffer?
	JNZ	NOO	;go if you do not
	STA	OFLAG	;save flag if you want buffer open
	JMP	KSTAT	;don't output control-O
NOO	CPI	CTLZ	;end of file?
	JNZ	MODOUT	;no, then output character
	STA	BYTE	;tells PIP to write the memory buffer to disk file
	RET		;and PIP will go do it
MODOUT	OUT	MDAT	;send the character to the remote
MODIN	IN	MSTAT	;get the modem status
	ANI	RCV	;mask off all but the receive bit
	CPI	RCVT	;test the receive bit
	JNZ	KSTAT	;go if nothing received
	IN	MDAT	;OK, there is modem input, go get it
	ANI	NOPAR	;mask off parity
	STA	BYTE	;save for possible entry into file buffer
	MOV	C,A	;the BIOS display routine wants the character in C
CONOUT	CALL	$-$	;display input
	LDA	OFLAG	;check whether input should be in memory buffer
	ORA	A	;zero flag will be reset if character goes in buffer
	JZ	KSTAT	;go if the character does not go in buffer
	RET		;PIP will put character in buffer and call 103H again
OFLAG	DB	0	;flag for memory buffer open
NEWSTRT	LHLD	1	;get wboote to determine BIOS vectors
	LXI	D,3	;load DE with 3
	DAD	D	;put console status vector in HL
	SHLD	KSTAT+1		;store
	DAD	D	;put console input vector in HL
	SHLD	KEYIN+1		;store
	DAD	D	;put console output vector in HL
	SHLD	CONOUT+1	;store
	JMP	OLDSTRT		;go to normal PIP start
	END

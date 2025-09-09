;
; TITLE		RELOCATION TABLE BUILDER
; FILENAME	REL.ASM
; AUTHOR	Robert A. Van Valzah  7/23/78
; LAST REVISOR	R. A. V.   12/24/79
; REASON	revised spelling of signon
;
;
vers	equ	6	;version number
;
BDOS	EQU	5
;
	maclib	utl	;get utl interface macro library
;
	utl	setadrs,setlen,help
;
setadrs:
	MOV	H,B	;GET PARAMETER 1 INTO REG HL
	MOV	L,C
	SHLD	CODE1	;SAVE IT AS CODE IMAGE 1 POINTER
	XCHG		;GET PARM. 2 INTO HL
	SHLD	CODE2	;SAVE IT AS CODE IMAGE 2 POINTER
	lxi	d,ackmsg ;send acknowledge message
	mov	a,c	;see if code 0 is on 8 byte boundry
	ani	7
	jz	smsg	;yes - send ack message
	lxi	d,nakmsg ;send error message
smsg:
	call	prmsg
	RET
nakmsg:
	db	13, 10, 'Code must be on 8 byte boundry.'
	db	0
ackmsg:
	db	13, 10, 'Code addresses recieved.'
	db	0
;
setlen:
	PUSH	D	;PUSH PARM. 2 (REL TBL ADR)
	LHLD	CODE2	;CODE IMAGE 2 POINTER INTO DE
	XCHG
	LHLD	CODE1	;CODE IMAGE 1 POINTER IN HL
	mov	a,c	;make sure len is multiple of 8
	ani	7
	jz	comp	;length is ok
	lxi	d,lenmsg ;print error message
	call	prmsg
	pop	d	;clean up stack before returning
	ret
lenmsg:
	db	13, 10, 'Length must be a multiple of 8.'
	db	0
;
COMP:
	LDAX	D	;GET A BYTE FROM IMAGE 2
	sub	M	;COMPARE TO SAME BYTE IN IMAGE 1
	JNZ	SETBIT	;IF NOT EQUAL, SET REL BIT
	ORA	A	;EQUAL, RESET BIT
	JMP	SHIFTBIT
SETBIT:
	cpi	1	;warn if difference is not 1 or -1
	jz	diffok	;difference of 1 is ok
	cpi	0ffh
	jz	diffok	;difference of -1 is ok
	push b ! push d ! push h
	lxi	d,warnmes ;issue waring message
	call	prmsg
	pop	d	;get code 0 address back
	push	d	;and save again
	call	hexode	;print error address
	mvi	a,'H'
	call	conout
	pop h ! pop d ! pop b
diffok:
	STC		;SET REL BIT
SHIFTBIT:
	LDA	BITS	;GET OTHER BITS OF THIS WORD
	RAL		;SHIFT NEW BITS INTO POSITION
	STA	BITS	;SAVE BACK NEW REL WORD
	INX	H	;BUMP IMAGE 1 POINTER
	INX	D	;BUMP IMAGE 2 POINTER
	MOV	A,L	;SEE IF AT 8 BYTE BOUNDRY
	ANI  0000$0111B	;THIS MEANS REL WORD IS FULL
	JNZ	ENDTEST	;NOT FULL - JUST SEE IF DONE
	XTHL		;FULL - WRITE TO REL TABLE
	LDA	BITS	;GET REL WORD
	MOV	M,A	;PUT IN TABLE
	INX	H	;BUMP TABLE POINTER
	XTHL		;TABLE POINTER BACK ON THE STACK
ENDTEST:
	DCX	B	;DECREMENT LENGTH
	MOV	A,B	;SEE IF DONE (LENGTH = 0)
	ORA	C
	JNZ	COMP	;NOPE - KEEP COMPARING
	call	crlf
	POP	d	;REMOVE REL TBL ADR FROM STACK
	dcx	d
	call	hexode	;print last reloc table adr
	lxi	d,donemsg ;print done message
	call	prmsg
	RET		;BACK TO SID
donemsg:
	db	'H is last address of reloc table.'
	db	0
warnmes:
	db	13, 10, 'Warning, difference not 1 or -1 at '
	db	0
;
help:
	lxi	d,helpmsg
	call	prmsg
	ret
;
INIT:
	lxi	d,signon ;print signon message
	call	prmsg
	ret
signon:
	db	13, 10, 'REL.UTL Vers '
	db	vers / 10+'0', '.', vers mod 10+'0'
	db	13, 10, 'Ready to build relocation tables.'
	db	13, 10, 'Type C.HELP for more help.'
	db	0
helpmsg:
	db	13, 10, 'Format is:'
	db	13, 10, 'C.SETADRS,<adr of one code image>,'
	db	'<adr of other code image>'
	db	13, 10, 'C.SETLEN,<len of code to be relocated>,'
	db	'<dest. adr of rel table>'
	db	13, 10, 'The call to SETADRS must precede the'
	db	' call to SETLEN.'
	db	13, 10, 'The relocation table will be built'
	db	' when SETLEN is called.'
	db	0
;
CODE1	DW	0
CODE2	DW	0
BITS	DB	0
;
	org	(($-1) and 0fff8h) + 8 ;org up mod 8
;
codelen	equ	$-base
;
	end	setadrs

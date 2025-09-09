
;			ZB4MHZ.ASM

;		P. L. Kelley (617) 332-1610
;			 05/24/82

;****WARNING**** Read the text of this file before using. ****WARNING****

;Converts ZBIOS.SYS and ZFOR.COM to operate with a 4 MHz CPU on the H89
;using the Percom disk controller. Note that single density soft sectored
;disks and hard sectored disks cannot be cold booted at 4 MHz with Percom's
;rom.

TRUE		EQU	-1
FALSE		EQU	NOT TRUE

;You will want to convert this into two files:

;	1. The present version of this file

;	2. A file called ZF4MHZ.ASM made by reversing TRUE and FALSE
;	   in the equates which follow

ZB4MHZ	EQU	TRUE	;makes ZB4MHZ.ASM/HEX, set FALSE for ZF4MHZ.ASM/HEX
ZF4MHZ	EQU	FALSE	;set TRUE to make ZF4MHZ.ASM/HEX


;set the following to FALSE if no parallel printer

PARALLEL 	EQU	TRUE


;This program is set up for version 1.00 of Percom's ZBIOS.SYS and
;ZFOR.COM. If you have another version you will likely need to
;change the values of BLSTLOC, FCOUNT, and the various HDLYs and
;INTDLYs.

;After you overlay the memory image of ZBIOS.SYS with ZB4MHZ.HEX do:
;	SAVE 23 ZBIOS.SYS

;ZB4MHZ does two things:

;	1. Allows operation with a 4MHz CPU

;	2. Operates a Centronics 730 parallel printer as follows:
;		a. Handles formfeed
;		b. Assumes auto linefeed after carriage return


;After you overlay the memory image of ZFOR.COM with ZF4MHZ.HEX do:
;	SAVE 9 ZFOR.COM

;ZF4MHZ allows operation of ZFOR.COM with a 4 MHz CPU.


TPA	EQU	0100H	;location of start of ZBIOS.SYS when loaded by DDT

BPATCH	EQU	1600H	;area for patching located above
			;distribution version of ZBIOS.SYS

FPATCH	EQU	0898H	;area for patching ZFOR.COM located at
			;lowest memory reserved for stack
			;i.e. assume area reserved for stack in
			;distribution version is longer than necessary
	
BLSTLOC		EQU	02BEH
BHDLY1		EQU	0B9EH
BHDLY2		EQU	0BA6H
BHDLY3		EQU	0C70H
BHDLY4		EQU	0C93H
BHDLY5		EQU	0CDAH
BINTDLY		EQU	0D14H

FHDLY1		EQU	0608H
FHDLY2		EQU	0623H
FCOUNT		EQU	0752H
FHDLY3		EQU	075FH
FINTDLY1	EQU	07E5H
FINTDLY2	EQU	0811H

DPORT		EQU	0E0H	;printer data port
TPORT		EQU	0E5H	;port to test for printer status
BUSY		EQU	020H	;busy bit

;change the following to suit your system size

SZ64K		EQU	TRUE
SZ48K		EQU	FALSE
SZ32K		EQU	FALSE

;end of system size choice

	
	IF	SZ64K

BIOS	EQU	0E800H	;start of BIOS for 64K

	ENDIF	;SZ64K

	
	IF	SZ48K

BIOS	EQU	0A800H

	ENDIF	;SZ48K


	IF	SZ32K

BIOS	EQU	6800H

	ENDIF	;SZ32K


	IF	ZB4MHZ

PATCH	EQU	BPATCH+TPA
OFFSET	EQU	BIOS-TPA

	ENDIF	;ZB4MHZ


	IF	ZF4MHZ

PATCH	EQU	FPATCH
OFFSET	EQU	0

	ENDIF	;ZF4MHZ


	IF	ZB4MHZ AND PARALLEL

	ORG	BLSTLOC+TPA	;location to patch to jump to parallel
				;printer routine

	JMP	PARPRINT

	ENDIF	;ZB4MHZ AND PARALLEL



	IF	ZB4MHZ


;the next five changes take care of hard disk timing in ZBIOS

	ORG	BHDLY1+TPA

	MVI	A,28H		;2X previous value


	ORG	BHDLY2+TPA

	MVI	A,20H		;2X previous value


	ORG	BHDLY3+TPA

	MVI	A,28H		;2X previous value


	ORG	BHDLY4+TPA

	MVI	A,28H		;2X previous value


	ORG	BHDLY5+TPA

	MVI	D,0F0H		;3X previous value


	ORG	BINTDLY+TPA	;location to modify ZBIOS.SYS
				;to extend the delay loop between the force
				;interrupt command and a type I command
				;*** this is crucial ***

	JMP	EXINTDLY	;delay routine in patch area
	NOP			;eliminate odd XTHL


	ENDIF	;ZB4MHZ



	IF	ZF4MHZ


;The next four fix hard disk timing in ZFOR.COM

	ORG	FHDLY1

	MVI	A,3		;3X the previous value


	ORG	FHDLY2

	MVI	A,3		;3X the previous value


	ORG	FCOUNT

	LXI	D,0480H		;the previous value was 036DH
				;it was found that doubling this
				;value would not give properly
				;formatted hard sectored disks

	ORG	FHDLY3

	MVI	A,28H		;2X the previous value


;The next two changes fix interrupt delay timing in ZFOR.COM


	ORG	FINTDLY1

	CALL	EXINTDLY
	NOP


	ORG	FINTDLY2

	CALL	EXINTDLY
	NOP

	ENDIF	;ZF4MHZ



	ORG	PATCH


EXINTDLY	EQU	$+OFFSET
	MVI	A,0BH		;delay count
DELAY		EQU	$+OFFSET
	DCR	A
	JNZ	DELAY		;loop until delay finished

	IF	ZB4MHZ

	CALL	BINTDLY+BIOS+3	;go back to output command
	PUSH	H		;delay just a bit for
	POP	H		;single density soft sectored disks

	ENDIF	;ZB4MHZ

	RET


	IF	ZB4MHZ AND PARALLEL

PARPRINT	EQU	$+OFFSET
	IN	TPORT
	RAR
	RAR
	RNC		;return	if printer is not connected
PBUSY	EQU	$+OFFSET
	IN	TPORT
	ANI	BUSY	;printer busy?
	JNZ	PARPRINT		;loop if printer busy
	MOV	A,E	;character in register E on entering routine
	CPI	80H	;test for non printable character
	RNC		;return if non printable
	CPI	20H	;test for not control character
	JNC	CHAR
	CPI	0AH	;test for linefeed
	JZ	LFEED
	CPI	0CH	;test for formfeed
	JZ	FFEED
	CPI	0DH	;test for carriage return
	JZ	CARET
	RET		;return if any other control character
			;i.e. present version does not allow
			;elongated characters
CHAR	EQU	$+OFFSET
	LXI	H,CRFLG	;point to cr flag
	MVI	M,00H	;reset cr flag
	INX	H	;point to crlf flag
	MVI	M,00H	;reset crlf flag
OUTPUT	EQU	$+OFFSET
	OUT	DPORT	;print character
	RET

CARET	EQU	$+OFFSET
	CALL	INCLN	;call line # increment routine
	LXI	H,CRFLG	;load carriage return flag
	MVI	A,01H	;load the value of the CR and CRLF flags
			;when set
	CMP	M	;test for CR flag already set
	JZ	CRLFRP	;jump to output LF if set
	MVI	M,01H	;set carriage return flag
	INX	H	;point to CRLF flag
	CMP	M	;test if flag set
	JZ	RCRLFF	;jump to reset CRLF flag and output LF
			;otherwise output CR
RELOAD	EQU	$+OFFSET
	MOV	A,E	;restore character
	JMP	OUTPUT

CRLFRP	EQU	$+OFFSET
	MVI	A,0AH	;load LF
	JMP	OUTPUT

RCRLFF	EQU	$+OFFSET
	MVI	M,00H	;reset CRLF flag
	JMP	CRLFRP	;jump to output LF

INCLN	EQU	$+OFFSET
	LXI	H,PAGEL	;point to page length
	MOV	A,M	;load page length into A
	INX	H	;point to line #
	INR	M	;increment line #
	CMP	M	;compare page length to line #
	JZ	NEWPG	;jump if new page
	RET

NEWPG	EQU	$+OFFSET
	MVI	M,00H	;new page
	RET

LFEED	EQU	$+OFFSET
	LXI	H,CRFLG	;point to CR flag
	MVI	A,00H	;load CR flag reset value
	CMP	M	;compare with flag
	JNZ	LFRST	;jump if line feed follows carriage return
	CALL	INCLN	;call line # increment routine
	JMP	RELOAD	;output LF

LFRST	EQU	$+OFFSET
	MVI	M,00H	;reset CR flag
	INX	H	;point to CRLF flag
	MVI	M,01H	;set CRLF flag
	RET		;don't output anything

FFEED	EQU	$+OFFSET

;The Centronics 730 does not respond to formfeed (0CH).
;Instead of linefeeds this routine outputs a space followed by
;a carriage return to prevent the ribbon from lifting above the
;print head when too much vertical paper motion occurs. The
;problem occurs with tractor feed paper.

	MVI	E,' '	;load a space
	CALL	PBUSY	;output a space
	PUSH	H	;give time
	POP	H	;     for BUSY
	PUSH	H	;	  signal to
	POP	H	;		turn on
	MVI	E,0DH	;load CR
	CALL	PBUSY	;output CR
	LXI	H,LINEN	;point to line #
	MVI	A,00H	;top of page line #
	CMP	M	;test for top of page
	RZ		;return if at top
	JMP	FFEED	;otherwise repeat

PAGEL	EQU	$+OFFSET
	DB	42H	;page length

LINEN	EQU	$+OFFSET
	DB	02H	;initial line #
			;the print head is two lines down when
			;the paper tear line is at the tear bar

CRFLG	EQU	$+OFFSET
	DB	00H,01H	;initial CR and CRLF flag values

	ENDIF	;ZB4MHZ AND PARALLEL


	END


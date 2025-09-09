;;;     mft - multiple file transfer (for single drive systems)
;
;     **Based on article in Dr. Dobbs Journal of Computer**
; **Calisthenics & Orthodontia #49, Box E, Menlo Park, Ca. 94025**
;		-------------------------
;
;	Version 4.6A - gfn3 routine restored to version 4.5 -
;	4.6 revision did not handle eight char. filenames.
;	I could not reproduce the error reported by cml when
;	copying ufn.<sp><sp><sp>. (CHS) 4/30/81
;
;	Modified to VER. 4.6 to strip off $R/O attribute
;	in output filename.  If source was R/O then cp/m 
;	gave a "Bdos error on $R/O file" when an attempt was
;	made to write to the newly created file.
;
;	Changed 'jz	gfn4' in rtn. gfn3
;	to	'jz	gfn3' in order to ignore spaces
;	in the file type. Before, whenever an extension
;	was '.<sp><sp><sp>' multiple copies of the file
;	name were built in the ifnt.
;
;	Added equate 'nosys' and associated rtn. in section
;	'cfnt3:' in order to ignore all files with a 'sys'
;	attribute.  This will allow the user to mask-off
;	any file(s) he doesn't want to copy.
;		   cml  4/10/81
;
;		-------------------------
; 
;       Version 4.5 - 10/29/80 - Deleted system disk request of V4.0
;        to shorten messages, minor changes in abort options and
;        other messages. Moved disk reset of V4.1 to point
;        before directory search. (CHS)
;
;       Version 4.4 - 10/28/80 - Modified to bail out with message 
;        if no FCB is specified. Updates rearranged with most
;        recent first for reader convenience. (Charles H. Strom)
;
;       VERSION 4.3 BY LEWIS MOSELEY, JR.  3/22/80
;       FIXED BUG WHICH SHOWED UP WHEN MULTIPLE COPIES WERE
;       MADE OF A MULTIPLE EXTENT FILE, IN THAT CP/M OPEN
;       THE NEXT EXTENT USING THE DATA AREA TO SEARCH THE
;       DIRECTORY, SCREWING UP THE DATA BLOCK THAT IS THERE.
;
;       VERSION 4.2 BY LEWIS MOSELEY, JR.  2/23/80
;       FIXED BUG THAT OCCURRED WHEN ONLY A SINGLE FILE
;               WAS SPECIFIED AND THAT FILE WAS NOT FOUND:
;               PROGRAM HUNG IN A LOOP
;
;       VERSION 4.1 BY LES FREED AND LEWIS MOSELEY 2/11/80
;       ADDED DISK RESET ON DISK CHANGE TO ALLOW
;               CHANGING DENSITY BETWEEN DISKS
;       ADDED CTL-C ABORT 
;
;       VERSION 4.0 BY LEWIS MOSELEY, JR.  12/79
;       ADDED OPTION FOR MULTIPLE OUTPUT COPIES
;       ADDED REQUEST FOR SYSTEM DISK BEFORE REBOOT
;
;       l.e. hughes     9/79
;       mycroft labs
;       atlanta, ga
;       MODIFIED FOR SOL & COMPATABLE COMPUTERS BY
;       LEWIS MOSELEY, JR. - ATLANTA,GA.
;

VERSION EQU	4
MODLEV	EQU	6
;
entry	equ	0005H		;bdos entry point
tfcb	equ	005CH		;system file control block
dbuf	equ	0080H		;system disk buffer
;	
true	equ	0ffh
false	equ	0h
;
nosys	equ	false		;true to ignore all $SYS files
;
CR	equ	0DH
LF	equ	0AH
;	
rcfc	equ	01		;read console
wcfc	equ	02		;write console
rdfc	equ	13		;reset disk
offc	equ	15		;open file
cffc	equ	16		;close file
sffc	equ	17		;search first
snfc	equ	18		;search next
dffc	equ	19		;delete file
rrfc	equ	20		;read record
wrfc	equ	21		;write record
mffc	equ	22		;make file
safc	equ	26		;set address
;	
fn	equ	01		;file name offset
ft	equ	09		;file type offset
ex	equ	12		;extent number offset
nr	equ	32		;next record offset
;	
	org	100H
mft:	lxi	sp,stack+64
	lxi	h,msg1		;print 'MFT V4.0'
	call	wasc
	xra	a		;clear break flags
	sta	ibflg
	sta	obflg
	STA	NDFLG		;CLEAR NO DUP FLAG
;	
	LDA	TFCB+1		;If no FCB specified
	CPI	' '		;then say so
	JNZ	OK
	LXI	H,MSGK		;and bail out
	CALL	WASC		;here
	JMP	0H
;
;	calculate buffer size = fwa(BDOS) - fwa(MBUF)
;	
OK	lhld	entry+1	 ;hl = (entry+1) - 6
	lxi	d,-6
	dad	d
	mov	a,l
	ani	80H		;hl = hl mod 128
	mov	l,a
	lxi	d,mbuf		;hl = hl - fwa(MBUF)
	mov	a,l
	sub	e
	mov	l,a
	mov	a,h
	sbb	d
	mov	h,a
	dad	h		;hl = hl / 128
	mov	l,h
	mvi	a,0
	aci	0
	mov	h,a
	dcx	h		;subtract one
	shld	space		;save as buffer size
	lxi	h,msg2		;write 'Buffer size = '
	call	wasc
	lhld	space		;write size of buffer
	call	wdwc
	lxi	h,msg3		;write ' sectors'
	call	wasc
;	
;	ask user to mount input disk
;	
mft1:	lxi	h,msg4		;write 'Mount input disk, type CR'
	call	wasc
	call	racc		;read response
	CPI	03		;CTL-C ?
	JZ	MFTL		;ABORT WITH MESSAGE
	cpi	CR		;loop if anything but CR
	jnz	mft1
	call	weolc		;echo CR,LF
	CALL	RESET		;adjust density
	lda	ibflg		;jump if ibflg set
	ora	a
	jnz	mft2a
;	
;	copy command line into cbuf
;	
	lxi	h,dbuf		;fwa of command line image
	lxi	d,cbuf		;fwa of command buffer
	mov	b,m		;fetch command line image length
	inx	h
mft2:	mov	a,m		;fetch next byte from cli
	inx	h
	stax	d		;store in dbuf
	inx	d
	dcr	b		;decrement count
	jnz	mft2		;loop until zero
	xra	a		;store zero byte at end
	stax	d
	lxi	h,cbuf		;reset cbufp
	shld	cbufp
	call	cfnt		;create file name table
	lxi	h,fnt		;reset fnt pointers
	shld	ifntp
	shld	ofntp
mft2a:	lxi	h,mbuf		;reset mbuf pointer
	shld	mbufp
	lhld	space		;reset msize
	shld	msize
	lda	ibflg		;jump if ibflg not set
	ora	a
	jz	mft3
	lxi	h,ifcb		;copy IFCB into TFCB
	lxi	d,tfcb
	mvi	b,33
	call	move
	xra	a		;clear ibflg
	sta	ibflg
	inr	a		;set obflg
	sta	obflg
	lhld	ifntp		;back ifntp up 4 bytes
	lxi	d,-4
	dad	d
	shld	ifntp
	lxi	h,tfcb+fn	;write filename
	call	wfnc
	lxi	h,msg6		;write ' - '
	call	wasc
	lhld	ifntp		;DE = ifntp
	xchg
	jmp	mft4		;continue reading previous file
;	
;	parse off next name from cbuf
;	
mft3:	lhld	ifntp		;fetch input fnt pointer
	mov	a,m		;jump if end of table
	cpi	0FFH
	jz	mft9
	mvi	m,1		;set 'file read' flag
	inx	h
	lxi	d,tfcb+fn	;copy filename into tfcb
	mvi	b,11
	call	move
	shld	ifntp		;save input fnt pointer
	lxi	h,tfcb+fn	;write filename
	call	wfnc
	lxi	h,msg6		;write ' - '
	call	wasc
	xra	a		;setup tfcb
	sta	tfcb
	sta	tfcb+ex
	sta	tfcb+nr
	call	open		;open file
	lhld	ifntp
	xchg
mft4:	lhld	mbufp
	mov	a,h		;copy into fnt entry
	stax	d
	inx	d
	mov	a,l
	stax	d
	inx	d
	xchg			;save fnt pointer
	shld	ifntp
	lxi	h,0		;file size (in sectors) = 0
	shld	fsize
;	
;	read next file from input disk
;	
mft6:	lhld	mbufp
	xchg
	call	setdma
	call	read		;read next sector
	ora	a		;jump if normal transfer
	jz	mft7
	cpi	1		;jump if EOF
	jz	mft8
	lxi	h,msg8		;write 'read error - '
	call	wasc
	jmp	mft8		;continue as if EOF
mft7:	lhld	mbufp		;mbufp = mbufp + 128
	lxi	d,128
	dad	d
	shld	mbufp
	lhld	fsize		;fsize = fsize + 1
	inx	h
	shld	fsize
	lhld	msize		;decrement msize
	dcx	h
	shld	msize
	mov	a,h		;loop if still positive
	ora	l
	jnz	mft6
	lxi	h,tfcb		;copy tfcb into ifcb
	lxi	d,ifcb
	mvi	b,33
	call	move
	mvi	a,1		;set ibflg
	sta	ibflg
mft8:	lxi	d,dbuf		;reset dma pointer
	call	setdma
	call	close		;close file
	lhld	fsize		;write file size
	call	wdwc
	lxi	h,msg9		;write ' sectors read'
	call	wasc
;	
;	update fnt, loop
;	
	lhld	fsize		;DE = file size
	xchg
	lhld	ifntp		;store file size in fnt entry
	mov	m,d
	inx	h
	mov	m,e
	inx	h
	shld	ifntp		;save fnt pointer
	lda	ibflg		;loop if ibflg not set
	ora	a
	jz	mft3
;
;	FLAG THAT THE MEMORY BUFFER HAS BEEN EXCEEDED, AND
;	TELL USER THAT DUPLICATE COPIES CANNOT BE MADE
	LDA	NDFLG		;TOLD HIM ALREADY?
	ORA	A
	JNZ	MFT9		;JUMP IF SO
	LXI	H,MSGH		;IF NOT, TELL HIM
	CALL	WASC
	MVI	A,1		;SET NDFLG THIS TIME
	STA	NDFLG
;
;	Ask user to mount output disk
;	
mft9:	lxi	h,msgA		;write 'Mount output disk, type CR'
	call	wasc
	call	racc		;read response
	CPI	03		;CTL-C?
	JZ	MFTL		;ABORT WITH MESSAGE IF SO
	cpi	CR		;loop if anything but CR
	jnz	mft9
	call	weolc		;echo CR,LF
	call	reset		;reset disk system 
				;make r/w and check density
	lda	obflg		;jump if obflg not set
	ora	a
	jz	mftA
	lxi	h,ofcb		;copy ofcb into tfcb
	lxi	d,tfcb
	mvi	b,33
	call	move
	call	open		;open previous file
	lhld	ofntp		;backup output fnt pointer 4 bytes
	lxi	d,-4
	dad	d
	shld	ofntp
	lxi	h,tfcb+fn	;write file name
	call	wfnc
	lxi	h,msg6		;write ' - '
	call	wasc
	jmp	mftb		;continue writing previous file
;	
;	write next file to output disk
;	
mftA:	lhld	ofntp
	mov	a,m
	ora	a
	jz	mftF
	cpi	0FFH
	jz	mftF
	inx	h
	lxi	d,tfcb+fn
	mvi	b,11
	call	move
	shld	ofntp
	lxi	h,tfcb+ft	;pt to $R/O byte
	mov	a,m		;get it from storage
	ani	7fh		;force it to $R/W
	mov	m,a		;put it back
	lxi	h,tfcb+fn
	call	wfnc
	lxi	h,msg6
	call	wasc
	xra	a
	sta	tfcb
	sta	tfcb+ex
	sta	tfcb+nr
	call	delt		;try to create output file
	call	make
	cpi	255		;jump if ok
	jnz	mftB
	lxi	h,msgB		;write 'unable to create'
	call	wasc
	jmp	mftG
mftB:	lhld	ofntp
	mov	d,m		;fetch fwa of file from fnt
	inx	h
	mov	e,m
	inx	h
	xchg
	shld	mbufp		;save it
	xchg
	mov	d,m		;fetch size of file from fnt
	inx	h
	mov	e,m
	inx	h
	xchg
	shld	fsize		;save it
	shld	xsize		;save for printout
	xchg
	shld	ofntp
	lhld	fsize		;jump if fsize=0
	mov	a,h
	ora	l
	jz	mftDA
mftC:	lhld	mbufp		;set dma address to mbufp
	xchg
	call	setdma
	call	write		;write next sector
	ora	a		;jump if ok
	jz	mftD
	lxi	h,msgC		;write 'error writing file'
	call	wasc
	jmp	mftG
mftD:	lhld	mbufp		;mbufp = mbufp + 128
	lxi	d,128
	dad	d
	shld	mbufp
	lhld	fsize		;fsize = fsize - 1
	dcx	h
	shld	fsize
	mov	a,h		;loop until zero
	ora	l
	jnz	mftC
mftDA:	lxi	h,tfcb		;copy tfcb into ofcb
	lxi	d,ofcb
	mvi	b,33
	call	move
	lxi	d,dbuf		;reset dma pointer
	call	setdma
	call	close		;try to close file
	cpi	255		;jump if ok
	jnz	mftE
	lxi	h,msgD		;write 'unable to close'
	call	wasc
mftE:	lhld	xsize		;write number of sectors written
	call	wdwc
	lxi	h,msgE		;write ' sectors written'
	call	wasc
	jmp	mftA
mftF:	lda	ibflg		;loop if ibflg set
	ora	a
	jnz	mft1
;Terminate program here on irrecoverable error or
;when all files have been copied.  Must reload system
;disk to avoid crash when copying to someone else's disk.
;If normal end, and if buffer has not been exceeded, give
;user the option of making another copy of the same
;set of files.
mftG:	LXI	H,MSGF		;SEE IF OPTION IS ALLOWED
	LDA	NDFLG
	ORA	A
	JNZ	MFTH		;JUMP IF NOT ALLOWED
	CALL	WASC		;ELSE TELL ABOUT OPTION
MFTH:	LXI	H,MSGG		;ASK FOR SYSTEM DISK
	call	wasc
	call	racc		;wait for response
	CPI	03H		;WARM BOOT IF ^C
	JZ	0
	CPI	CR		;ATTEMPT REPEAT IF <RETURN>
	JZ	MFTJ
	JMP	MFTG		;ELSE LOOP TILL GOOD RESPONSE
;
MFTJ:	CALL	WEOLC		;ACKNOWLEDGE COMMAND
	LDA	NDFLG		;REPEAT ALLOWED?
	ORA	A
	JNZ	MFTK		;JUMP IF NOT
	LXI	H,FNT		;ELSE RESET FNT POINTER
	SHLD	OFNTP
	LXI	H,MBUF		;RESET MEM BUF POINTER
	SHLD	MBUFP
	XRA	A		;RESET OUTPUT INTERRUPTED FLAG
	STA	OBFLG
	JMP	MFT9		;AND DO AGAIN
;
MFTK:	LXI	H,MSGH		;CANNOT REPEAT, TELL HIM AGAIN
	CALL	WASC
	JMP	MFTG		;AND WAIT FOR SYSTEM DISK
;	
MFTL:	LXI	H,MSGJ		;ABORT MESSAGE
	CALL	WASC
	JMP	0H		;WARM BOOT

;	subroutines
;	
move:	mov	a,m
	inx	h
	stax	d
	inx	d
	dcr	b
	jnz	move
	ret
;	
;;	gfn - get file name
;	
;	
gfn:	mov	a,m
	ora	a
	rz
	cpi	' '
	jnz	gfn0
	inx	h
	jmp	gfn
gfn0:	lxi	d,xfcb
	xra	a
	stax	d
	inx	d
	push	d
	mvi	b,11
	mvi	a,' '
gfn6:	stax	d
	inx	d
	dcr	b
	jnz	gfn6
	pop	d
	mvi	b,9
gfn1:	mov	a,m
	ora	a
	jz	gfn4
	inx	h
	cpi	' '
	jz	gfn4
	cpi	'.'
	jz	gfn2
	cpi	'*'
	jz	gfn7
	stax	d
	inx	d
	dcr	b
	jz	gfn5
	jmp	gfn1
gfn7:	dcr	b
	jz	gfn9
	mvi	a,'?'
	stax	d
	inx	d
	jmp	gfn7
gfn9:	mov	a,m
	cpi	'.'
	jnz	gfn4
	inx	h
gfn2:	lxi	d,xfcb+ft
	mvi	b,4
gfn3:	mov	a,m
	ora	a
	jz	gfn4
	inx	h
	cpi	' '
	jz	gfn4
	cpi	'*'
	jz	gfn8
	stax	d
	inx	d
	dcr	b
	jz	gfn5
	jmp	gfn3
gfn8:	dcr	b
	jz	gfn4
	mvi	a,'?'
	stax	d
	inx	d
	jmp	gfn8
gfn4:	xra	a
	ret
gfn5:	stc
	ret
;	
;;	cfnt - create file name table
;	
;	
cfnt:	lxi	h,fnt		;reset ifntp
	shld	ifntp
	MVI	M,0FFH		;VER 4.2 BUG FIX 
cfnt1:	lhld	cbufp		;get cbufp
	mov	a,m		;exit if end of list
	ora	a
	rz
	call	gfn		;get next afn
	shld	cbufp		;save command buffer ptr
	jnc	cfnt2		;jump if filename ok
	lxi	h,msg5		;write 'Syntax error in filename'
	call	wasc
	jmp	cfnt1		;loop
cfnt2:	xra	a		;clear xfcb extent field
	sta	xfcb+ex
	lxi	d,xfcb		;search for first occurance
	call	srchf
	cpi	255		;jump if found
	jnz	cfnt3
	lxi	h,xfcb+fn	;write filename
	call	wfnc
	lxi	h,msg7		;write ' not found'
	call	wasc
	jmp	cfnt1		;loop
cfnt3:	ani	3		;index into cbuf
	mov	l,a
	mvi	h,0
	dad	h
	dad	h
	dad	h
	dad	h
	dad	h
	lxi	d,dbuf
	dad	d
;
	if	nosys

	push	h
	push	d
	lxi	d,10
	dad	d
	mov	a,m		;get 't2'
	ani	80h		;look at sys bit
	pop	d
	pop	h
	jnz	cfnt4		;'sys file'-ignore

	endif
;
	xchg			;copy filename into fnt
	lhld	ifntp
	xchg
	mvi	b,12
	call	move
	lxi	h,zeros		;zero fill rest of entry
	mvi	b,4
	call	move
	xchg
	shld	ifntp		;save input fnt pointer
	mvi	m,0FFH		;insure FF byte at end
cfnt4:	lxi	d,xfcb		;search for next occurance
	call	srchn
	cpi	255		;jump if found
	jnz	cfnt3
	jmp	cfnt1		;go get next afn
;	
;;	wasc - write ascii string to console
;	
;	
wasc:	mov	a,m
	ora	a
	rz
	call	wacc
	inx	h
	jmp	wasc
;	
;	
;;	wfnc - write file name to console
;Note: Under SOLOS and CUTER, 01 is the cursor-left character.
;When MFTing a multi-extent file, the extent character must
;be filtered out of the file-name-block to avoid wierd
;console output.
;
wfnc:	mov	a,m
	ora	a		;0=thru
	rz
	cpi	20h		;skip print if < space
	jc	wfnc1
	call	wacc
wfnc1	inx	h
	jmp	wfnc
;	
;;	weolc - write end of line to console
;	
;	
weolc:	mvi	a,CR
	call	wacc
	mvi	a,LF
	jmp	wacc
;	
;;	wdwc - write decimal word to console
;	
;	
wdwc:	push	h
	push	d
	push	b
	mvi	b,0		;clear 'digit written' flag
	lxi	d,10000		;write 1st digit
	call	wndd
	lxi	d,1000		;write 2nd digit
	call	wndd
	lxi	d,100		;write 3rd digit
	call	wndd
	lxi	d,10		;write 4th digit
	call	wndd
	lxi	d,1		;write 5th digit
	mvi	b,1		;force last digit to print
	call	wndd
	pop	b
	pop	d
	pop	h
	ret
;	
wndd:	mvi	c,0		;c=0
wndd1:	mov	a,l		;hl = hl - de
	sub	e
	mov	l,a
	mov	a,h
	sbb	d
	mov	h,a
	jc	wndd2		;jump if < 0
	inr	c		;c = c + 1
	jmp	wndd1		;loop
wndd2:	dad	d		;hl = hl + de
	mov	a,c		;jump if c non-zero
	ora	c
	jnz	wndd4
	mov	a,b		;jump if digit written
	ora	b
	jnz	wndd4
	mvi	a,' '		;write one space
	jmp	wacc
wndd4:	mvi	b,1		;set 'digit written' flag
	mov	a,c		;encode c into decimal ascii
	adi	'0'
	jmp	wacc		;go write it
;	
;;	wacc - write ascii character to console
;	
;	
wacc:	push	h
	push	d
	push	b
	push	psw
	mvi	c,wcfc
	mov	e,a
	call	entry
	pop	psw
	pop	b
	pop	d
	pop	h
	ret
;	
;;	racc - read ascii character from console
;	
;	
racc:	push	h
	push	d
	push	b
	mvi	c,rcfc
	call	entry
	pop	b
	pop	d
	pop	h
	ret
;	
;;	reset - reset disk system
;	
;	
reset:	push	h
	push	d
	push	b
	mvi	c,rdfc
	call	entry
	pop	b
	pop	d
	pop	h
	ret
;	
;;	open - open disk file
;	
;	
open:	push	h
	push	d
	push	b
	lxi	d,tfcb
	mvi	c,offc
	call	entry
	pop	b
	pop	d
	pop	h
	ret
;	
;;	read - read record from disk file
;	
;	
read:	push	h
	push	d
	push	b
	lxi	d,tfcb
	mvi	c,rrfc
	call	entry
	pop	b
	pop	d
	pop	h
	ret
;	
;;	close - close disk file
;	
;	
close:	push	h
	push	d
	push	b
	lxi	d,tfcb
	mvi	c,cffc
	call	entry
	pop	b
	pop	d
	pop	h
	ret
;	
;;	delt - delete disk file
;	
;	
delt:	push	h
	push	d
	push	b
	lxi	d,tfcb
	mvi	c,dffc
	call	entry
	pop	b
	pop	d
	pop	h
	ret
;	
;;	make - make new disk file
;	
;	
make:	push	h
	push	d
	push	b
	lxi	d,tfcb
	mvi	c,mffc
	call	entry
	pop	b
	pop	d
	pop	h
	ret
;	
;;	write - write record to file
;	
;	
write:	push	h
	push	d
	push	b
;
;;	REVISION 4.3 MODS
;
	LDA	tfcb+nr		;LAST RECORD IN EXTENT?
	CPI	7FH
	JNZ	WRITE1		;NO, CONTINUE
	LHLD	mbufp		;EXISTING DATA AREA
	LXI	D,dbuf		;POINT TO SAFE AREA
	CALL	SETDMA		;TELL CP/M WHERE TO GET DATA
	MVI	B,80H		;LENGTH TO MOVE
	CALL	MOVE		;MOVE DATA AWAY SO...
;CP/M DOESN'T OVERWRITE THE REAL DATA IN OPENING NEXT EXTENT
;END REVISION 4.3 MODS

WRITE1: lxi	d,tfcb
	mvi	c,wrfc
	call	entry
	pop	b
	pop	d
	pop	h
	ret
;	
;;	setdma - set dma address
;	
;	
setdma: push	h
	push	d
	push	b
	mvi	c,safc
	call	entry
	pop	b
	pop	d
	pop	h
	ret
;	
;;	srchf - search for first occurance of afn
;	
;	
srchf:	push	h
	push	d
	push	b
	mvi	c,sffc
	call	entry
	pop	b
	pop	d
	pop	h
	ret
;	
;;	srchn - search for next occurance of afn
;	
;	
srchn:	push	h
	push	d
	push	b
	mvi	c,snfc
	call	entry
	pop	b
	pop	d
	pop	h
	ret
;	
msg1:	db	CR,LF,'MFT V'
	DB	VERSION+'0'	;VERSION #
	DB	'.',MODLEV+'0'	;MODIFICATION LEVEL
	DB	CR,LF
	db	'Multi-File-Transfer for single disk,',CR,LF
	db	'With multiple-copy option.',CR,LF,LF,0
msg2:	db	'Buffer size = ',0
msg3:	db	' sectors',CR,LF,LF,0
msg4:	db	'Mount INPUT disk, type RETURN (or ^C to reboot)',0
msg5:	db	'Syntax error in filename',CR,LF,0
msg6:	db	' - ',0
msg7:	db	' not found',CR,LF,0
msg8:	db	'read error - ',0
msg9:	db	' sectors read',CR,LF,0
msgA:	db	'Mount OUTPUT disk, type RETURN (or ^C to reboot)',0
msgB:	db	'unable to create',CR,LF,0
msgC:	db	'error writing file',CR,LF,0
msgD:	db	'unable to close',CR,LF,0
msgE:	db	' sectors written',CR,LF,0
MSGF:	db	CR,LF,'Completed. '
	db	'Type RETURN for another copy, OR...',0
MSGG:	db	CR,LF,'type ^C to reboot.',CR,LF,0
MSGH:	db	CR,LF,'++Memory buffer exceeded, cannot ',CR,LF
	db	'make duplicate copies this time;',CR,LF
	DB	'last ouput file is incomplete++',CR,LF,LF,0
MSGJ	DB	CR,LF,'++PROGRAM ABORTED++',CR,LF,0
MSGK	DB	CR,LF,'No file name specified',CR,LF,0
;
;
zeros:	db	0,0,0,0
;	
	org	($+15)/16*16
;	
fnt:	ds	16*64+1
;	
stack:	ds	64
space:	ds	2		;available space
msize:	ds	2		;memory size
cbuf:	ds	80		;command buffer
cbufp:	ds	2		;command buffer pointer
fsize:	ds	2		;file size in sectors
xsize:	ds	2		;file size for printout
ifntp:	ds	2		;input fnt pointer
ofntp:	ds	2		;output fnt pointer
mbufp:	ds	2		;memory buffer pointer
ifcb:	ds	33		;input fcb
ofcb:	ds	33		;output fcb
xfcb:	ds	33		;temporary fcb
ibflg:	ds	1		;input break flag
obflg:	ds	1		;output break flag
NDFLG:	DS	1		;NO DUPLICATE ALLOWED FLAG
;	
mbuf	equ	$
;	
	end	mft

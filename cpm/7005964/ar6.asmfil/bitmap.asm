;
;	BITMAP for CP/M 2.0+		as of 7/11/80
;
;
;	Lauren Guimont
;	14211 8th Avenue South
;	Seattle, Washington  98168
;
;
;
;The bitmap idea is based upon Ward Christensen's original
;  bitmap program, which refused to run on 2.0+ systems.
;  After giving his program a quick going over with SID, I
;  decided it would be easier to rewrite it than to try and
;  patch it for 2.0, 2.1, 2.2.
;
;
;		***** EQUATES *****
;
base	equ	0		; 'normal' CP/M
bdos	equ	base+5		; jump to bdos
ochar	equ	2		; bdos console output
sdsk	equ	14		; select disk
curdsk	equ	25		; current disk
gtaloc	equ	27		; get allocation address
dskpar	equ	31		; get disk parameters
fcb	equ	base+5ch	; file control block
;
;
;
	org	base+100h	; start of TPA
;
	lxi	h,0		; clear HL
	dad	sp		; load HL with CCP sp
	shld	oldsp		; save it for later
	lxi	sp,stack	; initialize our own sp
	jmp	start		; bypass some subroutines
	ds	48		; stack space
stack	equ	$		; our own stack
oldsp	ds	2		; old stack from ccp
;
inlprt:				; in line print
	xthl			; HL to stack...pointer to HL
inlprt1	mov	a,m		; get a character
	inx	h		; increment the pointer
	cpi	'$'		; endmark?
	jz	inlprt2		; if so, prepare to exit
	call	conout		; output to console
	jmp	inlprt1		; go get another
inlprt2	xthl			; orig HL...sp at end of msg
	ret			; return to end of msg
;
conout	push	h		; single character console
	push	d		; ...output; 1st save all
	push	b		; ...the registers
	push	psw
	mvi	c,ochar		; tell bdos
	mov	e,a		; bdos wants it in E
	call	bdos		; let bdos do it
	pop	psw		; reinstate all registers
	pop	b
	pop	d
	pop	h
	ret			; return to caller
;
crlf	call	inlprt		; use in line print
	db	0dh,0ah,'$'	; ...for cr & lf
	ret			; return to caller
;
one	push	psw		; save Acc
	mvi	a,'1'		; print a '1' to console
	call	conout		; do it
	pop	psw		; restore Acc
	ret			; return to caller
;
zero	push	psw		; save Acc
	mvi	a,'0'		; print a '0' to console
	call	conout		; do it
	push	h		; save <hl>
	lhld	free		; get nb of free blocks
	inx	h		; add one free
	shld	free		; store total free count
	pop	h
	pop	psw		; restore Acc
	ret			; return to caller
;
;Binary to decimal output routine. Enter with 8 bit binary
;number in <A>. Second entry at BNDEC2 assumes 16 bit nb. in <HL>
;
bndec1	mvi	h,0
	mov	l,a		;<HL> now has number
;
bndec2	push	b
	push	d
	push	h
	lxi	b,-10
	lxi	d,-1
bndc	dad	b
	inx	d
	jc	bndc
	lxi	b,10
	dad	b
	xchg
	mov	a,h
	ora	l
	cnz	bndec2
	mov	a,e
	adi	'0'
	call	conout
	pop	h
	pop	d
	pop	b
	ret
;
err1	call	inlprt		; in line print
	db	0dh,0ah,'Nonstandard disk '
	db	'parameter block error'
	db	0dh,0ah,'$'
;
finis	lhld	oldsp		; get CCP sp
	sphl			; retore it
	ret			; direct return to CCP
;
;We need a little internal storage
;
drive	ds	1		; current drive
aldrv	ds	1		; alternate specified drv
dpb	ds	2		; disk parameter block add
tbtr	ds	2		; total bits to read
alloc	ds	2		; allocation address
blksiz	ds	1		; block size code
free	dw	0		; count of free blocks
;
;The actual start of it all
;
start	lda	fcb		; get any alternate drv
	sta	aldrv		; save it for later
	call	inlprt		; in line print
	db	'BITMAP 2.2    AS OF '
	db	'7/11/80',0dh,0ah,0dh,0ah,'$'
	mvi	c,curdsk	; get current disk in
	call	bdos		; ...use from bdos
	sta	drive		; save it
	lda	aldrv		; get any alternate drv
	ora	a		; any specified?
	jz	dpblk		; if not, skip next
	dcr	a		; less one
	sta	drive		; save as drive to use
;
dpblk	lda	drive		; get drive to bitmap
	mvi	c,sdsk		; set call for disk select
	mov	e,a		; bdos wants it in E
	call	bdos		; let bdos do it
	mvi	c,dskpar	; we want dsk parameter blk
	call	bdos		; get it, and.....
	shld	dpb		; ...save it
	lxi	d,5		; offset for total blks used
	dad	d		; add it to HL
	mov	e,m		; lsb into E
	inx	h		; point to msb
	mov	d,m		; get it
	xchg			; put it in HL...
	inx	h		; alloc size = (dsm/8)+1
	shld	tbtr		; ...and save it
	lhld	dpb		; get dsk parameter blk add
	inx	h		; ...and increment HL to
	inx	h		; ...the 3rd byte
	mov	a,m		; it has the block size
	sui	2		; it will be 3-7 (make it 1-5)
	cpi	5+1		; check for over 5
	jnc	err1		; nonstandard size
	cpi	1		; check for less than 1
	jc	err1		; nonstandard size
	push	psw		; save it
	call	inlprt		; in line print
	db	'Allocated disk block size is $'
	pop	psw		; get block size back
	sta	blksiz		; save it for end
	lxi	h,512		; set 1/2k counter
lp	dad	h		; multiply * 2=1024
	dcr	a		; less block size code count
	jnz	lp		; loop till <A>= 0
	call	bndec2		; print size in K
;
dpbend	call	inlprt		; finish message
	db	' bytes per block',0dh,0ah,'$'
	lhld	tbtr		; total bits to read
	push	h		; save it in the stack
	lda	drive		; again to be safe
	mov	e,a		; into E for bdos
	mvi	c,sdsk		; reselect disk
	call	bdos		; let bdos do it
	mvi	c,gtaloc	; get the allocation address
	call	bdos		; ...from bdos
	pop	d		; tbtr from stack
	dcx	h		; back allocation up one
;
;
;We now have the total number of bits to read in DE, and
;  the address to start reading them at in HL for the
;  proper drive. So now let's print the bitmap.
;
;
bmap	mvi	c,48		; 1's and 0's per line
	call	crlf		; followed by a cr,lf
bmap1	inx	h		; kick the pointer
	mov	a,m		; get the byte
	mvi	b,8		; it has 8 bits
bmap2	rlc			; runn'em through carry
	cc	one		; carry set = print '1'
	cnc	zero		; carry not set = print '0'
	dcx	d		; decrement bit count
	push	psw		; save the bit pattern
	mov	a,d		; check to see if...
	ora	e		; ...DE = 0
	jz	bmapend		; if so, we're finished
	pop	psw		; restore bit pattern
	dcr	c		; decrement line count
	jz	bmap		; new line if zero
	dcr	b		; decrment bit count
	jz	bmap1		; new byte if zero
	jmp	bmap2		; finish this byte
;
bmapend	pop	psw		; not neccessary, but keeps the
	call	crlf		; ...stack straight..send cr,lf
	call	crlf
	lda	drive		;get drive used
	adi	'A'
	call	conout
	call	inlprt
	db	': R/W, Space: $'
	lda	blksiz		; get block size code
	lhld	free		; get nb of free blocks
lp1	dcr	a
	jz	don		; multiplied by size of block
	dad	h		; times 2
	jmp	lp1
;
don	call	bndec2		; print size of free space
	call	inlprt
	db	'k',0dh,0ah,'$'
	jmp	finis		; restore things and GET OUT
;
	end

;		U.COM - VERSION 1.0
;			BY ROBERT FISHER
;			   November 27, 1981
;
;Select drive and user area with one command.
;
;Usage:
;       U B4
;will select drive B:, user area 4.
;
;The drive may be any valid drive letter in upper or lower case,
;and the user area may be any user area in the range 0-31. 
;(But see the customization area below.)
;Either may be omitted.  If both are omitted, a usage message is printed.
;
;To be useful, this program must be accessable from all drives and
;all user areas.
;This is no problem if you are using one of the modified CCP's, but
;requires some other mechanism for a standare CCP.
;
;Check the public programs: DUPUSR21.ASM and CCPPATCH.ASM or the
;various versions of CCPZ.ASM
;
;One further note.  Your BIOS must be correctly written for this 
;program to work.  Specifically, it must not reset the user area
;to zero on warm boot.  (The California Computer System BIOS
;fails in this respect.)
;
	org 100h
fcb	equ	5ch
bdos	equ	5
cdrive	equ	04
warmbt	equ	0
;
prstr	equ	9
;
tab	equ	9
lf	equ	0ah
cr	equ	0dh
;
;USER customization parameters
maxuser	equ	15	;maximum user area   (may be in range 0-31)
numdrvs	equ	4	;number of drives in your system
;
;set selected drive
	lxi	h,fcb+1
	mov	a,m
	cpi	' '
	jz	usage	;no parameters
	cpi	'9'+1	
	jc	digit	;no drive was specified
	ani	5fh	;make it upper case
	sui	'A'
	jc	usage	;illegal character
	cpi	numdrvs
	jnc	usage	;too high a drive specified
	mov	e,a
	lda	cdrive	;put new drive into lower nibble of cdrive
	ani	0f0h	;zero out old drive number
	ora	e	;slip the new drive in
	sta	cdrive	;this sets the drive
	
;
;set selected user area
	inx	h
	mov	a,m
	cpi	' '
	jz	warmbt	;no user area specified
digit	sui	'0'
	jc	usage	;non-digit
	cpi	10
	jnc	usage	;non-digit
	mov	e,a	;move it to e to preserve it
	inx	h
	mov	a,m
	cpi	' '
	jz	setusr	;one-digit user
	sui	'0'
	jc	usage	;non-digit
	cpi	10
	jnc	usage	;non-digit
	mov	c,a
	xra	a	;clear the carry bit
	mov	a,e	;get first digit back
	ral		;x2
	mov	e,a	
	ral		;x4
	ral		;x8
	add	e	;x10
	add	c	;add in second digit
	mov	e,a
;
setusr:	mov	a,e	;get it back if it's not there already
	cpi	maxuser+1
	jnc	usage
	cmc		;clear the carry bit
;
;User area goes in upper nibble of cdrive.
	ral
	ral
	ral
	ral
	mov	c,a
	lda	cdrive
	ani	0fh	;zero out old user number
	ora	c	;slip in new user number
	sta	cdrive
;	
;
	jmp	warmbt
;Print USAGE message if no parameters provided, or if parameters
;are illegal.
usage:	lxi	d,message
	mvi	c,prstr
	call	bdos
	ret

message	db	'Drive and user selector: U.COM - Version 1.0',cr,lf
	db	tab,tab,tab,tab,'by Robert Fisher - November 27, 1981',cr,lf,lf
	db	'Sample usage:',cr,lf,lf
	db	tab,tab,'U B4',cr,lf,lf
	db	'selects drive B, user area 4.',cr,lf,lf
	db	tab,tab,'U 13',cr,lf,lf
	db	'selects user area 13 of the current drive.',cr,lf,lf
	db	tab,tab,'U B',cr,lf,lf
	db	'selects drive B, current user area.',cr,lf,lf
	db	'Lower case is acceptable for the drive letter.',cr,lf
	db	'The drive or the user area may be omitted.',cr,lf,lf
	db	'$'

	end

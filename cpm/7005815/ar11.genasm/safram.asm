*	safram.asm				Roy Lipscomb
*	Version 1.0				Aug 1, 1982
*
*	Creates a "safe" partition below BDOS.  Modules residing
*	in the partition are safe from destruction until the
*	the next system reset.
*
*	Copyright 1982 by Roy Lipscomb, Logic Associates, Chicago
*
*	Original distributor:  HP/RCPM, (312) 955-4493
*
*
********************************************************************
*
*	Description of this program is contained in SAFRAM.DOC and
*	in SAFRAM.H.
*
*	Before attempting to assemble this source, please read the
*	ASSEMBLING section in SAFRAM.DOC.
*
*********************************************************
*		service/loader routines			*
*********************************************************

	if	copy1		;service routines
	org 	100h
	jmp	begin


no	equ	0
yes	equ	1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;		customizing variables			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
boot	equ	0		;lowest address within CP/M

notify	equ	yes		;at each ^C, notify of secure addr

hotboot	equ	0		;set to 0 to deactivate.
				;hotboot gives displacement from start
				; of bios to first instruction after
				; code that loads CCP/BDOS/BIOS.
				; See document SAFRAM.H for information.

pagebnd	equ	no		;to force all secure addresses
				;to page boundary, change to "yes"

;nothing below this point needs to be customized.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
bell	equ	7
coutdsp	equ	12-3		;displacement of charout from wboot
bdosjmp	equ	boot+5
pstr	equ	9
deffcb	equ	boot+5ch
tbuff	equ	boot+80h

tab	equ	9
cr	equ	13
lf	equ	10
blank	equ	' '

pageopt	equ	(not pagebnd)/100h ;if pagebnd = no, pageopt = 0ffh
secaddr	dw	0		;highest available RAM excluding CCP
loadpnt	dw	0
modbase	dw	0		;starting point of module
				;(different from loadpnt if old module)

;values used in setting traps
biosdsp	dw	0
biosav	dw	0
trapent	dw	0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;values used in manipulating the ccp

doslen1	equ	0d00h		;length of cpm 1.x bdos
doslen2	equ	0e00h		;length of cpm 2.x bdos

ccplen	equ	800h		;length of ccp
ccpclen	equ	7		;ccp command-length byte
ccpcchr	equ	88h		;ccp current-char displacement
ccp	dw	0		;ccp entry point

curdrv	equ	4		;current drive in pg zero
ccpstrt	dw	0		;pointer to first char in ccp buff



;messages
eom	equ	'$'

baddr	db	cr,lf
	db	bell
	db	'Abort:  Valid address range at present is '
badad1	db	'....H through '
badad2	db	'....H.'
	db	cr,lf
	db	'$'

ccpmess	db	'Abort:  unable to locate CCP'
	db	bell,cr,lf,cr,lf,eom

helpmes	db	cr,lf
	db	'  SAFRAM'
	db	'   Copyright 1982 by Roy Lipscomb, Logic Associates'
	db	cr,lf
	db	'              Version 1.0      Aug, 1982'
	db	cr,lf
	db	cr,lf
	db	'  Assigns safe partition (removed only by system'
	db	' reset) below BDOS.'
	db	cr,lf
	db	'  (Multiple executions of SAFRAM are permitted).'
	db	cr,lf
	db	cr,lf
	db	'   []  To secure the CCP or the boot+6 address, '
	db	'type "SAFRAM".'
	db	cr,lf
	db	'   []  To secure a lower address, type "SAFRAM xxxx",'
	db	' where'
	db	cr,lf
	db	'       "xxxx" is address in hex.'
	db	cr,lf
	db	cr,lf
	db	'    ',eom

crlf	db	cr,lf
	db	eom


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;		mainline				;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

begin	call	signon		;print signon message

	call	getbase		;compute load address: just below CCP
	cz	ccperr		;ccp not found
	jz	exit

;test for explicit address on command line.  Abort if bad.
	call	expladr
	jnz	exit		;quit if error

;if already loaded and active, don't load again (just update it)
	call	tstact
	cz	active
	cnz	instal

;if ddt executing, do restart 7; else return to cpm
exit	lxi	h,0
	dad	sp		;if stack pointer <= 100,
	mov	a,h		; then ddt active
	cpi	2
	rnc		;stack pointer >1ff, so must be cpm

	rst	7		;ddt active;  do restart 7

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;		compute load address			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;if ccp not found, return with zero set

;first try to find ccp:  standard method
getbase	lhld	boot+6
	shld	secaddr		;secure-address if ccp already
				;  secured (default)
	lxi	d,0
	call	tstccp		;add de and hl for candidate ccpbase
	jz	ccpnosc		;ccp found, not secured

;second try:  via cbios entry point of cpm 2.x
	lhld	boot+1
	lxi	d,-doslen2
	call	tstccp		;add de and hl for candidate ccpbase
	jz	ccpsec		;ccp found, secured

;last try:  via cbios entry point of cpm 1.x
	lhld	boot+1
	lxi	d,-doslen1
	call	tstccp		;add de and hl for candidate ccpbase
	jz	ccpsec		;ccp found, secured

;ccp not found
	xra	a
	ret			;set zero flag ("not found")

;ccp secured/not-secured
ccpnosc	lhld	ccp		;(really contains bdos addr here)
	shld	secaddr		;set to secure ccp

ccpsec	ori	1
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;test for explicit address on command line.  Abort if error
;if no error, return with z flag = yes

;get parm length and address
expladr	lxi	d,tbuff		;get parm length
	ldax	d
	mov	b,a		;save parm length byte
	inr	b

;skip leading blanks, exit if nothing left
expl4	dcr	b
	jz	expl9

	inx	d
	ldax	d
	call	blnktab		;test for blank or tab
	jz	expl4

;digest the parm
	lxi	h,0		;initialize hex value

expl6	call	asc2hex		;build hex value in hl
	jnz	expl8		;exit if error

	dcr	b
	jz	expl7

	inx	d
	ldax	d
	call	blnktab		;test for blank or tab
	jnz	expl6

;value digested:  verify it's acceptable
expl7	xchg			;save in de
	lxi	h,progend+2
	call	neghl
	dad	d
	jnc	expl8		;error if below end of this prog...

	lhld	secaddr
	inx	h
	call	neghl
	dad	d
	jc	expl8		;  ...or if higher than available top

;value ok:  substitute it for implicit address
	xchg
	shld	secaddr

	xra	a		;set z = "no error"
	jmp	expl9

;error exit:  display acceptable addr range, then exit.
expl8	lxi	h,progend+3
	call	hex2asc		;put value in de and hl
	lxi	h,badad1
	call	put2bad

	lhld	secaddr
	call	hex2asc
	lxi	h,badad2
	call	put2bad

	lxi	d,baddr
	mvi	c,pstr
	call	bdosjmp

	ori	1		;set z = "error"

expl9	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;test for blank or tab in a; if yes, return z = yes
blnktab cpi	blank
	rz

	cpi	tab

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;put address into error message
put2bad	mov	m,b
	inx	h

	mov	m,c
	inx	h

	mov	m,d
	inx	h

	mov	m,e

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;convert ascii characters into hex (using hl)
asc2hex	sui	'0'
	rc			;exit if invalid char

	cpi	10
	jc	asc2b
	sui	7

	cpi	16
	jnc	asc2x

asc2b	dad	h
	dad	h
	dad	h
	dad	h

	add	l
	mov	l,a

	xra	a		;set z = "no error"

	ret

;error exit
asc2x	ori	1		;set z = "error"

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;convert hex value to ascii
hex2asc	call	hex2b
	mov	b,d
	mov	c,e

hex2b	call	hex2c
	mov	d,a

	call	hex2c
	mov	e,a

	ret

hex2c	mov	a,h

	dad	h
	dad	h
	dad	h
	dad	h

	rar
	rar
	rar
	rar

	ani	0fh
	adi	'0'

	cpi	'9'+1
	rc

	adi	7

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;convert hl to its negative
neghl	push	psw

	mov	a,h
	cma
	mov	h,a

	mov	a,l
	cma
	mov	l,a

	inx	h

	pop	psw

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;test if this location has ccp

;compute tentative ccpbase
tstccp	mvi	l,0
	dad	d		;compute tentative bdos entry point

	lxi	d,-ccplen
	dad	d		;tentative bdos entry minus ccp length

	shld	ccp		; ...gives tentative ccp entry

;test for the two leading jumps in the ccp
	mvi	a,jmp
	lxi	b,3

	cmp	m
	rnz

	dad	b
	cmp	m
	rnz

;test for standard "maximum buffer length" value
	dad	b
	mov	a,m

	cpi	7fh		;standard ccp maxbuff len
	jz	tstcc4

	cpi	50h		;standard zcp maxbuff len
	rnz

;test for "buffer length" < "maximum buffer length"
tstcc4	inx	h
	cmp	m
	rc			;give up if bufflen > maxbufflen

	xra	a		;looks ok

	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;		test if module already active		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;check address in bios table for wboot
tstact	lhld	boot+1
	inx	h
	mov	e,m
	inx	h
	mov	d,m
	xchg
	shld	modbase		;save it

;test if "secure" message present where expected
	lxi	d,wb2mess	;get adjustment for message
	dad	d

;compare to unmoved module message
	lxi	d,message+module1
	mvi	b,testlen
tstmess	ldax	d
	cmp	m
	jnz	failtst
	inx	h
	inx	d
	dcr	b
	jnz	tstmess

;active already
	xra	a
	ret

failtst	ori	1		;set flag
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	module already active:  process only stub	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;determine where to install bypass
active	lhld	secaddr
	lxi	d,-3
	dad	d
	mvi	a,pageopt
	ana	l
	mov	l,a
	shld	loadpnt

;determine old module's start
	lhld	modbase
	lxi	d,-beforwb
	dad	d
	shld	modbase

;secure, then update message and savearea
	call	doprot

;set for display of current secured address
	lhld	modbase
	lxi	d,bootflg
	dad	d
	mvi	m,on		;set flag to "on"

;set to bypass "not active" module
	xra	a

	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	module not active:  load from scratch		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;if hotboot option requested, set it now
instal	call	sethot

;compute load point
	lhld	secaddr
	lxi	d,-length
	dad	d
	mvi	a,pageopt
	ana	l
	mov	l,a
	shld	loadpnt
	shld	modbase		;modbase = new module entry

;move it
	call	chgaddr		;convert to true addresses
	call	movemod		;move module to load address
	call	traps		;install traps
	call	doprot		;do secure, and update message

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;overlay warmboot jmptable entry with hotboot, if hotboot > bdos.
sethot	lxi	b,hotboot
	mov	a,b
	ora	c
	jz	noacex		;hotboot option not in effect, so exit.

	lhld	boot+1		;put warmstart jmptab entry into hl
	mov	d,h
	mov	e,l		;  point de to warmboot jmp addr
	inx	d

	dcx	b		;normalize bc for warmstart, not cold
	dcx	b
	dcx	b
	dad	b		;compute hl = hotboot jump address

	mov	a,l		;substitute hot for warm boot address
	stax	d
	inx	d

	mov	a,h
	stax	d

noacex	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;		convert module1 to true addresses	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; change pseudo addresses to true addresses
chgaddr	lxi	b,length
	lxi	d,module1
	lxi	h,module2
truloop	ldax	d
	cmp	m
	cnz	convert

	inx	h
	inx	d
	dcx	b

	mov	a,b
	ora	c
	jnz	truloop


	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	convert displacement into address		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

convert	push	b		;length of module not yet processed
	push	h		;module2 character position

; get displacement from instruction, put into bc.
	ldax	d
	mov	b,a
	dcx	d
	ldax	d
	mov	c,a

	lxi	h,-module1	;normalize displacement to zero
	dad	b
	push	h
	pop	b

	lhld	loadpnt		;add load point for true addr
	dad	b

; move true address to instruction
	mov	a,l
	stax	d
	inx	d
	mov	a,h
	stax	d

	pop	h
	pop	b

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;		move module into place			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

movemod	lhld	loadpnt
	xchg				;de=destination
	lxi	h,module1		;hl=source 
	lxi	b,length 

	call	move


	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	install security, describe in message		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;move the new secured address to de, then store wherever needed

; secure the module
doprot	lhld	6
	xchg
	lhld	loadpnt
	shld	6

;install bypass at base of secured RAM
	push	h		;save new secured address
	mvi	m,jmp
	inx	h
	mov	m,e
	inx	h
	mov	m,d
	pop	d		;restore new secured address

;store new secured address in module
	lhld	modbase
	lxi	b,savbase
	dad	b
	mov	m,e
	inx	h
	mov	m,d

;convert hex address at location 6 to ascii, put in message
	lhld	modbase		;address message
	lxi	b,messadr
	dad	b		;pointer to message into hl

;output hi and lo bytes of address to message
	call	hilo
hilo	mov	a,d
	mov	d,e		;get next byte
	push	psw
	rar
	rar
	rar
	rar
	call	hexbyte
	pop	psw

hexbyte	ani	0fh
	adi	'0'
	cpi	'9'+1
	jc	movhex
	adi	7
movhex	mov	m,a
	inx	h

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;		set all traps				;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;set trap for wboot
traps	lxi	h,toboot+1
	shld	biosav
	lxi	h,beforwb
	shld	trapent
	lxi	h,0
	shld	biosdsp

	call	settrap

;set trap for conout
	lxi	h,jmpcout+1
	shld	biosav
	lxi	h,pentry
	shld	trapent
	lxi	h,coutdsp
	shld	biosdsp

	call	settrap

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;			set a trap			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

settrap	lhld	modbase		;get address of moved module
	push	h
	pop	b		;save in bc

	lhld	biosdsp		;get displace for bios jmptable into de
	push	h
	pop	d

;get contents of bios jumptable entry
	lhld	boot+1
	dad	d		;address bios jumptable entry
	inx	h
	push	h		;...save pointer to table entry

	mov	e,m		;...and get contents
	inx	h
	mov	d,m

;store bios entry into trap savearea
	lhld	biosav		;save bios contents into trap mod
	dad	b
	mov	m,e
	inx	h
	mov	m,d

;set bios entry to trap entry
	lhld	trapent		;get addr of appropriate trap into de
	dad	b
	xchg

	pop	h		;store trap addr in bios jmptab
	mov	m,e
	inx	h
	mov	m,d

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;		print messages				;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
signon	lxi	d,helpmes
	jmp	domess

ccperr	lxi	d,ccpmess

domess	mvi	c,pstr
	call	bdosjmp
	xra	a		;set zero flag (for ccperr return)
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;		move block of data			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;source in hl, destination in de, length in bc.

move	mov	a,b
	ora	c
	rz
	mov	a,m
	stax	d
	inx	d
	inx	h
	dcx	b
	jmp	move

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;		end of service routines			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	endif




*********************************************************
*********************************************************
*	beginning of movable module			*
*********************************************************
*********************************************************


	org	($+0ffh)/100h*100h	;must be page boundary
adjust	set	$

	if	copy1
module1	equ	$
	endif

	if	not copy1
module2	equ	$
	endif


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

address	equ	0ffffh		;various address to fill at runtime
on	equ	0		;do resecure
off	equ	0ffh
pflag	equ	on		;harden security as soon as loaded

pbase	equ	$-adjust
	jmp	address		;security base:  "address" set at run
				;time to jump to previous pbase

notiflg	equ	$-adjust
	db	notify		;yes/no for message at each ^C
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;maintrap:  perform setup if wboot (or trap just loaded)

pentry	equ	$-adjust
bootflg	equ	pentry+1
	mvi	a,pflag		;"on" for wboot
	cpi	on		;test for "on"
	cz	afterwb+adjust
jmpcout	equ	$-adjust
	jmp	address		;from bios conout jmptable entry
				;("address" set at runtime)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;pre-wboot action:  set flag
beforwb	equ	$-adjust
	mvi	a,on
	sta	bootflg+adjust
toboot	equ	$-adjust
	jmp	address		;on to wboot (address set at runtime)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;post-wboot action:  reset flag, restore security, rearm boot trap
afterwb	equ	$-adjust
	mvi	a,off
	sta	bootflg+adjust	;turn off flag

savbase	equ	$-adjust+1
	lxi	h,address	;restore secured address to 5h
	shld	6		;("address" filled at runtime)

;if display option set, notify that security still in effect
	lda	notiflg+adjust
	cpi	yes
	rnz

	push	b
	lxi	d,message+adjust ;notify of current pbase

display	equ	$-adjust
	ldax	d
	inx	d
	cpi	eom
	jz	dispend+adjust

	mov	c,a
	push	d
	call	jmpcout+adjust
	pop	d

	jmp	display+adjust


dispend	equ	$-adjust
	pop	b

	ret



;don't remove the message below; used to test if module already present

message	equ	$-adjust

;(number of blanks below is arbitrary)
	db	'                                            '
	db	'(Safram at '
messadr	equ	$-adjust
	db	'....)',cr,lf,eom

wb2mess	equ	message-beforwb		;distance from wboot trap
testlen	equ	messadr-message


*********************************************************
*		end of relocatable routines		*
*********************************************************

;get length of relocatable routines
length	equ	$-adjust

;flip the copy1/copy2 toggle
copy1	set	not copy1

;assemble address of end of this program
	if	copy1
progend	equ	$
	endif

;link a second copy, if this was the first copy
	if	not copy1
	link	safram
	endif

;Date: 22 Jun 1981 (Monday) 1041-PST
;From: Neil Maron
;To:   All
;Re:   A safe public USER 0 for .COM files patch for CP/M 2.2
;
;This patch includes CCPPATCH so that the system will look on
;drive A: if your .COM file isn't on the logged in drive.  In
;addition, it makes "USER 0" public.  I consider it safer than
;the "BDOS22.PAT" which makes "USER 0" public but also may have
;certain bad side effects.  This of course is tested and is up
;in my system.
;
;This is for CP/M 2.2 .
;
;Patchfile>>>
;
;N.Maron 19jun81
;Patch to look on A: for .COM file then look on USER 0
;or look on USER 0 if d: given explicitly in command.
;
msize	equ	54	   ;CP/M system size in kilobytes
;
;Set for your system
;
delta	equ	0000h	   ;offset from standard CP/M size (probably 0 in
			   ; your case
bias	equ	(msize-20)*1024-delta  ; offset from 20k CP/M
ccp	equ	3400h+bias
;
coa	equ	ccp+8ch    ;CCP console output routine from A
gtusr	equ	CCP+113h   ;CCP get user number routine
stusr	equ	CCP+115h   ;CCP set user number routine
ocpmfcb equ	ccp+0d0h   ;CCP open file @ cpmfcb$ routine
cpmtype$ equ	ccp+7d6h   ;type field in cpmfcb$
cmdsk$	equ	ccp+7f0h   ;loc of disk given in command
cmderr	equ	ccp+76bh   ;loc to type error in command
win	equ	ccp+6deh   ;go here if we get file open
;
patcharea equ	?????	   ;patch area in your CBIOS
			   ;(not in CCP or BDOS)
;
	org	ccp+6dbh
	jz	patch	   ;replace "jz cpm+76bh"=jz cmderr
;
	org	ccp+7f2h   ;replaces an unused area of NOP's
;
patch:	lxi	h,cmdsk$   ;get drive from current command
	ora	m	   ;A=0 on entry, so fetches drive
	jnz	patch1	   ;if explicit drive given go try USER 0
			   ;(this will be escape even if we force A:)
	inr	m	   ;force explicit reference to drive A
	lxi	d,cpmtype$ ;need DE set up to this on entry to CCP
	jmp	ccp+6cdh   ;now go reenter CCP
;
;This is the addition to the above patch
;
	org	patcharea  ;patch area in memory
;
;Arrive here because explicit drive set or can't find file on A:
;
patch1: call	gtusr	   ;get user code
	ora	a	   ;set flags
	jz	cmderr	   ;already user 0 so lose
	mov	e,a	   ;get old value into E for later
	push	d	   ;save it
	mvi	e,0	   ;set USER=0
	call	stusr
	call	ocpmfcb	   ;try open again
	pop	d	   ;get old user code back before we save flags
	push	psw	   ;now save flags from call
	call	stusr	   ;now go set back to old user number
	pop	psw	   ;get flags back from OPEN call
	jnz	win	   ;go to win if we won
	jmp	cmderr	   ;too bad we lose
;
	end
;
;<<<<End of patch file

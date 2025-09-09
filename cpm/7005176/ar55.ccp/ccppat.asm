; This patch causes the CCP of a cp/m 2.x system to look on drive A
; when you are logged into a drive other than A and call for a .COM
; file that does not exist on that drive.  Giving an explicit drive
; reference overrides this feature, so that you can always force
; the file to be loaded from a specific drive.
;
msize	equ	60		; set this to your nominal system size
;
cpmb	equ	(msize-20)*1024+3400h	; start of CCP in given sys size
;
	org	cpmb+6dbh
	jz	patch		; replaces "jz cpmb+76bh"
;
	org	cpmb+7f2h	; replaces an unused area of NOP's
patch:
	lxi	h,cpmb+7f0h	; get drive from current command
	ora	m		; accum was 0 on entry, so this fetches drive
	jnz	cpmb+76bh	; command has explicit drive...give error
	inr	m		; force explicit reference to drive A
	lxi	d,cpmb+7d6h	; we need de set up when we
	jmp	cpmb+6cdh	; re-enter ccp
;
	end

; 
;       INIT4TH Version 1.0 as of December 13, 1981
; 
;                By: Kelly Smith, CP/M-Net
; 
;      The purpose of INIT4TH,  came about from the flagrant 
; destruction  of Fig-Forth screens that were co-resident on 
; my CP/M diskettes...I would forget that the screens DO NOT 
; appear  in the CP/M directory,  and as such are  prone  to 
; eminent  destruction (due totally to my stupidity) by  the 
; CP/M "PIP" command.  What to do? Well, I also got tired of 
; clearing  out  screens  that  were  full  of  "e5's"  from 
; formatting,  and  decided  to  kill  two  birds  with  one 
; stone...
; 
;      INIT4TH  will  allow retention of all  relevant  CP/M 
; files (such as FORTH itself) on a CP/M and FORTH diskette, 
; initialize  all sectors NOT occupied by the resident  CP/M 
; files, and RESERVE all remaining sectors as available disk 
; area  for FORTH screens.  How is it  done?  Well,  INIT4TH 
; creats  one  "super  file"  called  RESERVED.4TH  that  is 
; nothing  but  blanks  (actually ASCII "space"  code)  that 
; aquires all CP/M groups remaining after the resident  CP/M 
; files...once    your   quasi   CP/M-FORTH   diskette    is 
; initialized,  it's  FULL  as far as CP/M is concerned  for 
; further PIPing,  and ready for whatever you want to  place 
; into  the  available  Fig-Forth screen  area  (my  version 
; starts  with a blank screen number 17,  up to  249).  It's 
; best,  if you PIP all the CP/M files to a blank  formatted 
; diskette first to make them contiguous on the diskette (no 
; "holes"),  and  then  run INIT4TH on it  to  "take-up-the-
; slack".
; 
;      But  WARNING...do  not  run this on a  diskette  that 
; already  has screens that you want to  preserve...this  is 
; ONLY  for diskette INITIALIZATION of FORTH  screens...copy 
; from  another  diskette as you normally do to  place  your 
; "treasured" screens on it.
; 
;      A  conditional assembly equate "SYS" is used to  make 
; RESERVED.4TH  invisible  in the directory (if you want  it 
; that way).
; 
;      I  hope this is of some use to you,  and if you  make 
; any  changes,  I  would appreciate it,  if you  modem  the 
; program to CP/M-Net (805) 527-9321 as INIT4TH.NEW...
; 
;      P.S.  I have learned many new WORDs using FORTH,  but 
; none are repeatable here...
; 
;                         Best regards: Kelly Smith CP/M-Net
;
;
;
; define TRUE/FALSE assembly parameters
;
true	equ	-1	; define TRUE
false	equ	not true; define FALSE
sys	equ	true	; define SYS (make RESERVED.4TH a $SYS file)
;
;
; BDOS entry point and function codes
; 
base	equ	0	; base address of "standard" CP/M system
bdos	equ	base+5	; CP/M BDOS entry address
msgfc	equ	9	; message function
resdsk	equ	13	; reset disk system
offc	equ	15	; open file
cffc	equ	16	; close file
wrfc	equ	21	; write record
mffc	equ	22	; make file
sdma	equ	26	; set dma address
; 
; secondary FCB field definitions
; 
fn	equ	1	; file name field (rel)
ft	equ	9	; file type field (rel)
ex	equ	12	; file extent field (rel)
frc	equ	15	; file record count (rel)
nr	equ	32	; next record field (rel)
; 
; ASCII control characters
; 
cr	equ	0dh	; carriage return
lf	equ	0ah	; line feed
bel	equ	07h	; bell signal
;
;
	org	base+100h
;
	lxi	h,0	; save old stack pointer
	dad	sp
	shld	oldstk
	lxi	sp,stack; make a new stack pointer
	lxi	d,initmsg	; Forth Screen initialization in progress
	mvi	c,msgfc
	call	bdos
	call	reset	; reset disk in case it's R/O
init4th:call	open	; attempt to open RESERVED.4TH
	inr	a	; check CP/M return code
	jnz	makeok	; RESERVED.4TH already exist?
	call	make	; make new file
	inr	a	; check CP/M return code
	jnz	makeok
	lxi	d,dirful; oops...disk directory is full
exit:	mvi	c,msgfc
	call	bdos
	lhld	oldstk	; get old CP/M stack pointer
	sphl
	ret
;
; RESERVED.4TH exists, so set the FCB entry for next append to file
;
makeok:		
;
	lxi	d,active; indicate disk activity with "."
	mvi	c,msgfc
	call	bdos
	call	setdma	; set dma for record to write
	call	write	; write it out...
	push	psw	; save possible error code
	lda	fcb+frc	; get record count
	sta	fcb+nr	; make next record
	pop	psw	; get possible error code
	ora	a	; disk full yet, all available records?
	jz	makeok	; do more records, if not
	call	close	; close-up shop, and go home
	lxi	d,dskful; Forth Screens are now initialized...
	jmp	exit	; exit to CP/M
; 
;  reset - reset disk
;
reset:		
	push	h
	push	d
	push	b
	mvi	c,resdsk
	call	bdos
	pop	b
	pop	d
	pop	h
	ret
; 
; open - open disk file
; 
open:		
	push	h
	push	d
	push	b
	lxi	d,fcb
	mvi	c,offc
	call	bdos
	pop	b
	pop	d
	pop	h
	ret
;
; setdma - set dma for record
;
setdma:
	push	h
	push	d
	push	b
	lxi	d,dbuf
	mvi	c,sdma
	call	bdos
	pop	b
	pop	d
	pop	h
	ret
;
; write - write record
;
write:
	push	h
	push	d
	push	b
	lxi	d,fcb
	mvi	c,wrfc
	call	bdos
	pop	b
	pop	d
	pop	h
	ret
; 
; close - close disk file
; 
close:		
	push	h
	push	d
	push	b
	lxi	d,fcb
	mvi	c,cffc
	call	bdos
	pop	b
	pop	d
	pop	h
	ret
; 
; make - make new disk file
; 
make:		
	push	h
	push	d
	push	b
	lxi	d,fcb
	mvi	c,mffc
	call	bdos
	pop	b
	pop	d
	pop	h
	ret
;

initmsg:db	cr,lf,'Forth Screen initialization in progress',cr,lf,'$'
;
active:	db	'.$'
;
dirful:	db	cr,lf,'Oops, this diskette is already full!$'
;
dskful:	db	cr,lf,lf,'Forth Screen initialization completed'

	if	SYS
	db	' as (RESERVED.4TH)$'
	endif		; SYS

	if	not SYS
	db	' as RESERVED.4TH$'
	endif		; SYS

;
fcb:	db	2	; initialize diskette in B: drive

	if	SYS
	db	'RESERVED4','T'+80H,'H'
	endif		; SYS

	if	not SYS
	db	'RESERVED4TH'
	endif		; SYS

	db	0,0,0,0,0,0,0,0,0,0
;
; data area
; 
	ds	128	; 64 level stack
stack	equ	$	;local stack
;
oldstk		
	ds	2	; storage for old CP/M stack pointer
;
dbuf:	db	'                '	; use blanks for initialization data
	db	'                '
	db	'                '
	db	'                '
	db	'                '
	db	'                '
	db	'                '
	db	'                '
;
	end

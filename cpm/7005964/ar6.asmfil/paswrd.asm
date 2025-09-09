;	title	'PASSWORD.ASM'
;	page	60
;
;
;		PASSWORD.ASM			Version 1.0
;	 By Bo McCormick       8/6/81
;
; This is a program that adds password protection
; to programs. Format:
;
; PASSWORD name_of_file
;
; Then answer the prompt with the password to be
; applied to the program:
;
; Password : enter password here
;
; If everything goes well, the program will be saved to disk.
; If not, a message is printed and control is passed
; to the CCP.
;
; The good part of this is, when you type in the program
; program name next time, instead of running the program
; right away, the program asks you for the password. If you
; reply with something other than the original password, the
; program doesn't run, and it returns to the ccp.
;
;
;EQUATES
mesout:	equ	9		;BDOS functions
incon:	equ	10
open:	equ	15
close:	equ	16
delete:	equ	19
read:	equ	20
write:	equ	21
setdma:	equ	26
;
cr	equ	0dh		;ascii values
lf	equ	0ah
eos	equ	'$'
;
boot	equ	0		;0 for standard CP/M
				;4200H for ALT. CP/M;
bdos	equ	boot+5
fcb	equ	boot+5ch
defbuf	equ	boot+80h
tpa	equ	boot+100h
stack	equ	tpa
;
	org	tpa

;
;
start:	lxi	h,0		;save stack pointer
	dad	sp		;put stack in hl
	shld	old$stack-offset	;save it
	lxi	sp,stack	;get new stack
;
; stack saved so program can return to CCP without
; intervening warm start.
;
	lda	fcb+9		;get first char of extension
	cpi	' '		;if ' ' then change to .COM
	jz	no$type
	cpi	'C'		;If there is an extension,
	jnz	not$right	;make sure it's .COM
	lda	fcb+10		;check second letter
	cpi	'O'		
	jnz	not$right
	lda	fcb+11
	cpi	'M'		;last letter
	jz	is$com		;if it is a COM, then cont.
not$right:
	call	end$mes		;it's not a com file, so tell
;
	db	cr,lf,'Must be a command (.COM) file'
	db	cr,lf,eos
;
end$mes:
	pop	d		;get address of message
	mvi	c,mesout	;PRINT STRING command
	call	bdos		;print error message
;
finish:	lhld	old$stack-offset ;get old stack
	sphl			;put it in HL
	ret			;return to CP/M
;
no$type	mvi	a,'C'		;if there was space, change
	sta	fcb+9		;to COM
	mvi	a,'O'
	sta	fcb+10
	mvi	a,'M'
	sta	fcb+11
;
is$com	mvi	a,0		;zero record count
	sta	fcb+32
	mvi	c,open		;OPEN file command
	lxi	d,fcb		;load address of FCB in DE
	call	bdos		;Open file
	inr	a		;successful?
	jnz	open$ok		;if so, then continue
	call	end$mes		;if not, then tell
;
	db	cr,lf,'Cannot open file',cr,lf,eos
;
open$ok	lxi	d,buffer-offset	;point to where program goes
r$loop:	mvi	c,setdma	;SET DMA command
	push	d		;save it
	call	bdos		;and tell CP/M
	lxi	d,fcb		;point to FCB
	mvi	c,read		;READ sector command
	call	bdos		;do it
	pop	d		;get DMA address back
	ana	a		;EOF?
	jnz	done$read	;if so, then ask for password
	lxi	h,80h		;length of sector
	dad	d		;bump DMA
	xchg			;put new address in DE
	jmp	r$loop		;and read some more
;
done$read:
	xchg			;dma ==> hl
	shld	end$prog-offset	;save last address
gpasag	call	get$pas		;print password message
;
pas$mes	db	'Password: ',eos
;
get$pas	pop	d		;get address of message
	mvi	c,mesout	;PRINT STRING function
	call	bdos		;print it
	lxi	d,defbuf	;point to default buffer
	mvi	a,8		;tell CP/M max chars
	stax	d		;put it there
	mvi	c,incon		;READ LINE command
	call	bdos		;do it
	lxi	h,defbuf+1	;point to length
	lxi	d,password-offset	;point to storage
	lda	defbuf+1	;get length
	ana	a		;set flags
	jz	gpasag		;if 0 then ask again
	inr	a		;plus 1 for length byte
	mov	b,a		;put length in B
mploop	mov	a,m		;get char
	stax	d		;save it
	inx	h		;increment pointer
	inx	d		;  "          "
	dcr	b		;decrement length
	jnz	mploop		;if not zero, then next char
	xra	a		;zero a
	sta	fcb+12		;zero bytes in FCB
	sta	fcb+14
	sta	fcb+32
	mvi	c,open		;OPEN file command
	lxi	d,fcb		;point to FCB
	call	bdos		;open the file
	lxi	d,n$start	;point to new program start
;
	push	d
w$loop1	pop	d		;get DMA
	push	d		;put it back on stack
	mvi	c,setdma	;SET DMA command
	call	bdos		;tell CP/M
	lxi	d,fcb		;point to FCB
	mvi	c,write		;WRITE SECTOR command
	call	bdos		;do it
	pop	h		;get DMA address from stack
	lxi	d,80h		;length of sector
	dad	d		;HL has new DMA
	push	h		;put it on stack
	mov	a,h		;this is to get 2's complement
	cma			;of address. We are subtracting
	mov	d,a		;the current address from the
	mov	a,l		;high address. If the high byte
	cma			;<1 , we are done
	mov	e,a		;
	inx	d		;Now 2's comp. of address in DE
	lhld	end$prog-offset	;get ending address
	dad	d		;Subtract (add 2's comp)
	mov	a,h		;get high byte
	inr	a		;is it FF (-1)?		
	ana	a		;set flags
	jnz	w$loop1		;if not, write another sector
;
	mvi	c,close		;That's it. Close the file
	lxi	d,fcb		;point to FCB
	call	bdos		;do it
	jmp	finish		;goto finish
;
;
n$start:
offset	equ	100h-n$start
;
;	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	%% WARNING -                                        %%
;	%% From now on, all labels are in                   %%
;	%% the form:                                        %%
;	%%      LABEL   EQU  $+OFFSET                       %%
;	%%  This is to allow the program to run at100H      %%
;	%% when it is saved by the earlier portion.         %%
;	%%  ALL new labels added MUST be in the form        %%
;	%% LABEL   EQU  $+OFFSET for this program to work   %%
;	%% properly.                                        %%
;	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;This is portion of the program is placed at the beginning
;of the program to be PASSWORDed. When it is executed, it will
;ask for a password. If the password is incorrect, the program
;warm starts. If the password is correct, the program is moved
;to the TPA and executed.
;
	lxi	h,0		;save stack pointer
	dad	sp		;stack is in HL
	shld	old$stack	;save it
	lxi	sp,stack	;get new stack
	call	ot$pw		;print password message
;
	db	cr,lf,'Password :'
	db	eos
;
ot$pw	equ	$+offset
	pop	d		;get address of message
	mvi	c,mesout	;PRINT STRING command
	call	bdos		;print it
	lxi	d,newbuf	;point to input buffer
	mvi	c,incon		;READ LINE command
	call	bdos		;read it
;
	lxi	h,password	;point to actual password
	lxi	d,newbuf+1	;point to user's input
	mov	b,m		;get length
;
c$lp	equ	$+offset
	ldax	d		;get char
	cmp	m		;are they the same?
	jnz	boot		;if not, restart
	inx	h		;point to next characters
	inx	d		;  "    "  "        "
	dcr	b		;decrement length
	jnz	c$lp		;if not done, then loop
;
; Now we move a segment of code to a part of the default
; buffer. This segment moves the actual program down to the
; TPA
;
	lxi	h,n$mv		;point to code
	lxi	d,defbuf+20h	;point to new postion
	mvi	b,n$m$len	;length
;
move	equ	$+offset
	mov	a,m		;get byte
	stax	d		;save it
	inx	d		;point to next addresses
	inx	h		;  "   "    "      "
	dcr	b		;decrement length
	jnz	move		;if not done, loop
	jmp	defbuf+20h	;go to segment
;
n$mv	equ	$+offset	;segment that gets moved
	lhld	old$stack	;get stack pointer
	push	h		;save it on stack
	lxi	h,buffer	;get start of actual program
	mov	a,h		;We have to compute the length
	cma			;and because X-Y equals
	mov	d,a		;X + Two's complent(Y), we have
	mov	a,l		;to find the 2's comp. of the
	cma			;first address
	mov	e,a		;
	inx	d		;Y is in DE
	lhld	end$prog	;get last address
	dad	d		;subtract (add 2's comp)
	mov	b,h		;put length in BC
	mov	c,l		; "    "     "  "
	lxi	d,tpa		;point to TPA
	lxi	h,buffer	;point to first address
n$m$lp	equ	defbuf+20h+$+offset-n$mv
	mov	a,m		;get byte
	stax	d		;save byte
	inx	h		;increment address
	inx	d		;    "        "
	dcx	b		;decrement length
	mov	a,b		;check for zero left
	ora	c		;Are we done?
	jnz	n$m$lp		;if not, loop some more
	pop	h		;get stack from stack
	sphl			;put stack in SP
	jmp	tpa		;run program
;
n$m$len	equ	$+offset-n$mv	;length of segment
;
;
password	equ	$+offset ;password storage
	db	0,'         '
;
newbuf	equ	$+offset	;Users input buffer
	db	10H,0,'                '
;
old$stack	equ	$+offset ;place for stack
	ds	2
;
end$prog	equ	$+offset ;place for address
	ds	2
;
buffer	equ	$+offset	;where actual program goes
	end

;
;		formham.asm
;		by roderick w. hart wa3mez
;		october 9, 1981
;
; this routine is called to convert a character into a code that
; permits double bit error detection and single bit error correct-
; ion. the process used is well know to data communication engineers
; as hamming code error correction and detection.
;
; if errors occur randomly and independently, and if the pro-
; bability of a single error occurring is p, then the probability
; of a double error is p^2, and the probability of a triple error
; is p^3. if you assume that the probability of a single error is
; 1/10,000, then the probability of a double error would be 1/100,
; 000,000, and the probability of a triple error would be 1/1,000,
; 000,000,000. as you can see the user has to make a decision at
; some point as to the value of correction and detection overhead.
; the procedure used in this routine will cause a file to double
; its size, therefore it will not be of much value on high quality
; circuits. it is anticipated that the use of hamming code will be
; most efficient on high speed radio circuit where the transfer
; media tends to vary causing distortion that could result in dropped
; bits.
;
;
;***************************************************************
;	entry
;	a = character
;
;	exit
;	d = hamming code for most significant 4 bits of character
;	e = hamming code for least significant 4 bits of character
;***************************************************************
;
;
makcode:xra	a
	sta	word		;make sure everything is zeroed
	sta	store
	push	psw		;save character for now
	ani	0fh		;mask 4 least significant bits
	sta	word		;store temporarily
	pop	psw		;get character
	rar			;...shift
	rar			;......4
	rar			;.........places
	rar			;............to right
	ani	0fh		;mask 4 least significant bits
	call	adjbyte		;adjust data and check bits
	call	ckbits		;create most significant bit hamming code
	mov	d,a		;store in d
	lda	word		;get least significant bits
	call	adjbyte		;adjust data and check bits
	call	ckbits		;create least significant bit hamming code
	mov	e,a		;store in e
	ret
;
;
adjbyte:push	psw		;store bits temporarily
	ani	8h		;check bit 3
	jnz	seta		;if = 1 goto seta
	pop	psw		;otherwise retrieve bits
	ani	7h		;mask 3 least significant bits
	ret
;
;
seta:	pop	psw		;retrieve bits
	ani	7h		;mask 3 least significant bits
	ori	10h		;set bit 4 = 1
	ret			;return with bit 4 = 1 and bit 3 = 0
;
;
ckbits: sta	store
	ani	15h		;test bits 0,2, and 3
	cpe	setx1		;set check bit 1 if even parity
	lda	store
	ani	13h		;test bits 0,1, and 3
	cpe	setx2		;set check bit 2 if even parity
	lda	store
	ani	07h		;test bits 0,1, and 2
	cpe	setx4		;set check bit 4 if even parity
	lda	store
	ani	7fh		;test bits 0,1,2,3,4,5, and 6
	cpe	setm		;set m bit if even parity
	ret
;
;
setx1:	lda	store
	ori	40h		;set check bit 1
	sta	store
	ret
;
setx2:	lda	store
	ori	20h		;set check bit 2
	sta	store
	ret
;
setx4:	lda	store
	ori	8h		;set check bit 4
	sta	store
 	ret
;
setm:	lda	store
	ori	80h		;set m bit
	sta	store
	ret
;
;
word	dw	1
store	dw	1




	end

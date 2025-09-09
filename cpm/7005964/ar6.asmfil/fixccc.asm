
;
; Modified 8-13-81 changed setnm to correct wild card expansion
;****************************************************************
;****************************************************************
;************* Be sure to change addresses in bds.lib ***********
;*************** if you change ccc.asm   ---CAF *****************
;****************************************************************
;****************************************************************
;modified segment in ccc.asm to allow wild cards to work right
setnm:	push b
	ldax d
	cpi '*'		;wild card?
	mvi a,'?'	;if so, pad with ? characters
	jnz setnm2
	inx d	;bump past nathan so *.c doesn't mean *.*
	jp pad2

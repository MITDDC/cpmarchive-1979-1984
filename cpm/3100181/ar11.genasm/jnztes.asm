;
; Test of alleged bug in DCON and DDT 
; where JZ and JNZ supposedly trace
; incorrectly.	Result: no bug found.
;   05/28/82 and 05/29/82  (Ron Fowler)
;	|	   |
;	|	   |
;	|	    ---> lowercase
;	 --------------> uppercase
;
	ORG	100H
;
;
;		TEST				   |	 RESULT
;		----				   |	 ------
;						   |
LOOP:	ORI	1		;RESET Z	   |
	JNZ	NOZ1		;TEST JNZ--------->| went to noz1, as expected
	JZ	YESZ1		;TEST JZ---------->| never got here
;						   |
; CAN'T GET HERE FROM UP THERE                     |
; (from noz1 or yesz1 only)			   |
;						   |
STEP2:	XRA	A		;SET Z		   |
	JNZ	NOZ2		;TEST JNZ--------->| didn't jump, as expected
	JZ	YESZ2		;----------------->| went to yesz2, expected
;						   |
; CAN'T GET HERE FROM UP THERE                     |
;						   |
step3:	mvi	b,8		;do a subtraction  |
	mvi	a,8		;that =0	   |
	sub	b		;		   |
	jnz	noz3		;----------------->| didn't jump here, expected
	jz	yesz3		;----------------->| jumped here as expected
;						   |
; ditto here from there 			   |
;						   |
step4:	mvi	b,8		;do subtraction    |
	mvi	a,9		;  that's nz       |
	sub	b		;		   |
	jnz	noz4		;----------------->| jumped here, as expected
	jz	yesz4		;----------------->| never got here, expected

;
; can't be here
;
	jmp	loop		;but do something anyway
;
; Turnaround here, and proceed to next step
;
NOZ1:	JMP	STEP2
YESZ1:	JMP	STEP2
;
NOZ2:	JMP	step3		;new further testing
YESZ2:	JMP	step3
;
noz3:	jmp	step4		;one more test
yesz3:	jmp	step4
;
noz4:	jmp	loop		;repeat entire test
yesz4:	jmp	loop
;
	end

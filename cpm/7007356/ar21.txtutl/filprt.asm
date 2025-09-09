;
;	FILPRINT.ASM as of 7/29/80
;	 by Keith Petersen, W8SDZ
;
;	(for CP/M 2.x only)
;This program will print any ASCII file made with
;a CP/M editor.  The file must contain no tabs, and
;must end with a single $ character.  When you make
;the file with the editor, start it with one line
;of 80 spaces.  Then after you end the edit, DDT
;the file and patch it with FILPRINT.HEX (with no
;offset).  Save the patched file as a .COM file.
;
;
	ORG	100H
;
BEGIN:	LXI	H,STRING
;
LOOP:	MOV	A,M	;GET CHARACTER
	CPI	'$'	;ENDING CHAR?
	RZ		;RETURN TO CP/M
	CALL	OUTPUT	;OUTPUT CHAR & GET ANY INPUT
	CPI	'C'-40H	;CONTROL-C?
	RZ		;RETURN TO CP/M
	INX	H	;POINT TO NEXT CHAR
	JMP	LOOP	;GET ANOTHER CHAR
;
OUTPUT:	MOV	E,A	;CHAR TO E FOR CP/M
	MVI	C,6	;CP/M-2 DIRECT OUTPUT FUNCTION
	CALL	DOFUNC	;DO IT
	MVI	E,0FFH
	MVI	C,6	;DIRECT INPUT WITH NO ECHO
	CALL	DOFUNC	;DO IT
	ORA	A
	RZ		;NOTHING TYPED
	CPI	'S'-40H	;CONTROL-S?
	RNZ
WAIT:	MVI	E,0FFH
	MVI	C,6
	CALL	DOFUNC
	ORA	A
	JZ	WAIT
	RET
;
DOFUNC:	PUSH	H
	CALL	5
	POP	H
	RET
;
STRING:	DB	'CTL-S pauses, CTL-C aborts'
	DB	0DH,0AH
;
	END

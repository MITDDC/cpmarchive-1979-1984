; ZCPR contains two minor but inconvenient bugs in the TYPE command.
; 1. Non-printing control codes increment the column count though
;    the cursor column on the console hasn't moved.  Also stray line
;    feeds (<LF> with no <CR>) reset the column count when in fact
;    only a line feed has been printed and the cursor is still
;    (one would hope) in the same column on the console.  In either
;    case all further TAB expansion untill the next <CR> will be
;    incorrect.
; 2. When TYPE pauses (in the page mode) waiting a key from the
;    terminal, the key when pressed will be echoed to the console
;    display before the file resumes typing.  This charecter isn't
;    counted in the column count so not only does it mess up the
;    screen bye echoing, it also causes the tab expansion to be off
;    untill the next <CR>.  This is not a problem if the charecter
;    typed to resume a paused output is a non-printing control code
;    or a <CR>.  (for thoes of us who like <space-bar> for --More--
;    I offer the following patches.)
;
;		Comments to: GRUPP@MIT-MC
;    
;--------------------------------------------------------------
;The following code should be added in section 3 after
;the CONIN: sub-routine.
;
NOECHO:
	PUSH	D	;Get char from CON: with no echo
	MVI	C,6	;Set up for direct CON I/O
	MVI	E,0FFH	;
	CALL	BDOSB
	POP	D
	CPI	0	;Con stat, 0 = no char
	JRZ	NOECHO	;Loop till we get a char
	RET
;
;--------------------------------------------------------------
;In Section 5D (TYPE Command) the code from:
; "OUTPUT CHAR TO CON: OR LST: DEVICE WITH TABULATION" to:
; "CONTINUE PROCESSING" should be replaced with the following;
;
;
; OUTPUT CHAR TO CON: OR LST: DEVICE WITH TABULATION
;
	CPI	CR		;Is char <CR> ?
	JRNZ	NOCR		;No
	MVI	B,0		;Yes... reset tab count.
NOCR:
	CPI	' '		;Is char control code ?
	JRC	NOPRT		;Yes... non printing don't bump count
	INR	B		;else increment char count
NOPRT:
	CPI	TAB		;Tab ?
	JRZ	LTAB		;Yes... expand.
	CALL	LCOUT		;Output char (or control char)
	JR	TYPE2L
LTAB:
	MVI	A,' '		;<SP>
	CALL	LCOUT
	INR	B		;Incr col count
	MOV	A,B
	ANI	7
	JRNZ	LTAB
;
; CONTINUE PROCESSING
;
;--------------------------------------------------------------
;The marked change should be made in the PGFLG: routine. ---------------|
;									|
;									|
PGFLG	EQU	$+1		;POINTER TO IN-THE-CODE BUFFER PGFLG	|
	MVI	A,0		;0 MAY BE CHANGED BY PGFLG EQUATE	|
	CPI	PGDFLG		;PAGE DEFAULT OVERRIDE OPTION WANTED?	|
;									|
	IF	PGDFLT		;IF PAGING IS DEFAULT			|
	JRZ	PGBAK		;  PGDFLG MEANS NO PAGING, PLEASE	|
	ELSE			;IF PAGING NOT DEFAULT			|
	JRNZ	PGBAK		;  PGDFLG MEANS PLEASE PAGINATE		|
	ENDIF								|
;									|
	CALL	NOECHO		;get char to continue... but,	<<<-----|
				;DON'T mess up screen with it.	<<<-----|
	CPI	'C'-'@' 	;^C
	JZ	RSTCPR		;RESTART CPR
;
;
;--------------------------------------------------------------

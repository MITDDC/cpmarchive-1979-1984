;**********************************************************
;
;		USRDFLT.CCP by R. L. Plouffe
;		     (703) 527-3215
;		      May 26, 1981
;
;		For CP/M 2.x systems only.
;
;These routines are based on ideas and code found on the
;CALAMITY CLIFFS machine. Authors are apparently Ron Fowler
;and Keith Peterson.  What is done here is to integrate these
;ideas and to add an important new feature which causes CCP
;commands as well as pseudo CCP/transients to be either public
;or private. Also, I have added a patch that allows pseudo
;CCP/transients to be called and executed from any USER area
;and any drive without having to place multiple copies in
;various USER areas.

;Add this code to your customized user or bios file and the
;CCP patches will be automatically overlayed when you put it
;in with DDT provided that your file contains an equate for
;the CCP beginning address for your system size. NOTE that the
;command address table and the command strings have been taken
;out of the CCP. However the code space that they occupied has
;been well stuffed with other patch code.
;
;Donated for the benefit of hobby computing. This creation
;may not be sold.
;
CCP	EQU	YOUR CCP ADDRESS	;BASE OF CCP
;
BDOS	EQU	CCP+800H		;BASE OF BDOS
BIOS	EQU	CCP+1600H
DFCB	EQU	5CH
MAXUSER	EQU	4			;FOR EXAMPLE
DRIVE	EQU	0004H			;LOC OF CURRENT DRIVE BYTE
CR	EQU	0DH
LF	EQU	0AH
;
;
; BEGINNING OF CODE THAT IS PATCHED INTO THE CCP.
;
;**********************************************************
; This patch is used to restrict access to the higher user
; areas while leaving the lower user areas public. The high-
; est available public user area is defined by MAXUSER.
;
	ORG	CCP+117H
	JMP	MAXUSR
	;the routine is contained in the USER area of your
	;customized BIOS
;**********************************************************
; This patch causes user number to be reported at the cp/m
; prompt.....i.e. - A2>.  User 0 report is suppressed.
;
	ORG	CCP+390H
	MVI	C,32
	CALL	UPATCH
	;the routine UPATCH is located in the USER area of
	;your customized BIOS.
;**********************************************************
; This patch causes the CCP of a cp/m 2.x system to look on
; drive A when you are logged into a drive other than A and
; call for a .COM file that does not exist on that drive.
; Giving an explicit drive reference overrides this feature,
; so that you can always force the file to be loaded from a
; specific drive.
;
	ORG	CCP+6DBH
	JZ	PATCH		;REPLACES "JZ CCP+76BH"
;
	ORG	CCP+7F2H
PATCH:	LXI	H,CCP+7F0H	;GET DRIVE FROM CURRENT CMD.
	ORA	M		;FETCHES DRIVE
	JNZ	CCP+76BH	;GIVE ERROR IF CMD HAS DRIVE #
	INR	M		;FORCE TO DRIVE A
	LXI	D,CCP+7D6H	;UNDO WHEN...
	JMP	CCP+6CDH	;REENTERING CCP
;
;**********************************************************
;This patch extends the CCP to include up to N additional
;commands that are user defined.
;
	ORG	CCP+3B5H
CMDPTR:	DW	CMDTBL2		;COMMAND TABLE
	;
	ORG	CCP+32FH
STRPTR:	DW	CMDSTR2		;COMMAND STRING
	;
	ORG	CCP+335H
MAXCCP:	DB	(RETCON-CMDTBL2)/2 ;TO LIMIT PUBLIC ACCESS TO CCP
				   ;COMMANDS. RESET TO ALL WHEN 
				   ;PASSWORD IS ENTERED FOR USER
				   ;AREAS ABOVE MAXUSER.
;THE REST OF THE PATCH IS IN CUSTOMIZED BIOS AREA
;
;**********************************************************
;This is the routine that cause those utilities which are in
;the CCP command table to be available from all user areas.
;They must be resident in USER 0 or 15 and named the same as in 
;command string....i.e, 'EDIT' for 'WORDSTAR',  'STAT' for 'STAT',
;etc.. The names and addresses can be in either the public or
;private areas. Don't expand this code except to use indicated
;spare bytes because you will wipe out other good code if you
;do.
;
	ORG	CCP+3C1H
TRDFLT0:
	MVI	E,0
	PUSH	D		;SAVE IT ON THE STACK
	JMP	DFLT
	ORG	CCP+310H
TRDFLT15:
	MVI	E,15
	PUSH	D		;SAVE IT ON THE STACK
DFLT:	
	CALL	CCP+113H	;GET CALLING USER CODE
	STA	HOLDUSER
	POP	D		;SET TO DEFAULT USER
	CALL	CCP+115H	;DO IT
	LXI	H,RSTUSR	;RSTUSR is located in USER2
	SHLD	CCP+75DH
	JMP	CCP+6A5H	;GET THE FILE TO THE TPA
	DB	0,0		;SPARE BYTES
;
	ORG	CCP+3C7H
RSTUSR:	LDA	HOLDUSER
	MOV	E,A
	JMP	BRIDGE
HOLDUSER:
	DB	0
	ORG	BDOS+0DEEH	;SPARE BYTES HERE IN BDOS
BRIDGE:	CALL	CCP+115H	;SET USER #
	LXI	H,100H
	SHLD	CCP+75DH
	CALL	100H
	JMP	CCP+75FH
	DB	0,0,0		;SPARES
;
; END OF CODE THAT IS PATCHED INTO THE CCP.
;
;*********************************************************
;*********************************************************
;							 *
;	PUT THE CODE FROM HERE TO THE END IN YOUR	 *
;	CUSTOMIZED BIOS.  SEE GENESYS AND GENEUSER	 *
;	FOR A TECHNIQUE TO EXPAND YOUR USER AREA.	 *
;							 *
;**********************************************************
;**********************************************************
;This patch which is called fron the CCP provides for a
;report of USER number at the prompt....i.e. A2> for USER 2,
;'A' drive.
;
;	ORG	BIOS+WHATEVER
UPATCH:
	LDA	PASSFLG
	INR	A
	JNZ	UPATCH1
	LXI	H,CMDSTR1
	SHLD	STRPTR
	LXI	H,CMDTBL1
	SHLD	CMDPTR
	MVI	A,(RETCON-CMDTBL1)/2
	STA	MAXCCP
UPATCH1:
	MVI	E,0FFH
	CALL	BDOS+6H		;GET USER NUMBER
	ANI	0FH		;KILL UNWANTED BITS
	JZ	UPA2		;IF USER 0, DON'T REPORT
	CPI	10
	JC	UPA1		;JIF USER NUM = 0 THRU 9
	SUI	10		;USER NUM = 10 THRU 15
	PUSH	PSW
	MVI	E,'1'
	MVI	C,2
	CALL	BDOS+6H		;PRINT A '1'
	POP	PSW
;
UPA1:	ADI	'0'
	MOV	E,A
	MVI	C,2
	CALL	BDOS+6H		;PRINT DIGIT
;
UPA2:	MVI	E,'>'
	MVI	C,2
	JMP	BDOS+6H		;PRINT '>', EXIT
;
;**********************************************************
;This patch which is branched to from the CCP provides for
;restricting access to USER areas above 'MAXUSER' by requiring
;a password to be entered. Password flag is reset upon cold
;boot.
;
MAXUSR:	MOV	A,E
	CPI	0FFH
	JZ	BDOS+6H
	LDA	PASSFLG
	INR	A
	JZ	NMDONE1
	LXI	H,DFCB+1	;POINT TO ORIGINATING USER#
				;IN COMMAND LINE
NUMLUP:	MOV	A,M		;GET CHARACTER
	INX	H		;BUMP CHAR POINTER
	SUI	'0'		;REMOVE ASCII BIAS
	JC	NUMDONE
	CPI	10		;CHECK IF PAST 9
	JNC	NUMDONE		;ANY VALID CHAR ENDS NUMBER
	MOV	D,A		;
	MOV	A,E		;GET ACCUMULATED NUMBER
	ADD	A		;X2
	ADD	A		;X4
	ADD	E		;X5
	ADD	A		;A10
	ADD	D		;PLUS NEW DIGIT
	MOV	E,A		;SAVE ACCUMULATION
	JMP	NUMLUP		;GET NEXT CHAR
NUMDONE:
	MOV	A,E		;GET ACCUMULATED NUMBER
	ORA	A		;BELOW 0 OR ABOVE 127?
	JM	HUH		;INVALID CHAR ENTERED
	CPI	MAXUSER+1	
	JNC	HUH		;RESTRICT ACCESS
NMDONE1:
	MOV	A,E
	RLC
	RLC
	RLC
	RLC			;MOVE TO UPPER NIBBLE
	MOV	B,A		;SAVE REQUESTED USER NUMBER
	LDA	DRIVE		;GET CURRENT USER/DRIVE
	ANI	0FH		;STRIP OFF OLD USER #
	ORA	B		;GET NEW USER NUMBER
	STA	DRIVE		;SET NEW USER NUMBER
	JMP	BDOS+6H		;SET IT AND EXIT
;
;**********************************************************
;This is the password routine which is entered by typing
;the PASS command from the CCP.  If password is entered
;correctly, then user has access to all user areas including
;those above MAXUSER and also has access to all private CCP
;commands as weel as private transients.
;
PASSFLG:
	DB	0		;STORE FOR PASSWORD FLAG
PASS:	LDA	PASSFLG
	INR	A
	JZ	PASSED	
	LXI	D,PSWDMSG	
	CALL	PRNSTR		;PRINT AND GET PASSWD
PASSINP:
	LXI	H,PASSWD	;POINT TO PASSWORD
	MVI	E,0		;NO MISSED LETTERS
PWMLP:	PUSH	D
	PUSH	H
PWMLP1:	MVI	C,6		;GET A CHAR
	MVI	E,0FFH
	CALL	BDOS+6H
	ORA	A
	JZ	PWMLP1
	POP	H
	POP	D
	CPI	60H		;LOWER CASE?
	JC	NOTLC		;NO,
	ANI	5FH		;MAKE UPPER CASE
NOTLC:
	CMP	M		;MATCH PASSWORD?
	JZ	PWMAT		;..YES
	MVI	E,1		;..NO, SHOW MISS
	CPI	CR
	JNZ	PWMLP		;..NO, WAIT FOR C/R
HUH:	JMP	CCP+382H		;RETURN TO CCP
;
PWMAT:
	INX	H
	CPI	CR
	JNZ	PWMLP
	MOV	A,E
	ORA	A
	JNZ	HUH
	MVI	A,0FFH
	STA	PASSFLG
PASSED:	LXI	D,OKMSG
	CALL	PRNSTR
	JMP	CCP+382H
;
PRNSTR:	MVI	C,9
	JMP	BDOS+6H
;
PSWDMSG:
	DB	CR,LF,'Password: $'
;
PASSWD:
	DB	'URPASSWRD',CR
;
OKMSG:
	DB	CR,LF,'OK$'
;
;**********************************************************
;This is the command string which is divided into private
;and public sections. Use exactly three letters and a space
;or exactly four letters to name a command.  Transient commands
;must be named exactly the same on your A drive.
;
CMDSTR1:
	DB	'ERA REN SAVESTATPIP DDT ASM LOADCOPYEDIT'
CMDSTR2:
	DB	'SRD DIR TYPEUSERPASSMDM BYE CRCK'
;
;**********************************************************
;This is the command address table which is divided into
;private and public areas. The address of the routine to
;be jumped to must be here for any CCP included code as well
;as any that you add and put in your customized BIOS. For
;private and public transients use TRDFLT15 and TRDFLT0
;respectively and put private transients in USER 15 on your
;system disk (drive A)--similarly put public transients in
;USER 0 on 'A'.  These transients will now be available from
;any drive and from any USER number depending on password
;privilege.  You can expand the table to any extent that you
;have space and the command string above must be expanded
;in synchronism.
;
;Put the private transients in USER 15
CMDTBL1:
	DW	CCP+51FH	;ERA....PRIVATE COMMANDS
	DW	CCP+610H	;REN
	DW	CCP+5ADH	;SAVE
	DW	TRDFLT15	;STAT...THE FOLLOWING UTILITIES
	DW	TRDFLT15	;PIP....WILL BE TREATED AS CCP
	DW	TRDFLT15	;DDT....COMMANDS. THEY MUST BE ON
	DW	TRDFLT15	;ASM....DISK AS TRANSIENTS AT USER 15
	DW	TRDFLT15	;LOAD...AND WILL NOW BE AVAILABLE AT
	DW	TRDFLT15	;COPY...ALL USER #'S
	DW	TRDFLT15	;EDIT (RENAME WORDSTAR TO EDIT)
;Put the public transients below in USER 0
CMDTBL2:
	DW	TRDFLT0		;SRD ....PUBLIC COMMANDS
	DW	CCP+477H	;DIR
	DW	CCP+55DH	;TYPE
	DW	CCP+68EH	;USER
	DW	PASS		;PASS(WORD)
	DW	TRDFLT0		;MDM  for MODEM program
	DW	TRDFLT0		;BYE  for Ward's BYE program
	DW	TRDFLT0		;CRCK does a CRC 16 check on file
RETCON:
	DW	CCP+6A5H	;RETURN TO CONSOLE (MUST BE LAST)
;
	END
;	for now	


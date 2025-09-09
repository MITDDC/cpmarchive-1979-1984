;COMMO2 was started on 08/05/81 by John C. Gilbert
;It is an adaptation of the program MAKESUB.ASM that
;is designed to take the output of a CBASIC program
;named COMMO1.INT & transform it into a file $$$.SUB
;that will execute batch transfers between modems
;
;To use the system, you should have the following programs online:
;
;     A tailored version of MTN22A.COM
;     SENDOUT.COM
;     FMAP or a text editor
;     XMODEM.COM
;     MODEM.COM
;
;It works in the following way:
;
;     Step  1  - Form a file named NAMES.SUB of the  files  to  be 
;          moved.  I  use  FMAP B:(param) F to form mine from  the 
;          directory.  It  automatically  creates a file  of  this 
;          name. the param if of the form FN.FT with wild cards.
;
;     Step 2 - Execute RUN COMMO1.  Basically it is setup to  send 
;          from  your  end at 600 baud.  Either parameter  can  be 
;          altered in the call; e.g. you can say 300 R and it will 
;          receive  the files from the other end at 300 baud or to 
;          send at 300,  just 300 will do it.  The program reallys 
;          sets up dummy files in the form expected by SUBMIT, but 
;          because  they are written in CBASIC,  the output  comes 
;          out surrounded by quotes.
;
;     Step 3  - Use MTN to establish the basic commo  link.  There 
;          might be some neat way to do it,  but I just move a one 
;          block file using XMODEM & MODEM.
;
;     Step 4 - Execute COMMO2.  It reads the output of COMMO1  and 
;          creates  a  file of the form $$$.SUB.  In fact,  it  is 
;          built  on  the framework of  MAKESUB.ASM.  When  it  is 
;          finished,  CP/M  is  faked  and  begins  executing  the 
;          transfers.
;
;A couple of comments. It executes from the A-disk, but expects to 
;move all files to and from the B-disk.  COMMO1 creates an interim 
;file  NAMES.$$$,  but both programs clean up after themselves  so 
;both  files;  NAMES.SAV  &  NAMES.$$$ should be gone when  it  is 
;finished.
;
;         
CR	EQU	0DH	;CARRIAGE RETURN
LF	EQU	0AH	;LINE FEED
DRNAME:	EQU	4	; ADDRS. WHERE DRIVE IS
BDOS:	EQU	5	;ENTRY TO OPER. SYS.
FCB	EQU	5CH	;DEFAULT FCB
FCBEX:	EQU 	FCB+12
FCBNR:	EQU 	FCB+32	;NEXT REC NO.
BUFF	EQU	80H	;CP/M DEFAULT BUFFER
NAMLEN	EQU	BUFF+1	;LGTH OF ITEM IS IN 2ND CHR.
MAKE	EQU	22
WRITE	EQU	21
READF	EQU	20	;DISK READ FUNCTION
CLOSE	EQU	16
OPENF	EQU	15	;FILE OPEN
DELETF	EQU	19	;FILE DELETE
INITF	EQU	13	;INITIALIZE, SELECT 'A'
;
	ORG	100H
;
START:	LXI	H,0
	DAD	SP	 ;GET OLD STACK POINTER
	SHLD	STACK	 ;SAVE IT
	LXI	SP,STACK ;SET NEW STACK POINTER
;
	MVI	C,INITF	;INITIALIZE SET DMA
	CALL	BDOS;	;& A-DISK
;
	LXI	H,FILNAM ;POINT TO FILENAME
	LXI	D,FCB	;POINT TO FCB
	MVI	B,13	 ;LENGTH OF FILENAME
	CALL	MOVER	;MOVE IT TO FCB
;
;	GO MAKE THE FILE
;
	XRA	A
	STA	FCBNR	;SET RECORD NUMBER TO ZERO
	LXI	D,FCB	;POINT TO NAME
	MVI	C,MAKE	;MAKE FILE
	CALL	BDOS
;
;	GET THE DATA TO WRITE ON FILE
;
	CALL	SETUP	;Initialize file, set FCBCR to 0
AGAIN:	CALL	DISKR	;GET A RECORD FROM NAMES.SUB
	LDA	NAMLEN	;GET LENGTH OF FIELD
	MOV	B,A	;TO USE AS COUNTER
	STA	BUFF	;STORE IN OUTPUT
	LXI	H,BUFF+2;GET FIRST CHAR. LOC'N
	LXI	D,BUFF+1;MOVE AHEAD ONE
	CALL	MOVER	;MOVE NAME INTO BUFFER
	DCX	H	;BACK ONE POSITION
	XRA	A	;0 ->A-REG
	MOV	M,A	;0 IN LAST POSITION
;
;	WRITE FILE NAME TO DISK
;
	LXI	D,FCB	;POINT TO NAME
	MVI	C,WRITE	;WRITE RECORD
	CALL	BDOS
	JMP	AGAIN	;GET ANOTHER RECORD
;	
;	NOW CLOSE THE FILE ON DISK
;
EOF:	LXI	D,FCB	;POINT TO NAME
	MVI	C,CLOSE	;CLOSE FILE
	CALL	BDOS
;
;	INSURE THE DISK WE WANT TO SUBMIT ON
;
FINIS:	XRA	A	;GET A ZERO
	STA	DRNAME	;SET CP/M FOR DRIVE A:
EXIT:	;
	LXI	D,TFCB	;DELETE NAMES.$$$
	MVI	C,DELETF;
	CALL	BDOS
	CALL	ILPRT	;PRINT COMPLETION MESSAGE
	DB	CR,LF,'EXITING TO EXECUTE FILE TRANSFER'
	DB	CR,LF,LF,0
	LHLD	STACK	;GET OLD CP/M (OR MP/M) STACK
	SPHL		;RESTORE OLD STACK POINTER
	JMP	0	;REBOOT
;
;MOVE (B) BYTES FROM (HL) TO (DE)
;
MOVER:	MOV	A,M	;GET BYTE FROM SOURCE
	STAX	D	;STORE AT DESTINATION
	INX	H	;INCREMENT SOURCE ADR
	INX	D	;INCREMENT DESTINATION ADR
	DCR	B	;DECREMENT MOVE COUNTER
	JNZ	MOVER	;NOT DONE, DO MORE	
	RET
;
FILNAM:	DB	0	;UNUSED EXTENT
	DB	'$$$     SUB'	;NAME OF SUBMIT FILE
	DB	0	;SET EXTENT OF SUBMIT FILE
;
DISKR	;READ A FILE DISK RECORD
	PUSH H!	PUSH D!	PUSH B
	LXI	D,TFCB
	MVI	C,READF
	CALL	BDOS
	POP B!	POP D!	POP H
	CPI	0	;CHECK FOR ERRORS
	RZ
;	CHECK FOR EOF
	CPI	1
	JZ	EOF
	CALL	ILPRT	;PRINT FILE READ ERROR
	DB	'DISK READ ERROR',0
	JMP	FINIS
;
SETUP	;SET UP FILE
;	OPEN FILE FOR INPUT
	LXI	D,TFCB	;OPEN FILE
	MVI	C,OPENF
	CALL	BDOS
;	CHECK FOR ERRORS
	CPI	255
	JNZ	OPNOK
;	BAD OPEN
	CALL	ILPRT	;PRINT MESSAGE 
	DB	CR,LF,'ERROR IN OPENING FILE',0
	JMP	FINIS
;
OPNOK	;OPEN IS OK
	CALL	ILPRT	;DEBUGGING MESSAGE
	DB	CR,LF,'OPENED NAMES.$$$',0
	XRA	A	;SETTING TO 0TH REC
	STA	TFCBCR
	RET
;
           ;Routine to print info following until '0'
;
ILPRT:	XTHL		;SAVE HL, GET MSG
;
ILPLP:	MOV	A,M	;GET CHAR
	ORA	A	;END OF MESSAGE?
	JZ	ILPRET	;YES, RETURN
	PUSH B!	PUSH D!	PUSH H
	MOV	E,A	;SET CHAR FOR BDOS
	MVI	C,2	;SET TYPEF COMMAND
	CALL	BDOS	;OUTPUT CHAR
	POP H!	POP D!	POP B
	INX	H	;TO NEXT CHAR.
	JMP	ILPLP	;LOOP
;
ILPRET	XTHL		;RESTORE HL, RETURN ADDRESS
	RET		;RETURN PAST MESSAGE STRING
;
;	FILE CONTROL BLOCK DEFINITIONS
;
TFCB	DB	0	;DRIVE NAME
	DB	'NAMES   '
	DB	'$$$'
	DB	0	;
	DS	21	;SPACE FOR BALANCE OF TFCB
TFCBFN	EQU	TFCB+1	;FILE NAME
TFCBFT	EQU	TFCB+9	;FILE TYPE
TFCBRL	EQU	TFCB+12	;CURR REEL NUM
TFCBRC	EQU	TFCB+15	;REC COUNT
TFCBCR	EQU	TFCB+32	;CURR (NEXT) REC NUM
TFCBLN	EQU	TFCB+33	;TFCB LENGTH
;
	DS	64	;ROOM FOR 32 LEVEL STACK
STACK	DS	2	;OLD CP/M (OR MP/M) STACK SAVED HERE
;
END
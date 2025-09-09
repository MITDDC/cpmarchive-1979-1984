rem	COMMO1.BAS started 08/05/81 by John C. Gilbert
rem	written in CBASIC2
rem
rem	To use the system, you should have the following programs online:
rem
rem     A tailored version of MTN22A.COM
rem     SENDOUT.COM
rem     FMAP or a text editor
rem     XMODEM.COM
rem     MODEM.COM
rem
rem	It works in the following way:
rem
rem     Step  1  - Form a file named NAMES.SUB of the  files  to  be 
rem          moved.  I  use  FMAP B:(param) F to form mine from  the 
rem          directory.  It  automatically  creates a file  of  this 
rem          name. the param if of the form FN.FT with wild cards.
rem
rem     Step 2 - Execute RUN COMMO1.  Basically it is setup to  send 
rem          from  your  end at 600 baud.  Either parameter  can  be 
rem          altered in the call; e.g. you can say 300 R and it will 
rem          receive  the files from the other end at 300 baud or to 
rem          send at 300,  just 300 will do it.  The program reallys 
rem          sets up dummy files in the form expected by SUBMIT, but 
rem          because  they are written in CBASIC,  the output  comes 
rem          out surrounded by quotes.
rem
rem     Step 3  - Use MTN to establish the basic commo  link.  There 
rem          might be some neat way to do it,  but I just move a one 
rem          block file using XMODEM & MODEM.
rem
rem     Step 4 - Execute COMMO2.  It reads the output of COMMO1  and 
rem          creates  a  file of the form $$$.SUB.  In fact,  it  is 
rem          built  on  the framework of  MAKESUB.ASM.  When  it  is 
rem          finished,  CP/M  is  faked  and  begins  executing  the 
rem          transfers.
rem
rem	A couple of comments. It executes from the A-disk, but expects to 
rem	move all files to and from the B-disk.  COMMO1 creates an interim 
rem	file  NAMES.$$$,  but both programs clean up after themselves  so 
rem	both  files;  NAMES.SAV  &  NAMES.$$$ should be gone when  it  is 
rem	finished.
rem
rem 	COPYNAME is a program to read a file created by FMAP 
rem	named NAMES.SUB and create a file NAMES.$$$ which will
rem	move a succession of files between MODEM & XMODEM
rem	until there are no more left
rem
rem	It uses two kinds of parameters; R or S as a param to
rem	the modem &
rem	xxx which is the speed for the move. The default is 
rem	S.600
rem
	MPARAM$ = "S"
	XPARAM$ = "R"
	IF MATCH("R",COMMAND$,1) THEN\
		MPARAM$ = "R":\
		XPARAM$ = "S"
	S% = MATCH("###",COMMAND$,1)
	IF S% THEN\
		MPARAM$ = MPARAM$+"."+MID$(COMMAND$,S%,3):\
		XPARAM$ = XPARAM$+"."+MID$(COMMAND$,S%,3):\
	ELSE\
		MPARAM$ = MPARAM$+".600":\
		XPARAM$ = XPARAM$+".600"
	SENDOUT$ = "SENDOUT "
	MODEM$ = "MODEM "+MPARAM$+" B:"
	XMODEM$ = "XMODEM "+XPARAM$+" B:"
	REM ****************************************************
DEF FN.SIZE.BLOCK$(N$)
	X$ = CHR$(LEN(N$))
	FN.SIZE.BLOCK$ = (X$+N$)
	RETURN
FEND
	REM ****************************************************
	IF END #1 THEN 90.01	REM IF EOF THEN QUIT
	OPEN "NAMES.SUB" AS 1
	CREATE "NAMES.$$$" RECL 128 AS 2
	FOR I% = 1 TO 65
		READ #1;LINE NAME$
		IF LEFT$(NAME$,1) EQ "-" THEN\
			N% = -1:\
			GOTO 50
		PRINT "INCLUDE ";NAME$," TYPE <Y/N>";:INPUT LINE C$
		IF UCASE$(LEFT$(C$,1)) EQ "N" THEN GOTO 50
		XNAME$ = NAME$
		IF RIGHT$(NAME$,3) EQ "COM" THEN\
			XNAME$ = LEFT$(NAME$,LEN(NAME$)-3)+"OBJ"
		IF RIGHT$(NAME$,3) EQ "ASM" THEN\
			XNAME$ = LEFT$(NAME$,LEN(NAME$)-3)+"ASC"
		PRINT #2;FN.SIZE.BLOCK$(MODEM$+NAME$)
		PRINT #2;FN.SIZE.BLOCK$(SENDOUT$+XMODEM$+XNAME$)
50	NEXT I%
90.01	REM EMPTY FILE *****************************************
	PRINT "Finished, Number of Records is";I%-1+N%
	DELETE 1
	CLOSE 2
	STOP

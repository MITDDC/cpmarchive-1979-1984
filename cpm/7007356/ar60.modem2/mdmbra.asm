************************************************************************

        UNIVERSAL BAUD RATE SELECTION ROUTINE FOR MODEM PROGRAMS
                          By: Rory Jan (6/82)
                             Rexdale, Ont.

Note:  This is not a stand alone program,  it is merely an upgrade  that 
can be incorporated into most MODEM/XMODEM programs.

This  file  contains  a new GETBAUD subroutine (S/R) for  use  with  the 
series of MODEM/XMODEM programs. This S/R uses look-up tables to preform 
it's  wonders (instead of hardware dependent  calculations).  What  this 
means  is  no  matter what type of programable baud rate  generator  you 
have,  you will now be able to use the option of specifying a baud  rate 
when you invoke the modem program.  Of course, if you're lucky enough to 
already  be able to do that,  then this file is of ALMOST no use to  you 
(read on).

The  format  of  the baud rate selection option on the command  line  is 
slightly different,  it must be entered in 100's of baud instead of just 
baud (eg.  MODEM T.6 means 600 baud).  This allows the specification  of 
baud  rates up to 25500 as opposed to 999 max using the previous  format 
(this  is due to the 3 baud rate char limit on the command line).  Along 
with the new GETBAUD S/R,  this file also contains a debugged CVBIN  S/R 
(the  CVBIN S/R found in MODEM217 doesn't work but may have already been 
corrected  by  now) and updated HELP and EXAM S/R's  which  reflect  the 
slightly  different  baud  rate  selection  format  (using  IF/ENDIF's). 
Although CVBIN,  HELP & EXAM were taken from MODEM217, they should still 
be  direct  replacements  for  the corresponding  S/R's  in  most  MODEM 
programs.

This  MODEM/XMODEM  update  is  provided  in the form  of  S/R's  to  be 
incorporated  into your own modem program simply because there  are  too 
many versions of MODEM to provide diff files for (and if you altered the 
program  much,  you couldn't use the diff file anyway).  Therefore,  you 
must  at least know roughly what 8080 (blaaaa) assembly language is  all 
about to stick this routine in (it's veeeeery easy).

It would be a great service to all new Modemites if some generous person 
would  take  the latest and greatest MODEM program and replace  all  the 
IF/ENDIF'd  stuff  in the GETBAUD S/R with this universal  S/R  and  put 
EQU's near the start of the file to specify allowable baud rates and the 
corresponding  baud rate gen.  (or modem or serial interface or...) data 
required.  This  way  most  people could avoid the hastle  of  having  3 
versions of their modem  program for 3 different baud rates.

Now for the routines...

************************************************************************

                         SETTING UP THE TABLES

The  tables are presently set up for a COM5016 dual baud rate generator. 

Table 1 (BRTBL1) simply contains the baud rate that would be entered  on 
the  command  line (actual values,  not ASCII),  see present set-up  for 
example.

Table  2  (BRTBL2)  contains  the  corresponding  baud  rate   generator 
programing data (eg.  in the present set-up, 0EEH is brate gen. data for 
9600 baud).

The  2  tables can be changed to any length as long as size of BRTBL1  = 
size of BRTBL2 (obviously...).

************************************************************************

                          ROUTINE (???) NOTES

- If  you know the CVBIN S/R in your MODEM  prog.  works,  don't  bother 
replacing it with this one.
- If you aren't worried about the 'help' and 'example' information being 
completely correct, don't replace (or update) it either.
- The  S/R ERXIT CALLed from BADRATE simply prints the message  directly 
following  the  call,  then exits the prog.  I'm sure you have the  same 
routine, but the name could be different (not likely).
- If it's not already in your prog, put a DEFBAUD EQU 0XXH ;DEFAULT BAUD 
RATE  GEN  DATA statement near the start of the file and set it  to  the 
BAUD RATE GEN data for your default baud rate.
- Add  the statement BRGNLUP EQU TRUE ;TRUE,  USES LOOK-UP  TABLE  BRATE 
SELECT near the modem type select options at the beginning of the file. 
- The INITREQ label should be set TRUE (else how else can you init  your 
baud  rate  gen).  If  you  normally  set  it  FALSE,  you  can  prevent 
initialization  of everything but the baud rate buy removing all but the 
two statements shown below from the INITMD (INITMOD) S/R.
- Replace your similar statements:
	MVI	A,DEFBAUD	;INIT TO DEFAULT BAUD RATE
	OUT	BAUDRP
  with:
	CALL	GETBAUD		;GET BAUD RATE GEN DATA
	OUT	BAUDRP

************************************************************************

                            INSTALLING S/R'S

- Depending  on your style (or your mood),  you may want to install  the 
new GETBAUD S/R using IF/ENDIF's, or you may just feel like removing the 
original  stuff (it isn't used anyway) and putting this one straight in. 
Which ever way you do it,  make sure it (and only it) gets assembled.  I 
used a new label (BRGNLUP - baud rate gen look-up) and IF/ENDIF's myself 
(IF/ENDIF's in S/R's below are for MODEM217).
- If  your CVBIN S/R needs to be corrected,  simply substitute this  one 
for  your infested one (or if you don't have one at all,  stick this one 
in immediately after the GETBAUD S/R).
- If you want to replace your HELP & EXAM S/R's, do just that.

That's all folks...
WOW! What a massive amount of typing for such a pitifully small routine.
					R. Jan

************************************************************************
                              S/R GETBAUD
************************************************************************
;      
;---->	GETBAUD: GETS BAUD RATE FROM COMMAND
;
;	THIS ROUTINE CHECKS IF A BAUD RATE HAS BEEN
;	ASKED FOR, (SUCH AS MODEM T.6 FOR 600 BAUD),
;	AND IF SO, CALCULATES THE BAUD RATE GENERATOR
;	VALUE TO BE RETURNED (IN A), ELSE DEFAULTS
;	TO 'DEFBAUD'.
;
	IF	BRGNLUP
;
GETBAUD	LDA	FCB+9		;GET 'FILETYPE'
	CPI	' '		;USE DEFAULT?
	MVI	A,DEFBAUD	;JUST IN CASE
	RZ			;USE 'DEFBAUD'
;
	CALL	CVBIN		;GET BAUD RATE IN BINARY (/100)
;
	MOV	A,H		;INVALID BAUD RATE?
	CPI	0		;(I.E > 25500)
	JNZ	BADRATE		;INVALID
;
	LXI	D,BRTBL1-1	;INIT PTR TO BRATE TABLE
GETBD2	INX	D		;UPDATE PTR
	MOV	A,E		;END OF TABLE 1?
	CPI	BRTBL2 MOD 256
	JZ	BADRATE		;YES, INVALID BAUD RATE
	LDAX	D		;GET VAL FROM TABLE 1
	CMP	L		;MATCH?
	JNZ	GETBD2		;NOT YET, CONTINUE
	LXI	H,BRTBL2-BRTBL1	;SET HL TO POINT TO CORRESPONDING
				;VAL IN TABLE 2
	DAD	D
	MOV	A,M		;GET BRATE GEN DATA
	RET
;
; COM5016 BAUD RATE TABLE (IN HUNDREDS OF BAUD)
;
BRTBL1	DB	1		;110 BAUD
	DB	3		;300 BAUD
	DB	6		;600 BAUD
	DB	12		;1200 BAUD, ETC.
	DB	18
	DB	20
	DB	24
	DB	36
	DB	48
	DB	72
	DB	96
	DB	192		;19200 BAUD
;
; CORRESPONDING CONTROL VALUES FOR ABOVE BAUD RATES
;
BRTBL2	DB	22H		;110 BAUD
	DB	55H		;300 BAUD, ETC.
	DB	66H
	DB	77H
	DB	88H
	DB	99H
	DB	0AAH
	DB	0BBH
	DB	0CCH
	DB	0DDH
	DB	0EEH
	DB	0FFH		;19200 BAUD
;
	ENDIF			;BRGNLUP
************************************************************************
                               S/R CVBIN
(don't  forget  to  make sure things are assembled  if  you  stick  them 
between IF/ENDIF's)
************************************************************************
;                                       
; ROUTINE TO CONVERT BAUD RATE SPECIFIED ON COMMAND
; LINE TO BINARY (HEX). VAL RETURNED IN HL
;
	IF	PMMI OR DCH OR BRGNLUP	;(eg. as in MODEM217)
;
CVBIN	LXI	D,FCB+9		;PNT TO ASCII VAL
	LXI	H,0		;INIT BINARY RESULT
;
DECLP	MOV	A,E		;DONE?
	CPI	FCB+12 MOD 256
	RZ			;YEP, RETURN HEX IN HL
	LDAX	D		;GET ASCII DIGIT
	INX	D		;PNT TO NEXT DIGIT
	CPI	' '		;BLANK ONE?
	JZ	DECLP		;..YES, SKIP IT
	CPI	'0'		;VALIDATE IT
	JC	BADRATE 	;ERROR
	CPI	'9'+1		;VALIDATE
	JNC	BADRATE 	;ERROR
	SUI	'0'		;MAKE DIGIT BINARY
;
; MULTIPLY PREV VALUE BY 10
;
	MOV	B,H		;SET UP FOR
	MOV	C,L		;MULTIPLY BY 10
	DAD	H		;MULTIPLY BY 2
	DAD	H		;X 2 = 4
	DAD	B		;+ 1 = 5
	DAD	H		;X 2 = 10
	ADD	L		;ADD IN DIGIT
	MOV	L,A		;SAVE BACK
	JNZ	DECLP		;NO CARRY?
	INR	H		;ADD IN CARRY
	JMP	DECLP		;NEXT DIGIT
;
; INVALID BAUD RATE
;
BADRATE CALL	ERXIT
	DB	'++INVALID BAUD RATE++$'
;
	ENDIF			;PMMI OR DCH OR BRGNLUP
************************************************************************
                           S/R'S HELP & EXAM
************************************************************************
;
; ROUTINES TO GIVE HELP AND EXAMPLES
; HELP/EXAMPLE DATA IS AUTOMATICALLY ADJUSTED USING
; IF/ENDIF'S TO SHOW CORRECT BAUD RATE SELECT FORMAT
;
HELP	CALL	ILPRT
	DB	'(T)erminal and (E)cho mode commands:',CR,LF
	DB	'   Ctl-A = Ascii capture enable/disable toggle',CR,LF
	DB	'   Ctl-E = Exit to CP/M',CR,LF
	DB	'   Ctl-D = Disconnect phone',CR,LF
	DB	'   Ctl-P = Printer enable/disable toggle',CR,LF,CR,LF
	DB	'Format for command is:',CR,LF,CR,LF
	DB	'MODEM # Filename',CR,LF,CR,LF
	DB	'Where # is a 1 character primary option,',CR,LF
	DB	' which may be followed by sub-options,',CR,LF
	DB	' and by ".xxx" to set baud rate to'
	IF	BRGNLUP
	DB	CR,LF,' xxx*100 (i.e. enter baud rate in 100''s)'
	ENDIF
	IF	NOT BRGNLUP
	DB	' xxx'
	ENDIF
	DB	CR,LF,CR,LF,1
	DB	'Primary Options:',CR,LF
	DB	'   S to send a file',CR,LF
	DB	'   R to receive a file',CR,LF
	DB	'   T to act as a terminal',CR,LF
	DB	'   E to act as a computer (echo data)',CR,LF
	DB	'   D to disconnect the phone',CR,LF
	DB	'   H to print this help file',CR,LF,CR,LF,1
	DB	'Secondary options:',CR,LF
	DB	'   A answer mode',CR,LF
	DB	'   O originate mode',CR,LF
	DB	'   D disconnect after execution',CR,LF
	DB	'   T go to terminal mode after file xfer',CR,LF
	DB	'   E go to echo mode after file xfer',CR,LF
	DB	'   Q quiet mode - no status msgs',CR,LF
	DB	'   R show chars received',CR,LF
	DB	'   S show chars sent',CR,LF
	DB	'   V view file sent/received (no status)',CR,LF
	DB	'   C request CRC option for file xfers',CR,LF
	DB	'     Note: request made from receiving end',CR,LF
	DB	CR,LF,'For examples, type: MODEM X',CR,LF,0
	JMP	EXIT
;
EXAM	CALL	ILPRT
	DB	'Send file, originate mode, 300 baud:',CR,LF
	DB	'   MODEM SO fn.ft',CR,LF
	DB	'Send another file:',CR,LF
	DB	'   MODEM S fn.ft',CR,LF
	DB	'Then send a third file at '
	IF	BRGNLUP
	DB	'9600'
	ENDIF
	IF	NOT BRGNLUP
	DB	'600'
	ENDIF
	DB	' baud and disconnect:'CR,LF
	IF	BRGNLUP
	DB	'   MODEM SD.96 fn.ft'
	ENDIF
	IF	NOT BRGNLUP
	DB	'   MODEM SD.600 fn.ft'
	ENDIF
	DB	CR,LF,CR,LF
	DB	'Act as a terminal, originate mode, at 110 baud:',CR,LF
	IF	BRGNLUP
	DB	'   MODEM TO.1'
	ENDIF
	IF	NOT BRGNLUP
	DB	'   MODEM TO.110'
	ENDIF
	DB	CR,LF
	DB	'   (Use ctl-D to disconnect)',CR,LF,CR,LF,1
	DB	'Receive file, answer mode, view it, 600 baud:',CR,LF
	IF	BRGNLUP
	DB	'   MODEM RAV.6 fn.ft'
	ENDIF
	IF	NOT BRGNLUP
	DB	'   MODEM RAV.600 fn.ft'
	ENDIF
	DB	CR,LF
	DB	'Receive file, request cyclic redundancy check, 600 baud:',CR,LF
	IF	BRGNLUP
	DB	'   MODEM RC.6 fn.ft',
	ENDIF
	IF	NOT BRGNLUP
	DB	'   MODEM RC.600 fn.ft',
	ENDIF
	DB	CR,LF,CR,LF
	DB	'Turn printer mode on/off in terminal or echo mode:',CR,LF
	DB	'   ^P	 (printer now toggled)',CR,LF,CR,LF
	DB	'Turn on ascii capture mode:',CR,LF
	DB	'   ^A ',CR,LF
	DB	'   FILE NAME --> b:test.doc [CR] (file now open)',CR,LF
	DB	'Turn off ascii capture mode:',CR,LF
	DB	'   ^A	(ascii capture disabled, file closed)',CR,LF,0
	JMP	EXIT

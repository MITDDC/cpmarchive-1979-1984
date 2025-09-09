10 '  IBM Personal Computer implemntation of MODEM2 File transfer protocol
20 '           Copyright (C) 1982  By  William E. Westfield
40 '    Originally written for SRI International, Menlo Park, CA
60 ' 
80 '	-{ Version 3.005 }- latest change: data capture mode
100 '
120 '  This program is InterNet public, due to the help I have frequently
140 '  gotten from the network community.  It may be used for any purpose,
160 '  including comercial purposes, but it may not be resold for profit
180 '  under any circumstances.  Note that you are only entitled to get
200 '  this program free if you have direct access to a computer on the
220 ' ARPANet, UUCP, or CSNet.  Please do not give this program away
240 ' others.  All copies of this program must retain this notice.
260 '
280 ' If you BOUGHT this program, please dont share it with your
300 ' friends, though I dont mind if you tell them (ahem) how great it is.
320 ' As someone put it: "If I make a lot of money selling this program, I
340 ' will be encouraged to produce more high quality software at reasonable
360 ' prices.  If I find pirated copies floating around, I will charge more
380 ' money, protect my programs with unreasonable protection schemes,
400 ' and/or keep them to myself.
420 '
440 DEFINT A-Z : COLOR 7,0 : SCREEN 0,0,0 : WIDTH 80  : CLS
460 KEY OFF : LOCATE ,,1
480 DEF SEG=&H40 : MEMSIZE = PEEK(&H14)*256+PEEK(&H13)
500 PRINT STR$(MEMSIZE)+"K MODEM2 file transfer program and Heath-19 ";
520 PRINT "terminal emulator"
540 PRINT TAB(15);"Copyright 1982 by William E Westfield" : PRINT
560 IF MEMSIZE <= 64 THEN CLEAR ,&H8000 : DEFINT A-Z : MEMSIZE=64
580 IF MEMSIZE = 256 THEN SPACE = 16 ELSE IF MEMSIZE = 128 THEN SPACE= 8 ELSE SPACE =4
600 DEF SEG=(MEMSIZE-SPACE)*(1024/16)
620 ON ERROR GOTO 740
640 BLOAD "HEATH.X",0 : ON ERROR GOTO 0
660 ON ERROR GOTO 700 : BLOAD "KEYDEFS.DAT",&H800 : ON ERROR GOTO 0
680 GOTO 720
700 RESUME 720
720 TERPROG%=1 : GOTO 800
740 PRINT "No HEATH.X terminal emulation program."
760 PRINT "Will run dumb BASIC terminal emulator..."
780 TERPROG%=2 : RESUME 800
800 ' set up checksum routine
820 READ L  : CHKSUM = &H10
840 FOR I%=1 TO L: READ J : POKE &HF+I%, J : NEXT I%
860 '
880 NAK$=CHR$(21) : ACK$=CHR$(6) : SOH$=CHR$(1)
900 CR$=CHR$(13)  : EF$=CHR$(4)  : NUL$=CHR$(26)
920 '****** customize for your most common remote host, etc ********
910 DEFAULTSPEED$= "9600"
940    SYSTEMTYPE$="TOPS-20"
960   ' systemtype$="UNIX"   
980   ' systemtype$="VAX"    
990   ' systemtype$="IBM-PC"
1000  ' systemtype$="OTHER" 
1020  ' input "System type: ", systemtype$
1021 GOSUB 2800 
1040 '***************************************************************
1060 INPUT"Desired terminal line speed: ",SPEED
1080 IF SPEED=0 THEN SPEED$="" ELSE SPEED$=STR$(SPEED)
1100 IF SPEED$="" THEN SPEED$=DEFAULTSPEED$ : LOCATE CSRLIN-1,30 : PRINT SPEED$
1120 PRINT "First you must establish a MICOM"
1140 PRINT "connection to the remote computer"
1141 PRINT "and log in to your account."
1160 ON ERROR GOTO 1200
1180 OPEN "com1:"+SPEED$+",n,8,1" AS 1 : ON ERROR GOTO 0 : GOTO 1260
1200 PRINT "Communications error.  Is the Serial line connected ?"
1220 INPUT "If not, connect it now and hit RETURN.",A$
1240 RESUME 1160
1260 '
1280 '------------ Act as a terminal --------------
1300 '
1320 GOSUB 5500
1340 KEY(3) OFF
1360 ON TERPROG% GOSUB 5160,5260
1380 ON KEYNUM% GOTO 3780, 5780, 1280, 3500, 1460, 1800 ,1400,1400,1400, 2460
1400 BEEP : PRINT "Undefined Function Key"
1420 GOTO 1280
1440 '
1460 ' -------------- Push file to DUMB mainfraim ----------------
1480 '
1500 LOCATE 24,1 : PRINT SPC(79); : LOCATE 24,1 : KEY 3,CR$
1520 INPUT "Name of source file on IBM PC: ",F$
1540 IF F$="" THEN 1280
1560 SOURCE$=F$
1580 OPEN SOURCE$ FOR INPUT AS #2
1600 WHILE NOT EOF(2)
1620  LINE INPUT#2,O$        'get a line
1640  PRINT #1,O$+CR$;
1660  WHILE INSTR(O$,CHR$(10)) = 0
1680   IF LOC(1) > 0 THEN O$=INPUT$(LOC(1),1)
1700  WEND
1720 PRINT "+";
1740 WEND
1760 PRINT"Done"
1770 close #2
1780 GOTO 1280
1800 POKE &H5C,0 : FOR I=1 TO 11 : POKE &H5C+I,32 : NEXT I ' fill with spaces
1820 '
1840 '---------------- data caputure mode ----------------
1860 '
1880 LOCATE 25,1 : PRINT SPC(79); : LOCATE 24,1
1900 POKE &H5C,0 : FOR I=1 TO 11 : POKE &H5C+I,32 : NEXT I
1920 IF TERPROG% = 1 THEN 1960
1940 PRINT"Sorry, you need HEATH.X to do text capture." : GOTO 1280
1960 INPUT "Capture text into what file: ",F$
1980 ON ERROR GOTO 2020 : OPEN F$ FOR INPUT AS 2 : ON ERROR GOTO 0
2000 PRINT "File already exists, will append to file." : CLOSE 2 : GOTO 2060
2020 IF ERR=53 THEN PRINT "Creating new file."  : RESUME 2060
2040 PRINT "Illegal file specification.  Try again" : RESUME 1960
2060 ON ERROR GOTO 0
2080 IF MID$(F$,2,1)=":" THEN POKE &H5C, ASC(LEFT$(F$,1))-64  ' disk drive
2100 FILEND = INSTR(F$,".")-1 : IF FILEND<=0 THEN FILEND=LEN(F$)  
2120 J=1 :FOR I=INSTR(F$,":")+1 TO FILEND
2140	II = ASC(MID$(F$,I,1)) : IF II >= ASC("a") THEN II= II-32
2160	POKE &H5C+J, II  :  J= J+1
2180 NEXT I
2200 J=9 : FOR I=FILEND+2 TO LEN(F$)
2220	II = ASC(MID$(F$,I,1)) : IF II >= ASC("a") THEN II= II-32
2240	POKE &H5C+J, II  :  J= J+1
2260 NEXT I
2280 IF PEEK(&H801)=0 THEN POKE 801,31 : POKE 802,31
2300 LOCATE 25,1: PRINT "Text --> ";: COLOR 0,7 :PRINT F$;
2320 LOCATE 25,48: PRINT "End capture";: LOCATE 25,68 : PRINT "Save buffer";
2340 COLOR 7,0 : LOCATE 25,46: PRINT "F1"; : LOCATE 25,66 : PRINT"F2";
2360 POKE &H80,255 : LOCATE 24,1 : KEYNUM% = 13
2380 GOSUB 5180
2400 IF KEYNUM%=2 THEN 2420 ELSE POKE &H80, 0 : KEYNUM%=0 : GOTO 1280
2420 KEYNUM%=0 : GOTO 2380
2440 '
2460 ' -------------- define new remote host comand strings --------------
2480 '
2500 GOSUB 2540 : GOTO 1280
2520 '
2540 CLS : PRINT" Redefining the remote host comand strings." : PRINT
2560 PRINT" Several system types are already defined.  These are listed"
2580 PRINT" below.  To use anouther kind of system, you must specify the"
2600 PRINT" individual command strings necessary.  For a description of"
2620 PRINT" What these strings should be, see the user manual." : PRINT
2640 PRINT" current system type is : "; SYSTEMTYPE$ : PRINT
2660 PRINT" Available system types are :"
2680 PRINT"	Tops-20 running BillW's MODEM program."
2700 PRINT" 	Unix running Lauren's UMODEM program."
2720 PRINT" 	Vax VMS running John Perry's FTPGET and FTPSEND."
2740 PRINT"	IBM-PC Computer running BillW's XMODEM."
2760 INPUT" New system type: "; SYSTEMTYPE$
2780 IF SYSTEMTYPE$="" THEN RETURN		'Abort
2800 IF SYSTEMTYPE$="vax" OR SYSTEMTYPE$="VAX" THEN 2820 ELSE 2860
2820 SEND$="@usr:[tools]ftpsend"+CR$ : MODE$="c"+CR$ : LOGOUT$="logout"
2840 RECEIVE$="@usr:[tools]ftpget"+CR$ : SYSTEMTYPE$="VAX" : GOTO 3460
2860 '
2880 IF SYSTEMTYPE$="unix" OR SYSTEMTYPE$="UNIX" THEN 2900 ELSE 2940
2900 SEND$="umodem -ls" : RECEIVE$="umodem -lr" : MODE$="t" : LOGOUT$="logout"
2920 SYSTEMTYPE$= "UNIX" : GOTO 3460
2940 IF SYSTEMTYPE$="unixb" OR SYSTEMTYPE$="UNIXB" THEN 2960 ELSE 3000
2960 SEND$="umodem -ls" : RECEIVE$="umodem -lr" : MODE$="b" : LOGOUT$="logout"
2980 SYSTEMTYPE$= "UNIX-B" : GOTO 3460
3000 IF SYSTEMTYPE$ = "tops-20" OR SYSTEMTYPE$= "TOPS-20" THEN 3040
3020 IF SYSTEMTYPE$ = "tops20" OR SYSTEMTYPE$= "TOPS20" THEN 3040 ELSE 3080
3040 SEND$="<billw>nmodem sq" : RECEIVE$="<billw>nmodem rq" : MODE$=""
3060 LOGOUT$="kk" : SYSTEMTYPE$="TOPS-20" : GOTO 3460
3080 IF SYSTEMTYPE$="ibmpc" OR SYSTEMTYPE$="IBMPC" THEN 3120
3100 IF SYSTEMTYPE$="ibm-pc" OR SYSTEMTYPE$="IBM-PC" THEN 3120 ELSE 3160
3120 SEND$="SEND" : RECEIVE$= "RECEIVE" : MODE$="" : LOGOUT$="BYE"
3140 SYSTEMTYPE$="IBM-PC" : GOTO 3460
3160 PRINT "Unknown system type '";SYSTEMTYPE$"'. Redfine strings explicitly."
3180 PRINT: PRINT "Here are the current values..."
3200 PRINT "SEND$=";SEND$;"   RECEIVE$=";RECEIVE$;"   MODE$=";MODE$ : PRINT
3220 PRINT : INPUT"SEND$= ",F$
3240 IF F$ <> "" THEN SEND$=F$ : GOTO 3280
3260 LOCATE CSRLIN-1,8 : PRINT SEND$
3280 INPUT"RECEIVE$= ",F$
3300 IF F$ <> "" THEN RECEIVE$=F$ : GOTO 3340
3320 LOCATE CSRLIN-1,11 : PRINT RECEIVE$
3340 INPUT"MODE$= ",F$
3360 IF F$ <> "" THEN MODE$=F$ : IF MODE$="*" THEN MODE$="" : GOTO 3400
3380 LOCATE CSRLIN-1,8 : PRINT MODE$
3400 INPUT"LOGOUT$= ",F$
3420 IF F$ <> "" THEN LOGOUT$=F$ : GOTO 3460
3440 LOCATE CSRLIN-1,10 : PRINT LOGOUT$
3460 RETURN
3480 '
3500 ' -------------- EXIT, perhaps logging out -------------------
3520 '
3540 LOCATE 24,1: PRINT SPC(79); : LOCATE 24,1
3560 PRINT "Logout (Y or N) ?";
3580 YN$=INKEY$ : IF YN$="" THEN 3580
3600 IF YN$ = "Y" OR YN$ = "y" THEN 3620 ELSE PRINT "No" : GOTO 3660
3620 PRINT #1,LOGOUT$ : PRINT "Yes"
3640 FOR I%= 1 TO 600: NEXT: O$=INPUT$(LOC(1),1) 'flush
3660 CLOSE
3680 KEY 1,"List " : KEY 2,"Run"+CR$ : KEY 3,"Load"+CHR$(34): KEY 4,"Save"+CHR$(34)
3700 KEY 5,"Cont"+CR$ : KEY 6,",LPT1:"+CR$
3720 KEY ON : if yn$="b" then END else SYSTEM
3740 KEY OFF : GOTO 1160
3760 '
3780 ' ------------- Upload file to Remote Computer ---------------
3800 '
3820 LOCATE 24,1 : PRINT SPC(79); : LOCATE 24,1 : KEY 3,CR$
3840 INPUT "Name of source file on IBM PC: ",F$
3860 IF F$="" THEN 1280
3880 SOURCE$=F$ : DESTIN$=F$
3900 IF INSTR(1,F$," ") = 0 THEN 3980
3920 SOURCE$=LEFT$(F$,(INSTR(1,F$," ")-1))
3940 DESTIN$=RIGHT$(F$,(LEN(F$)-INSTR(1,F$," ")))
3960 GOTO 4120
3980 IF RECEIVE$ = "*" THEN 4060
4000 INPUT"Name of destination file on remote system: ", DESTIN$
4020 IF DESTIN$<>"" THEN 4060 ELSE DESTIN$=SOURCE$
4040 LOCATE CSRLIN-1,43 : PRINT DESTIN$
4060 ON ERROR GOTO 4160 : OPEN SOURCE$ FOR INPUT AS #2 : CLOSE 2
4080 ' note that "random" access is used to permit uploading of files
4100 ' that contain ^Zs, which basic otherwise thinks means EOF...
4120 OPEN SOURCE$ AS 2 LEN=128 : ON ERROR GOTO 0
4140 GOTO 4200
4160 PRINT "No such file as ";SOURCE$; ".   Try again"
4180 RESUME 3840
4200 NBLKS!=INT(LOF(2)/128)
4220 ON ERROR GOTO 0
4240 IF NBLKS! <> LOF(2)/128 THEN NBLKS!=NBLKS!+1
4260 PRINT "File is";NBLKS!;"blocks long."
4280 CURSAVE=CSRLIN
4300 IF RECEIVE$ <> "*" THEN PRINT#1, RECEIVE$+MODE$+" "+DESTIN$+CR$;
4320 FOR I=1 TO 300:NEXT I
4340 WHILE LOC(1) > 0 : O$ = INPUT$(LOC(1),1) : WEND 'flush echoing
4360 LOCATE 25,1:PRINT "FTP from IBM::";TAB(29);"to REMOTE::";
4380 PRINT TAB(62);"Block";TAB(72);"Retry";
4400 COLOR 0,7
4420 LOCATE 25,15:PRINT SOURCE$;
4440 LOCATE 25,40: PRINT DESTIN$;
4460 O$= INPUT$(1,1) ' wait for initial nak
4480 IF O$<>NAK$ THEN 4460
4500 COLOR 0,7
4520 KEY(3) ON : ON KEY(3) GOSUB 5120 ' provide escape feature
4540 FOR RECNUM=1 TO NBLKS!
4560   FIELD #2,128 AS O$ : GET #2,RECNUM  ' get a record from the file
4580   GOSUB 4760         ' send record to modem
4600 NEXT RECNUM
4620 PRINT #1,EF$
4640 CLOSE 2
4660 COLOR 7,0
4680 LOCATE 24,1 : COLOR 10,0
4700 PRINT SOURCE$;" successfully transferred";
4720 KEY(3) OFF
4740 COLOR 7,0 : GOTO 1280
4760 ' --------- Subroutine:  Transmit Block --------------
4780 CALL CHKSUM(O$,CH%) : CNT=10
4800 O$=SOH$+CHR$(RECNUM AND &HFF)+CHR$((NOT RECNUM) AND &HFF)+O$+CHR$(CH%)
4820  LOCATE 25,67: PRINT RECNUM;
4840 LOCATE 25,77,0 : PRINT 10-CNT;
4860 CNT=CNT-1: IF CNT=0 THEN 5080
4880 PRINT #1,O$;
4900 LOCATE 2,1
4920 FOR TIME=1 TO 1000
4940  IF LOC(1) = 0 THEN 5040
4960  C$=INPUT$(1,1)            'get nak or ack
4980  IF C$=NAK$ THEN 4840
5000  IF C$=ACK$ THEN RETURN
5020  COLOR 7,0 : PRINT CHR$(ASC(C$) AND 127);  : COLOR 0,7
5040 NEXT TIME
5060 GOTO 4840                  ' timeout, try again
5080 PRINT "ten consecutive naks or timeouts"
5100 PRINT "Aborting transfer"
5120 CLOSE 2 : RETURN 1280		' go back to terminal mode
5140 '-------- Subroutine: call machine language terminal emulator ---------
5160 KEYNUM% = 13
5180 LOCATE ,,1
5200 CLOSE 1
5220 A%=256 : CALL A%(KEYNUM%)
5240 OPEN "com1:"+SPEED$+",n,8,1" AS 1 : RETURN
5260 '-------- Subroutine: poor mans dumb terminal in basic -------- 
5280 LOCATE ,,1          'turn on cursor
5300 KEY 1,"" : KEY 2,"" : KEY 3,"" : KEY 4,"" : KEY 5,"" : KEY 10,""
5320 ON ERROR GOTO 5460
5340 PRINT #1,
5360 C$=INKEY$
5380 IF LEN(C$) >1 THEN KEYNUM%=ASC(RIGHT$(C$,1))-58 : ON ERROR GOTO 0: RETURN
5400 IF C$ <> ""  THEN PRINT #1,CHR$(ASC(C$) AND 127);
5420 WHILE LOC(1) > 0 : PRINT CHR$(ASC(INPUT$(1,1)) AND 127); : WEND
5440 GOTO 5360
5460 RESUME  ' ignore errors
5480 ' -------- Subroutine: set up status line --------
5500 CSRSAV%=CSRLIN
5520 LOCATE 25,1 : COLOR 7,0 : PRINT SPC(79);
5540 LOCATE 25,1 : PRINT "F1"; : LOCATE 25,23 : PRINT "F2";
5560 LOCATE 25,45: PRINT "F3"; : LOCATE 25,68 : PRINT "F4";
5580 COLOR 0,7
5600 LOCATE 25,3 : PRINT " IBM-->" + SYSTEMTYPE$ + " ";
5620 LOCATE 25,25 : PRINT " " + SYSTEMTYPE$ + "-->IBM ";
5640 LOCATE 25,47 : PRINT " IBM is terminal ";
5660 LOCATE 25,70 : PRINT " Exit ";
5680 LOCATE CSRSAV%,1 : COLOR 7,0
5700 RETURN
5720 '
5740 ' --------------- Download file from remote host --------------------
5760 '
5780 LOCATE 24,1 : PRINT SPC(79); : LOCATE 24,1 : KEY 3,CR$
5800 NBLK=1 'START WITH BLOCK 1
5820 IF SEND$="*" THEN 5980
5840 INPUT "Name of source file on remote system: ", F$
5860 IF F$="" THEN 1280
5880 SOURCE$=F$ : DESTIN$=F$
5900 IF INSTR(1,F$," ") = 0 THEN 5980
5920 SOURCE$=LEFT$(F$,(INSTR(1,F$," ")-1))
5940 DESTIN$=RIGHT$(F$,(LEN(F$)-INSTR(1,F$," ")))
5960 GOTO 6000
5980 INPUT"Name of destination file on IBM PC: ",DESTIN$
6000 IF DESTIN$<>"" THEN 6040 ELSE DESTIN$=SOURCE$
6020 LOCATE CSRLIN-1,37 : PRINT DESTIN$
6040 ON ERROR GOTO 6080
6060 OPEN DESTIN$ FOR OUTPUT AS #2 : ON ERROR GOTO 0 : GOTO 6120
6080 PRINT"Bad IBM file: ";DESTIN$;".  Try again"
6100 RESUME 5980
6120 LOCATE 25,1: PRINT"FTP from REMOTE::",TAB(35);"to IBM::";TAB(57);"Blk";
6140 PRINT TAB(67);"Bad";TAB(74);"Dup";
6160 COLOR 0,7
6180 LOCATE 25,18 : PRINT SOURCE$; : LOCATE 25,43 : PRINT DESTIN$;
6200 IF SEND$ <>"*" THEN PRINT #1, SEND$+MODE$+" "+ SOURCE$ +CR$;
6220 FOR I%=1 TO 300:NEXT I% : WHILE LOC(1) > 0 : O$ = INPUT$(LOC(1),1) : WEND
6240 KEY(3) ON : ON KEY(3) GOSUB 5120	' provide escape to terminal mode
6260 PRINT #1,NAK$;
6280 '
6300  LOCATE 25,60 : PRINT NBLK;
6320  GOSUB 6520
6340  IF O$=EF$ THEN 6420
6360  PRINT #2,O$;
6380  GOTO 6300
6400 '
6420 PRINT #1,ACK$;
6440 COLOR 7,0 : CLOSE 2
6460 LOCATE 24,1 : COLOR 10,0 : PRINT CHR$(7);SOURCE$;" successfully transferred";
6480 KEY(3) OFF
6500 COLOR 7,0 : GOTO 1280
6520 ' --------- Subroutine: Receive a block ---------------
6540 LOCATE 24,1 : CNT = 10
6560 FOR I%= 1 TO 1000
6580   IF LOC(1) = 0 THEN 6620
6600   O$=INPUT$(1,1) : GOTO 6700
6620 NEXT I%
6640 CNT=CNT-1 : IF CNT= 0 THEN 5080 
6660 PRINT #1, NAK$; : GOTO 6560
6680 '
6700 IF O$ = SOH$ THEN 6760
6720 IF O$ = EF$ THEN RETURN
6740 COLOR 7,0 : PRINT CHR$(ASC(O$) AND 127); : COLOR 0,7 : GOTO 6560
6760 WHILE LOC(1) < 131 : WEND : O$=INPUT$(131,1)
6780 A$=SOH$+LEFT$(O$,130) : CALL CHKSUM(A$, CH%)
6800 IF ASC(LEFT$(O$,1)) = (NBLK AND 255) THEN 6840 ' BLOCK WE ARE EXPECTING ?
6820 DUPS%= DUPS%+1:LOCATE 25,77:PRINT STR$(DUPS%);:PRINT #1,ACK$;:GOTO 6560
6840 IF CH% = ASC(MID$(O$,131,1)) THEN 6900
6860 BAD%= BAD%+1 : LOCATE 25,71 : PRINT BAD%;
6880 GOTO 6640
6900 O$ = MID$(O$,3,128)
6920 NBLK=NBLK+1        ' EXPECT NEXT BLOCK
6940 PRINT #1,ACK$;
6960 RETURN
6980 ' machine language Checksum routine (source in CHKSUM.A86)
7000 DATA 35
7020 DATA &H55, &H8B, &HEC, &H8B, &HB6, &H08, &H00, &H8A, &H0C, &HB5
7040 DATA &H00, &H8B, &HB4, &H01, &H00, &H33, &HC0, &HE3, &H05, &H02
7060 DATA &H04, &H46, &HE2, &HFB, &H8B, &HB6, &H06, &H00, &H89, &H04
7080 DATA &H5D, &HCA, &H04, 0, 0

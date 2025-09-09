10 '  IBM Personal Computer implemntation of MODEM2 File transfer protocol
20 '           Copyright (C) 1982  By  William E. Westfield
30 '    Originally written for SRI International, Menlo Park, CA
40 ' 
50 '  This program is InterNet public, due to the help I have frequently
60 '  gotten from the network community.  It may be used for any purpose,
70 '  including comercial purposes, but it may not be resold for profit
80 '  under any circumstances.  Note that you are only entitled to get
90 '  this program free if you have direct access to a computer on the
100 ' ARPANet, UUCP, or CSNet.  Please do not give this program away
110 ' others.  All copies of this program must retain this notice.
120 '
130 ' If you BOUGHT this program, please dont share it with your
140 ' friends, though I dont mind if you tell them (ahem) how great it is.
150 ' As someone put it: "If I make a lot of money selling this program, I
160 ' will be encouraged to produce more high quality software at reasonable
170 ' prices.  If I find pirated copies floating around, I will charge more
180 ' money, protect my programs with unreasonable protection schemes,
185 ' and/or keep them to myself.
190 '
200 DEF SEG=&H3700 : DEFINT A-Z
210 COLOR 7,0 : CLS
220 ON ERROR GOTO 250
230 BLOAD "heath.x",0 : ON ERROR GOTO 0
240 TERPROG%=1 : GOTO 280
250 PRINT "No HEATH.X terminal emulation program."
260 PRINT "Will run dumb BASIC terminal emulator..."
270 TERPROG%=2 : RESUME 280
280 ' set up checksum routine
290 READ L  : CHKSUM = &H10
300 FOR I%=1 TO L: READ J : POKE &HF+I%, J : NEXT I%
310 '
320 NAK$=CHR$(21) : ACK$=CHR$(6) : SOH$=CHR$(1)
321 CR$=chr$(13)  : EF$=CHR$(4)  : NUL$=CHR$(26)
330 '****** customize for your most common remote host ********
340    systemtype$="TOPS-20" : gosub 720 
350  ' systemtype$="UNIX"    : gosub 720 
360  ' systemtype$="VAX"     : gosub 720 
365  ' systemtype$="OTHER"   : gosub 720 
366  ' input "System type: ", systemtype$ : gosub 720
370 '**********************************************************
380 SCREEN 0,0,0 : WIDTH 80
390 KEY OFF : LOCATE ,,1
400 INPUT"Desired terminal line speed: ",SPEED$
410 IF SPEED$="" THEN SPEED$="9600" : locate csrlin-1,30 : print speed$
420 PRINT "First you must establish a MICOM connection to the KL"
430 PRINT " and log in to your acount."
440 ON ERROR GOTO 460
450 OPEN "com1:"+SPEED$+",n,8,1" AS 1 : ON ERROR GOTO 0 : GOTO 490
460 PRINT "Communications error.  Is the Serial line connected ?"
470 INPUT "If not, connect it now and hit RETURN.",A$
480 RESUME 440
490 '
500 '------------ Act as a terminal --------------
510 '
520 GOSUB 1970
530 KEY(3) OFF
540 ON TERPROG% GOSUB 1810,1860
550 ON KEYNUM% GOTO 1120, 2110, 500, 990, 560,560,560,560,560, 590
560 beep : PRINT "Undefined Function Key"
580 GOTO 500
590 '
600 ' -------------- define new remote host comand strings --------------
605 '
606 gosub 610 : goto 500
607 '
610 CLS : PRINT" Redefining the remote host comand strings." : PRINT
620 PRINT" Several system types are already defined.  These are listed"
630 PRINT" below.  To use anouther kind of system, you must specify the"
640 PRINT" individual command strings necessary.  For a description of"
650 PRINT" What these strings should be, see the user manual." : PRINT
660 PRINT" current system type is : "; SYSTEMTYPE$ : PRINT
670 PRINT" Available system types are :"
680 PRINT"	Tops-20 running BillW's MODEM program."
690 PRINT" 	Unix running Lauren's UMODEM program."
700 PRINT" 	Vax VMS running John Perry's FTPGET and FTPSEND." :PRINT
710 INPUT" New system type: "; SYSTEMTYPE$
715 if systemtype$="" then return		'Abort
720 IF SYSTEMTYPE$="vax" OR SYSTEMTYPE$="VAX" THEN 740 ELSE 760
740 SEND$="@drc0:[tools]ftpsend"+cr$ : MODE$="c"+CR$ : LOGOUT$="logout"
750 RECEIVE$="@drc0:[tools]ftpget"+cr$ : systemtype$="VAX" : GOTO 970
760 '
770 IF SYSTEMTYPE$="unix" OR SYSTEMTYPE$="UNIX" THEN 780 ELSE 800
780 SEND$="umodem -ls" : RECEIVE$="umodem -lr" : MODE$="t" : LOGOUT$="logout"
790 systemtype$= "UNIX" : GOTO 970
800 IF SYSTEMTYPE$ = "tops-20" OR SYSTEMTYPE$= "TOPS-20" THEN 820
810 IF SYSTEMTYPE$ = "tops20" OR SYSTEMTYPE$= "TOPS20" THEN 820 ELSE 840
820 SEND$="modem sq" : RECEIVE$="modem rq" : MODE$="a"
830 LOGOUT$="kk" : systemtype$="TOPS-20" : GOTO 970
840 PRINT "Unknown system type '";SYSTEMTYPE$"'. Redfine strings explicitly."
850 PRINT: PRINT "Here are the current values..."
860 PRINT "SEND$=";SEND$;"   RECEIVE$=";RECEIVE$;"   MODE$=";MODE$ : PRINT
870 PRINT : INPUT"SEND$= ",F$
880 IF F$="" THEN return ELSE IF F$ <> "/" THEN SEND$=F$ : GOTO 900
890 LOCATE CSRLIN-1,8 : PRINT SEND$
900 INPUT"RECEIVE$= ",F$
910 IF F$ <> "/" THEN RECEIVE$=F$ : GOTO 930
920 LOCATE CSRLIN-1,11 : PRINT RECEIVE$
930 INPUT"MODE$= ",F$
940 IF F$ <> "/" THEN MODE$=F$ : GOTO 960
950 LOCATE CSRLIN-1,8 : PRINT MODE$
960 INPUT"LOGOUT$= ",LOGOUT$
970 return
980 '
990 ' -------------- EXIT, perhaps logging out -------------------
1000 '
1010 LOCATE 24,1: PRINT SPACE$(79); : LOCATE 24,1
1020 INPUT "Logout (Y or N) ?",YN$
1030 IF LEFT$(YN$,1)="Y" OR LEFT$(YN$,1)="y" THEN 1050
1040 GOTO 1080
1050 PRINT #1,LOGOUT$
1060 FOR I%= 1 TO 300: NEXT: O$=INPUT$(LOC(1),1) 'flush
1070 CLOSE
1080 KEY 1,"List " : KEY 2,"Run"+CR$ : KEY 3,"Load"+CHR$(34): KEY 4,"Save"+CHR$(34)
1090 KEY 5,"Cont"+CR$ : KEY 6,",LPT1:"+CR$
1100 KEY ON : END
1110 '
1120 ' ------------- Upload file to Remote Computer ---------------
1130 '
1140 LOCATE 24,1 : PRINT SPACE$(79); : LOCATE 24,1 : KEY 3,CR$
1150 INPUT "Name of source file on IBM PC: ",F$
1160 IF F$="" THEN 500
1170 SOURCE$=F$ : DESTIN$=F$
1180 IF INSTR(1,F$," ") = 0 THEN 1220
1190 SOURCE$=LEFT$(F$,(INSTR(1,F$," ")-1))
1200 DESTIN$=RIGHT$(F$,(LEN(F$)-INSTR(1,F$," ")))
1210 GOTO 1290
1220 IF RECEIVE$ = "*" THEN 1260
1230 INPUT"Name of destination file on KL: ",DESTIN$
1240 IF DESTIN$<>"" THEN 1260 ELSE DESTIN$=SOURCE$
1250 LOCATE CSRLIN-1,33 : PRINT DESTIN$
1260 ON ERROR GOTO 1310
1270 ' note that "random" access is used to permit uploading of files
1280 ' that contain ^Zs, which basic otherwise thinks means EOF...
1290 OPEN SOURCE$ AS 2 LEN=128 : ON ERROR GOTO 0
1300 GOTO 1330
1310 PRINT "No such file as ";SOURCE$; ".   Try again"
1320 RESUME 1150
1330 NBLKS!=INT(LOF(2)/128)
1340 ON ERROR GOTO 0
1350 IF NBLKS! <> LOF(2)/128 THEN NBLKS!=NBLKS!+1
1360 PRINT "File is";NBLKS!;"blocks long."
1370 CURSAVE=CSRLIN
1380 IF RECEIVE$ <> "*" THEN PRINT#1, RECEIVE$+MODE$+" "+DESTIN$+CR$;
1390 FOR I=1 TO 300:NEXT I
1400 WHILE LOC(1) > 0 : O$ = INPUT$(LOC(1),1) : WEND 'flush echoing
1410 LOCATE 25,1:PRINT "FTP from IBM::";TAB(29);"to KL::";
1420 PRINT TAB(62);"Block";TAB(72);"Retry";
1430 COLOR 0,7
1440 LOCATE 25,15:PRINT SOURCE$;
1450 LOCATE 25,36: PRINT DESTIN$;
1460 O$= INPUT$(1,1) ' wait for initial nak
1470 IF O$<>NAK$ THEN 1460
1480 COLOR 0,7
1490 KEY(3) ON : ON KEY(3) GOSUB 1790 ' provide escape feature
1500 FOR RECNUM=1 TO NBLKS!
1510   FIELD #2,128 AS O$ : GET #2,RECNUM  ' get a record from the file
1520   GOSUB 1610         ' send record to modem
1530 NEXT RECNUM
1540 PRINT #1,EF$
1550 CLOSE 2
1560 COLOR 7,0
1570 LOCATE 24,1 : COLOR 10,0
1580 PRINT SOURCE$;" successfully transferred";
1590 KEY(3) OFF
1600 COLOR 7,0 : GOTO 500
1610 ' --------- Subroutine:  Transmit Block --------------
1620 CALL CHKSUM(O$,CH%)
1630 CNT=10
1640 O$=SOH$+CHR$(RECNUM AND &HFF)+CHR$((NOT RECNUM) AND &HFF)+O$+CHR$(CH% AND &HFF)
1650  LOCATE 25,67: PRINT RECNUM;
1660 LOCATE 25,77,0 : PRINT 10-CNT;
1670 CNT=CNT-1: IF CNT=0 THEN 1770
1680 PRINT #1,O$;
1690 LOCATE 2,1
1700 FOR TIME=1 TO 1000
1710  IF LOC(1) = 0 THEN 1750
1720  C$=INPUT$(1,1)            'get nak or ack
1730  IF C$=NAK$ THEN  LOCATE 1,1 : GOTO 1660
1740  IF C$=ACK$ THEN RETURN
1750 NEXT TIME
1760 GOTO 1660                  ' timeout, try again
1770 PRINT "ten consecutive naks or timeouts"
1780 PRINT "Aborting transfer"
1790 CLOSE 2 : RETURN 500		' go back to terminal mode
1800 '-------- Subroutine: call machine language terminal emulator ---------
1810 KEYNUM% = 13
1820 LOCATE ,,1
1830 CLOSE 1
1840 A%=256 : CALL A%(KEYNUM%)
1850 OPEN "com1:"+SPEED$+",n,8,1" AS 1 : RETURN
1860 '-------- Subroutine: poor mans dumb terminal in basic -------- 
1870 LOCATE ,,1          'turn on cursor
1880 ON ERROR GOTO 1950
1890 PRINT #1,
1900 C$=INKEY$
1910 IF LEN(C$) >1 THEN KEYNUM%=ASC(RIGHT$(C$,1))-58 : ON ERROR GOTO 0: RETURN
1920 IF C$ <> ""  THEN PRINT #1,CHR$(ASC(C$) AND 127);
1930 WHILE LOC(1) > 0 : PRINT CHR$(ASC(INPUT$(1,1)) AND 127); : WEND
1940 GOTO 1900
1950 RESUME  ' ignore errors
1960 ' -------- Subroutine: set up status line --------
1970 CSRSAV%=CSRLIN
1980 LOCATE 25,1 :PRINT SPACE$(79); : LOCATE 25,1 : COLOR 7,0
1990 LOCATE 25,1 : PRINT "F1"; : LOCATE 25,23 : PRINT "F2";
2000 LOCATE 25,45: PRINT "F3"; : LOCATE 25,68 : PRINT "F4";
2010 COLOR 0,7
2020 LOCATE 25,3 : PRINT " IBM-->" + systemtype$ + " ";
2030 LOCATE 25,25 : PRINT " " + systemtype$ + "-->IBM ";
2040 LOCATE 25,47 : PRINT " IBM is terminal ";
2050 LOCATE 25,70 : PRINT " Exit ";
2060 LOCATE CSRSAV%,1 : COLOR 7,0
2070 RETURN
2080 '
2090 ' --------------- Download file from remote host --------------------
2100 '
2110 LOCATE 24,1 : PRINT SPACE$(79); : LOCATE 24,1 : KEY 3,CR$
2120 NBLK=1 'START WITH BLOCK 1
2130 IF SEND$="*" THEN 2210
2140 INPUT "Name of source file on KL: ",F$
2150 IF F$="" THEN 500
2160 SOURCE$=F$ : DESTIN$=F$
2170 IF INSTR(1,F$," ") = 0 THEN 2210
2180 SOURCE$=LEFT$(F$,(INSTR(1,F$," ")-1))
2190 DESTIN$=RIGHT$(F$,(LEN(F$)-INSTR(1,F$," ")))
2200 GOTO 2220
2210 INPUT"Name of destination file on IBM PC: ",DESTIN$
2220 IF DESTIN$<>"" THEN 2240 ELSE DESTIN$=SOURCE$
2230 LOCATE CSRLIN-1,37 : PRINT DESTIN$
2240 ON ERROR GOTO 2260
2250 OPEN DESTIN$ FOR OUTPUT AS #2 : ON ERROR GOTO 0 : GOTO 2280
2260 PRINT"Bad IBM file: ";DESTIN$;".  Try again"
2270 RESUME 2210
2280 LOCATE 25,1: PRINT"FTP from KL::",TAB(35);"to IBM::";TAB(57);"Blk";
2290 PRINT TAB(67);"Bad";TAB(74);"Dup";
2300 COLOR 0,7
2310 LOCATE 25,14 : PRINT SOURCE$; : LOCATE 25,43 : PRINT DESTIN$;
2320 IF SEND$ <>"*" THEN PRINT #1, SEND$+MODE$+" "+F$+CR$;
2330 FOR I%=1 TO 300:NEXT I% : WHILE LOC(1) > 0 : O$ = INPUT$(LOC(1),1) : WEND
2340 KEY(3) ON : ON KEY(3) GOSUB 1790	' provide escape to terminal mode
2350 PRINT #1,NAK$;
2360 '
2370 LOCATE 25,60 : PRINT NBLK;
2380 GOSUB 2500
2390 IF O$=EF$ THEN 2450
2400 IF RIGHT$(O$,1)<>NUL$ THEN 2420
2410 O$=LEFT$(O$,INSTR(O$,NUL$+NUL$))
2420 PRINT #2,O$;
2430 GOTO 2370
2440 '
2450 PRINT #1,ACK$;
2460 COLOR 7,0 : CLOSE 2
2470 LOCATE 24,1 : COLOR 10,0 : PRINT CHR$(7);SOURCE$;" successfully transferred";
2480 KEY(3) OFF
2490 COLOR 7,0 : GOTO 500
2500 ' --------- Subroutine: Receive a block ---------------
2510 LOCATE 24,1 
2520 FOR I%= 1 TO 1000
2530 IF LOC(1) = 0 THEN 2550
2540 O$=INPUT$(1,1) : GOTO 2580
2550 NEXT I%
2560 PRINT #1, NAK$;
2570 GOTO 2520
2580 IF O$=EF$ THEN RETURN
2590 IF O$ <> SOH$ THEN PRINT O$; : GOTO 2520
2600 O$=INPUT$(131,1)
2610 CH%=1		' COMPUTE CHECKSUM
2620 A$=LEFT$(O$,130) : CALL CHKSUM(A$, CH%) : CH% =CH%+1
2630 IF ASC(LEFT$(O$,1)) = (NBLK AND 255) THEN 2650 ' BLOCK WE ARE EXPECTING ?
2640 DUPS%= DUPS%+1 : LOCATE 25,71 : PRINT DUPS%; : PRINT #1,ACK$; : GOTO 2520
2650 IF (CH% AND &HFF) = ASC(MID$(O$,131,1)) THEN 2680
2660 BAD%= BAD%+1 : LOCATE 25,77 : PRINT BAD%; : PRINT #1,NAK$;
2670 GOTO 2520
2680 O$ = MID$(O$,3,128)
2690 NBLK=NBLK+1        ' EXPECT NEXT BLOCK
2700 PRINT #1,ACK$;
2710 RETURN
2720 DATA 35
2730 DATA &H55, &H8B, &HEC, &H8B, &HB6, &H08, &H00, &H8A, &H0C, &HB5
2740 DATA &H00, &H8B, &HB4, &H01, &H00, &H33, &HC0, &HE3, &H05, &H02
2750 DATA &H04, &H46, &HE2, &HFB, &H8B, &HB6, &H06, &H00, &H89, &H04
2760 DATA &H5D, &HCA, &H04, 0, 0

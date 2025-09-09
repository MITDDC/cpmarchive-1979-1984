;		    FINDBAD.ASM ver. 5.4
;		     (revised 05/21/81)
;
;	     NON-DESTRUCTIVE DISK TEST PROGRAM
;
;FINDBAD will find all bad blocks on a disk and build a file
;named [UNUSED].BAD to allocate them, thus "locking out" the
;bad blocks so CP/M will not use them.
;
;Originally written by Gene Cotton,  published in "Interface
;Age", September 1980 issue, page 80.
;
;See notes below concerning 'TEST' conditional assembly option,
;SYSTST and BADUSR directives.
;
;********************************************************
;*							*
;*			  NOTE				*
;*							*
;*   This program has been re-written to allow it to	*
;* work  with (hopefully)  all CP/M 2.x systems, and	*
;* most 1.4 CP/M systems. It has been tested on sev-	*
;* eral different disk systems, including Northstar,	*
;* Micropolis, DJ2D, and  Keith  Petersen's 10 MByte    *
;* hard disk system.  I have tested it personally on	*
;* my "modified" Northstar, under several  different	*
;* formats (including >16K per extent), and have ob-	*
;* no difficulties.					*
;*  If you have have difficulties getting this	pro-	*
;* gram  to run, AND if you  are using CP/M 2.x, AND	*
;* if  you  know  your CBIOS  to be  bug-free, leave	*
;* me a message on the CBBS mentioned below ... I am	*
;* interested in making this program  as "universal"	*
;* as possible. 					*
;*  I can't help with any version of CP/M 1.4, other    *
;* than  "standard" versions  (whatever that means),	*
;* because there are just too many heavily  modified	*
;* versions available.					*
;*  One  possible  problem you may  find is with the	*
;* system tracks of your diskettes...if they are  of	*
;* a  different density  than the data	tracks, then	*
;* see the note regarding the "SYSTST" equate.		*
;*							*
;*				Ron Fowler		*
;*				Westland, Mich		*
;*				7 April, 1981		*
;*							*
;********************************************************
;
;SYSTST and BADUSR options:
;  Many double-density disk systems have single-density system 
;tracks.  If this is true with your system, you can change the 
;program to skip the system tracks,  without re-assembling it.  
;To do this, set the byte at 103H to a 0 if you don't want the 
;system  tracks tested,  otherwise leave it 1.   This is  also 
;necessary if you have a "blocked" disk system;  that is, when 
;the same physical disk is seperated into logical disks by use 
;of the SYSTRK word in the disk parameter block.
;   If you are a CP/M 2.x user, you may assign the user number 
;where  [UNUSED.BAD] will be created by changing the  byte  at 
;104H  to  the  desired user number.   If you want it  in  the 
;default user,  then leave it 0FFH.  CP/M 1.4 users can ignore 
;this byte altogether.
;
;Note that these changes can be done with DDT as follows:
;
;		A>DDT FINDBAD.COM
;		-S103
;		103 01 0	;DON'T TEST SYSTEM TRACKS
;		104 FF F	;PUT [UNUSED.BAD] IN USER 15
;		105 31 .	;DONE WITH CHANGES
;		-^C
;		A>SAVE XX FINDBAD.COM
;
;----------------------------------------------------------------
;NOTE: If you want to  update this program, make sure you have
;the latest version first.  After adding your changes, please
;modem a copy of the new file to "TECHNICAL CBBS" in Dearborn,
;Michigan - phone 313-846-6127 (110, 300, 450 or 600 baud).
;Use the filename FINDBAD.NEW.	 (KBP)
;
;Modifications/updates: (in reverse order to minimize reading time)
;
;05/21/81 Corrected error in description of how to set SYSTST
;	  byte at 103h.  Added CRLF to block error message. (KBP)
;
;05/19/81 Corrected omission in DOLOG routine so that BADUSR
;	  will work correctly. Thanks to Art Larky. (CHS)
;
;04/10/81 Changed extent DB from -1 to 0FFH so program can be
;	  assembled by ASM.  Added BADUSR info to instructions
;	  for altering with DDT.  (KBP)
;
;04/09/81 Changed sign-on message, added control-c abort test,
;	  added '*' to console once each track	(RGF)
;
;04/07/81 Re-wrote to add the following features:
;		1) "Universal" operation
;		2) DDT-changeable "SYSTRK" boolean (see above)
;		3) Report to console when bad blocks are detected
;		4) Changed the method of printing the number of
;		   bad blocks found (at end of run)...the old
;		   method used too much code, and was too cum-
;		   bersome.
;		5) Made several cosmetic changes
;
;			Ron Fowler
;			Westland, Mich
;
;03/23/81 Set equates to standard drive and not double-sided. (KBP)
;
;03/01/81 Corrected error for a Horizon with double sided drive.
;	  This uses 32k extents, which code did not take into account.
;	  (Bob Clyne)
;
;02/05/81 Merged 2/2/81 and 1/24/81 changes, which were done
;	  independently by Clyne and Mack.  (KBP)
;
;02/02/81 Added equates for North Star Horizon - 5.25" drives,
;	  double density, single and double sided. (Bob Clyne)
;
;01/24/81 Added equates for Jade DD disk controller
;	  (Pete H. Mack)
;
;01/19/81 Added equates for Icom Microfloppy 5.25" drives.
;	  (Eddie Currie)
;
;01/05/81 Added equates for Heath H-17 5.25" drives.
;	  (Ben Goldfarb)
;
;12/08/80 Added equates for National Multiplex D3S/D4S
;	  double-density board in various formats.
;	  (David Fiedler)
;
;09/22/80 Added equates for Morrow Disk Jockey 2D/SS, 256,
;	  512 and 1024-byte sector options.  Fix 'S2' update
;	  flag for larger max number of extents. Cleaned up
;	  file. (Ben Bronson and KBP)
;
;09/14/80 Corrected DGROUP equate for MMDBL. Added new routine
;	  to correct for IMDOS group allocation.  Corrected
;	  error in instructions for using TEST routine.
;	  (CHS) (AJ) (KBP) - (a group effort)
;
;09/08/80 Fixed several errors in Al Jewer's mods.  Changed
;	  return to CP/M to warm boot so bitmap in memory will
;	  be properly updated. Added conditional assembly for
;	  testing program. (KBP)
;
;09/02/80 Added IMDOS double-density equates & modified for 
;	  more then 256 blocks per disk. (Al Jewer)
;
;09/01/80 Changed equates so that parameters are automatically
;	  set for each disk system conditional assembly (KBP)
;
;08/31/80 Add conditional assembly for Digital Microsystems FDC3
;	  controller board in double-density format and fix to
;	  do 256 blocks in one register. (Thomas V. Churbuck)
;
;08/31/80 Correct MAXB equate - MAXB must include the directory
;	  blocks as well as the data blocks.  Fix to make sure
;	  any [UNUSED].BAD file is erased before data area is
;	  checked. (KBP)
;
;08/30/80 Added conditional assembly for Micromation
;	  double-density format. (Charles H. Strom)
;
;08/27/80 Fix missing conditional assembly in FINDB routine.
;	  Put version number in sign-on message. (KBP)
;
;08/26/80 Modified by Keith Petersen, W8SDZ, to:
;	  (1) Add conditional assembly for 1k/2k groups
;	  (2) Add conditional assembly for standard drives
;	      and Micropolis MOD II
;	  (3) Make compatible with CP/M-2.x
;	  (4) Remove unneeded code to check for drive name
;	      (CP/M does it for you and returns it in the FCB)
;	  (5) Changed to open additional extents as needed for
;	      overflow, instead of additional files
;	  (6) Add conditional assembly for system tracks check
;	      (some double-density disks have single-density
;	      system tracks which cannot be read by this program)
;	  (7) Increased stack area (some systems use more than
;	      others).
;
;08/06/80 Added comments and crunched some code.
;	  KELLY SMITH.	805-527-9321 (Modem, 300 Baud)
;			805-527-0518 (Verbal)
;
;
;			Using the Program
;
; Before  using this program to "reclaim" a diskette,  it  is
;recommended that the diskette be reformatted. If this is not
;possible,  at least assure yourself that any existing	files
;on the diskette  do not contain unreadable  sectors.  If you
;have changed disks since the last warm-boot, you  must warm-
;boot again before running this program.
;
; To  use the program,	insert	both the disk containing  the
;program  FINDBAD.COM and the diskette to be checked into the
;disk drives. It is possible that the diskette containing the
;program is the one to be checked. Assume that the program is
;on drive "A" and the suspected bad disk is on drive "B".  In
;response to the CP/M prompt "A>",  type in FINDBAD B:.  This
;will  load the file FINDBAD.COM from drive "A" and test  the
;diskette  on  drive "B" for  unreadable  sectors.  The  only
;allowable  parameter  after  the  program name  is  a	drive
;specification	(of the form " N:") for up to four (A  to  D)
;disk drives.  If no drive is specified, the currently logged
;in drive is assumed to contain the diskette to check.
;
; The  program first checks the CP/M System tracks (0 and 1),
;and  any  errors here prohibit the disk from being  used  on
;drive	"A",  since all "warm  boots" occur using the  system
;tracks from the "A" drive.
;
; The  program next checks the first two data blocks  (groups
;to some of us) containing the directory of the diskette.  If
;errors  occur	here,  the  program  terminates  and  control
;returns  to  CP/M  (no other data blocks are  checked	since
;errors in the directory render the disk useless).
;
; Finally,  all  the remaining data blocks are	checked.  Any
;sectors  which  are  unreadable cause the data  block	which
;contains them to be stored temporarily as a "bad block".  At
;the end of this phase,  the message "XX bad blocks found" is
;displayed (where XX is replaced by the number of bad blocks,
;or "No" if no read errors occur).  If bad blocks occur,  the
;filname [UNUSED].BAD is created, the list of "bad blocks" is
;placed  in  the allocation map of the	directory  entry  for
;[UNUSED].BAD,	and the file is closed.  Note,	that when the
;number of "bad blocks" exceeds 16,  the  program  will  open
;additional  extents  as  required  to	hold the overflow.  I
;suggest that if the diskette has more than  32 "bad blocks",
;perhaps it should be sent to the "big disk drive in the sky"
;for the rest it deserves.
;
; The  nifty part of all this is that if any "bad blocks"  do
;occur, they are allocated to [UNUSED].BAD and no longer will
;be available to CP/M for future allocation...bad sectors are
;logically locked out on the diskette!
;
;
;	       Using the TEST conditional assembly
;
;A  conditional  assembly has been added to allow  testing  this 
;program  to  make sure it is reading all sectors on  your  disk 
;that  are accessible to CP/M.	The program reads the disk on  a 
;block by block basis, so it is necessary to first determine the 
;number of blocks present.  To start, we must know the number of 
;sectors/block (8 sectors/block for standard IBM single  density 
;format).  If  this  value  is	not  known,  it  can  easily  be 
;determined  by saving one page in a test file and interrogating 
;using the STAT command:
;
;	A>SAVE 1 TEST.SIZ
;	A>STAT TEST.SIZ
;
;For standard single-density STAT will report this file as being
;1k.  The file size reported (in bytes) is the size of a  block. 
;This  value  divided  by 128 bytes/sector  (the  standard  CP/M 
;sector  size)	will  give sectors/block.  For	our  IBM  single 
;density example, we have:
;
;  (1024 bytes/block) / (128 bytes/sector) = 8 sectors/block.
;
;We  can now calculate blocks/track (assuming we know the number 
;sectors/track). In our example:
;
;  (26 sectors/track) / (8 sectors/block) = 3.25 blocks/track
;
;Now  armed with the total number of data tracks (75 in our  IBM 
;single density example), we get total blocks accessible: 
;
;  75 (tracks/disk) x (3.25 blocks/track) = 243.75 blocks/disk 
;
;CP/M cannot access a fractional block, so we round down (to 243 
;blocks  in  our  example).  Now  multiplying  total  blocks  by 
;sectors/block	results in total sectors as should  be	reported 
;when TEST is set TRUE and a good disk is read. For our example, 
;this value is 1944 sectors. 
;
;Finally,  note that if SYSTST is set to 0,  the sectors present 
;on  the  first  two tracks must be added in  as  well.  In  the 
;previous  example,  this  results in  1944 + 52 = 1996  sectors 
;reported by the TEST conditional.
;
;Run the program on a KNOWN-GOOD disk.	It should report that it
;has read  the	correct number of sectors.  The test conditional
;assembly should then be set FALSE and the program re-assembled.
;The test routines  cannot be left in  because this program does
;not read all the sectors in a block that is found to be bad and
;thus will report an inaccurate number of sectors read.
;
;
;Define TRUE and FALSE
;
FALSE	EQU	0
TRUE	EQU	NOT FALSE
;
;******************************************************************
;
;Conditional assembly switch for testing this program
;(for initial testing phase only - see remarks above)
;
TEST	EQU	FALSE	;TRUE FOR TESTING ONLY
;
;******************************************************************
;
;System equates
;
BASE	EQU	0	;STANDARD CP/M BASE ADDRESS (4200H FOR ALTCPM)
BDOS	EQU	BASE+5	;CP/M WARM BOOT ENTRY
FCB	EQU	BASE+5CH;CP/M DEFAULT FCB LOCATION
;
;Define ASCII characters used
;
CR	EQU	0DH	;CARRIAGE RETURN CHARACTER
LF	EQU	0AH	;LINE FEED CHARACTER
TAB	EQU	09H	;TAB CHARACTER
;
DPBOFF	EQU	3AH	;CP/M 1.4 OFFSET TO DPB WITHIN BDOS
TRNOFF	EQU	15	;CP/M 1.4 OFFSET TO SECTOR XLATE ROUTINE
;
;
	ORG	BASE+100H
;
	JMP	START	;JMP AROUND OPTION BYTES
;
;If you want the system tracks tested, then
;put a 1 here, otherwise 0.
;
SYSTST: DB	1	;0 IF NO SYS TRACKS, OTHERWISE 1
;
;If you are a CP/M 2.x user, change this byte
;to the user number you want [UNUSED].BAD to
;reside in.  If you want it in the default
;user, then leave it 0FFH.  CP/M 1.4 users
;can ignore this byte altogether.
;
BADUSR: DB	0FFH	;USER # WHERE [UNUSED.BAD] GOES
			;0FFH = DEFAULT USER
;
START:	LXI	SP,NEWSTK ;MAKE NEW STACK
	CALL	START2	;GO PRINT SIGNON
	DB	CR,LF,'FINDBAD - ver 5.4'
	DB	CR,LF,'Bad sector lockout '
	DB	'program',CR,LF
	DB	'Universal version',CR,LF
	DB	CR,LF,'Type CTL-C to abort',CR,LF,'$'
;
START2: POP	D	;GET MSG ADRS
	MVI	C,9	;BDOS PRINT BUFFER FUNCTION
	CALL	BDOS	;PRINT SIGN-ON MSG
	CALL	SETUP	;SET BIOS ENTRY, AND CHECK DRIVE
	CALL	ZMEM	;ZERO ALL AVAILABLE MEMORY
	CALL	FINDB	;ESTABLISH ALL BAD BLOCKS
	JZ	NOBAD	;SAY NO BAD BLOCKS, IF SO
	CALL	SETDM	;FIX DM BYTES IN FCB
;
NOBAD:	CALL	CRLF
	MVI	A,TAB
	CALL	TYPE
	LXI	D,NOMSG ;POINT FIRST TO 'NO'
	LHLD	BADBKS	;PICK UP # BAD BLOCKS
	MOV	A,H	;CHECK FOR ZERO
	ORA	L
	JZ	PMSG1	;JUMP IF NONE
	CALL	DECOUT	;OOPS..HAD SOME BAD ONES, REPORT
	JMP	PMSG2
;
PMSG1:	MVI	C,9	;BDOS PRINT BUFFER FUNCTION
	CALL	BDOS
;
PMSG2:	LXI	D,ENDMSG ;REST OF EXIT MESSAGE
;
PMSG:	MVI	C,9
	CALL	BDOS
;
	IF	TEST
	MVI	A,TAB	;GET A TAB
	CALL	TYPE	;PRINT IT
	LHLD	SECCNT	;GET NUMBER OF SECTORS READ
	CALL	DECOUT	;PRINT IT
	LXI	D,SECMSG ;POINT TO MESSAGE
	MVI	C,9	;BDOS PRINT BUFFER FUNCTION
	CALL	BDOS	;PRINT IT
	ENDIF		;TEST
;
	JMP	BASE	;EXIT TO CP/M WARM BOOT
;
;Get actual address of BIOS routines
;
SETUP:	LHLD	BASE+1	;GET BASE ADDRESS OF BIOS VECTORS
;
;WARNING...Program modification takes place here...do not change.
;
	LXI	D,24	 ;OFFSET TO "SETDSK"
	DAD	D
	SHLD	SETDSK+1 ;FIX OUR CALL ADDRESS
	LXI	D,3	 ;OFFSET TO "SETTRK"
	DAD	D
	SHLD	SETTRK+1 ;FIX OUR CALL ADDRESS
	LXI	D,3	 ;OFFSET TO "SETSEC"
	DAD	D
	SHLD	SETSEC+1 ;FIX OUR CALL ADDRESS
	LXI	D,6	 ;OFFSET TO "DREAD"
	DAD	D
	SHLD	DREAD+1  ;FIX OUR CALL ADDRESS
	LXI	D,9	 ;OFFSET TO CP/M 2.x SECTRAN
	DAD	D
	SHLD	SECTRN+1 ;FIX OUR CALL ADDRESS
	MVI	C,12	 ;GET VERSION FUNCTION
	CALL	BDOS
	MOV	A,H	 ;SAVE AS FLAG
	ORA	L
	STA	VER2FL
	JNZ	GDRIV	 ;SKIP 1.4 STUFF IF IS 2.x
	LXI	D,TRNOFF ;CP/M 1.4 OFFSET TO SECTRAN
	LHLD	BDOS+1	 ;SET UP JUMP TO 1.4 SECTRAN
	MVI	L,0
	DAD	D
	SHLD	SECTRN+1
;
;Check for drive specification
;
GDRIV:	LDA	FCB	;GET DRIVE NAME
	MOV	C,A
	ORA	A	;ZERO?
	JNZ	GD2	;IF NOT,THEN GO SPECIFY DRIVE
	MVI	C,25	;GET LOGGED-IN DRIVE
	CALL	BDOS
	INR	A	;MAKE 1-RELATIVE
	MOV	C,A
;
GD2:	LDA	VER2FL	;IF CP/M VERSION 2.x
	ORA	A
	JNZ	GD3	;  SELDSK WILL RETURN SEL ERR
;
;Is CP/M 1.4, which doesn't return a select
;error, so we have to do it here
;
	MOV	A,C
	CPI	4+1	;CHECK FOR HIGHEST DRIVE NUMBER
	JNC	SELERR	;SELECT ERROR
;
GD3:	DCR	C	;BACK OFF FOR CP/M
	PUSH	B	;SAVE DISK SELECTION
	MOV	E,C	;ALIGN FOR BDOS
	MVI	C,14	;SELECT DISK FUNCTION
	CALL	BDOS
	POP	B	;GET BACK DISK NUMBER
;
;EXPLANATION: WHY WE DO THE SAME THING TWICE
;
;	You might notice that we are
;	doing the disk selection twice,
;	once by a BDOS call and once by
;	direct BIOS call. The reason for this:
;
;	The BIOS call is necessary in order to
;	get the necessary pointer back from CP/M
;	(2.x) to find the sector translate table.
;	The BDOS call is necessary to keep CP/M
;	in step with the  BIOS...we may later
;	have to create a [UNUSED].BAD file, and
;	CP/M must know which drive we are using.
;			     (RGF)
;
SETDSK: CALL	$-$	;DIRECT BIOS VEC FILLED IN AT INIT
	LDA	VER2FL
	ORA	A
	JZ	DOLOG	;JUMP IF CP/M 1.4
	MOV	A,H
	ORA	L	;CHECK FOR 2.x 
	JZ	SELERR	;JUMP IF SELECT ERROR
	MOV	E,M	;GET SECTOR TABLE PNTR
	INX	H
	MOV	D,M
	INX	H
	XCHG
	SHLD	SECTBL	;STORE IT AWAY
	LXI	H,8	;OFFSET TO DPB POINTER
	DAD	D
	MOV	A,M	;PICK UP DPB POINTER
	INX	H	;  TO USE
	MOV	H,M	;  AS PARAMETER
	MOV	L,A	;  TO LOGIT
;
DOLOG:	CALL	LOGIT	;LOG IN DRIVE, GET DISK PARMS
	CALL	GETDIR	;CALCULATE DIRECTORY INFORMATION
;
;Now set the required user number
;
	LDA	VER2FL
	ORA	A
	RZ		;NO USERS IN CP/M 1.4
	LDA	BADUSR	;GET THE USER NUMBER
	CPI	0FFH	;IF IT IS 0FFH, THEN RETURN
	RZ
	MOV	E,A	;BDOS CALL NEEDS USER # IN E
	MVI	C,32	;GET/SET USER CODE
	CALL	BDOS
	RET
;
;Look for bad blocks
;
FINDB:	LDA	SYSTST
	ORA	A
	JZ	DODIR	;JUMP IF NO SYS TRACKS TO BE TESTED
	CALL	CHKSYS	;CHECK FOR BAD BLOCKS ON TRACK 0 AND 1
;
DODIR:	CALL	CHKDIR	;CHECK FOR BAD BLOCKS IN DIRECTORY
	CALL	TELL1
	DB	CR,LF,'Testing data area...',CR,LF,'$'
;
TELL1:	POP	D
	MVI	C,9	;BDOS PRINT STRING FUNCTION
	CALL	BDOS
	CALL	ERAB	;ERASE ANY [UNUSED].BAD FILE
	LHLD	DIRBKS	;START AT FIRST DATA BLOCK
	MOV	B,H	;PUT INTO BC
	MOV	C,L
;
FINDBA: CALL	READB	;READ THE BLOCK
	CNZ	SETBD	;IF BAD, ADD BLOCK TO LIST
	INX	B	;BUMP TO NEXT BLOCK
	LHLD	DSM
	MOV	D,B	;SET UP FOR (MAXGRP - CURGRP)
	MOV	E,C
	CALL	SUBDE	;DO SUBTRACT: (MAXGRP - CURGRP)
	JNC	FINDBA	;UNTIL CURGRP>MAXGRP
	CALL	CRLF
	LHLD	DMCNT	;GET NUMBER OF BAD SECTORS
	MOV	A,H
	ORA	L	;SET ZERO FLAG, IF NO BAD BLOCKS
	RET		;RETURN FROM "FINDB"
;
;Check system tracks, notify user if bad, but continue
;
CHKSYS: CALL	CHSY1	;PRINT MESSAGE
	DB	CR,LF,'Testing system tracks...',CR,LF,'$'
;
CHSY1:	POP	D
	MVI	C,9	;PRINT STRING FUNCTION
	CALL	BDOS
	LXI	H,0	;SET TRACK 0, SECTOR 1
	SHLD	TRACK
	INX	H
	SHLD	SECTOR
;
CHKSY1: CALL	READS	;READ A SECTOR
	JNZ	SYSERR	;NOTIFY, IF BAD BLOCKS HERE
	LHLD	SYSTRK	;SET UP (TRACK-SYSTRK)
	XCHG
	LHLD	TRACK
	CALL	SUBDE	;DO THE SUBTRACT
	JC	CHKSY1	;LOOP WHILE TRACK < SYSTRK
	RET		;RETURN FROM "CHKSYS"
;
SYSERR: LXI	D,ERMSG5 ;SAY NO GO, AND BAIL OUT
	MVI	C,9	;BDOS PRINT BUFFER FUNCTION
	CALL	BDOS
	RET		;RETURN FROM "SYSERR"
;
;Check for bad blocks in directory area
;
CHKDIR: CALL	CHKD1
	DB	CR,LF,'Testing directory area...',CR,LF,'$'
;
CHKD1:	POP	D
	MVI	C,9	;BDOS PRINT STRING FUNCTION
	CALL	BDOS
	LXI	B,0	;START AT BLOCK 0
;
CHKDI1: CALL	READB	;READ A BLOCK
	JNZ	ERROR6	;IF BAD, INDICATE ERROR IN DIRECTORY AREA
	INX	B	;BUMP FOR NEXT BLOCK
	LHLD	DIRBKS	;SET UP (CURGRP - DIRBKS)
	DCX	H	;MAKE 0-RELATIVE
	MOV	D,B
	MOV	E,C
	CALL	SUBDE	;DO THE SUBTRACT
	JNC	CHKDI1	;LOOP UNTIL CURGRP > DIRGRP
	RET		;RETURN FROM "CHKDIR"
;
;Read all sectors in block, and return zero flag set if none bad
;
READB:	CALL	CNVRTB	;CONVERT TO TRACK/SECTOR IN H&L REGS.
	LDA	BLM
	INR	A	;NUMBER OF SECTORS/BLOCK
	MOV	D,A	;  IN D REG
;
READBA: PUSH	D
	CALL	READS	;READ SKEWED SECTOR
	POP	D
	RNZ		;ERROR IF NOT ZERO...
	DCR	D	;DEBUMP SECTOR/BLOCK
	JNZ	READBA	;DO NEXT, IF NOT FINISHED
	RET		;RETURN FROM "READBA"
;
;Convert block number to track and skewed sector number
;
CNVRTB: PUSH	B	;SAVE CURRENT GROUP
	MOV	H,B	;NEED IT IN HL
	MOV	L,C	; FOR EASY SHIFTING
	LDA	BSH	;DPB VALUE THAT TELLS HOW TO
;
SHIFT:	DAD	H	;  SHIFT GROUP NUMBER TO GET
	DCR	A	;  DISK-DATA-AREA RELATIVE
	JNZ	SHIFT	;  SECTOR NUMBER
	XCHG		;REL SECTOR # INTO DE
	LHLD	SPT	;SECTORS PER TRACK FROM DPB
	CALL	NEG	;FASTER TO DAD THAN CALL SUBDE
	XCHG
	LXI	B,0	;INITIALIZE QUOTIENT
;
;Divide by number of sectors
;	quotient = track
;	     mod = sector
;
DIVLP:	INX	B	;DIRTY DIVISION
	DAD	D
	JC	DIVLP
	DCX	B	;FIXUP LAST
	XCHG
	LHLD	SPT
	DAD	D
	INX	H
	SHLD	SECTOR	;NOW HAVE LOGICAL SECTOR
	LHLD	SYSTRK	;BUT BEFORE WE HAVE TRACK #,
	DAD	B	;  WE HAVE TO ADD SYS TRACK OFFSET
	SHLD	TRACK
	POP	B	;THIS WAS OUR GROUP NUMBER
	RET
;
;READS reads a logical sector (if it can)
;and returns zero flag set if no error.
;
READS:	PUSH	B	;SAVE THE GROUP NUMBER
	CALL	LTOP	;CONVERT LOGICAL TO PHYSICAL
	LDA	VER2FL	;NOW CHECK VERSION
	ORA	A
	JZ	NOTCP2	;SKIP THIS STUFF IF CP/M 1.4
	LHLD	PHYSEC	;GET PHYSICAL SECTOR
	MOV	B,H	;INTO BC
	MOV	C,L
;
SETSEC: CALL	$-$	;ADDRS FILLED IN AT INIT
;
;QUICK NOTE OF EXPLANATION: This code appears
;as if we skipped the SETSEC routine for 1.4
;CP/M users.  That's not true; in CP/M 1.4, the
;call within the LTOP routine to SECTRAN  ac-
;tually does the set sector, so no need to do
;it twice.      (RGF)
;
NOTCP2: LHLD	TRACK	;NOW SET THE TRACK
	MOV	B,H	;CP/M WANTS IT IN BC
	MOV	C,L
;
SETTRK: CALL	$-$	;ADDRS FILLED IN AT INIT
;
;Now do the sector read
;
DREAD:	CALL	$-$	;ADDRS FILLED IN AT INIT
	ORA	A	;SET FLAGS
	PUSH	PSW	;SAVE ERROR FLAG
;
	IF	TEST
	LHLD	SECCNT	;GET SECTOR COUNT
	INX	H	;ADD ONE
	SHLD	SECCNT	;SAVE NEW COUNT
	ENDIF		;TEST
;
	LHLD	SECTOR	;GET LOGICAL SECTOR #
	INX	H	;WE WANT TO INCREMENT TO NEXT
	XCHG		;BUT FIRST...CHECK OVERFLOW
	LHLD	SPT	;  BY DOING (SECPERTRK-SECTOR)
	CALL	SUBDE	;DO THE SUBTRACTION
	XCHG
	JNC	NOOVF	;JUMP IF NOT SECTOR>SECPERTRK
;
;Sector overflow...bump track number, reset sector
;
	LHLD	TRACK
	INX	H
	SHLD	TRACK
	MVI	A,'*'	;TELL CONSOLE ANOTHER TRACK DONE
	CALL	TYPE
	CALL	STOP	;SEE IF CONSOLE WANTS TO QUIT
	LXI	H,1	;NEW SECTOR NUMBER ON NEXT TRACK
;
NOOVF:	SHLD	SECTOR	;PUT SECTOR AWAY
	POP	PSW	;GET BACK ERROR FLAGS
	POP	B	;RESTORE GROUP NUMBER
	RET
;
;Convert logical sector # to physical
;
LTOP:	LHLD	SECTBL	;SET UP PARAMETERS
	XCHG		;  FOR CALL TO SECTRAN
	LHLD	SECTOR
	MOV	B,H
	MOV	C,L
	DCX	B	;ALWAYS CALL SECTRAN W/ZERO-REL SEC #
;
SECT1:	CALL	SECTRN	;DO THE SECTOR TRANSLATION
	LDA	SPT+1	;CHECK IF BIG TRACKS
	ORA	A	;SET FLAGS (TRACKS > 256 SECTORS)
	JNZ	LTOP1	;NO SO SKIP
	MOV	H,A	;ZERO OUT UPPER 8 BITS
;
LTOP1:	SHLD	PHYSEC	;PUT AWAY PHYSICAL SECTOR
	RET
;
;Sector translation vector
;
SECTRN: JMP	$-$	;FILLED IN AT INIT
;
;Put bad block in bad block list
;
SETBD:	PUSH	B
	CALL	SETBD1
	DB	CR,LF,'Bad block: $'
;
SETBD1: POP	D	;RETRIEVE ARG
	MVI	C,9	;PRINT STRING
	CALL	BDOS
	POP	B	;GET BACK BLOCK NUMBER
	MOV	A,B
	CALL	HEXO	;PRINT IN HEX
	MOV	A,C
	CALL	HEXO
	CALL	CRLF
	LHLD	DMCNT	;GET NUMBER OF SECTORS
	LDA	BLM	;GET BLOCK SHIFT VALUE
	INR	A	;MAKES SECTOR/GROUP VALUE
	MOV	E,A	;WE WANT 16 BITS
	MVI	D,0
	DAD	D	;BUMP BY NUMBER IN THIS BLOCK
	SHLD	DMCNT	;UPDATE NUMBER OF SECTORS
	LHLD	BADBKS	;INCREMENT NUMBER OF BAD BLOCKS
	INX	H
	SHLD	BADBKS
	LHLD	DMPTR	;GET POINTER INTO DM
	MOV	M,C	;...AND PUT BAD BLOCK NUMBER
	INX	H	;BUMP TO NEXT AVAILABLE EXTENT
	LDA	DSM+1	;CHECK IF 8 OR 16 BIT BLOCK SIZE
	ORA	A
	JZ	SMGRP	;JUMP IF 8 BIT BLOCKS
	MOV	M,B	;ELSE STORE HI BYTE OF BLOCK #
	INX	H	;AND BUMP POINTER
;
SMGRP:	SHLD	DMPTR	;SAVE DM POINTER, FOR NEXT TIME THROUGH HERE
	RET		;RETURN FROM "SETBD"
;
;Eliminate any previous [UNUSED].BAD entries
;
ERAB:	LXI	D,BFCB	;POINT TO BAD FCB
	MVI	C,19	;BDOS DELETE FILE FUNCTION
	CALL	BDOS
	RET
;
;Create [UNUSED].BAD file entry
;
OPENB:	LXI	D,BFCB	;POINT TO BAD FCB
	MVI	C,22	;BDOS MAKE FILE FUNCTION
	CALL	BDOS
	CPI	0FFH	;CHECK FOR OPEN ERROR
	RNZ		;RETURN FROM "OPENB", IF NO ERROR
	JMP	ERROR7	;BAIL OUT...CAN'T CREATE [UNUSED].BAD
;
CLOSEB: XRA	A
	LDA	BFCB+14 ;GET CP/M 2.x 'S2' BYTE
	ANI	1FH	;ZERO UPDATE FLAGS
	STA	BFCB+14 ;RESTORE IT TO OUR FCB (WON'T HURT 1.4)
	LXI	D,BFCB	;FCB FOR [UNUSED].BAD
	MVI	C,16	;BDOS CLOSE FILE FUNCTION
	CALL	BDOS
	RET		;RETURN FROM "CLOSEB"
;
;Move bad area DM to BFCB
;
SETDM:	LXI	H,DM	;GET DM
	SHLD	DMPTR	;SAVE AS NEW POINTER
	LDA	EXM	;GET THE EXTENT SHIFT FACTOR
	MVI	C,0	;INIT BIT COUNT
	CALL	COLECT	;GET SHIFT VALUE
	LXI	H,128	;STARTING EXTENT SIZE
	MOV	A,C	;FIRST SEE IF ANY SHIFTS TO DO
	ORA	A
	JZ	NOSHFT	;JUMP IF NONE
;
ESHFT:	DAD	H	;SHIFT
	DCR	A	;BUMP
	JNZ	ESHFT	;LOOP
;
NOSHFT: PUSH	H	;SAVE THIS, IT IS RECORDS PER EXTENT
	LDA	BSH	;GET BLOCK SHIFT
	MOV	B,A
;
BSHFT:	CALL	ROTRHL	;SHIFT RIGHT
	DCR	B
	JNZ	BSHFT	;TO GET BLOCKS PER EXTENT
	MOV	A,L	;IT'S IN L (CAN'T BE >16)
	STA	BLKEXT	;SETDME WILL NEED THIS LATER
	POP	H	;GET BACK REC/EXT
;
SET1:	XCHG		;NOW HAVE REC/EXTENT IN DE
	LHLD	DMCNT	;COUNT OF BAD SECTORS
;
SETDMO: PUSH	H	;SET FLAGS ON (DMCNT-BADCNT)
	CALL	SUBDE	;HAVE TO SUBTRACT FIRST
	MOV	B,H	;SAVE RESULT IN BC
	MOV	C,L
	POP	H	;THIS POP MAKES IT COMPARE ONLY
	JC	SETDME	;JUMP IF LESS THAN 1 EXTENT WORTH
	MOV	A,B
	ORA	C	;TEST IF SUBTRACT WAS 0
	JZ	EVENEX	;EXTENT IS EXACTLY FILLED (SPL CASE)
	MOV	H,B	;RESTORE RESULT TO HL
	MOV	L,C
	PUSH	H	;SAVE TOTAL
	PUSH	D	;AND SECTORS/EXTENT
	XCHG
	CALL	SETDME	;PUT AWAY ONE EXTENT
	XCHG
	SHLD	DMPTR	;PUT BACK NEW DM POINTER
	POP	D	;GET BACK SECTORS/EXTENT
	POP	H	;AND COUNT OF BAD SECTORS
	JMP	SETDMO	;AND LOOP
;
;Handle the special case of a file that ends on an extent
;boundary.  CP/M requires that such a file have a succeeding
;empty extent in order for the BDOS to properly access the file.
;
EVENEX: XCHG		;FIRST SET EXTENT W/BAD BLOCKS
	CALL	SETDME
	XCHG
	SHLD	DMPTR
	LXI	H,0	;NOW SET ONE WITH NO DATA BLOCKS
;
;Fill in an extent's worth of bad sectors/block numbers.
;Also fill in the extent number in the FCB.
;
SETDME: PUSH	H	;SAVE RECORD COUNT
	LDA	EXTNUM	;UPDATE EXTENT BYTE
	INR	A
	STA	EXTNUM	;SAVE FOR LATER
	STA	BFCB+12 ; AND PUT IN FCB
	CALL	OPENB	;OPEN THIS EXTENT
	POP	H	;RETRIEVE REC COUNT
;
;Divide record count by 128 to get the number
;of logical extents to put in the EX field
;
	MVI	B,0	;INIT QUOTIENT
	LXI	D,-128	;-DIVISOR
	MOV	A,H	;TEST FOR SPL CASE
	ORA	L	;  OF NO RECORDS
	JZ	SKIP
;
DIVLOP: DAD	D	;SUBTRACT
	INR	B	;BUMP QUOTIENT
	JC	DIVLOP
	LXI	D,128	;FIX UP OVERSHOOT
	DAD	D
	DCR	B
	MOV	A,H	;TEST FOR WRAPAROUND
	ORA	L
	JNZ	SKIP
	MVI	L,80H	;RECORD LENGTH
	DCR	B
;
SKIP:	LDA	EXTNUM	;NOW FIX UP EXTENT NUM
	ADD	B
	STA	EXTNUM
	STA	BFCB+12
	MOV	A,L	;MOD IS RECORD COUNT
	STA	BFCB+15 ;THAT GOES IN RC BYTE
;
MOVDM:	LDA	BLKEXT	;GET BLOCKS PER EXTENT
	MOV	B,A	;INTO B
;
SETD1:	LHLD	DMPTR	;POINT TO BAD ALLOCATION MAP
	XCHG
	LXI	H,BFCB+16 ;DISK ALLOC MAP IN FCB
;
SETDML: LDAX	D
	MOV	M,A
	INX	H
	INX	D
;
;Now see if 16 bit groups...if so,
;we have to move another byte
;
	LDA	DSM+1	;THIS TELLS US
	ORA	A
	JZ	BUMP1	;IF ZERO, THEN NOT
	LDAX	D	;IS 16 BITS, SO DO ANOTHER
	MOV	M,A
	INX	H
	INX	D
;
BUMP1:	DCR	B	;COUNT DOWN
	JNZ	SETDML
	PUSH	D
	CALL	CLOSEB	;CLOSE THIS EXTENT
	POP	D
	RET
;
;Error messages
;
SELERR: LXI	D,SELEMS ;SAY NO GO, AND BAIL OUT
	JMP	PMSG
;
SELEMS: DB	CR,LF,'Drive specifier out of range$'
;
ERMSG5: DB	CR,LF,'+++ Warning...System tracks'
	DB	' bad +++',CR,LF,CR,LF,'$'
;
ERROR6: LXI	D,ERMSG6 ;OOPS...CLOBBERED DIRECTORY
	JMP	PMSG
;
ERMSG6: DB	CR,LF,'Bad directory area, try reformatting$'
;
ERROR7: LXI	D,ERMSG7 ;SAY NO GO, AND BAIL OUT
	JMP	PMSG
;
ERMSG7: DB	CR,LF,'Can''t create [UNUSED].BAD$'
;
;
;==== SUBROUTINES ====
;
;Decimal output routine
;
DECOUT: PUSH	B
	PUSH	D
	PUSH	H
	LXI	B,-10
	LXI	D,-1
;
DECOU2: DAD	B
	INX	D
	JC	DECOU2
	LXI	B,10
	DAD	B
	XCHG
	MOV	A,H
	ORA	L
	CNZ	DECOUT
	MOV	A,E
	ADI	'0'
	CALL	TYPE
	POP	H
	POP	D
	POP	B
	RET
;
;Carriage-return/line-feed to console
;
CRLF:	MVI	A,CR
	CALL	TYPE
	MVI	A,LF	;FALL INTO 'TYPE'
;
TYPE:	PUSH	B
	PUSH	D
	PUSH	H
	MOV	E,A	;CHARACTER TO E FOR CP/M
	MVI	C,2	;PRINT CONSOLE FUNCTION
	CALL	BDOS	;PRINT CHARACTER
	POP	H
	POP	D
	POP	B
	RET
;
;Subroutine to test console for control-c abort
;
STOP:	LHLD	1	;FIND BIOS IN MEMORY
	MVI	L,6	;OFFSET TO CONSOLE STATUS
	CALL	GOHL	;THANKS TO BRUCE RATOFF FOR THIS TRICK
	ORA	A	;TEST FLAGS ON ZERO
	RZ		;RETURN IF NO CHAR
	LHLD	1	;NOW FIND CONSOLE INPUT
	MVI	L,9	;OFFSET FOR CONIN
	CALL	GOHL
	CPI	'C'-40H ;IS IT CONTROL-C?
	RNZ		;RETURN IF NOT
	LXI	D,ABORTM ;EXIT WITH MESSAGE
	MVI	C,9	;PRINT MESSAGE FUNCTION
	CALL	BDOS	;SAY GOODBYE
	JMP	0	;THEN LEAVE
;
ABORTM: DB	CR,LF
	DB	'Test aborted by control-C'
	DB	CR,LF,'$'
;
;A thing to allow a call to @HL
;
GOHL:	PCHL
;
;Zero all of memory to hold DM values
;
ZMEM:	LHLD	BDOS+1	;GET TOP-OF-MEM POINTER
	LXI	D,DM	;STARTING POINT
	CALL	SUBDE	;GET NUMBER OF BYTES
	MOV	B,H
	MOV	C,L
	XCHG		;BEGIN IN HL, COUNT IN BC
;
ZLOOP:	MVI	M,0	;ZERO A BYTE
	INX	H	;POINT PAST
	DCX	B	;COUNT DOWN
	MOV	A,B
	ORA	C
	JNZ	ZLOOP
	RET
;
;Subtract DE from HL
;
SUBDE:	MOV	A,L
	SUB	E
	MOV	L,A
	MOV	A,H
	SBB	D
	MOV	H,A
	RET
;
;Negate HL
;
NEG:	MOV	A,L
	CMA
	MOV	L,A
	MOV	A,H
	CMA
	MOV	H,A
	INX	H
	RET
;
;Move from (HL) to (DE)
;Count in BC
;
MOVE:	MOV	A,M
	STAX	D
	INX	H
	INX	D
	DCR	B
	JNZ	MOVE
	RET
;
;Print byte in accumulator in hex
;
HEXO:	PUSH	PSW	;SAVE FOR SECOND HALF
	RRC		;MOVE INTO POSITION
	RRC
	RRC
	RRC
	CALL	NYBBLE	;PRINT MS NYBBLE
	POP	PSW
;
NYBBLE: ANI	0FH	;LO NYBBLE ONLY
	ADI	90H 
	DAA
	ACI	40H
	DAA
	JMP	TYPE	;PRINT IN HEX
;
;Subroutine to determine the number
;of groups reserved for the directory
;
GETDIR: MVI	C,0	;INIT BIT COUNT
	LDA	AL0	;READ DIR GRP BITS
	CALL	COLECT	;COLLECT COUNT OF DIR GRPS..
	LDA	AL1	;..IN REGISTER C
	CALL	COLECT
	MOV	L,C
	MVI	H,0	;BC NOW HAS A DEFAULT START GRP #
	SHLD	DIRBKS	;SAVE FOR LATER
	RET
;
;Collect the number of '1' bits in A as a count in C
;
COLECT: MVI	B,8
;
COLOP:	RAL
	JNC	COSKIP
	INR	C
;
COSKIP: DCR	B
	JNZ	COLOP
	RET
;
;Shift HL right one place
;
ROTRHL: ORA	A	;CLEAR CARRY
	MOV	A,H	;GET HI BYTE
	RAR		;SHIFT RIGHT
	MOV	H,A	;PUT BACK
	MOV	A,L	;GET LO
	RAR		;SHIFT WITH CARRY
	MOV	L,A	;PUT BACK
	RET
;
;Routine to fill in disk parameters
;
LOGIT:	LDA	VER2FL
	ORA	A	;IF NOT CP/M 2.x THEN
	JZ	LOG14	;	DO IT AS 1.4
	LXI	D,DPB	;   THEN MOVE TO LOCAL
	MVI	B,DPBLEN ;  WORKSPACE
	CALL	MOVE
	RET
;
LOG14:	LHLD	BDOS+1	;FIRST FIND 1.4 BDOS
	MVI	L,0
	LXI	D,DPBOFF ;THEN OFFSET TO 1.4'S DPB
	DAD	D
	MVI	D,0	;SO 8 BIT PARMS WILL BE 16
	MOV	E,M	;NOW MOVE PARMS
	INX	H	; DOWN FROM BDOS DISK PARM BLOCK
	XCHG		; TO OURS
	SHLD	SPT
	XCHG
	MOV	E,M
	INX	H
	XCHG
	SHLD	DRM
	XCHG
	MOV	A,M
	INX	H
	STA	BSH
	MOV	A,M
	INX	H
	STA	BLM
	MOV	E,M
	INX	H
	XCHG
	SHLD	DSM
	XCHG
	MOV	E,M
	INX	H
	XCHG
	SHLD	AL0
	XCHG
	MOV	E,M
	XCHG
	SHLD	SYSTRK
	RET
;
;--------------------------------------------------
;The disk parameter block
;is moved here from CP/M
;
DPB	EQU	$	;DISK PARAMETER BLOCK (COPY)
;
SPT:	DS	2	;SECTORS PER TRACK
BSH:	DS	1	;BLOCK SHIFT
BLM:	DS	1	;BLOCK MASK
EXM:	DS	1	;EXTENT MASK
DSM:	DS	2	;MAXIMUM BLOCK NUMBER
DRM:	DS	2	;MAXIMUM DIRECTORY BLOCK NUMBER
AL0:	DS	1	;DIRECTORY ALLOCATION VECTOR
AL1:	DS	1	;DIRECTORY ALLOCATION VECTOR
CKS:	DS	2	;CHECKED DIRECTORY ENTRIES
SYSTRK: DS	2	;SYSTEM TRACKS
;
;End of disk parameter block
;
DPBLEN	EQU	$-DPB	;LENGTH OF DISK PARM BLOCK
;
;--------------------------------------------------
BLKEXT: DB	0	;BLOCKS PER EXTENT
DIRBKS: DW	0	;CALCULATED # OF DIR BLOCKS
VER2FL: DB	0	;VERSION 2.X FLAG
;
BFCB:	DB	0,'[UNUSED]BAD',0,0,0,0
FCBDM:	DS	17
;
NOMSG:	DB	'No$'
ENDMSG: DB	' bad blocks found',CR,LF,'$'
;
BADBKS: DW	0	;COUNT OF BAD BLOCKS
SECTOR: DW	0	;CURRENT SECTOR NUMBER
TRACK:	DW	0	;CURRENT TRACK NUMBER
PHYSEC: DW	0	;CURRENT PHYSICAL SECTOR NUMBER
SECTBL: DW	0	;SECTOR SKEW TABLE POINTER
;
EXTNUM: DB	0FFH	;USED FOR UPDATING EXTENT NUMBER
DMCNT:	DW	0	;NUMBER OF BAD SECTORS
DMPTR:	DW	DM	;POINTER TO NEXT BLOCK ID
;
SECMSG: DB	' total sectors read',CR,LF,'$'
;
SECCNT: DW	0	;NUMBER OF SECTORS READ
;
	DS	64	;ROOM FOR 32 LEVEL STACK
NEWSTK	EQU	$	;OUR STACK
DM	EQU	$	;BAD BLOCK ALLOCATION MAP
;
	END

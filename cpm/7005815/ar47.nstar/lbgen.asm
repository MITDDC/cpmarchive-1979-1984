
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
;		GENESYS version 3.2 - July 18, 1981
;			   r. l. plouffe
;		for use with cp/m 1.45, 2.0x, or 2.2x
;		on north star with lifeboat bios
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
;	This is a version of SYSGEN that runs above the
; sysgen image of cp/m, thus permitting the first four
; north star sectors to contain code for an expanded user
; area.  To use this feature, the cold boot loader must
; be modified to load code from ccp-900H. This version of
; GENESYS patches in a complete new cold boot loader that
; accomplishes this function into the sysgen image prior to
; writing to either a CPM.xx file or to the system tracks.
; The new loader reads all 10 sectors of the system tracks
; except that it skips sector 4 on track 1 since that sector
; is read in by the boot prom. The init routine which you put
; in user1 should run at ccp-900H and move the user2 code
; to a location just above the running cp/m. A special org
; must be contained at the portion of init that runs at
; ccp-900h so that the lifeboat format byte will be present
; at 05CH above ccp-900H since that code will be resident
; at sector 0, track 1 of the north star disk where it is
; tested by the lifeboat bios for reading or writing of files
; so that the skew factor will be correct. GENEUSER.ASM which
; is also on this disk will do all of the above and provides
; general user code for 1.45, 2.0 and 2.2 including t102 clock,
; pmmi modem, and north star parity error routines as well.
;	The program reads the format of the destination
; drive and changes the format byte found on the source
; drive so that the destination drive format remains
; unchanged after being written to with the 'sysgened' cp/m.
; Thus neither drive is changed in format so far as files
; are concerned after using GENESYS.
;
;
BDOS	EQU	0005H		;jmp to bdos function calls
BIOSV	EQU	0001H		;bios warm boot vector
CR	EQU	0DH		;carriage return
LF	EQU	0AH		;line feed
TAB	EQU	09H		;tab function
BELL	EQU	07H		;ding
;
FCB	EQU	005CH		;address of FCB
FRSTCHAR EQU	005DH		;addr of 1rst char in FCB
CURREC	EQU	007CH		;addr of curr record #
SYSIMG	EQU	0100H		;cp/m sysgen image
SEC0IMG	EQU	0080H		;sector 0 image
DMAINCR	EQU	0080H		;dma increment amount
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
; Routine for moving the whole program beginning with START
; to just above the 'sysgen' image of cp/m so that the space
; from 100H to 8FFH will be available for init and user2 code
; for storage on sectors 0-3 of track 1 on the north star disk.
; If any code after START is added/changed, the address labels
; must be followed by EQU	$+BIAS.
;
DEST	EQU	2D00H		;running location of genesys
;
	ORG	SYSIMG
;
	LXI	B,PEND1-SOURCE1
	LXI	H,DEST2+PEND1-SOURCE1
	LXI	D,SOURCE2+PEND1-SOURCE1-1
	CALL	MOVEIT
	LXI	B,PEND-START		;# of bytes to move
	LXI	H,DEST+PEND-START	;end of moved code
	LXI	D,SOURCE-START+PEND-1	;end of source code
	CALL	MOVEIT
	PCHL
;
MOVEIT:	LDAX	D		;get byte
	DCX	H		;bump pointers
	MOV	M,A		;new home
	DCX	D
	DCX	B		;bump byte count
	MOV	A,B		;check if zero
	ORA	C
	JNZ	MOVEIT		;if not, keep moving
	RET			;jump to start
;
SOURCE	EQU	$		;boundary memory marker
;
BIAS	EQU	DEST-SOURCE	;relocation amount
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
; The beginning of it all.
;
;
START:	EQU	$+BIAS		; 
	LXI	SP,STACK	;point to new stack
	LXI	D,SIGNON	;give signon message
	CALL	PRNMSG		;to the console
	CALL	SKWGEN		;write the skew table
	LDA	FRSTCHAR
	CPI	20H
	JZ	NOFILE		;
	LXI	D,FCB
	CALL	OPEN		;
	INR	A
	JNZ	OPENOK		;
	LXI	D,NOFILMSG	;say no source file
	CALL	PRNMSG		;to the console
	JMP	EXIT		;
;
OPENOK:	EQU	$+BIAS		; 
	XRA	A
	STA	CURREC
	MVI	C,50H		;# of cp/m sectors in file
;
CHKFIL:	EQU	$+BIAS		;this loop checks for bad file
	PUSH	B
	LXI	D,FCB
	CALL	SEQRD		;read sequential
	ORA	A
	POP	B
	JNZ	BADFILE		;if 0, say  incomplete
	DCR	C
	JNZ	CHKFIL		;if not done, get another sec.
; initialize current record buffer and set dma to sys image
	XRA	A
	STA	CURREC		;set current record to 0
	LXI	H,SYSIMG	;initial dma
; now read all sectors of the file to ram at sys image
RDFILE:	EQU	$+BIAS		; 
	PUSH	H
	MOV	B,H		;set dma address
	MOV	C,L
	CALL	DMASET
	LXI	D,FCB
	CALL	SEQRD		;read sequential to dma
	POP	H
	ORA	A
	JNZ	IMGRDY		;
	LXI	D,DMAINCR
	DAD	D
	JMP	RDFILE		;
;
BADFILE:EQU	$+BIAS		; 
	LXI	D,INCMPMSG	;say source file incomplete
	CALL	PRNMSG		;to the console
	JMP	EXIT		;
; if no file in command line, get sys from selected drive
NOFILE:	EQU	$+BIAS		; 
	LXI	D,SRCNAME	;ask for source drive name
	CALL	PRNMSG		;at the console
	CALL	CONIN		;read the console buffer
	SUI	41H
	CPI	4
	JC	FROM		;
	CALL	BADNAME		;
	JMP	NOFILE		;
;
FROM:	EQU	$+BIAS		; 
	STA	CURRDRV		;
	ADI	41H		;convert to alpha
	STA	SRCDRV		;
	LXI	D,SRCMSG	;say to place source disk
	CALL	PRNMSG		;to the console
	CALL	CONIN		;
	CPI	0DH
	JNZ	EXIT		;
	CALL	CRLF		;
	XRA	A
	STA	RDWRFLG		;set flag to read
	CALL	RDWRSYS		;
;
IMGRDY:	EQU	$+BIAS		; 
	LDA	900H		;get hi byte of cold loader org
	SUI	34H		;get the difference
	MOV	C,A		;store in C for a while
	LXI	H,CLDBTABL	;point to addresses of bytes in
				;cold loader that need to be changed
CHNGCLDBT:EQU	$+BIAS
	MOV	E,M
	INX	H
	MOV	D,M
	MOV	A,M
	ORA	E
	JZ	MOVER
	LDAX	D
	ADD	C
	STAX	D
	INX	H
	JMP	CHNGCLDBT
; now patch the cold boot loader into the system image
;
	DEST1	EQU	0907H
;
MOVER:	EQU	$+BIAS
	LXI	B,PEND1-SOURCE1
	LXI	H,DEST1+PEND1-SOURCE1
	LXI	D,PEND1-1
MOVCONT:EQU	$+BIAS 
	LDAX	D
	DCX	H
	MOV	M,A
	DCX	D
	DCX	B
	MOV	A,B
	ORA	C
	JNZ	MOVCONT
;now test and patch for bugs in the various versions
	LDA	1201H		;get version
	LHLD	900H-1		;get hi byte of cldbt addr.
	MVI	L,0CH		;addr in cldbt page to patch
	CPI	20H		;see if 2.0x
	JNZ	TST22		;if not, see if it's 2.2
	SHLD	26BFH		;replace in patch table
TST22:	EQU	$+BIAS
	CPI	22H		;see if 2.2
	JNZ	TST14		;if not, see if it's 1.4
	LDA	1511H		;
	CPI	01H		;see if it's 2.21A
	JZ	TST14		;if so, don't patch
	CPI	0CCH		;see if it's 2.22
	JZ	SKP221
	SHLD	151BH		;replace in patch table
	ORA	A		;clear status
TST14:	EQU	$+BIAS
	CZ	FIX221A		;fix if 221A
SKP221:	EQU	$+BIAS
	MOV	A,H		;get hi byte of cldbt addr.
	ADI	24H		;make it hi byte of sys size
	MOV	B,A		;save for a while
	LDA	1201H		;get version
	CPI	0EH		;see if 1.45
	JNZ	RSTCNT		;if not jmp to reset counter
	MOV	A,B		;get hi byte of sys size
	SUI	0AH		;make it hi byte of bios last blk
	MOV	H,A		;put in H
	MVI	L,0F7H		;addr in bios last pg to patch
	SHLD	1E6CH		;put in bdos patch table
	XRA	A		;zero A
	STA	0906H		;patch coldboot loader
	MOV	A,B		;get hi byte of sys size again
	SUI	0CH		;to make compatible w/1.45 sizing
	MOV	B,A		;save in B
; now calculate the system size and store in SAVE prompt
RSTCNT:	EQU	$+BIAS
	LXI	H,3030H		;set to say 00
	SHLD	FILNAM+3	;tens digit
SYSSIZ:	EQU	$+BIAS
	LXI	H,FILNAM+4	;units digit
	INR	M		;increment it
	MOV	A,M		;to acc.
	CPI	3AH		;overflow of units?
	JC	SYSSIZ1		;
	MVI	M,30H		;reset units digit
	DCX	H		;go to tens digit
	INR	M		;increment it
SYSSIZ1:EQU	$+BIAS
	DCR	B
	DCR	B
	DCR	B
	DCR	B
	JNZ	SYSSIZ		;count more if not done
; now patch the image for cp/m version
	LDA	900H		;get the msb of booter
	MOV	B,A		;store in B for a while
	LDA	1201H		;get the cp/m version #
	CPI	0EH		;see if version 1.45
	LXI	D,ONEFOUR	;point to image addresses
	JZ	PATCHER		;if so jump to patch routine
	CPI	20H		;see if version 2.0x
	LXI	D,TWOZERO	;point to image addresses
	JZ	PATCHER		;if so jump to patch routine
	CPI	22H		;see if version 2.2x
	LXI	D,TWOTWO	;point to image addresses
	JZ	PATCHER		;if so jump to patch routine
	JMP	BADVERS		;if none of the above,say sorry
PATCHER:EQU	$+BIAS
	LXI	H,INIT+7-BIAS1+100H ;get patch location in booter
	CALL	PATCH		;patch it
	LXI	H,BOOT+9-BIAS1+100H
	CALL	PATCH
	LXI	H,BOOT+6-BIAS1+100H
	CALL	PATCH		
	LXI	D,IMG0100	;say cp/m image ready
	CALL	PRNMSG		;to the console
; now put the sys image to a selected drive
DESTDR:	EQU	$+BIAS		; 
	LXI	D,TODRV		;ask for destination drive name
	CALL	PRNMSG		;at the console
	CALL	CONIN		;read the console buffer
	CPI	0DH		;done?
	JZ	EXIT		;
	SUI	41H
	CPI	4
	JC	DESTDRV		;
	CALL	BADNAME		;
	JMP	DESTDR		;
;
FIX221A:EQU	$+BIAS
	MOV	A,H		;get hi byte of cldbt addr
	MVI	L,0F2H		;byte to fix
	SHLD	153DH		;add to patch table
	XRA	A		;A=0
	STA	247AH		;remove stack unbalance so that
				;read-after-write bit can be set
				;in the MODE byte. otherwise, bug
	RET
;
PATCH:	EQU	$+BIAS
	LDAX	D		;lsb
	MOV	M,A		;patch it
	INX	H
	INX	D
	LDAX	D		;msb
	ADD	B		;add hi byte of booter
	SUI	09H		;convert to hi byte of addr
	MOV	M,A		;patch it
	INX	D
	RET
;
DESTDRV:EQU	$+BIAS		; 
	STA	CURRDRV		;
	ADI	41H
	STA	DSTDR		;
; read the first sector (with 10 retries) of dest drive
; and get format byte to store in system image
	XRA	A		;zero the retry count
	STA	RETRY		;put in retry counter buff.
X10TRY:	EQU	$+BIAS
	LDA	CURRDRV		;get current drive no.
	MOV	C,A		;
	CALL	DSKSEL		;select the drive
	MVI	C,0
	CALL	TRKSET		;set to track 0
	LXI	B,1		;
	CALL	SECSET		;set to sector 1
	LXI	B,SEC0IMG	;dma
	CALL	DMASET		;set dma to SEC0IMG
	LDA	RETRY		;get retry count
	CPI	0AH		;allow 10 of them
	JC	REPEAT		;increment and read
ERROR:	EQU	$+BIAS
	LXI	D,PERMERR	;point to error msg
	CALL	PRNSTR		;send it to console
	JMP	EXIT		;back to cp/m
;
REPEAT:	EQU	$+BIAS
	INR	A		;bump retry counter
	STA	RETRY		;
	CALL	SECRD		;read first sector to 80h
	ORA	A		;bad read?
	JNZ	X10TRY		;if so, try again
;
TINU:	EQU	$+BIAS
; now get the format byte from dest drive 1rst sector image
	LDA	00DCH		;get dest drive format
; put format byte in system image
	STA	015CH		;store it in the sys image
	LXI	D,DESTMSG	;say to place dest disk
	CALL	PRNMSG		;at the console
	CALL	CONIN		;
	CPI	0DH		;return key?
	JZ	WRSYS		;
	CPI	20H		;space bar?
	JZ	WRFILE		;if so, write sys to a file
	JMP	EXIT		;exit to cp/m if any other key
;
WRSYS:	EQU	$+BIAS
	CALL	CRLF		;send cr,lf to console
	LXI	D,SYSMSG
	CALL	PRNMSG
	LXI	H,RDWRFLG	;point to rd/wr flag buffer
	MVI	M,1		;set it for write operations
	CALL	RDWRSYS		;
DONE:	EQU	$+BIAS
	LXI	D,FDONE		;say function complete
	CALL	PRNSTR		;to the console
	JMP	DESTDR		;want another drive?
;
BADVERS:EQU	$+BIAS
	LXI	D,SORRY
	CALL	PRNSTR
	HLT
;
EXIT:	EQU	$+BIAS		; 
	MVI	C,0
	CALL	DSKSEL		;select drive A
	CALL	CRLF		;output a cr,lf sequence
	JMP	0		;return to cp/m
;
BADNAME:EQU	$+BIAS		; 
	LXI	D,INVLDR	;say invalid drive name
	CALL	PRNMSG		;to the console
	RET
;
BADOPEN:EQU	$+BIAS
	LXI	D,NOOPEN	;say cant open the file
	CALL	PRNMSG		;to the console
	JMP	EXIT		;back to cp/m
;
BADWR:	EQU	$+BIAS
	LXI	D,WRBAD		;say bad write operation
	CALL	PRNMSG
	JMP	EXIT
;
WRFILE:	EQU	$+BIAS
	CALL	CRLF
	;
	MVI	B,14
	LXI	D,FILNAM
	LXI	H,FRSTCHAR
OVER:	EQU	$+BIAS
	LDAX	D
	MOV	M,A
	INX	H
	INX	D
	DCR	B
	JNZ	OVER
	XRA	A
	STA	FCB
	STA	CURREC
	;
	MVI	C,SELDRV
	LDA	CURRDRV
	MOV	E,A
	CALL	BDOS
	;
	LXI	D,FCB
	MVI	C,FILDEL
	CALL	BDOS
	LXI	D,FCB
	MVI	C,FILMAK
	CALL	BDOS
	INR	A
	JZ	BADOPEN
	LXI	D,FILMSG
	CALL	PRNMSG
	LXI	H,SYSIMG	;start of system image
WRFIL:	EQU	$+BIAS	
	PUSH	H
	XCHG
	CALL	BUFSET
	LXI	D,FCB
	MVI	C,WRSEQ
	CALL	BDOS
	POP	H
	ORA	A
	JNZ	BADWR		;say bad write
	LXI	D,DMAINCR	;increment dma by 80h
	DAD	D
	PUSH	H
	MVI	A,50H		;# of cp/m sectors
	LXI	H,CURREC
	CMP	M
	POP	H
	JZ	CLOSIT
	JMP	WRFIL
;
CLOSIT:	EQU	$+BIAS
	LXI	D,FCB
	MVI	C,CLOSFIL
	CALL	BDOS
	INR	A
	JNZ	DONE
;
BADCLOS:EQU	$+BIAS
	LXI	D,NOCLOSE
	CALL	PRNMSG
	JMP	EXIT
;
SORRY:	EQU	$+BIAS
	DB	CR,LF,TAB,'SORRY, BAD'
	DB	' VERSION OF CP/M',BELL,'$'
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
; Routines for selecting drive, track, sector and setting of
; disk memory access address when reading or writing sys trks.
; Module provides for up to 10 tries at read or write
; and gives an error message if errors are detected.
;
RDWRSYS:EQU	$+BIAS	; 
; select which drive
	LDA	CURRDRV		;get current disk number
	MOV	C,A
	CALL	DSKSEL		;select disk
; initialize dma address
	LXI	H,SYSIMG		;start of cp/m image
	SHLD	IMGADR		;current image addr buffer
; initialize current track buffer
	MVI	A,0FFH		;track zero-1
	STA	TRKBUF		;current track buffer
; initialize skew pointer to first entry in skew table
	LXI	H,SKWTBL	;point to skew table
	SHLD	SKWPTR		;put in skew pointer buffer
; now set the track number
;
TRAKSET:EQU	$+BIAS		; 
	LXI	H,TRKBUF	;get previous track #
	INR	M		;advance track #
	MVI	A,2		;get # of system tracks
	CMP	M		;see if done
	RZ			;if so, return
	LXI	H,TRKBUF	;get track number
	MOV	C,M
	CALL	TRKSET		;set track number
;
; initialize sector number to zero
	XRA	A		;zero the accumulator
	STA	SECBUF		;sector number buffer
; now set sector and dma in accordance with skew table
SCTRSET:EQU	$+BIAS		; 
	MVI	A,28H		;get # of sectors/track
	LXI	H,SECBUF	;get current sector number
	CMP	M		;see if done
	JZ	ADJDMA		;
	INR	M		;advance sector number
	LDA	TRKBUF		;get current track #
	ORA	A
	JNZ	SCTR		;
	LDA	SECBUF		;get sector #
	MOV	E,A
	MVI	D,0
	LHLD	SKWPTR		;get skew pointer
	DCX	H
	DAD	D
	MOV	A,M
	CPI	1H
	JC	SCTRSET		;
SCTR:	EQU	$+BIAS		; 
	LXI	H,SECBUF	;point to sector # buffer
	MOV	E,M		;store sector # in DE pair
	MVI	D,0
	LHLD	SKWPTR		;get skew pointer
	MOV	B,M
	DCX	H
	DAD	D
	MOV	C,M
	PUSH	B
	CALL	SECSET		;set sector 
	POP	B
	MOV	A,C
	SUB	B
	CALL	X128		;
	XCHG
	LHLD	IMGADR		;get current image address
	DAD	D
	MOV	B,H
	MOV	C,L
	CALL	DMASET		;set dma address
;
; set read/write retry counter to zero
	XRA	A
	STA	RETRY		;set re-try counter to 0
; now read or write up to 10 times until no error is detected
TRYX10:	EQU	$+BIAS		; 
	LDA	RETRY		;get re-try count
	CPI	0AH		;allow 10 of them
	JC	RDWRTRY		;
	LXI	D,PERMERR	;say permanent error
	CALL	PRNSTR		;to the console
	CALL	CONIN		;
	CPI	0DH
	JNZ	EXIT		;
	CALL	CRLF		;
	JMP	SCTRSET		;
RDWRTRY:EQU	$+BIAS		; 
	INR	A
	STA	RETRY		;bump re-try counter
	LDA	RDWRFLG		;see if read or write
	ORA	A
	JZ	READIT		;if zero, then read
	CALL	SECWR		;write sector
	JMP	ERRCHK		;
;
READIT:	EQU	$+BIAS		; 
	CALL	SECRD		;
;
ERRCHK:	EQU	$+BIAS		; 
	ORA	A
	JZ	SCTRSET		;if zero, then do another sec
	JMP	TRYX10		;else try again
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
; This routine multiplies sector number by 128 to adjust the
; current dma address.
;
ADJDMA:	EQU	$+BIAS
	MVI	A,28H		;get # of sectors/track
	CALL	X128		;multiply by 128
	XCHG
	LHLD	IMGADR		;get current image sddr
	DAD	D		;adjust it
	SHLD	IMGADR		;store it
	JMP	TRAKSET
X128:	EQU	$+BIAS		; 
	MOV	L,A
	MVI	H,0
	DAD	H
	DAD	H
	DAD	H
	DAD	H
	DAD	H
	DAD	H
	DAD	H
	RET
;
SKWGEN:	EQU	$+BIAS
	LXI	H,SKWTBL
	MVI	A,15H
	;
SKWGEN1:EQU	$+BIAS
	SUI	14H
	CALL	FOURSEC
	ADI	10H
	CALL	FOURSEC
	CPI	29H
	JNZ	SKWGEN1
	RET
	;
FOURSEC:EQU	$+BIAS
	MVI	C,4
SKWWR:	EQU	$+BIAS
	MOV	M,A
	INX	H
	INR	A
	DCR	C
	JNZ	SKWWR
	RET
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
; Routines for msg out to console.
;
CRLF:	EQU	$+BIAS		;get carriage ret, line feed
	LXI	D,CRLFMSG	;point to it
	JMP	PRNSTR		;send it to console
;
CRLFMSG:EQU	$+BIAS		;carriage ret, line feed
	DB	CR,LF,'$'
;
PRNMSG:	EQU	$+BIAS		; 
	PUSH	D
	CALL	CRLF		;get carriage ret, line feed
	POP	D
; fall through to prnstr
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
; BDOS and BIOS functions
;
PRNSTR:	EQU	$+BIAS		; 
	MVI	C,PRTSTRG	;print string to console
	JMP	BDOS
;
DSKSEL:	EQU	$+BIAS		;
	LHLD	BIOSV
	LXI	D,SELDSK	;select disk drive
	DAD	D
	PCHL
;
TRKSET:	EQU	$+BIAS		; 
	PUSH	B
	MVI	B,0		;zero the B register
	CALL	TRKSET1		;set track number
	POP	B
	RET
;
TRKSET1:EQU	$+BIAS		; 
	LHLD	BIOSV
	LXI	D,SETTRK	;set track number
	DAD	D
	PCHL
;
SECSET:	EQU	$+BIAS		; 
	LHLD	BIOSV
	LXI	D,SETSEC	;set sector number
	DAD	D
	PCHL
;
DMASET:	EQU	$+BIAS
	LHLD	BIOSV
	LXI	D,SETDMA	;set disk memory address
	DAD	D
	PCHL
;
SECRD:	EQU	$+BIAS		; 
	LHLD	BIOSV
	LXI	D,RDSEC		;read selected sector
	DAD	D
	PCHL
;
SECWR:	EQU	$+BIAS		; 
	LHLD	BIOSV
	LXI	D,WRSEC		;write selected sector
	DAD	D
	PCHL
;
SEQRD:	EQU	$+BIAS		; 
	MVI	C,RDSEQ		;read next 128 bytes to dma
	JMP	BDOS
;
BUFSET:	EQU	$+BIAS
	MVI	C,SETBUF	;set the dma
	JMP	BDOS
;
OPEN:	EQU	$+BIAS		; 
	MVI	C,OPNFIL	;open the file
	JMP	BDOS
;
CONIN:	EQU	$+BIAS
	MVI	C,CONSIN	;console input
	CALL	BDOS
	CPI	60H		;convert to upper case
	RC
	CPI	7BH
	RNC
	ANI	5FH
	RET
;
; Messages for the console
;
SIGNON:	EQU	$+BIAS		; 
	DB	TAB,'GENESYS vers 3.2',CR,LF
	DB	TAB,'for cp/m 1.45,2.01,2.2,2.21A or 2.22',CR,LF
	DB	TAB,'on North Star DQ w/Lifeboat bios'
	DB	CR,LF,TAB,'July 18, 1981',CR,LF,'$'
;
SRCNAME:EQU	$+BIAS		; 
	DB	TAB,'Source drive NAME: $'
;
SRCMSG:	EQU	$+BIAS		; 
	DB	TAB,'Put SOURCE disk on: '
;
SRCDRV:	EQU	$+BIAS		; 
	DB	0,', & hit RETURN$'
;
IMG0100:EQU	$+BIAS		; 
	DB	CR,LF,TAB,'CP/M image in RAM from 100H'
	DB	' to 2900H$'
;
	
TODRV:	EQU	$+BIAS		; 
	DB	CR,LF,TAB,'Destination drive NAME'
	DB	CR,LF,TAB,'(or RETURN to reboot): $'
;
DESTMSG:EQU	$+BIAS		; 
	DB	TAB,'Put DESTINATION disk on: '
;
DSTDR:	EQU	$+BIAS		; 
	DB	0,CR,LF,CR,LF,TAB,'& hit RETURN to write'
	DB	' system'
	DB	CR,LF,TAB,'or, hit SPACE bar to save '
;
FILNAM:	EQU	$+BIAS
	DB	'CPMxx   COM',0,0,0,'$'
;
PERMERR:EQU	$+BIAS		; 
	DB	TAB,'Hard ERROR',BELL,'$'
;
FDONE:	EQU	$+BIAS		; 
	DB	TAB,'Done',BELL,'$'
;
INVLDR:	EQU	$+BIAS		; 
	DB	TAB,'Invalid, (Use A B C or D)$'
;
NOFILMSG:EQU	$+BIAS		;
	DB	TAB,'No source file$' 
;
INCMPMSG:EQU	$+BIAS		;
	DB	TAB,'Source file incomplete$'
;
NOOPEN:	EQU	$+BIAS
	DB	TAB,'Can`t open file$'
;
WRBAD	EQU	$+BIAS
	DB	TAB,'Bad write -full disk?$'
;
NOCLOSE:EQU	$+BIAS
	DB	TAB,'Can`t close file -write protected?$'
;
SYSMSG:	EQU	$+BIAS
	DB	TAB,'Writing cp/m system -wait-$'
;
FILMSG	EQU	$+BIAS
	DB	TAB,'Writing cp/m.com file -wait-$'
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
; Tables
;
CLDBTABL:EQU	$+BIAS
	DW	STRT-1
	DW	STRT+3
	DW	STRT+7
	DW	STRT+0AH
	DW	TWOTRKS+7
	DW	TWOTRKS+0DH
	DW	STSECT+2
	DW	STSECT+0BH
	DW	STSECT+0EH
	DW	RDENBL+5
	DW	DELAY+3
	DW	DELAY+8
	DW	SYNCH+4
	DW	SYNCH+8
	DW	COUNT+6
	DW	COUNT+0FH
	DW	COUNT+12H
	DW	HALT+2
	DW	READSECS+2
	DW	TWOBLKS+8
	DW	TWOBLKS+0DH
	DW	TWOBLKS+12H
	DW	NEXTSEC+9
	DW	NEXTSEC+0DH
	DW	NEXTSEC+11H
	DW	NEXTSEC+20H
	DW	NEXTSEC+24H
	DW	INIT+2
	DW	CHNGBIOS+7
	DW	CHNGBIOS+0EH
	DW	BOOT+2
	DW	ADVSEC+2
	DW	ADVSEC+8
	DW	DETSEC+4
	DW	DETSEC+8
	DW	DETSEC+0EH
	DW	0000H		;table scan terminator
;
ONEFOUR:EQU	$+BIAS		;table for version 1.45
	DW	1E40H		;promtabl
	DW	1F00H		;bios
	DW	090CH		;promhi
;
TWOZERO:EQU	$+BIAS		;table for version 2.0x
	DW	26B5H		;promtabl
	DW	2000H		;bios
	DW	26F5H		;promhi
;
TWOTWO:	EQU	$+BIAS		;table for version 2.2x
	DW	1511H		;promtabl
	DW	2000H		;bios
	DW	26F5H		;promhi
;
PEND	EQU	$+BIAS
	DS	DEST2-PEND
;
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
; Bdos function call equates
;
CONSIN	EQU	01H		;console input
RDSEQ	EQU	14H		;read sequential
WRSEQ	EQU	15H		;write sequential
SELDRV	EQU	0EH		;select disk
SETBUF	EQU	1AH		;set dma
OPNFIL	EQU	0FH		;open file
FILDEL	EQU	13H		;delete file
FILMAK	EQU	16H		;make a file
CLOSFIL	EQU	10H		;close file
PRTSTRG	EQU	09H		;print string to console
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
; Bios function call equates
;
SELDSK	EQU	18H		;select disk drive
SETTRK	EQU	1BH		;set track number
SETSEC	EQU	1EH		;set sector number
SETDMA	EQU	21H		;set disk memory address
RDSEC	EQU	24H		;read selected sector
WRSEC	EQU	27H		;write selected sector
;
;=============================================================
;
;		COLDBOOT LOADER FOR NORTH STAR
;
; WILL LOAD ALL SECTORS ON BOTH SYSTEM TRACKS TO RAM BEGINNING
; AT CCP-900H THUS GIVING A SECOND USER AREA OF UP TO 2KBYTES.
; THE SOFTWARE SKIPS READING OF SECTOR 4 ON TRACK 1 SINCE THAT
; SECTOR IS LOADED BY THE BOOTSTRAP PROM ON THE DISK CONTROLLER.
;
;			R. L. PLOUFFE
;			  12/19/80
;
;=============================================================
;
ORIG	EQU	0807H		;
PROM	EQU	0E800H		;DISK CONTR PROM ADDRESS
				;DO NOT CHANGE EVEN IF YOU HAVE
				;RELOCATED YOUR PROM. THE COLD BOOT
				;LOADER NEEDS THIS VALUE TO DETERMINE
				;AMOUNT BY WHICH YOU HAVE MOVED YOUR
				;PROM AND THEN PATCH ALL PROM DEPENDENT
				;BYTES IN THE BIOS BY ADDING THE DIFF-
				;ERENCE.
USER2	EQU	ORIG-800H-7H	;LOCATION OF 2ND USER AREA
CMDMSB	EQU	(PROM+300H)/256	;HI BYTE OF CONTROLLER COMMANDS
DSKRD	EQU	40H		;BYTE FOR READ COMMAND
ASTAT	EQU	10H		;LO BYTE FOR A STATUS MASK
RSTSEC	EQU	11H		;LO BYTE FOR RESET SECTOR COMMAND
STEPIN	EQU	21H		;LO BYTE FOR STEP-IN CMD, DR 1
STEPIN1	EQU	31H		;LSB FOR STEPIN,DR1,HEAD LOADED
CMOTON	EQU	35H		;MOTORS ON, GET C-STATUS
RESET	EQU	07H		;RESET CONTROLLER, DESELECT DRIVES
				;AND STOP THE MOTORS
DMA	EQU	USER2		;BEGINNING RAM ADDRESS
STACK1	EQU	USER2		;STACK
;
DEST2	EQU	DEST+707H
	ORG	ORIG
SOURCE2	EQU	$
BIAS1	EQU	DEST2-SOURCE2
SOURCE1	EQU	$+BIAS1
;
	JMP	INIT
STRT:	EQU	$+BIAS1
	DI
	LXI	SP,STACK1+BIAS1	
	XCHG
	SHLD	RDCMD	
	LXI	H,DMA+BIAS1	
	MVI	E,2
TWOTRKS0:EQU	$+BIAS1
	LXI	B,0A00H
TWOTRKS:EQU	$+BIAS1
	PUSH	H
	PUSH	B
	PUSH	D
	MOV	A,E
	DCR	A
	JZ	READ
	MOV	A,C
	CPI	4
	JZ	NEXTSEC
READ:	EQU	$+BIAS1
	PUSH	H
STSECT:	EQU	$+BIAS1		
	CALL	ONESEC
	MVI	L,CMOTON	
	MOV	A,M
	ANI	0FH
	CMP	C
	JNZ	STSECT	
	LHLD	RDCMD	
	MVI	L,ASTAT
RDENBL:	EQU	$+BIAS1		
	MOV	A,M
	ANI	4
	JZ	RDENBL	
	MVI	A,9
DELAY:	EQU	$+BIAS1		
	DCR	A
	JNZ	DELAY	
	MVI	B,8CH
	LHLD	RDCMD	
	MVI	L,ASTAT
SYNCH:	EQU	$+BIAS1		
	MOV	A,M
	RRC
	JC	READSECS	
	DCR	B
	JNZ	SYNCH	
;
REBOOT:	EQU	$+BIAS1		
	LXI	H,0FFFFH
COUNT:	EQU	$+BIAS1
	INX	H
	MOV	A,M
	CPI	76H
	JZ	COUNT
	MVI	A,76H
	MOV	M,A
	MOV	A,L
	CPI	07H
	JZ	HALT
	LHLD	RDCMD
	DCR	H
	DCR	H
	DCR	H
	MVI	L,0
	PCHL
;
HALT:	EQU	$+BIAS1
	LHLD	RDCMD
	MVI	L,RESET		;RESET THE DISK CONTROLLER
	MOV	A,M		;DO IT
	HLT			;STOP THE COMPUTER
;
READSECS:EQU	$+BIAS1		
	LHLD	RDCMD	
	XCHG
	POP	H
	MVI	B,0
	MVI	L,0
	MVI	C,2
TWOBLKS:EQU	$+BIAS1		
	LDAX	D
	MOV	M,A
	XRA	B
	RLC
	MOV	B,A
	INR	L
	JNZ	TWOBLKS	
	INR	H
	DCR	C
	JNZ	TWOBLKS
	LDAX	D
	XRA	B
	JNZ	REBOOT	
NEXTSEC:EQU	$+BIAS1
	POP	D
	POP	B
	POP 	H
	INR	H
	INR	H
	INR	C
	DCR	B
	JNZ	TWOTRKS
	DCR	E
	JZ	INIT
	PUSH	H
	LHLD	RDCMD	
	DCR	H
	MVI	L,STEPIN
	MOV	A,M
	MVI	L,STEPIN1
	MOV	A,M
	MVI	L,STEPIN
	MOV	A,M
	MVI	D,2
	CALL	ADVSEC	
	POP	H
	JMP	TWOTRKS0
;
INIT:	EQU	$+BIAS1		
	LDA	CMDHI
	SUI	CMDMSB
	MOV	C,A
	LXI	H,0000H		;0000H, storage location for
				;PROMTABL address	
CHNGBIOS:EQU	$+BIAS1		
	MOV	E,M
	INX	H
	MOV	D,M
	MOV	A,M
	ORA	E
	JZ	BOOT
	LDAX	D
	ADD	C
	STAX	D
	INX	H
	JMP	CHNGBIOS	
;
;
ONESEC:	EQU	$+BIAS1
	MVI	D,1
ADVSEC:	EQU	$+BIAS1		
	LHLD	RDCMD	
	MVI	L,RSTSEC
	MOV	A,M
	LHLD	RDCMD	
	MVI	L,ASTAT
DETSEC:	EQU	$+BIAS1		
	MOV	A,M
	ORA	A
	JP	DETSEC	
	DCR	D
	LHLD	RDCMD	
	MVI	L,RSTSEC
	MOV	A,M
	JNZ	ADVSEC	
	RET
;
DUPL:	EQU	$+BIAS1
	DW	0EB40H		;duplicate required here for 2.21A
				;gets patched to correct prom by the
				;patch table in bdos
;
BOOT:	EQU	$+BIAS1
	LDA	CMDHI
	SUI	3
	STA	0000H		;0000H, storage location for
				;addr of PROM hi byte
	JMP	0000H		;storage loc. for jmp to BIOS
;
RDCMD:	EQU	$+BIAS1
	DB	DSKRD
CMDHI:	EQU	$+BIAS1
	DB	CMDMSB
;
PEND1	EQU	$+BIAS1
;
;==========================================================
;
; Buffer space
;
SKWTBL:	EQU	$+BIAS1
	DS	40		;written by SKWGEN
;
CURRDRV:EQU	$+BIAS1		;current disk # buffer 
	DS	1
;
TRKBUF:	EQU	$+BIAS1		;current track buffer 
	DS	1
;
SECBUF:	EQU	$+BIAS1		;sector number buffer 
	DS	1
;
RDWRFLG:EQU	$+BIAS1		;read/write flag WRITE=1 
	DS	1
;
IMGADR:	EQU	$+BIAS1		;current image address 
	DS	2
;
RETRY:	EQU	$+BIAS1		;buffer for re-try count 
	DS	1
;
SKWPTR:	EQU	$+BIAS1		;skew pointer buffer 
	DS	2
;
	DS	207		;stack area 
STACK:	EQU	$+BIAS1
;
;	the
	END

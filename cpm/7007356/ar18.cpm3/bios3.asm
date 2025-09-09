*****************************************************************
*								*
* BIOS and Loader BIOS for CP/M Plus (Beta V1.2) for DJ2D	*
* controller.							*
* Written November 1982 by Dave Hardy and Ken Jackson		*
*								*
*****************************************************************

	TITLE	'BIOS and Loader BIOS For CP/M Plus'

*****************************************************************
*								*
* To install this BIOS into CP/M Plus, perform the following	*
* steps:							*
*	1. Add your own console and printer I/O to this file	*
*	   at CONIN:, CONOUT:, CONST:, LIST:, and LISTST:	*
*	2. Add any initialization that you need at TINIT:	*
*	3. Set the LDRBIOS equate in this file to TRUE		*
*	4. RMAC SCB $PZ -S	(assemble SCB.ASM, supplied)	*
*	5. RMAC BIOS3 $PZ -S	(assemble LDRBIOS)		*
*	6. REN LDRBIOS.REL=BIOS3.REL				*
*	7. Set the LDRBIOS equate in this file FALSE		*
*	8. RMAC BIOS3 $PZ -S    (assemble BIOS)			*
*	9. LINK BIOS3[B]=BIOS3,SCB				*
*      10. GENCPM						*
*		(answer all questions with a carriage return,	*
*		 except answer "N" at "Bank switched memory?"	*	
*		 question, and answer with your top page of	*
*		 memory when asked "Top page of memory?")	*
*      11. LINK CPMLDR[L100]=CPMLDR,LDRBIOS			*
*      12. CPMLDR		(Load and run CP/M Plus)	*
*								*
*****************************************************************

FALSE	EQU	0		;Define TRUE and FALSE
TRUE	EQU	NOT FALSE

*****************************************************************
*								*
* The following revision number is in reference to the CP/M	*
* Plus BIOS. 							*
*								*
*****************************************************************

REVNUM	EQU	10		;BIOS revision number
CPMREV	EQU	30		;CP/M revision number

*****************************************************************
*								*
* These are the routines called from the DJ2D's built-in EPROM.	*
* (model B only)						*
*								*
*****************************************************************

ORIGIN	EQU	0F800H		;EPROM origin of your DJ2D board
DJRAM	EQU	ORIGIN+400H	;DJ2D RAM address
DJHOME	EQU	DJRAM+9H	;DJ2D track zero seek
DJTRK	EQU	DJRAM+0CH	;DJ2D track seek routine
DJSEC	EQU	DJRAM+0FH	;DJ2D set sector routine
DJDMA	EQU	DJRAM+012H	;DJ2D set DMA address
DJREAD	EQU	DJRAM+15H	;DJ2D read routine
DJWRITE	EQU	DJRAM+18H	;DJ2D write routine
DJSEL	EQU	DJRAM+1BH	;DJ2D select drive routine
DJSTAT	EQU	DJRAM+27H	;DJ2D status routine
DJSIDE	EQU	DJRAM+30H	;DJ2D set side routine

*****************************************************************
*								*
* Miscellaneous internal BIOS equates.				*
* We've tried to maintain compatibility with the Morrow's DJ2D	*
* BIOS.								*
*								*
*****************************************************************

LDRBIOS	EQU	FALSE		;TRUE, if want to assemble as Loader BIOS
UD2	EQU	TRUE		;TRUE, if want to use User/Drive byte @ addr 4
CDISK	EQU	4		;Address of last logged disk
BUFF	EQU	80H		;Default buffer address
TPA	EQU	100H		;Transient memory
ENTRY	EQU	5		;BDOS entry jump address
RETRIES	EQU	10		;Max retries on disk i/o before error
ACR	EQU	0DH		;A carriage return
ALF	EQU	0AH		;A line feed
MAXDISK	EQU	4		;Maximum # of disk drives
CLEAR	EQU	1AH		;Clear Screen code for LDRBIOS

*****************************************************************
*								*
* PUBLIC and EXTERNAL declarations required for CP/M Plus.	*
*								*
*****************************************************************

	CSEG
	PUBLIC	?BOOT,?WBOOT,?CONST,?CONIN,?CONO,?LIST,?AUXO,?AUXI
	PUBLIC	?HOME,?SLDSK,?STTRK,?STSEC,?STDMA,?READ,?WRITE
	PUBLIC	?LISTS,?SCTRN
	PUBLIC	?CONOS,?AUXIS,?AUXOS,?DVTAB,?DEVIN,?DRTBL,?MLTIO,?FLUSH
	PUBLIC	?MOV,?TIM,?BNKSL,?STBNK,?XMOV
	IF	NOT LDRBIOS
	PUBLIC	?INIT,?LDCCP
	EXTRN	@CIVEC,@COVEC,@AIVEC,@AOVEC,@LOVEC,@MXTPA
	ENDIF

*****************************************************************
*								*
*  THE BIOS JUMP TABLE						*
*								*
* The jump table below must remain in the same order, the 	*
* routines may be changed, but the function executed must be	*
* the same.  There are 33 jumps in the CP/M Plus BIOS vector.	*
*								*
*****************************************************************

;
?BOOT:	JMP	CBOOT			; cold start entry point
WBOOTE:
?WBOOT:	JMP	WBOOT			; warm start entry point
?CONST:	JMP	CONST			; console status A=ff=ready
?CONIN:	JMP	CONIN			; console input  data in A
COUT:
?CONO:	JMP	CONOUT			; console output data in C
?LIST:	JMP	LIST			; list device    data in C
?AUXO:	JMP	AUXOUT			; punch device   none
?AUXI:	JMP	AUXIN	  		; reader device  none
?HOME	JMP	HOME			; seek home track
?SLDSK:	JMP	SETDRV			; select disk    disk in C
?STTRK:	JMP	SETTRK			; seek track     track in BC
?STSEC:	JMP	SETSEC			; set sector     sector in BC
?STDMA:	JMP	SETDMA			; set dma        dma in BC
?READ:	JMP	READ			; read sector
?WRITE:	JMP	WRITE			; write sector
?LISTS:	JMP	LISTST			; return list status A=FF=ready
?SCTRN:	JMP	SECTRAN			; sector translate  sector in BC
?CONOS:	JMP	CONOST			; Return Output Status of Console
?AUXIS:	JMP	AUXIST			; Return Input Status of Aux. Port
?AUXOS:	JMP	AUXOST			; Return Output Status of Aux. Port
?DVTAB:	JMP	DEVTBL			; Return Address of Char. I/O Table
?DEVIN:	JMP	DEVINI			; Initialize Char. I/O Devices
?DRTBL:	JMP	DRVTBL			; Return Address of Disk Drive Table
?MLTIO:	JMP	MULTIO			; Set number of logically conseqcuitive
					;  sectors to be read or written
?FLUSH:	JMP	FLUSH			; Force Physical Buffer Flushing for 
					;  user-supported deblocking
?MOV:	JMP	MOVE			; Memory Move for Large Memory Copy
?TIM:	JMP	?TIME			; Get The Time
?BNKSL:	JMP	SELMEM			; Select Alternate Bank of Memory
?STBNK:	JMP	SETBNK			; Select Bank for DMA Operation
?XMOV:	JMP	XMOVE			; Set Bank When a Buffer is in a Bank
					;  other than 0 or 1
DJDRV	JMP	DJSEL			; Hook for SINGLE.COM program
					; Reserved for System Implementor
	JMP	RESERV1			; Reserved for CP/M Plus
	JMP	RESERV2			; Reserved for CP/M Plus
;
;  Device Table is not implemented, so return HL=0
DEVTBL:	LXI	H,0
	RET
;
;  Flush routine is not implemented, so return A=0
FLUSH:	XRA	A
	RET
;
;  Drive Table is not used, so return HL=0FFFEH
DRVTBL:	LXI	H,0FFFEH
	RET
;
;  The following jumps from the BIOS jump vector are not implemented:
CONOST:
AUXIST:
AUXOUT:
AUXIN:
AUXOST:
DEVINI:
MULTIO:
XMOVE:
SELMEM:
SETBNK:
RESERV1:
RESERV2:
?TIME:
	RET

*****************************************************************
*								*
* Cold-boot sign-on message					*
*								*
*****************************************************************

PROMPT:
	IF	LDRBIOS
	DB	ACR,ALF,ALF
	DB	'Loader for Morrow Designs DJ2D Controller.'
	DB	ACR,ALF,0
	ENDIF
;
	IF	NOT LDRBIOS
	DB	ACR,ALF,ALF
	DB	'CP/M Plus (V'		;CP/M version number
	DB	CPMREV/10+'0'
	DB	'.'
	DB	(CPMREV MOD 10)+'0'
	DB	'), BIOS rev '
	DB	REVNUM/10+'0','.'	;Cbios revision number
	DB	REVNUM MOD 10+'0'
	DB	ACR,ALF
	DB	'For Morrow Designs DJ2D Controller '
	DB	'@ 0'

	IF	ORIGIN/4096 > 10	;Controller origin (HEX)
	DB	ORIGIN/4096+'A'-10
	ELSE
	DB	ORIGIN/4096+'0'
	ENDIF

	IF	(ORIGIN/256 AND 0FH) > 10
	DB	(ORIGIN/256 AND 0FH)+'A'-10
	ELSE
	DB	(ORIGIN/256 AND 0FH)+'0'
	ENDIF
	DB	'00H.'
	DB	ACR,ALF,0
	ENDIF

*****************************************************************
*								*
* Utility subroutine to output the message pointed at by H&L,	*
* terminated with a null.  Used only during cold boot.		*
*								*
*****************************************************************

MESSAGE	MOV	A,M		;Get a character of the message
	INX	H		;Bump text pointer
	ANA	A		;Test for end
	RZ			;Return if done
	PUSH	H		;Save pointer to text
	MOV	C,A		;Output character in C
	CALL	COUT		;Output the character
	POP	H		;Restore the pointer
	JMP	MESSAGE		;Continue until null reached

*****************************************************************
*								*
* System initialization Subroutine				*
* Put any initialization procedures required by your system	*
* here (e.g. setting up UARTS, etc.)				*
*								*
*****************************************************************

	IF	LDRBIOS		;Then perform any initializations
TINIT:	MVI	C,CLEAR		; that your system requires
	CALL	COUT		;Clear the console screen
	RET
	ENDIF

*****************************************************************
*								*
* Cold boot routines						*
*								*
*****************************************************************

CBOOT:
	IF	LDRBIOS		;Then Initialize terminal or whatever
	CALL	TINIT
	ENDIF
;
	IF	NOT LDRBIOS
	LXI	SP,TPA		;Set up stack
	ENDIF
;
	LXI	H,PROMPT	;Prep for sending signon message
	CALL	MESSAGE		;Send the prompt
	XRA	A		;Select disk A
	STA	CPMDRV
	STA	CDISK
;
	IF	NOT LDRBIOS
	CALL	?INIT		;Initialize page zero and SCB
	JMP	WBOOT		;Warm-boot
;
;  System initialization subroutine
?INIT:	MVI	A,JMP		;Set up jumps at addresses 0 and 5
	STA	0
	STA	5
	LXI	H,WBOOTE
	SHLD	1
	LHLD	@MXTPA
	SHLD	6
	LXI	H,1		;Initialize System Control Block
	SHLD	@CIVEC
	SHLD	@COVEC
	LXI	H,2
	SHLD	@LOVEC
	LXI	H,4
	SHLD	@AIVEC
	SHLD	@AOVEC
	LXI	H,LOG$MSG	;Print sign-on message on console
	CALL	MESSAGE
	RET

*****************************************************************
*								*
*  Subroutine to load the CCP into memory at address 100H	*
*								*
*****************************************************************

?LDCCP:	XRA	A
	STA	CCP$FCB+15	;Start with extent 0
	LXI	H,0
	SHLD	FCB$NR		;Record 0
	LXI	D,CCP$FCB
	CALL	OPEN		;Open file CCP.COM
	INR	A
	JZ	NO$CCP		;Tell if no file found
	LXI	D,0100H		;Else
	CALL	SETBUF		;Set to load into TPA
	LXI	D,128
	CALL	SETMULTI	;Allow up to 16k bytes
	LXI	D,CCP$FCB
	CALL	REBOOT		;Read file into memory
	RET
;
;  Print error message if can't find CCP.COM on default drive
NO$CCP:	LXI	H,CCP$MSG
	CALL	MESSAGE		;REPORT THIS
	CALL	?CONIN		;GET A RESPONSE
	JMP	?LDCCP		;AND TRY AGAIN

;
;  CP/M BDOS function interface used to load CCP.COM
OPEN:	MVI	C,15
	JMP	BDOSGO		;OPEN FILE CONTROL

SETMULTI:
	MVI	C,44
	JMP	BDOSGO		;SET MULTI RECORD COUNT

REBOOT:	MVI	C,20
	JMP	BDOSGO		;READ RECORDS

SETBUF:	MVI	C,26
	JMP	BDOSGO		;SETDMA

BDOSGO:	LHLD	@MXTPA
	PCHL	
;
;  Miscellaneous messages for console
LOG$MSG:
	DB	13,10,13,10,'CP/M Version 3.0',00
CCP$MSG:
	DB	13,10,'BIOS Err on A: NO CCP.COM file',00
;
;  File Control Block used to load CCP.COM
CCP$FCB:
	DB	1,'CCP     ','COM',0,0,0,0
	DS	16
FCB$NR:	DB	0,0,0
	ENDIF	;NOT LDRBIOS

*****************************************************************
*								*
*  Warm-boot subroutine						*
*								*
*****************************************************************


WBOOT:
	IF	NOT LDRBIOS
	LXI	SP,TPA		;Set up stack pointer
	ENDIF
;
	LXI	D,BUFF		;Set up initial DMA address
	CALL	SETDMA
;
	IF	NOT LDRBIOS
	CALL	?LDCCP		;Load the CCP.COM file into the TPA
	ENDIF
;
	MVI	A,JMP		;Set up jumps at addresses 0 and 5
	STA	0
	STA	5
	LXI	H,WBOOTE
	SHLD	1
;
	IF	NOT LDRBIOS
	LHLD	@MXTPA
	SHLD	6
;
	IF	UD2
;  This conditional is used if you want the system to read the 
;  USER/DRIVE byte at address 4 during each warm-boot, to maintain
;  compatibility with certain CP/M 2.2 programs that modify this byte
;  to change default user area of drive.  Making this conditional TRUE
;  may cause some unusual side-effects when you warm-boot while logged
;  into any drive other than 'A' drive.  Note also that the location of
;  the warm-boot user and drive bytes in the SCB is undocumented, so it
;  may be changed from the address assumed here.  This may also have been
;  changed since the Beta 1.2 version that we evaluated, so use it with
;  a great deal of caution.
;
;  Copy USER/DRIVE byte from address 4 into the System Control Block
	LHLD	1	;Get address page of BIOS
	DCR	H	;Point to default drive byte in SCB
	MVI	L,0AFH
	LDA	4	;Get default drive from User/Drive byte
	ANI	0FH
	MOV	M,A	;Store DRIVE in SCB
	INX	H	;Point to default user byte in SCB
	LDA	4	;Get default user from User/Drive byte
	RRC
	RRC
	RRC
	RRC
	ANI	0FH
	MOV	M,A	;Store USER in SCB
;
	ENDIF	;UD2
	ENDIF	;NOT LDRBIOS
;
	LDA	CDISK	;Put current disk into A
	MOV	C,A
;
	IF	NOT LDRBIOS
	JMP	0100H	;Jump to CCP
	ENDIF
;
	IF	LDRBIOS
	RET		;Return to loader
  	ENDIF

*****************************************************************
*								*
* General purpose memory move subroutine.			*
* Moves BC bytes from DE to HL					*
*								*
*****************************************************************

MOVE:	LDAX	D
	MOV	M,A
	INX	D
	INX	H
	DCR	C
	JNZ	MOVE
	MOV	A,B
	ORA	C
	RZ
	DCR	B
	JMP	MOVE

*****************************************************************
*								*
* Setsec subroutine saves the desired sector to seek to until	*	
* an actual read or write is attempted.				*
*								*
*****************************************************************

SETSEC	MOV	A,C		;Save the sector number
	STA	CPMSEC
	RET

*****************************************************************
*								*
* Setdma subroutine saves the DMA address for the data transfer.*
*								*
*****************************************************************

SETDMA	MOV	H,B		;Save DMA address that is in BC
	MOV	L,C
	SHLD	CPMDMA
	RET

*****************************************************************
*								*
* Home subroutine does a seek to track zero.			*
*								*
*****************************************************************

HOME	MVI	C,0		;Track to seek to

*****************************************************************
*								*
* Settrk subroutine saves the TRK # to seek to. Nothing is done *
* until an actual read or write.				*
*								*
*****************************************************************

SETTRK	MOV	A,C
	STA	CPMTRK
	RET

*****************************************************************
*								*
* Sectran subroutine translates a logical sector # into a	*
* physical sector #.  Note that this routine is similar to the	*
* original one used in the DJ2D CP/M 2 BIOS, but has some	*
* significant differences.					*
*								*
*****************************************************************

SECTRAN	INX	B
	PUSH	D		;Save table address
	PUSH	B		;Save sector #
	CALL	GETDPB		;Get DPB address into HL
	MOV	A,M		;Get # of CP/M sectors/track
	ORA	A		;Clear carry
	RAR			;Divide by two
	SUB	C
	PUSH	PSW		;Save adjusted sector
	JM	SIDETWO
SIDEA	POP	PSW		;Discard adjusted sector
	POP	B		;Restore sector requested
	POP	D		;Restor address of xlt table
SIDEONE	XCHG			;exchange DPB and table address
	DAD	B		;bc = offset into table
	MOV	L,M		;hl <- physical sector
	MVI	H,0
	RET

SIDETWO	LXI	B,17		;Offset to side bit
	DAD	B
	MOV	A,M
	ANI	8		;Test for double sided
	JZ	SIDEA		;Media is only single sided
	POP	PSW		;Retrieve adjusted sector
	POP	B
	CMA			;Make sector request positive
	INR	A
	MOV	C,A		;Make new sector the requested sector
	POP	D
	CALL	SIDEONE
	MVI	A,80H		;Side two bit
	ORA	L		;	and sector
	MOV	L,A
	RET

*****************************************************************
*								*
* Setdrv subroutine selects the next drive to be used in	*
* read/write operations. If the drive has never been selected	*
* before, a parameter table is created which correctly		*
* describes the diskette currently in the drive. Diskettes can	*
* be of four different sector sizes:				*	
*	1) 128 bytes single density.				*
*	2) 256 bytes double density.				*
*	3) 512 bytes double density.				*
*	4) 1024 bytes double density.				*
*  Note the changes made for CP/M 3.0				*
*								*
*****************************************************************

SETDRV	MOV	A,C		;Save the drive #
	STA	CPMDRV
	CPI	MAXDISK		;Check for a valid drive #
	JNC	ZRET		;Illegal drive #
	MOV	A,E		;Test if drive ever logged in before
	ANI	1
	JNZ	SETDRV1		;Bit 0 of E = 0 means never selected before
	MVI	A,1		;Select sector 1 of track 1
	STA	TRUESEC
	STA	CPMTRK
	CALL	FILL		;Flush buffer and refill
	JC	ZRET		;Test for error return
	CALL	DJSTAT		;Get status on current drive
	ANI	2CH		;Look at side and denstiy bits
	MOV	E,A
	ANI	20H
	MOV	A,E
	JNZ	SETDR1
	ORI	10H
SETDR1:	RAR
	PUSH	PSW		;Save DJSTAT single/double-sided info
	ANI	6
	LXI	H,XLTS		;Table of XLT addresses
	PUSH	H
	MOV	E,A
	MVI	D,0
	DAD	D
	PUSH	H		;Save pointer to proper XLT
	CALL	GETDPB		;Get DPH pointer into DE
	XCHG			;
	POP	D
	MVI	B,2		;Number of bytes to move
	CALL	MOVLOP		;Move the address of XLT
	LXI	D,10		;Offset to DPB pointer
	DAD	D		;Point HL to DPB address
	XCHG			;Point HL to DBP base, DE to &DPH.DPB
	POP	H
	POP	PSW		;Offset to correct DPB
	MOV	C,A
	MVI	B,0
	DAD	B		;Add to translate table to point to density
				;(The DPB table is cleverly located right
				; after the xlt table)
	XCHG			;Put DPB address in DPH
	MVI	B,2		;Move DPB address into DPH
	CALL	MOVLOP
SETDRV1	CALL	GETDPB		;Get address of DPB in HL
	LXI	B,17		;Offset to sector size
	DAD	B
	MOV	A,M		;Get sector size
	ANI	7H
	STA	SECSIZ
	MOV	A,M
	RAR
	RAR
	RAR
	RAR
	ANI	0FH
	STA	SECPSEC		;Single/double-sided flag
	XCHG			;HL to DPH
	RET

ZRET	LXI	H,0		;Seldrv error exit
	RET

*****************************************************************
*								*
* Getdpb subroutine returns HL pointing to the DPB of the	*
* currently selected drive, DE pointing to DPH.			*
*								*
*****************************************************************

GETDPB:	LDA	CPMDRV		;Get drive #
	LXI	H,DPZERO
	LXI	D,19H
GETDP1:	ORA	A
	JZ	GETDP2
	DAD	D
	DCR	A
	JMP	GETDP1
;
GETDP2:	PUSH	H		;Save address of DPH
	LXI	D,12		;Offset to DPB
	DAD	D
	MOV	A,M		;Get low byte of DPB address
	INX	H
	MOV	H,M		;Get low byte of DPB
	MOV	L,A
	POP	D
	RET

*****************************************************************
*								*
* xlts points to a table of addresses that point to each	*
* of the xlt tables for each sector size.			*
*								*
* The table following the xlt's is a table of the DPB's, used	*
* by the SETDRV subroutine to calculate density			*
*								*
*****************************************************************

XLTS	DW	XLT128		;Xlt for 128 byte sectors
	DW	XLT256		;Xlt for 256 byte sectors
	DW	XLT512		;Xlt for 512 byte sectors
	DW	XLT124		;Xlt for 1024 byte sectors
;
	DW	DPB128S		;DPB FOR 128 BYTE SECTORS SINGLE SIDE
	DW	DPB256S		;DPB FOR 256 BYTE SECTORS SINGLE SIDE
	DW	DPB512S		;DPB FOR 512 BYTE SECTORS SINGLE SIDE
	DW	DP1024S		;DPB FOR 1024 BYTE SECTORS SINGLE SIDE
	DW	DPB128D		;DPB FOR 128 BYTE SECTORS DOUBLE SIDE
	DW	DPB256D		;DPB FOR 256 BYTE SECTORS DOUBLE SIDE
	DW	DPB512D		;DPB FOR 512 BYTE SECTORS DOUBLE SIDE
	DW	DP1024D		;DPB F0R 1024 BYTE SECTORS DOUBLE SIDE
 
*****************************************************************
*								*
* Write subroutine moves data from memory into the buffer. If	*
* the desired CP/M sector is not contained in the disk buffer,	*
* the buffer is first flushed to the disk if it has ever been	*
* written into, then a read is performed into the buffer to get	*
* the desired sector. Once the correct sector is in memory, the	*
* buffer written indicator is set, so the buffer will be	*
* flushed, then the data is transferred into the buffer. 	*
*								*
*****************************************************************

WRITE	MOV	A,C		;Save write command type
	STA	WRITTYP
	MVI	A,1		;Set write command
	DB	(MVI) OR (B*8)	;Fake "mvi b" instruction will
				; cause the following "xra a" to
				; be skipped over.
				;This is the same (ugh) trick that
				;Morrow's used, but it works...

*****************************************************************
*								*
* Read subroutine to buffer data from the disk. If the sector 	*
* requested from CP/M is in the buffer, then the data is simply	*
* transferred from the buffer to the desired dma address. If	*
* the buffer does not contain the desired sector, the buffer is	*
* flushed to the disk if it has ever been written into, then	*
* filled with the sector from the disk that contains the	*
* desired CP/M sector.						*
*								*
*****************************************************************

READ	XRA	A		;Set the command type to read
	STA	RDWR		;Save command type

;
; Redwrt calculates the physical sector on the disk that
; contains the desired CP/M sector, then checks if it is the
; sector currently in the buffer. If no match is made, the
; buffer is flushed if necessary and the correct sector read
; from the disk.
REDWRT	MVI	B,0		;The 0 is modified to contain the log2
SECSIZ	EQU	$-1		;	of the physical sector size/128
				;	on the currently selected disk.
				;(Another Morrow trick)
	LDA	CPMSEC		;Get the desired CP/M sector #
	PUSH	PSW		;Temporary save
	ANI	80H		;Save only the side bit
	MOV	C,A		;Remember the side
	POP	PSW		;Get the sector back
	ANI	7FH		;Forget the side bit
	DCR	A		;Temporary adjustment
DIVLOOP	DCR	B		;Update repeat count
	JZ	DIVDONE
	ORA	A		;Clear the carry flag
	RAR			;Divide the CP/M sector # by the size
				;	of the physical sectors
	JMP	DIVLOOP		;
DIVDONE	INR	A
	ORA	C		;Restore the side bit
	STA	TRUESEC		;Save the physical sector number
	LXI	H,CPMDRV	;Pointer to desired drive,track, and sector
	LXI	D,BUFDRV	;Pointer to buffer drive,track, and sector
	MVI	B,4		;Count loop
DTSLOP	DCR	B		;Test if done with compare
	JZ	SECMOV		;Yes, match. Go move the data
	LDAX	D		;Get a byte to compare
	CMP	M		;Test for match
	INX	H		;Bump pointers to next data item
	INX	D
	JZ	DTSLOP		;Match, continue testing

;
; If drive, track, and sector don't match, then flush the buffer if
; necessary and refill.
	CALL	FILL		;Get correct physical sector into buffer
	RC			;Return error if no good

;
; SECMOV has been previously modified to cause either a transfer
; into or out of the buffer. (Yet another Morrow trick)
SECMOV	LDA	CPMSEC		;Get the CP/M sector to transfer
	DCR	A		;Adjust to proper sector in buffer
	ANI	0		;Strip off high ordered bits
SECPSEC	EQU	$-1		;The 0 is modified to represent the # of
				;	CP/M sectors per physical sectors
	MOV	L,A		;Put into HL
	MVI	H,0
	DAD	H		;Form offset into buffer
	DAD	H
	DAD	H
	DAD	H
	DAD	H
	DAD	H
	DAD	H
	LXI	D,BUFFER	;Beginning address of buffer
	DAD	D		;Form beginning address of sector to transfer
	XCHG			;DE = address in buffer
	LXI	H,0		;Get DMA address, the 0 is modified to
				;	contain the DMA address
CPMDMA	EQU	$-2
	MVI	A,0		;The zero gets modified to contain
				;	a zero if a read, or a 1 if write
RDWR	EQU	$-1
	ANA	A		;Test which kind of operation
	JNZ	INTO		;Transfer data into the buffer
	CALL	MOVER
	XRA	A
	RET

INTO	XCHG			;
	CALL	MOVER		;Move the data, HL = destination
				;	DE = source
	MVI	A,1
	STA	BUFWRTN		;Set buffer written into flag
	MVI	A,0		;Check for directory write
WRITTYP	EQU	$-1
	DCR	A
	MVI	A,0
	STA	WRITTYP		;Set no directory write
	RNZ			;No error exit

*****************************************************************
*								*
* FLUSHA subroutine writes the contents of the buffer out to	*
* the disk if it has ever been written into.			*
*								*
*****************************************************************

FLUSHA	MVI	A,0		;The 0 is modified to reflect if
				; the buffer has been written into
BUFWRTN	EQU	$-1
	ANA	A		;Test if written into
	RZ			;Not written, all done
	LXI	H,DJWRITE	;Write operation
;
; Prep prepares to read/write the disk. Retries are attempted.
; Upon entry, H&L must contain the read or write operation
; address.
PREP	XRA	A		;Reset buffer written flag
	STA	BUFWRTN
	SHLD	RETRYOP		;Set up the read/write operation
	MVI	B,RETRIES	;Maximum number of retries to attempt
RETRYLP	PUSH	B		;Save the retry count
	LDA	BUFDRV		;Get drive number involved in the operation
	MOV	C,A
	CALL	DJDRV		;Select the drive
	LDA	BUFTRK
	ANA	A		;Test for track zero
	MOV	C,A
	PUSH	B
	CZ	DJHOME		;Home the drive if track 0
	POP	B		;Restore track #
	CALL	DJTRK		;Seek to proper track
	LDA	BUFSEC		;Get sector involved in operation
	PUSH	PSW		;Save the sector #
	RLC			;Bit 0 of A equals side #
	ANI	1		;Strip off unnecessary bits
	MOV	C,A		;C <- side #
	CALL	DJSIDE		;Select the side
	POP	PSW		;A <- sector #
	ANI	7FH		;Strip off side bit
	MOV	C,A		;C <- sector #
	CALL	DJSEC		;Set the sector to transfer
	LXI	B,BUFFER	;Set the DMA address
	CALL	DJDMA
	CALL	DJREAD		;The read operation is modified to write
RETRYOP	EQU	$-2
	POP	B		;Restore the retry counter
	MVI	A,0		;No error exit status
	RNC			;Return no error
	DCR	B		;Update the retry counter
	STC			;Assume retry count expired
	MVI	A,0FFH		;Error return
	RZ
	JMP	RETRYLP		;Try again

*****************************************************************
*								*
* Fill subroutine fills the buffer with a new sector		*
* from the disk.						*
*								*
*****************************************************************

FILL	CALL	FLUSHA		;Flush buffer first
	RC			;Check for error
	LXI	D,CPMDRV	;Update the drive, track, and sector
	LXI	H,BUFDRV	
	MVI	B,3		;Number of bytes to move
	CALL	MOVLOP		;Copy the data
	LXI	H,DJREAD
	JMP	PREP		;Select drive, track, and sector.
				;	Then read the buffer

*****************************************************************
*								*
* Mover subroutine moves 128 bytes of data. Source pointer	*
* in DE, Dest pointer in HL.					*
*								*
*****************************************************************

MOVER	MVI	B,128		;Length of transfer
MOVLOP	LDAX	D		;Get a bte of source
	MOV	M,A		;Move it
	INX	D		;Bump pointers
	INX	H
	DCR	B		;Update counter
	JNZ	MOVLOP		;Continue moving until done
	RET

*****************************************************************
*								*
* Terminal driver subroutines.  Note that the console device	*
* is NOT the DJ2D memory-mapped serial I/O port.		*
*								*
*****************************************************************

*****************************************************************
*								*
* const: get the status for the console				*
*								*
*****************************************************************

CONST	IN	80H		;Read console status port
	ANI	40H
	MVI	A,0
	RZ			;Return A=0, if no character waiting
	INR	A
	RET			;Else return A=01H

*****************************************************************
*								*
* conin: get a character from the console			*
*								*
*****************************************************************

CONIN:	IN	80H		;Read console status port
	ANI	40H
	JZ	CONIN		;Wait for a character
	IN	81H		;Read the console data port
	ANI	7FH		;Mask the MSB
	RET			;Return with the character in A

*****************************************************************
*								*
* conout: send a character to the console			*
*								*
*****************************************************************

CONOUT	IN	80H		;Read the console status port
	ANI	80H
	JZ	CONOUT		;Wait until character can be sent
	MOV	A,C
	OUT	81H		;Send character to console data port
	RET			;Return

*****************************************************************
*								*
* listst: get the status for the list device.  Note that the	*
* list device used is the memory-mapped DJ2D serial I/O port.	*
*								*
*****************************************************************

LISTST:	LDA	ORIGIN+3F9H	;Read printer status port (memory mapped)
	CMA			; (invert to positive logic)
	ANI	08H
	MVI	A,00H
	RZ			;return A=0, if not ready
	MVI	A,0FFH		;return A=0FFH, if ready 
	RET

*****************************************************************
*								*
* list: send a character to the list device			*
*								*
*****************************************************************

LIST:	LDA	ORIGIN+3F9H	;Read list device status (memory mapped)
	CMA			; (invert it to positive logic)
	ANI	08H		;Wait until ok to send
	JZ	LIST
	MOV	A,C		;Send the character
	CMA			; (invert it to positive logic)
	STA	ORIGIN+3F8H  	; to memory mapped I/O.
	RET

*****************************************************************
*								*
* Xlt tables (sector skew tables)  These tables			*
* define the sector translation that occurs when mapping CP/M	*
* sectors to physical sectors on the disk. There is one skew	*
* table for each of the possible sector sizes. 			*
*								*
*****************************************************************

XLT128	DB	0
	DB	1,7,13,19,25
	DB	5,11,17,23
	DB	3,9,15,21
	DB	2,8,14,20,26
	DB	6,12,18,24
	DB	4,10,16,22

XLT256	DB	0
	DB	1,2,19,20,37,38
	DB	3,4,21,22,39,40
	DB	5,6,23,24,41,42
	DB	7,8,25,26,43,44
	DB	9,10,27,28,45,46
	DB	11,12,29,30,47,48
	DB	13,14,31,32,49,50
	DB	15,16,33,34,51,52
	DB	17,18,35,36


xlt512	db	0
	db	1,2,3,4,17,18,19,20
	db	33,34,35,36,49,50,51,52
	db	5,6,7,8,21,22,23,24
	db	37,38,39,40,53,54,55,56
	db	9,10,11,12,25,26,27,28
	db	41,42,43,44,57,58,59,60
	db	13,14,15,16,29,30,31,32
	db	45,46,47,48

XLT124	DB	0
	DB	1,2,3,4,5,6,7,8
	DB	25,26,27,28,29,30,31,32
	DB	49,50,51,52,53,54,55,56
	DB	9,10,11,12,13,14,15,16
	DB	33,34,35,36,37,38,39,40
	DB	57,58,59,60,61,62,63,64
	DB	17,18,19,20,21,22,23,24
	DB	41,42,43,44,45,46,47,48

*****************************************************************
*								*
* DISK PARAMETER BLOCKS.  The following sizes and densities are *
* specified to maintain compatibility with DJ2D CP/M 2.2:	*
*	128 bytes, SSSD						*
*	256 bytes, SSDD						*
*	512 bytes, SSDD						*
*      1024 bytes, SSDD						*
*	128 bytes, DSDD						*
*	256 bytes, DSDD						*
*	512 bytes, DSDD						*
*      1024 bytes, DSDD						*
*								*
*****************************************************************

*****************************************************************
*								*
* The following DPB defines a  diskette for 128 byte sectors,	*
* single density, and single sided.				*
*								*
*****************************************************************

DPB128S	DW	26		;SPT  Number of CP/M sectors/track
	DB	3		;BSH  Block Shift Factor
	DB	7		;BLM  Block Mask
	DB	0		;EXM  Extent Mask
	DW	242		;DSM  Disk Space Maximum
	DW	63		;DRM  Directory Maximum
	DB	0C0H		;AL0  Initial Allocation Vectors
	DB	0		;AL1
	DW	16		;CKS  Directory Check Size
	DW	2		;OFF  Track Offset
	DB	00		;PSH  Physical Record Shift factor
	DB	00		;PHM  Physical Record Mask
				;(Following byte is used only by the BIOS)
	DB	1H		;16*((#cpm sectors/physical sector) -1) +
				;log2(#bytes per sector/128) + 1 +
				;8 if double sided.

*****************************************************************
*								*
* The following DPB defines a diskette for 256 byte sectors,	*
* double density, and single sided.				*
*								*
*****************************************************************

DPB256S	DW	52		;CP/M sectors/track
	DB	4		;BSH
	DB	15		;BLM
	DB	0		;EXM
	DW	242		;DSM
	DW	127		;DRM
	DB	0C0H		;AL0
	DB	0		;AL1
	DW	32		;CKS
	DW	2		;OFF
	DB	00		;PSH
	DB	00		;PHM
				;
	DB	12H		;16*((#cpm sectors/physical sector) -1) +
				;log2(#bytes per sector/128) + 1 +
				;8 if double sided.

*****************************************************************
*								*
* The following DPB defines a diskette as 512 byte sectors,	*
* double density, and single sided.				*
*								*
*****************************************************************

DPB512S	DW	60		;CP/M sectors/track
	DB	4		;BSH
	DB	15		;BLM
	DB	0		;EXM
	DW	280		;DSM
	DW	127		;DRM
	DB	0C0H		;AL0
	DB	0		;AL1
	DW	32		;CKS
	DW	2		;OFF
	DB	00		;PSH
	DB	00		;PHM
				;
	DB	33H		;16*((#cpm sectors/physical sector) -1) +
				;log2(#bytes per sector/128) + 1 +
				;8 if double sided.

*****************************************************************
*								*
* The following DPB defines a diskette as 1024 byte sectors,	*
* double density, and single sided.				*
*								*
*****************************************************************

DP1024S	DW	64		;CP/M sectors/track
	DB	4		;BSH
	DB	15		;BLM
	DB	0		;EXM
	DW	299		;DSM
	DW	127		;DRM
	DB	0C0H		;AL0
	DB	0		;AL1
	DW	32		;CKS
	DW	2		;OFF
	DB	00		;PSH
	DB	00		;PHM
				;
	DB	74H		;16*((#cpm sectors/physical sector) -1) +
				;log2(#bytes per sector/128) + 1 +
				;8 if double sided.

*****************************************************************
*								*
* The following DPB defines a diskette for 128 byte sectors,	*
* single density, and double sided.				*
*								*
*****************************************************************

DPB128D	DW	52		;CP/M sectors/track
	DB	4		;BSH
	DB	15		;BLM
	DB	1		;EXM
	DW	242		;DSM
	DW	127		;DRM
	DB	0C0H		;AL0
	DB	0		;AL1
	DW	32		;CKS
	DW	2		;OFF
	DB	00		;PSH
	DB	00		;PHM
				;
	DB	9H

*****************************************************************
*								*
* The following DPB defines a diskette as 256 byte sectors,	*
* double density, and double sided.				*
*								*
*****************************************************************

DPB256D	DW	104		;CP/M sectors/track
	DB	4		;BSH
	DB	15		;BLM
	DB	0		;EXM
	DW	486		;DSM
	DW	255		;DRM
	DB	0F0H		;AL0
	DB	0		;AL1
	DW	64		;CKS
	DW	2		;OFF
	DB	00		;PSH
	DB	00		;PHM
				;
	DB	1AH

*****************************************************************
*								*
* The following DPB defines a diskette as 512 byte sectors,	*
* double density, and double sided.				*
*								*
*****************************************************************

DPB512D	DW	120		;CP/M sectors/track
	DB	4		;BSH
	DB	15		;BLM
	DB	0		;EXM
	DW	561		;DSM
	DW	255		;DRM
	DB	0F0H		;AL0
	DB	0		;AL1
	DW	64		;CKS
	DW	2		;OFF
	DB	00		;PSH
	DB	00		;PHM
				;
	DB	3BH

*****************************************************************
*								*
* The following DPB defines a diskette as 1024 byte sectors,	*
* double density, and double sided.				*
*								*
*****************************************************************

DP1024D	DW	128		;CP/M sectors/track
	DB	4		;BSH
	DB	15		;BLM
	DB	0		;EXM
	DW	599		;DSM
	DW	255		;DRM
	DB	0F0H		;AL0
	DB	0		;AL1
	DW	64		;CKS
	DW	2		;OFF
	DB	00		;PSH
	DB	00		;PHM
				;
	DB	7CH

*****************************************************************
*								*
* DISK PARAMETER HEADERS (for four drives)			*
*								*
*****************************************************************

DPZERO	DW	0		;XLT  Address of translation table (filled
				;	in by setdrv)
	DW	0,0,0,0		;-0-  BDOS Scratch Area
	DB	0
	DB	0		;MF   Media Flag
	DW	0		;DPB  Address of DPB (filled in by setdrv)
	DW	CSV0		;CSV  Directory check vector
	DW	ALV0		;ALV  Allocation vector
	DW	DIRBCB		;DIRBCB  Directory Buffer Control Block
	DW	0FFFFH		;DTABCB  Data Buffer Control Block
	DW	0FFFFH		;HASH   Directory Hashing Table
	DB	0		;HBANK  Bank number of Hash Table
;
DPONE	DW	0
	DW	0,0,0,0
	DB	0
	DB	0
	DW	0
	DW	CSV1
	DW	ALV1
	DW	DIRBCB
	DW	0FFFFH
	DW	0FFFFH
	DB	0
;
DPTWO	DW	0
	DW	0,0,0,0
	DB	0
	DB	0
	DW	0
	DW	CSV1
	DW	ALV1
	DW	DIRBCB
	DW	0FFFFH
	DW	0FFFFH
	DB	0
;
DPTHRE	DW	0
	DW	0,0,0,0
	DB	0
	DB	0
	DW	0
	DW	CSV1
	DW	ALV1
	DW	DIRBCB
	DW	0FFFFH
	DW	0FFFFH
	DB	0

*****************************************************************
*								*
*  Directory Buffer Control Block				*
*								*
*****************************************************************

DIRBCB:	DB	0FFH		;DRV  Drive number
	DB	00,00,00	;REC#  Record position in buffer
	DB	00		;WFLG  Buffer Written flag
	DB	00		;00  BDOS scratch byte
	DW	0000		;TRACK   Buffer contents' phys track
	DW	0000		;SECTOR  Buffer contents' phys sector
	DW	DIRBUF		;BUFFAD  Buffer address

*****************************************************************
*								*
* Miscellaneous ram locations used by the BIOS			*
*								*
*****************************************************************

CPMSEC	DB	0		;CP/M sector #
CPMDRV	DB	0		;CP/M drive #
CPMTRK	DB	0		;CP/M track #
TRUESEC	DB	0		;Disk Jockey sector that contains CP/M sector
BUFDRV	DB	0		;Drive that buffer belongs to
BUFTRK	DB	0		;Track that buffer belongs to
BUFSEC	DB	0		;Sector that buffer belongs to
BUFFER	DS	1024		;Maximum size buffer for 1K sectors

*****************************************************************
*								*
*  Allocation Vectors (for four drives)				*
*  Each vector requires 2 bits for each block on the drive	*
*								*
*****************************************************************

ALV0	DS	150		;Allocation vector for drive A
ALV1	DS	150		;Allocation vector for drive B
ALV2	DS	150		;Allocation vector for drive C
ALV3	DS	150		;Allocation vector for drive D

*****************************************************************
*								*
*  Checksum Vectors (for four drives)				*
*  Each vector requires 1 bit for every four directory entries	*
*								*
*****************************************************************

CSV0	DS	64		;Directory check vector for drive A
CSV1	DS	64		;Directory check vector for drive B
CSV2	DS	64		;Directory check vector for drive C
CSV3	DS	64		;Directory check vector for drive D

*****************************************************************
*								*
*  Directory Buffer						*
*								*
*****************************************************************

DIRBUF	DS	128

;
	END

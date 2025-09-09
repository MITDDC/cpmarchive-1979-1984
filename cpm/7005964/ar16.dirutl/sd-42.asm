*			 SD.ASM Ver 4.2
*			(Rev 11-1-81)

*		    SUPER DIRECTORY PROGRAM
*		       by Bruce	R. Ratoff

*	    Based on 'DIRS' by Keith Petersen, W8SDZ

* Displays the directory of a CP/M disk, sorted	alphabetically,
* with the file	size in	K, rounded to the nearest CP/M block size.

* This latest variation	on a common theme will automatically adjust
* itself for any block size and	directory length under CP/M 1.4	or 2.x
* or MP/M (any version).  Provisions are made for (1) automatic	pauses
* when the screen fills	up; (2)	searching individual or	multiple drives
* and/or user areas; (3) unconditional or optionally resetting the disk
* system before	execution begins; (4) directing	output to a disk file
* and appending	to it on subsequent runs; (5) summary line output giving
* drive	and user information, #	of files matched and how much space they
* consume, and the amount of free space	remaining on the disk; (6) displaying
* or suppressing CP/M 2	"system" files;	(7) accepting ambiguous	filenames
* with or without a drive name;	and (8)	printer	output.

* See SD.DOC for detailed instructions on configuring and running SD.ASM

* ==========================================================================

*	    NOTE: If you add improvements or otherwise update
*	    this program, please modem a copy of the new file
*	    to "TECHNICAL CBBS"	in Dearborn, Michigan -	phone
*	    313-846-6127 (110, 300, 450	or 600 baud).  Use the
*	    filename SD-NEW.NEW.  (KBP)

*	    As SD-41.ASM is "officially experimental", the author
*	    of the latest revisions would appreciate feedback on
*	    any bugs which may be discovered.  CC bug notes to
*	    me c/o Hyde Park RCP/M (phone 312-955-4493).  (DB)

* ==========================================================================

* Fixes/updates	(in reverse order to minimize reading time):

* 11-1-81 Eliminated LF after "More" message. Allows yet another
* line per more.
* 10-25-81 Incorporated 10/21 updates renamed version. -CAF
* 	Also made display more compact by eliminating unneeded lf's
*	This allows two more lines per "more"

* 10-21-81 Added conditionals for REVIDEO for reverse video
*	   display of tags ($SYS, etc.) -CAF

* 10/20/81 minor update to correct (1) malfunction when appending to an
*	   existing sd.dir file with the directory from an empty disk;
*	   (2) clobbering data area while closing sd.dir when last record
*	   appended is completely full; and (3) equate interaction error
*	   between fopt and aopt.  (ver 4.1 - david boruff)

* 10/19/81 MAJOR UPDATE adding new command line options for
*	   (1) disk system reset;  (2) page pause override;
*	   (3) displaying directory of a specified user	area;
*	   (4) searching ranges	of drives or user areas; and
*	   (5) printer output.	Corrected previous name error
*	   to avoid confusion with Keith Petersen's old SDIR.

*	   Corrected obscure file output bug which occurred only
*	   when appending on even record or extent boundaries.
*	   Reset equate	of Ver 2.3 deleted as redundant	now that
*	   command line	reset available	as an option or	default.
*	   Shortened page-pause	message	to free-up program space.
*	   Optimized much of the existing code to compact the load
*	   module and gain space for new features.  Option scanner
*	   rewritten to	permit free form input and to simplify any
*	   future expansions of	the command line option	set.
*	   Reclaimed uninitialized data	memory to further compact
*	   load	module size.  By popular demand, restored code to
*	   display free	space remaining	when no	files are found.
*	   Added tables	to allow restricting directory searches
*	   to a	range of drives	and/or user areas.  BDOS intercept
*	   added to facilitate searching drives	that may not be
*	   on-line (more generally applicable than the FILEFIND
*	   method if your BIOS returns control to BDOS on fatal disk
*	   errors).  General cosmetic overhaul including tabular
*	   realignment and additional comments to enhance readability
*	   at the cost of a "few" extra bytes.	(Ver 4.0 - David Boruff)

* 09/23/81 MINOR UPDATE	to add equate to allow suppressing user
*	   numbers in the directory output. (Ver 3.1 - David Boruff)

* 09/18/81 MAJOR UPDATE	implementing new file output option allowing
*	   directory output to be appended to a	disk file.  Changed
*	   option specification	format to require a dollar sign
*	   preceding the option	specifiers.  Changed header format
*	   to display drive & user #'s for each line less than 4
*	   files wide.	Changed	code for no files found	to display
*	   error message only.	(Ver 3.0 - David Boruff)

* 09/12/81 MINOR UPDATE	deleting WIDE and NOT WIDE code	in deference
*	   to equating screen size.  Added Flashwriter II equate to
*	   allow display of file attributes in reverse video.  Changed
*	   tag-line to display drive and user #.  Added	equate to allow
*	   disk	system reset on	startup.  Other	cosmetic changes made
*	   to open up display format and give output a less cramped
*	   appearance. (Ver 2.3	- David	Boruff)

* 06/05/81 Added PGPAWZ	(page pause) conditional for remote
*	   CP/M	systems	where pausing may not be wanted.
*	   Setting PGPAWZ and REPSIZ to	FALSE will result in
*	   a display like DIR, but sorted and with the stat
*	   of space remaining.	Rearranged equates to allow
*	   15 lines per	page when narrow display is chosen.
*	   (Ver	2.2 - KBP)

* 06/01/81 Added version number, restored CTL-C	break, added
*	   CTL-C test to allow break at	page pause, added
*	   routine to gobble up	any waiting console character
*	   at EXIT, added conditional assembly to allow	no
*	   report of file sizes, added conditional assembly
*	   for direct console I/O for remote CP/M systems
*	   where phone line noise would	garbage	display.  (KBP)

* 05/06/81 Corrected double printing of	drive name in CALLB.
*	   Error only occurred with narrow display when	file
*	   wasn't found. (Tim Nicholas)

* 02/06/81 Changed sort	to have	odd gap	(KBP say its faster)

* 01/06/81 Changed sort	from bubble sort to shell sort
*	   for faster speed.

* 12/24/80 Changed BIOS	conout to BDOS conout to allow
*	   printing of directory with CTL-P.  Also added
*	   print of remaining space even if file not
*	   found. (Steve Nossen)

* 12/15/80 Added space suppression when	printing file
*	   totals.  (KBP)

* 12/14/80 Added logic to print	space remaining	on disk.
*	   Changed ^C test so that interrupting	character is
*	   not echoed (makes remote use	cleaner).  (BRR)

* 12/02/80 Fixed bug in	print routine which compared last file
*	   against garbage before printing. (BRR)

* 11/29/80 Changed to allow printing 4 file names. (Ben	Bronson
*	   and Keith Petersen)

* 11/22/80 Fixed bug in	handling >256 files.  Changed abort test
*	   in print routine to only abort on control-c.	 (BRR)

* ==========================================================================

*	     Set 'RMAC'	TRUE to	assemble with relocating assembler
*	     (requires link with PAGE 0	equates	in separate file).

* ==========================================================================

FALSE	EQU	0
TRUE	EQU	NOT FALSE

******************************
*			     *
* USER OPTION SPECIFICATIONS *
*			     *
******************************

AOPT	EQU	TRUE		;True to allow searching all user areas
ALTCPM	EQU	FALSE		;True for H8 or	TRS-80
DIRCON	EQU	FALSE		;True for direct console output
DOPT	EQU	TRUE		;True to allow searching all drives on-line
FOPT	EQU	TRUE		;True to allow file output option
NOPT	EQU	TRUE		;True to allow disabling page pause option
OPTION	EQU	TRUE		;True if allowing ANY command line options
PGPAWZ	EQU	TRUE		;True for pause after each page
POPT	EQU	TRUE		;True to allow printer option
REPERR	EQU	TRUE 		;True to report command line option errors
REPSIZ	EQU	TRUE		;True to report file sizes
REPUSR	EQU	TRUE		;True to report user numbers
RMAC	EQU	FALSE		;True for assembly by RMAC
ROPT	EQU	TRUE		;True to allow reset option
SOPT	EQU	TRUE		;True to allow system file option
UOPT	EQU	TRUE		;True to allow user number option
REVIDEO	EQU	TRUE		;Use reverse video sequences
INTOREV	EQU	0160Q		;Sequence to enter reverse video (Z19)
OUTAREV	EQU	0161Q		;And to get out
VECTOR	EQU	FALSE		;True to display attributes on Flashwriter II
VIDEO	EQU	0E009H		;Entry to Flashwriter video driver PROM

DELIM	EQU	7CH		;Fence (delimiter) character (vertical bar)

NPL	EQU	4		;# of names per line (max of 3 for 64x16)
*						     (max of 4 for 80x24)

LPS	EQU	23		;# of lines per screen (max of 14 for 64x16)
*						       (max of 23 for 80x24)

	IF	NOPT AND NOT PGPAWZ
	++++ NOPT OPTION REDUNDANT WITHOUT PGPAWZ ++++
	ENDIF

	IF	REPERR AND NOT OPTION
	++++ REPERR EQUATE USELESS WITHOUT OPTION ++++
	ENDIF

* BDOS equates

RDCHR	EQU	1		;Read char from	console
WRCHR	EQU	2		;Write char to console
CONST	EQU	11		;Check cons stat
RESET	EQU	13		;Reset disk system
SELDSK	EQU	14		;Select	disk
OPEN	EQU	15		;0FFH=not found
CLOSE	EQU	16		;   "	"
SEARCH	EQU	17		;   "	"
NEXT	EQU	18		;   "	"
READ	EQU	20		;not 0 = EOF
WRITE	EQU	21		;not 0 = disk full
MAKE	EQU	22		;0FFH =	directory full
CURDSK	EQU	25		;Get currently logged disk name
SETDMA	EQU	26		;Set current DMA
GALLOC	EQU	27		;Get address of	allocation vector
CURDPB	EQU	31		;Get current disk parameters
CURUSR	EQU	32		;Get currently logged user number (2.x only)

	IF	ALTCPM
BASE	EQU	4200H
TPA	EQU	4300H
	ENDIF

	IF	RMAC
	EXTRN	BASE,FCB,BDOS	;Make base external
	ENDIF

	IF	(NOT ALTCPM) AND (NOT RMAC)
BASE	EQU	$		;Default to 0 (or 100H with MAC	+R option)
TPA	EQU	100H
	ENDIF

	IF	NOT RMAC
FCB	EQU	BASE+5CH
BDOS	EQU	BASE+5
	ENDIF

FILL	MACRO	BYTES,WITH
	REPT	BYTES
	DB	WITH
	ENDM
	ENDM

$-MACRO

	PAGE	60
	TITLE	'SD Version 4.2 - 25 Oct 1981'

*********************************
*				*
* BEGIN	EXECUTABLE PROGRAM CODE	*
*				*
*********************************

	IF	NOT RMAC
	ORG	TPA
	ENDIF

	JMP	START

	DB	' SD 4.2 - 10/25/81 '

START:	LXI	H,0
	DAD	SP		;HL=old	stack
	SHLD	STACK		;Save it
	LXI	SP,STACK	;Get new stack

	MVI	C,12		;Get and save the CP/M version #
	CALL	BDOS
	MOV	A,L
	STA	VERFLG
	CPI	20H		;Set carry if CP/M 1.4

	MVI	E,0FFH		;Get current user number if using CP/M 2, or
	MVI	C,CURUSR	;Fall through with A=0 if not
	CNC	CPM

	STA	OLDUSR		;Initialize startup user number
	STA	NEWUSR		;..and make new	user match it

	IF	DOPT
	STA	BASUSR		;Save extra copy for multi-disk	directories
	CALL	SWAPEM		;Swap BDOS error vector	tables
	ENDIF

	MVI	C,CURDSK
	CALL	CPM		;Get current disk nr
	STA	OLDDSK		;Save for reset	if needed

	IF	FOPT
	INR	A
	STA	OUTFCB		;Set directory output file drive
	ENDIF

	LXI	H,FCB
	MOV	A,M		;Get drive name	for directory search
	ORA	A		;Any specified?
	JNZ	START2		;Yes skip next routine
	LDA	OLDDSK		;Otherwise, get	default	disk
	INR	A
START2:	MOV	M,A		;Put the absolute drive	code in	directory FCB

* If at	least one option is allowed, scan the command line for the
* option field delimiter.  The option field delimiter is considered
* valid	only if	it is preceded by at least 1 space (otherwise, it
* may be part of the directory filename).  Any unrecognized options
* or illegal user numbers will be flagged or ignored (see REPERR).
* (We scan the command line buffer rather than the 2nd default FCB
* because all 8	options	plus a 2 digit user number won't fit in
* the FCB name field).

	IF	OPTION
	LXI	H,80H		;Set command line buffer pointer
	MOV	B,M		;Get length of command line buffer

* Search for the command line delimiter.  If not found, assume no options.

SCNDOL:	INX	H
	DCR	B
	JM	CKREST		;Exit if command line buffer empty
	MOV	A,M
	CPI	'$'
	JNZ	SCNDOL
	DCX	H		;'$' found - make sure space precedes it
	MOV	A,M
	INX	H
	CPI	' '
	JNZ	SCNDOL		;No space - ignore "$" and search again

* Valid	delimiter found.  Scan the rest	of the buffer for options.  Errors
* past this point will cause an	abort if the command line error	option is
* enabled.  Otherwise, the dud option will be ignored and SD will attempt
* to continue stumbling	through	the rest of the	field.

	XCHG			;Get option field pointer to DE
SCNOPT:	INX	D		;Bump to next option field character
	DCR	B		;Dock characters left in option	field
	JM	CKREST		;If option field exhausted, exit
SCNAGN:	LDAX	D		;Get the next option character
	CPI	' '		;Do we have a space?
	JZ	SCNOPT		;Ignore	it if so
	LXI	H,OTBL-1	;Get base of option lookup table
	MVI	C,OEND-OTBL+1	;Get length of option lookup table
NOMACH:	INX	H		;Bump to next option table character
	DCR	C		;Are we	out of the table?
	JZ	CK4USR		;If so, check for user option
	CMP	M		;Compare our character with option table
	JNZ	NOMACH		;Exit if no match
	MVI	M,0		;Otherwise, activate the flag
	JMP	SCNOPT		;..and go get the next option character

* If option character doesn't match the table, see if we have a User
* option.

CK4USR:	IF	UOPT		;Check for user	number option
	CPI	'U'
	JNZ	CLERR		;Last option, so bad deal if that ain't it

UAGN:	INX	D		;Bump to user number digit
	DCR	B
	JM	CLERR		;Error if nothing left
	LDAX	D		;Get decimal digit
	CPI	' '		;Ignore	leading	spaces
	JZ	UAGN
	SUI	30H		;Subtract ASCII	BIAS
	JC	CLERR		;Error if < 0
	CPI	10
	JNC	CLERR		;Error if > 9
	STA	NEWUSR		;Save user number as it	may be only 1 digit

	IF	DOPT
	STA	BASUSR		;Duplicate it if multi-disk mode
	ENDIF

	INX	D		;Bump to possible 2nd digit of user number
	DCR	B
	JM	CKREST		;If no more buffer, exit with complete user #
	LDAX	D		;Else, check for another digit
	SUI	30H
	JC	SCNAGN		;If next char not numeric, its not part	of
	CPI	10		;..user	number so go check for another option
	JNC	SCNAGN
	MOV	L,A		;Save units digit
	LDA	NEWUSR		;Get tens digit
	ADD	A		;Multiply by 10
	MOV	H,A
	ADD	A
	ADD	A
	ADD	H
	ADD	L		;Combine with units digit
	STA	NEWUSR		;Save the total	user number

	IF	DOPT
	STA	BASUSR		;Duplicate it if multi-disk mode
	ENDIF

	JMP	SCNOPT		;Continue scanning
	ENDIF			;Balance UOPT

* If command line error	option enabled,	playback the command line up
* to the character that	we gagged on and exit.	If REPERR is not enabled,
* then continue	as if nothing were amiss to avoid acknowledging	that
* some options are available.

CLERR:	IF	REPERR
	XRA	A
	INX	D		;Tag end of command line with terminator
	STAX	D
	CALL	CRLF
	LXI	D,ERRMS2
	CALL	PRINT
	LXI	D,ERRTAG
	CALL	PRINT
	LXI	H,81H		;Playback bad command line to error point
CLELP:	MOV	A,M
	ORA	A
	JZ	CLEX
	CALL	TYPE
	INX	H
	JMP	CLELP

CLEX:	MVI	A,'?'		;Tag line with a '?' field
	CALL	TYPE
	CALL	CRLF		;Space down 1 more line
	JMP	EXIT		;..and return to CP/M
	ELSE

	JMP	SCNOPT		;If not	reporting errors, ignore the dud

	ENDIF			;Balance REPERR
	ENDIF			;Balance OPTION

* Options input or not specified.  If reset option specified, reset
* the disk system now.	Its important that the reset be done OUTSIDE
* the multiple drive loop if the file output option is enabled because
* CP/M 1.4 clobbers the DMA buffer on reset.

CKREST: IF	ROPT
	LDA	ROPFLG		;If reset flag set, reset disk system before
	ORA	A		;..starting to update allocation vectors
	MVI	C,RESET
	CZ	CPM
	ENDIF			;Balance ROPT

* Validate drive code and user area numbers from the drive table.

NOOPT:	LXI	D,DREMSG	;Get the drive/user error message
	PUSH	D
	LDA	FCB		;Get directory drive code
	DCR	A		;Normalize to range of 0-15
	CPI	HIDRV-LODRV	;Compare with maximum drives on-line
	JNC	ERXIT		;Take drive error exit if out of range
	LXI	H,USRMSG	;Switch	to user	# error	message
	XTHL
	MOV	E,A		;Use drive code	as index into table
	MVI	D,0
	LXI	H,LODRV		;Point to base of drive/user table
	DAD	D
	MOV	A,M		;Get the maximum user #	for this drive
	ANI	0FH		;Make sure its in range	0 - 15
	STA	MAXUSR		;Save it for later
	LXI	H,NEWUSR	;Point to the directory	user area
	CMP	M		;Compare it with the maximum
	JC	ERXIT		;Take error exit if user number	illegal
	POP	D		;Destroy error message pointer

	LXI	H,FCB+1 	;Point to name
	MOV	A,M		;Any specified?
	CPI	' '
	JNZ	GOTFCB

* No FCB - make	FCB all	'?'

	MVI	B,11		;FN+FT count

QLOOP:	MVI	M,'?'		;Store '?' IN FCB
	INX	H
	DCR	B
	JNZ	QLOOP

GOTFCB:	MVI	A,'?'		;Force wild extent
	STA	FCB+12
	CALL	SETSRC		;Set DMA for BDOS media change check
	LXI	H,FCB		;Point to FCB drive code for directory
	MOV	E,M		;Get the drive code out of the FCB
	DCR	E		;Normalize drive code for SELECT
	MVI	C,SELDSK	;Select the directory drive to retrieve
	CALL	CPM		;..the proper allocation vector
	CALL	CKVER		;Check version
	JC	V14		;Pre-2.X...get params the 1.4 way

	MVI	C,CURDPB	;It's 2.X or MP/M...request DPB
	CALL	BDOS
	INX	H
	INX	H
	MOV	A,M		;Get block shift
	STA	BLKSHF
	INX	H		;Bump to block mask
	MOV	A,M
	STA	BLKMSK		;Get it
	INX	H
	INX	H
	MOV	E,M		;Get max block #
	INX	H
	MOV	D,M
	XCHG
	SHLD	BLKMAX		;Save it
	XCHG
	INX	H
	MOV	E,M		;Get directory size
	INX	H
	MOV	D,M
	XCHG
	JMP	FREE		;Let FREE save it and setup order table

V14:	LHLD	BDOS+1		;Get params 1.4 style
	MVI	L,3BH		;Point to directory size
	MOV	E,M		;Get it
	MVI	D,0		;Force high order to 0
	PUSH	D		;Save for later
	INX	H		;Point to block	shift
	MOV	A,M		;Fetch
	STA	BLKSHF		;Save
	INX	H		;Point to block	mask
	MOV	A,M		;Fetch it
	STA	BLKMSK		;And save it
	INX	H
	MOV	E,M		;Get max. block	no.
	MVI	D,0
	XCHG
	SHLD	BLKMAX		;Save it
	POP	H		;Restore directory size

* Calculate # of K free	on selected drive now so that the FREE figure
* will not reflect either the creation or additions to the SD.DIR
* file (which we would probably	erase or move anyway).

FREE:	SHLD	DIRMAX		;Save max # of entries in directory
	MVI	C,GALLOC	;Get address of	allocation vector
	CALL	BDOS
	XCHG
	LHLD	BLKMAX		;Get its length
	INX	H
	LXI	B,0		;Init block count to 0

GSPBYT:	PUSH	D		;Save alloc address
	LDAX	D
	MVI	E,8		;Set to	process	8 blocks

GSPLUP:	RAL			;Test bit
	JC	NOTFRE
	INX	B

NOTFRE:	MOV	D,A		;Save bits
	DCX	H		;Count down blocks
	MOV	A,L
	ORA	H
	JZ	ENDALC		;Quit if out of	blocks
	MOV	A,D		;Restore bits
	DCR	E		;Count down 8 bits
	JNZ	GSPLUP		;Do another bit
	POP	D		;Bump to next byte..
	INX	D		;..of alloc. vector
	JMP	GSPBYT		;Process it

ENDALC:	POP	D		;Clear allocation vector pointer from stack
	MOV	L,C		;Copy blocks to	hl
	MOV	H,B
	LDA	BLKSHF		;Get block shift factor
	SUI	3		;Convert from sectors to K
	JZ	SAVFRE		;Skip shifts if 1K blocks - return free in HL

FREKLP: DAD	H		;Multiply blocks by K/BLK
	DCR	A
	JNZ	FREKLP
SAVFRE: SHLD	FREEBY		;Save the free space for output later

* Reenter here on subsequent passes while in the all-users mode

SETTBL:	LHLD	DIRMAX		;Get directory maximum again
	INX	H		;Directory size	is DIRMAX+1
	DAD	H		;Double	directory size
	LXI	D,ORDER		;To get	size of	order table
	DAD	D		;Allocate order	table
	SHLD	TBLOC		;Name table begins where order table ends
	SHLD	NEXTT
	XCHG
	LHLD	BDOS+1		;Make sure we have room	to continue
	MOV	A,E
	SUB	L
	MOV	A,D
	SBB	H
	JNC	OUTMEM

	IF	UOPT
	CALL	CKVER		;Set carry if pre-CP/M 2
	LDA	NEWUSR		;Get user area for directory
	MOV	E,A
	MVI	C,CURUSR	;Get the user function
	CNC	CPM		;..and set new user number if CP/M 2
	ENDIF

* Look up the FCB in the directory

SFIRST:	LXI	H,0
	SHLD	COUNT		;Initialize match counter
	SHLD	TOTFIL		;     "	    total file counter
	SHLD	TOTSIZ		;     "	    total size counter
	CALL	SETSRC		;Set DMA for directory search
	MVI	C,SEARCH	;Get 'search first' function
	JMP	LOOK		;..and go search for 1st match

* Read more directory entries

MORDIR:	MVI	C,NEXT		;Search	next
LOOK:	LXI	D,FCB
	CALL	CPM		;Read directory	entry
	INR	A		;Check for end (0FFH)
	JZ	SPRINT		;If no more, sort & print what we have

* Point	to directory entry

SOME:	DCR	A		;Undo prev 'INR A'
	ANI	3		;Make modulus 4
	ADD	A		;Multiply...
	ADD	A		;..by 32 because
	ADD	A		;..each	directory
	ADD	A		;..entry is 32
	ADD	A		;..bytes long
	LXI	H,BASE+81H	;Point to buffer
				;(skip to FN/FT)
	ADD	L		;Point to entry
	ADI	9		;Point to SYS byte
	MOV	L,A		;Save (can't carry to H)

	IF	SOPT
	LDA	SOPFLG		;Did user request SYS files?
	ORA	A
	JZ	SYSFOK
	ENDIF

	MOV	A,M		;Get SYS byte
	ORA	A		;Check bit 7
	JM	MORDIR		;Skip that file

SYSFOK:	MOV	A,L		;Go back now
	SUI	10		;Back to user number (alloc flag)
	MOV	L,A		;HL points to entry now

	LDA	NEWUSR		;Get current user
	CMP	M
	JNZ	MORDIR		;Ignore	if different
	INX	H

* Move entry to	table

	XCHG			;Entry to DE
	LHLD	NEXTT		;Next table entry to HL
	MVI	B,12		;Entry length (name, type, extent)

TMOVE:	LDAX	D		;Get entry char

	IF	NOT (VECTOR OR REVIDEO)
	ANI	7FH		;Remove	attributes
	ENDIF

	MOV	M,A		;Store in table
	INX	D
	INX	H
	DCR	B		;More?
	JNZ	TMOVE
	INX	D
	INX	D		;Point to sector count
	LDAX	D		;Get it
	MOV	M,A		;Store in table
	INX	H
	SHLD	NEXTT		;Save updated table addr
	XCHG
	LHLD	COUNT		;Bump the # of matches made
	INX	H
	SHLD	COUNT
	LXI	H,13		;Size of next entry
	DAD	D
	XCHG			;Future	NEXTT is in DE
	LHLD	BDOS+1		;Pick up TPA end
	MOV	A,E
	SUB	L		;Compare NEXTT-TPA end
	MOV	A,D
	SBB	H
	JC	MORDIR		;If TPA	END > NEXTT then loop back for more

OUTMEM:	CALL	ERXIT		;Exit if directory too large
	DB	'MEMOR','Y' OR 80H

* Sort and print

SPRINT: IF	AOPT OR FOPT OR UOPT
	CALL	SETFOP		;Return to file output DMA & user #
	ENDIF

	LHLD	COUNT		;Get file name count
	MOV	A,L
	ORA	H		;Any found?
	JZ	PRTOTL		;Exit if no files found
	PUSH	H		;Save file count
	STA	SUPSPC		;Enable	leading	zero suppression

* Initialize the order table

	LHLD	TBLOC		;Get start of name table
	XCHG			;Into DE
	LXI	H,ORDER		;Point to order	table
	LXI	B,13		;Entry length

BLDORD:	MOV	M,E		;Save low order	address
	INX	H
	MOV	M,D		;Save high order address
	INX	H
	XCHG			;Table addr to HL
	DAD	B		;Point to next entry
	XCHG
	XTHL			;Save tbl addr,	fetch loop counter
	DCX	H		;Count down loop
	MOV	A,L
	ORA	H		;More?
	XTHL			;(restore tbl addr, save counter)
	JNZ	BLDORD		;Yes, go do another one
	POP	H		;Clean loop counter off	stack
	LHLD	COUNT		;Get count
	SHLD	SCOUNT		;Save as # to sort
	DCX	H		;Only 1	entry?
	MOV	A,L
	ORA	H
	JZ	DONE		;Yes, so skip sort

* This sort routine is adapted from SOFTWARE TOOLS
* by Kernigan and Plaugher.

SORT:	LHLD	SCOUNT		;Number	of entries

L0:	ORA	A		;Clear carry
	MOV	A,H		;GAP=GAP/2
	RAR
	MOV	H,A
	MOV	A,L
	RAR
	MOV	L,A
	ORA	H		;Is it zero?
	JZ	DONE		;Then none left
	MOV	A,L		;Make gap odd
	ORI	01
	MOV	L,A
	SHLD	GAP
	INX	H		;I=GAP+1

L2:	SHLD	I
	XCHG
	LHLD	GAP
	MOV	A,E		;J=I-GAP
	SUB	L
	MOV	L,A
	MOV	A,D
	SBB	H
	MOV	H,A

L3:	SHLD	J
	XCHG
	LHLD	GAP		;JG=J+GAP
	DAD	D
	SHLD	JG
	MVI	A,12		;Compare 12 chars
	CALL	COMPARE		;Compare (J) and (JG)
	JP	L5		;If A(J)<=A(JG)
	LHLD	J
	XCHG
	LHLD	JG
	CALL	SWAP		;Exchange A(J) and A(JG)
	LHLD	J		;J=J-GAP
	XCHG
	LHLD	GAP
	MOV	A,E
	SUB	L
	MOV	L,A
	MOV	A,D
	SBB	H
	MOV	H,A
	JM	L5		;If J>0	GOTO L3
	ORA	L		;Check for zero
	JZ	L5
	JMP	L3

L5:	LHLD	SCOUNT		;For later
	XCHG
	LHLD	I		;I=I+1
	INX	H
	MOV	A,E		;IF I<=N GOTO L2
	SUB	L
	MOV	A,D
	SBB	H
	JP	L2
	LHLD	GAP
	JMP	L0

* Sort is all done - print entries

DONE:	IF	FOPT		;If output option wanted, prepare file
	LDA	FOPFLG
	ORA	A
	JNZ	NOOUT		;If file output, fall through with A=0

* IF ALL USER OPTION ENABLED, AND WE'RE NOT ON THE FIRST PASS, THEN THE
* OUTPUT FILE IS ALREADY OPEN AND POSITIONED, SO WE CAN SKIP THE OPEN.

;	IF	AOPT
	lxi	h,opnflg	;point to output file open flag
	cmp	m		;a=0, set z if opnflg=0 also
	jnz	noout		;if opnflg not zero, skip open
	dcr	m		;else, make opnflg not zero and open
;	ENDIF			;Balance AOPT

* First pass on file append - prepare SD.DIR to receive new or appended
* output.

	LXI	D,OUTFCB	;Does output file already exist?
	MVI	C,SEARCH
	CALL	CPM
	INR	A
	JNZ	OPENIT		;If it does, then open it for processing
	MVI	C,MAKE		;Otherwise, create the output file
	CALL	CPM
	INR	A
	JNZ	NOOUT		;Continue if open successful

* If make or open fails, declare error

OPNERR:	CALL	ERXIT
	DB	'OPE','N' OR 80H

WRTERR:	CALL	ERXIT
	DB	'WRIT','E' OR 80H

* Output file already exists - open it and position to the last
* record of the	last extent.

OPENIT: MVI	C,OPEN		;Open 1st extent of output file
	CALL	CPM
	INR	A
	JZ	OPNERR		;Bad deal if 1st won't open

OPNMOR:	LDA	OUTFCB+15
	CPI	128
	JC	LSTEXT		;If RC<128, this is last extent
	LXI	H,OUTFCB+12
	INR	M		;Else, bump to next extent
	MVI	C,OPEN		;..and try to open it
	CALL	CPM
	INR	A
	JNZ	OPNMOR		;Continue opening extents til no more
	DCR	M		;Then, reopen preceding	extent
	MVI	C,OPEN
	CALL	CPM
	LDA	OUTFCB+15	;Get RC	for the	last extent

* At this point, OUTFCB is opened to the last extent of the file,
* so read in the last record in the last extent.

LSTEXT:	ORA	A		;Is this extent	empty?
	JZ	NOOUT		;If so, then we're starting a clean slate
	DCR	A		;Normalize record count
	STA	OUTFCB+32	;Set record number to read
	MVI	C,READ		;..and read last record	of file
	CALL	CPM
	ORA	A		;Was read successful?
	JZ	RDOK		;If so,	proceed	to scan	for EOF	mark
APERR:	CALL	ERXIT
	DB	'APPEN','D' OR 80H

* We now have the last record in the file in our buffer.
* Scan the last	record for the EOF mark, indicating where
* we can start adding data.

RDOK:	LXI	H,OUTBUF	;Point to start of output buffer
	MVI	B,128		;Get length of output buffer
SCAN:	MOV	A,M
	CPI	'Z'-40H		;Have we found end of file?
	JZ	RESCR		;If so, save pointers and reset CR
	INX	H
	DCR	B
	JNZ	SCAN		;Otherwise, keep looking til end of buffer

* If we find an explicit EOF mark in the last buffer (or an implied EOF
* if the last record is full), move the FCB record and extent pointers
* back to correct for the read operation so that our first write operation
* will effectively replace the last record of the SD.DIR file.

RESCR:	PUSH	H		;Save EOF buffer pointer
	PUSH	B		;Save EOF buffer remaining
	LXI	H,OUTFCB+32	;Get current record again
	DCR	M		;Dock it
	JP	SAMEXT		;If CR >=0, we're still in same extent
	LXI	H,OUTFCB+12	;Else, move to previous	extent
	DCR	M
	MVI	C,OPEN		;Then, reopen the previous extent
	CALL	CPM
	INR	A
	JZ	APERR		;Append position error if we can't reopen
	LDA	OUTFCB+15	;Else, position to last record of extent
	DCR	A
	STA	OUTFCB+32
SAMEXT: POP	PSW		;Recall where EOF is in buffer
	STA	BUFCNT		;..and set buffer counter
	POP	H		;Recall next buffer pointer
	SHLD	BUFPNT		;.. and set pointer for first addition

	ENDIF			;Balance FOPT

NOOUT:	LXI	H,ORDER		;Initialize order table	pointer
	SHLD	NEXTT
	JMP	NEWLIN		;Start new line	and output the files

* Output the directory files we've matched.

ENTRY:	LHLD	COUNT
	DCX	H		;Dock file count
	SHLD	COUNT
	MOV	A,H		;Is this the last file?
	ORA	L
	JZ	OKPRNT		;If COUNT=0, last file so skip compare

* Compare each entry to	make sure that it isn't part of a multiple
* extent file.	Go only	when we	have the last extent of	the file.

	PUSH	B		;Save NPL
	CALL	CKABRT		;Check for abort code from keyboard
	LHLD	NEXTT
	MVI	A,11
	CALL	COMPR		;Does this entry match next one?
	POP	B		;Recall	NPL
	JNZ	OKPRNT		;No, print it
	INX	H
	INX	H		;Skip since highest extent comes last in list
	SHLD	NEXTT
	JMP	ENTRY		;Loop back for next lowest extent

* Valid	entry obtained - spit it out.

OKPRNT:	LHLD	NEXTT		;Get order table pointer
	MOV	E,M		;Get low order address
	INX	H
	MOV	D,M		;Get high order	address
	INX	H
	SHLD	NEXTT		;Save updated table pointer
	XCHG			;Table entry to	HL

	MVI	B,8		;File name length
	CALL	TYPEIT		;Type filename

	MVI	A,'.'		;Period	after FN
	CALL	TYPE

	MVI	B,3		;Display 3 characters of filetype
	CALL	TYPEIT

* Compute the size of the file and update our summary datum.

	MOV	E,M		;Get extent #
	MVI	D,0
	INX	H
	MOV	A,M		;Get sector count of last extent
	XCHG
	DAD	H		;# of extents times 16k
	DAD	H
	DAD	H
	DAD	H
	XCHG			;Save in DE
	LXI	H,BLKMSK
	ADD	M		;Round last extent to block size
	RRC
	RRC			;Convert from sectors to K
	RRC
	ANI	1FH
	MOV	L,A		;Add to	total K
	MVI	H,0
	DAD	D
	LDA	BLKMSK		;Get SECTORS/BLK-1
	RRC
	RRC			;Convert to K/BLK
	RRC
	ANI	1FH
	CMA			;Use to	finish rounding
	ANA	L
	MOV	L,A
	XCHG			;Save file size	in DE
	LHLD	TOTSIZ
	DAD	D		;Add to	total used
	SHLD	TOTSIZ
	LHLD	TOTFIL		;Increment file	count
	INX	H
	SHLD	TOTFIL
	XCHG			;Get back file size

* If report size enabled, output the size of the individual file.

	IF	REPSIZ		;If file size report wanted
	CALL	DECPRT		;..go print it
	MVI	A,'k'		;..and follow with K size
	CALL	TYPE
	ENDIF

* One file output - test to see	if we have to output another one.

	LHLD	COUNT		;Get current file counter and test it
	MOV	A,H
	ORA	L
	JZ	PRTOTL		;If no more files, exit	to summary output

* At least one more file to output - can we put	it on the current line?

	DCR	C
	PUSH	PSW
	CNZ	FENCE		;If room left, output the fence	character
	POP	PSW
	JNZ	ENTRY		;.. and	go output another file

* Current line full, start a new one.

NEWLIN:	MVI	C,NPL		;Reset names per line counter
	CALL	CRLF		;Space down to next line

	IF	NPL LT 4	;If printing less than 4 wide ..
	LDA	FCB		;.. precede new	line with drive	name
	ADI	'A'-1
	CALL	TYPE

	IF	REPUSR		;If reporting user numbers and running under
	CALL	CKVER		;..CP/M	2, output the user number too
	CNC	TYPUSR
	ENDIF			;Balance REPUSR

	MVI	A,':'		;Tag header with a colon and a space
	CALL	FPAD		;..and exit back to ENTRY

	ENDIF			;Balance NPL GT	3

	JMP	ENTRY		;Go back and output another file

* Print	HL in decimal with leading zero	suppression

DECPRT:	SUB	A		;Clear leading zero flag
	STA	LZFLG
	LXI	D,-1000		;Print 1000's digit
	CALL	DIGIT
	LXI	D,-100		;Etc.
	CALL	DIGIT
	LXI	D,-10
	CALL	DIGIT
	MVI	A,'0'		;Get 1's digit
	ADD	L
	JMP	TYPE

DIGIT:	MVI	B,'0'		;Start off with	ASCII 0

DIGLP:	PUSH	H		;Save current remainder
	DAD	D		;Subtract
	JNC	DIGEX		;Quit on overflow
	POP	PSW		;Throw away remainder
	INR	B		;Bump digit
	JMP	DIGLP		;Loop back

DIGEX:	POP	H		;Restore pointer
	MOV	A,B
	CPI	'0'		;Zero digit?
	JNZ	DIGNZ		;No, type it
	LDA	LZFLG		;Leading zero?
	ORA	A
	MVI	A,'0'
	JNZ	TYPE		;Print digit
	LDA	SUPSPC		;Get space suppression flag
	ORA	A		;See if	printing file totals
	RZ			;Yes, don't give leading spaces
	JMP	SPACE		;Leading zero...print space

DIGNZ:	STA	LZFLG		;Set leading zero flag so next zero prints
	JMP	TYPE		;And print digit

* Show total space and files used

PRTOTL:	XRA	A		;Get a zero to...
	STA	SUPSPC		;Suppress leading spaces in totals

	LHLD	TOTFIL		;How many files	did we match?
	MOV	A,H
	ORA	L

	JZ	NXTUSR		;Skip the summary if we	didn't find any

	PUSH	H		;Save TOTFIL
	STA	FNDFLG		;Set file found flag

	LXI	D,TOTMS1	;Print [CR,LF,LF]"DRIVE	"
	CALL	PRINT
	LDA	FCB
	ADI	'A'-1
	CALL	TYPE		;Output	the drive code

	IF	REPUSR
	CALL	CKVER
	JC	NOUSER
	LXI	D,TOTMS2	;Print ", USER "
	CALL	PRINT
	CALL	TYPUSR		;Output	the user number
	ENDIF

NOUSER:	LXI	D,TOTMS3	;Print " CONTAINS "
	CALL	PRINT
	LHLD	TOTSIZ		;Print total K used by files matched
	CALL	DECPRT
	LXI	D,TOTMS4	;PRINT "K IN "
	CALL	PRINT
	POP	H		;Recall	TOTFIL
	CALL	DECPRT		;Print number of files matched
	LXI	D,TOTMS5	;Print " FILES WITH "
	CALL	PRINT
	CALL	PRTFRE		;Output	free space remaining & " FREE."

* Directory for	one user area completed.  If all users option is
* selected, then go do another directory on the	next user number
* until	we exceed the maximum user # for the selected drive.

NXTUSR:	IF	AOPT		;If all	users option enabled
	LDA	AOPFLG		;If not	all users mode - skip next
	ORA	A
	JNZ	GOCLZ
	CALL	CKVER		;Are we running CP/M 2?
	JC	GOCLZ		;Skip user increment if not
	CALL	CKABRT		;Check for user	abort first
	LDA	MAXUSR		;No abort - get	maximum	user number
	LXI	H,NEWUSR	;Bump directory	user number
	INR	M
	CMP	M		;Does next user	# exceed maximum?
	JNC	SETTBL		;Continue if more user areas to	go

	IF	DOPT		;If multi-disk option enabled
	LDA	BASUSR		;Reset base user number	for the
	MOV	M,A		;..next	directory search
	ENDIF			;Balance DOPT

	ENDIF			;Balance AOPT

* We've finished all of our outputting.  Flush the remainder of the
* output buffer and close the file before going to exit routine.

GOCLZ:	IF	FOPT
;	LDA	FOPFLG		;Is file output mode active?
;	ORA	A
;	JNZ	NXTDSK		;If not, move to next drive, otherwise ..
;	STA	PASS1		;Make PASS1=0 to force reopen on next drive

	lxi	h,opnflg	;get file open status then reset flag to
	mov	a,m		;..force reopen on next pass
	mvi	m,0
	ora	a
	jz	nxtdsk		;skip closing sd.dir if it wasn't opened

	LXI	H,BUFCNT
	MOV	A,M		;RETRIEVE # OF UNFLUSHED CHARACTERS IN BUFFER
	MVI	M,128		;FORCE BUFCNT TO EMPTY STATUS FOR NEXT DRIVE
	ORA	A		;IF BUFCNT=128, BUFFER EMPTY SO SET SIGN BIT
	jm	cloze		;close sd.dir if buffer is empty
	jz	flush		;write last record to sd.dir if buffer full

	LHLD	BUFPNT		;OTHERWISE, PAD UNUSED BUFFER WITH CTRL-ZS
PUTAGN:	MVI	M,'Z'-40H
	INX	H
	DCR	A
	JNZ	PUTAGN		;CONTINUE PADDING TIL BUFFER FILLED OUT
;	MVI	A,128
;	STA	BUFCNT		;Force buffer to empty status

FLUSH:	LXI	D,OUTFCB	;FLUSH THE LAST OUTPUT BUFFER
	MVI	C,WRITE
	CALL	CPM
	ORA	A
	JNZ	WRTERR
CLOZE:	LXI	D,OUTFCB	;CLOSE THE OUTPUT FILE
	MVI	C,CLOSE
	CALL	CPM
	ENDIF			;BALANCE FOPT

* Directory for	all user areas completed.  If the multi-disk option
* is enabled and selected, reset to the	base user area and repeat
* the directory	for next drive on-line until we	either exceed the
* drives in our	LODRV-HIDRV table, or the BDOS shuts us	down with
* a select or bad sector error,	which will be intercepted back to
* the EXIT module.

NXTDSK: LXI	H,FNDFLG	;Get file found flag
	MOV	A,M
	MVI	M,0		;Clear file found flag for next drive
	ORA	A
	JNZ	NDSK		;Continue if at least 1 file found

	IF	FOPT		;If file output enabled, disable temporarily
	LXI	H,FOPFLG
	DCR	M
	PUSH	H
	ENDIF

	LDA	FCB		;Stash ASCII directory drive in NO FILE msg
	ADI	'A'-1
	STA	NOFMS2
	LXI	D,NOFMS1	;Print "NO FILE ON ? - "
	CALL	PRINT
	CALL	PRTFRE		;Tag with free message

	IF	FOPT		;Restore original file output mode
	POP	H
	INR	M
	ENDIF

NDSK:	IF	DOPT		;If multi-disk option enabled
	LDA	DOPFLG		;If multi-disk not selected - skip next
	ORA	A
	JNZ	EXIT
	CALL	CKABRT		;Check for user	abort first
	MVI	A,HIDRV-LODRV	;Get maximum drive code	to search
	LXI	H,FCB		;Bump directory	FCB drive code
	INR	M
	CMP	M		;Does next disk	exceed maximum?
	JNC	NOOPT		;Search	next disk if not
	ENDIF			;Balance DOPT

	JMP	EXIT		;All done - exit to CCP

* Print	the user number	of the directory in decimal

TYPUSR:	IF	REPUSR
	LDA	NEWUSR
	CPI	10		;If user no. > 9 print leading 1
	JC	DUX
	MVI	A,'1'
	CALL	TYPE
	LDA	NEWUSR		;Print low digit of user no.
	SUI	10
DUX:	ADI	'0'
	JMP	TYPE
	ENDIF

* Force	new line on video and check for	page pause

CRLF:	MVI	A,0DH		;Send CR
	CALL	TYPE
	MVI	A,0AH		;Send LF
	JMP	TYPE		;Exit to caller	from TYPE

* Separate the directory output	on a line with a space,	the delimiter,
* followed by another space.

FENCE:	CALL	SPACE

	MVI	A,DELIM		;Fence character
FPAD:	CALL	TYPE		;Print it, fall	into space

SPACE:	MVI	A,' '		;Fall through to TYPE

* Output character in A to console, and optionally to printer and/or
* the output file.

TYPE:	PUSH	B
	PUSH	D
	PUSH	H

	IF	FOPT OR	POPT OR	PGPAWZ OR REVIDEO
	PUSH	PSW		;Save the character to output
	ENDIF
	CALL	TYPE1		;Send it to console
	IF	FOPT OR	POPT OR	PGPAWZ OR REVIDEO
	POP	PSW		;Restore the output character
	ENDIF

	IF	VECTOR AND (FOPT OR PGPAWZ OR REVIDEO)
	ANI	7FH		;Strip parity bit on character
	ENDIF

* Test file output mode and skip to page pause test if not active.

	IF	FOPT
	MOV	B,A		;Save stripped character to B
	LDA	FOPFLG		;Is file output	active?
	ORA	A
	JNZ	NOWRIT		;Go check for page pause if not

* File output mode active - make sure we have room in buffer to add
* next character.  If buffer full, write out current record first
* and then start a new record with current character.

	LHLD	BUFPNT		;Get current buffer pointer
	LDA	BUFCNT		;Get buffer capacity remaining
	ORA	A
	JNZ	PUTBUF		;Continue if buffer not full
	LXI	D,OUTFCB	;Otherwise, write the current buffer out
	MVI	C,WRITE
	CALL	CPM		;(Note call must save character	in B)
	ORA	A
	JNZ	WRTERR		;Take write error exit if disk full or R/O
	LXI	H,OUTBUF	;Reset buffer pointer
	MVI	A,128		;Reset buffer capacity

PUTBUF: MOV	M,B		;Shove character to next buffer position
	INX	H		;Bump buffer pointer
	SHLD	BUFPNT		;.. and save it
	DCR	A		;Dock count of characters left in buffer
	STA	BUFCNT		;..and save it

NOWRIT:	MOV	A,B		;Recall	stripped character

	ENDIF			;Balance FOPT

	IF	POPT		;If printer option
	MOV	E,A		;Setup list output call
	MVI	C,5
	LDA	POPFLG		;Test printer flag
	ORA	A
	CZ	CPM		;Print character if flag true
	MOV	A,E		;Recall	character
	ENDIF

	IF	PGPAWZ
	CPI	0AH		;Do we have a LF?
	JNZ	TYPRET		;Exit if not
	ENDIF

	IF	NOPT AND PGPAWZ
	LDA	NOPFLG		;Is the	page pause function disabled?
	ORA	A
	JZ	TYPRET		;Exit if so
	ENDIF

	IF	PGPAWZ
	LDA	LINCNT		;Get line count
	INR	A		;Bump it
	CPI	LPS		;Are we	at the end of the screen?
	JC	NOTEOS		;Skip if not
	LXI	D,EOSMSG	;Else, display pause message
	MVI	C,9		;..without checking for	LFs
	CALL	BDOS
	CALL	CINPUT		;Wait for character
	CPI	'C'-40H
	JZ	EXIT		;Abort on CTRL-C
	XRA	A		;Reset line count
NOTEOS:	STA	LINCNT		;Save new line count
	ENDIF

TYPRET:	POP	H		;Exit from TYPE
	POP	D
	POP	B
	RET

* Output character directly through the	BIOS

TYPE1:	IF	VECTOR
	ORA	A		;Set sign flag if MS bit is on
	JP	TYPE2		;If character is ASCII,	continue
	MOV	B,A		;Else, get character to	B
	MVI	A,5		;Set video driver function for direct output
	JMP	VIDEO		;Display in reverse video and exit from	VIDEO
	ENDIF

	IF	DIRCON
TYPE2:	MOV	C,A		;Get character into BIOS entry register
	LHLD	BASE+1		;Get page base of BIOS
	MVI	L,12		;Get entry vector to CONOUT
	JMP	GOHL		;Call CONOUT direct through the BIOS
	ELSE

	IF	REVIDEO
TYPE2:	ORA	A
	JP	TYPE99
	PUSH	PSW
	MVI	A,033Q		;send ESC -char perhaps?
	CALL	TYPE99
	MVI	A,INTOREV
	CALL	TYPE99		;send reverse video character
	POP	PSW
	ANI	7FH
	CALL	TYPE99
	MVI	A,033Q		;ESC sequence getting outta reverse?
	CALL	TYPE99
	MVI	A,OUTAREV
	CALL	TYPE99		;send normal video character
	RET
	ELSE
TYPE2:	MOV	E,A		;Get character into BDOS entry register
	MVI	C,WRCHR
	JMP	BDOS		;Call CONOUT via the BDOS
	ENDIF			;Balance REVIDEO
	ENDIF			;Balance DIRCON

	IF	REVIDEO
TYPE99:	MOV	E,A		;Get character into BDOS entry register
	MVI	C,WRCHR
	JMP	BDOS		;Call CONOUT via the BDOS
	ENDIF			;REVIDEO

* Print	a string at HL of length B

TYPEIT:	MOV	A,M
	CALL	TYPE
	INX	H
	DCR	B
	JNZ	TYPEIT
	RET

* Print	string terminated with last byte high on console.

PRINT:	LDAX	D
	PUSH	PSW
	ANI	7FH
	CALL	TYPE
	POP	PSW
	ORA	A
	RM
	INX	D
	JMP	PRINT

* Fetch	character from console (without	echo)

CINPUT:	LHLD	BASE+1
	MVI	L,9
	CALL	GOHL
	ANI	7FH
	RET

* Check	for a CTRL-C or	CTRL-S entered from the	keyboard.  Jump	to
* exit if CTRL-C, pause	on CTRL-S.

CKABRT:	LHLD	BASE+1
	MVI	L,6		;Check status of keyboard
	CALL	GOHL		;Any key pressed?
	ORA	A
	RZ			;No, return to caller
	CALL	CINPUT		;Get character
	CPI	'C'-40H		;CTRL-C?
	JZ	EXIT		;If CTRL-C then	quit
	CPI	'S'-40H		;CTRL-S?
	RNZ			;No, return to caller
	CALL	CINPUT		;Yes, wait for another char.
	CPI	'C'-40H		;Might be CTRL-C
	JZ	EXIT		;Exit if CTRL-C, else fall thru	and continue
	RET

* Kludge to allow call to address in HL

GOHL:	PCHL

* Entry	to BDOS	saving all extended registers

CPM:	PUSH	B
	PUSH	D
	PUSH	H
	CALL	BDOS
	POP	H
	POP	D
	POP	B
	RET

* For file output mode,	return to old user area	and set	DMA for
* the file output buffer.

SETFOP:	IF	UOPT OR	AOPT
	CALL	CKVER		;Clear carry if	CP/M 2 or later
	LDA	OLDUSR		;Get user number at startup
	MOV	E,A
	MVI	C,CURUSR
	CNC	CPM		;Reset the old user number if CP/M 2
	ENDIF

	IF	FOPT
	LXI	D,OUTBUF	;Move DMA from search buffer into the
	JMP	SET2		;..output buffer
	ENDIF
	RET

* Move disk buffer DMA to default buffer for directory search operations
* and BDOS media change routines (necessary for pre-CP/M 2 systems while
* in file output mode with an active buffer).

SETSRC: LXI	D,BASE+80H
SET2:	MVI	C,SETDMA
	JMP	CPM

* Print	the amount of free space remaining on the selected drive

PRTFRE: LHLD	FREEBY		;Get space left before adding to MASTER.DIR
	CALL	DECPRT		;Print K free
	LXI	D,TOTMS6	;Print " FREE."
	JMP	PRINT

* Compare routine for sort

COMPR:	PUSH	H		;Save table addr
	MOV	E,M		;Load low order
	INX	H
	MOV	D,M		;Load high order
	INX	H
	MOV	C,M
	INX	H
	MOV	B,M

* BC, DE now point to entries to be compared

	XCHG
	MOV	E,A		;Get count

CMPLP:	LDAX	B
	CMP	M
	INX	H
	INX	B
	JNZ	NOTEQL		;Quit on mismatch
	DCR	E		;Or end	of count
	JNZ	CMPLP

NOTEQL:	POP	H
	RET			;Cond code tells all

* Swap entries in the order table

SWAP:	LXI	B,ORDER-2	;Table base
	DAD	H		;*2
	DAD	B		;+ base
	XCHG
	DAD	H		;*2
	DAD	B		;+ base
	MOV	C,M
	LDAX	D
	XCHG
	MOV	M,C
	STAX	D
	INX	H
	INX	D
	MOV	C,M
	LDAX	D
	XCHG
	MOV	M,C
	STAX	D
	RET

* New compare routine

COMPARE:LXI	B,ORDER-2
	DAD	H
	DAD	B
	XCHG
	DAD	H
	DAD	B
	XCHG
	MOV	C,M
	INX	H
	MOV	B,M
	XCHG
	MOV	E,M
	INX	H
	MOV	D,M
	XCHG
	MOV	E,A		;Count

CMPLPE:	LDAX	B
	CMP	M
	INX	B
	INX	H
	RNZ
	DCR	E
	JNZ	CMPLPE
	RET

* Error	exit

ERXIT:	IF	FOPT
	MVI	A,-1
	STA	FOPFLG		;Disable file output mode on error
	ENDIF

	CALL	CRLF		;Space down
	POP	D		;Get pointer to	message	string
	CALL	PRINT		;Print it
	LXI	D,ERRMS1	;Print " ERROR"
	CALL	PRINT
	CALL	CRLF		;Space down

* Exit - all done, restore stack

EXIT:	MVI	C,CONST		;Check console status
	CALL	CPM
	ORA	A		;Char waiting?
	MVI	C,RDCHR
	CNZ	CPM		;Gobble	up char

	IF	DOPT		;Restore BDOS intercept	vectors
	CALL	SWAPEM
	ENDIF

	IF	ROPT
	LDA	ROPFLG		;If disk system	was reset
	ORA	A
	LDA	OLDDSK		;Get default disk at startup
	MOV	E,A
	MVI	C,SELDSK	;Reselect it
	CZ	CPM
	ENDIF			;Balance ROPT

	LHLD	STACK		;Get old stack pointer
	SPHL			;Move back to old stack
	RET			;..and return to CCP

* Exchange BDOS	select and sector error	vectors	for our	own intercept
* vectors so we	can catch a reference to an illegal drive.

	IF	DOPT
SWAPEM:	LHLD	BDOS+1		;Get pointer to	base of	BDOS
	MVI	L,9		;Point to sector error vector
	LXI	D,VECTBL	;Exchanging with our own vector	table
	MVI	A,4		;4 bytes to swap
SWAPLP:	MOV	B,M		;Get byte from HL
	XCHG
	MOV	C,M		;Get byte from DE
	MOV	M,B		;Put byte from HL
	XCHG
	MOV	M,C		;Put byte from DE
	INX	H		;Bump exchange pointers
	INX	D
	DCR	A		;Dock counter
	JNZ	SWAPLP		;Continue swapping til done
	RET
	ENDIF

* Check	CP/M version number.  Return carry flag	set if pre-CP/M	2.
* If CP/M 2 or later or	MP/M (any version), return carry clear.

CKVER:	LDA	VERFLG
	CPI	20H
	RET

* Recovery point from intercepted BDOS select and bad sector errors.

DSKERR: IF	DOPT
	LXI	SP,STACK	;Get out of BDOS' stack
	JMP	EXIT		;..and exit back to CCP
	ENDIF

***********************
*		      *
* End of Program Code *
*		      *
***********************

* Initialized data area

DREMSG:	DB	'DRIV','E' OR 80H

	IF	PGPAWZ
EOSMSG: DB	09H,'[ More ]',0DH,'$'
	ENDIF

ERRMS1: DB	' '
ERRMS2:	DB	'ERRO','R' OR 80H

	IF	REPERR
ERRTAG:	DB	' -','>' OR 80H
	ENDIF

NOFMS1: DB	0DH,0AH,'NO FILE ON '
NOFMS2: DB	'  -',' ' OR 80H

TOTMS1:	DB	0DH,0AH,09H,'Drive',' ' OR 80H

	IF	REPUSR
TOTMS2:	DB	', user',' ' OR	80H
	ENDIF

TOTMS3:	DB	' contains',' '	OR 80H
TOTMS4: DB	'K in',' ' OR 80H
TOTMS5:	DB	' files with',' ' OR 80H
TOTMS6: DB	'K fre','e' OR 80H
USRMSG: DB	'User ','#' OR 80H

FNDFLG: DB	0		;Flag whether any files matched

	IF	PGPAWZ
LINCNT:	DB	0		;Count of lines	printed	on screen
	ENDIF

* Drive	code/user area lookup table

* Note that the	LODRV-HIDRV table is included here fully configured.
* For your own use, you	should change the maximum user areas as
* appropriate for each drive on	your system, and then delete any
* DBs referencing drives that don't exist.  Note also that there
* are only 16 user areas available under CP/M 2, so the highest
* legal user area you can specify is 15 (range 0-15 = 16 areas).
* The program will convert anything over 15 into mod 15.

LODRV	EQU	$		;Mark beginning	of drive/user table

	DB	2		;Maximum user area for Drive A
	DB	2		;   "	  "    "    "	 "   B
	DB	2		;   "	  "    "    "	 "   C
	DB	2		;   "	  "    "    "	 "   D
	DB	2		;   "	  "    "    "	 "   E
	DB	2		;   "	  "    "    "	 "   F
;	DB	15		;   "	  "    "    "	 "   G
;	DB	15		;   "	  "    "    "	 "   H
;	DB	15		;   "	  "    "    "	 "   I
;	DB	15		;   "	  "    "    "	 "   J
;	DB	15		;   "	  "    "    "	 "   K
;	DB	15		;   "	  "    "    "	 "   L
;	DB	15		;   "	  "    "    "	 "   M
;	DB	15		;   "	  "    "    "	 "   N
;	DB	15		;   "	  "    "    "	 "   O
;	DB	15		;   "	  "    "    "	 "   P

HIDRV	EQU	$		;Mark end of drive/user	table

* Option field lookup table.
* Note that you	can force any of these options as a DEFAULT by
* changing the letter for the option into a zero (assuming that
* its enabling equate is true).	 Each option that you hard-wire	in
* this manner will no longer be	recognized as a	command	line OPTION,
* and if you redundantly key it in, SD will flag it as unrecognized.

OTBL	EQU	$		;Mark start of option table

	IF	AOPT		;All users-option flag
AOPFLG:	DB	'A'
	ENDIF

	IF	DOPT		;Multi-disk-option flag
DOPFLG:	DB	'D'
	ENDIF

	IF	FOPT		;File-output-option flag
FOPFLG:	DB	'F'
	ENDIF

	IF	NOPT AND PGPAWZ	;No page-pause option flag
NOPFLG:	DB	'N'
	ENDIF

	IF	POPT		;Printer option	flag
POPFLG:	DB	'P'
	ENDIF

	IF	ROPT		;Reset option flag
ROPFLG:	DB	'R'
	ENDIF

	IF	SOPT		;System	file option flag
SOPFLG:	DB	'S'
	ENDIF

OEND	EQU	$		;Mark end of option table

* End of option	lookup table

;	IF	AOPT
;PASS1: DB	0		;First pass flag for all user file output
;	ENDIF

	IF	DOPT
VECTBL: DW	DSKERR		;BDOS SECTOR ERROR INTERCEPT VECTOR
	DW	DSKERR		;BDOS SELECT ERROR INTERCEPT VECTOR
	ENDIF

	IF	FOPT
BUFPNT: DW	OUTBUF		;POINTER TO NEXT LOCATION IN OUTPUT BUFFER
BUFCNT: DB	128		;NUMBER OF BYTES LEFT IN OUTPUT BUFFER
opnflg: db	0		;file open flag for all user file output
OUTFCB:	DB	0,'SD      DIR'
	FILL	21,0		;REST OF SD.DIR FCB
OUTBUF	DS	128		;OUTPUT FILE BUFFER
	ENDIF

* Uninitialized	data area

BASUSR	DS	1		;Dupe of original directory user # to search
BLKMAX	DS	2		;Highest block # on drive
BLKMSK	DS	1		;SEC/BLK - 1
BLKSHF	DS	1		;# shifts to mult by SEC/BLK
COUNT	DS	2		;Entry count
DIRMAX	DS	2		;Highest file #	in directory
FREEBY	DS	2		;Contains number of K left on directory	drive
GAP	DS	2		;Sort routine storage
I	DS	2		;Sort routine storage
J	DS	2		;Sort routine storage
JG	DS	2		;Sort routine storage
LZFLG	DS	1		;0 when	printing leading zeros
MAXUSR	DS	1		;Maximum user #	for drive from lookup table
NEWUSR	DS	1		;Contains user number selected by "$U" option
NEXTT	DS	2		;Next table entry
OLDDSK	DS	1		;Holder	for currently logged-in	drive
OLDUSR	DS	1		;Contains user number upon invocation
SCOUNT	DS	2		;# to sort
SUPSPC	DS	1		;Leading space flag for	decimal	routine
TBLOC	DS	2		;Pointer to start of name table
TEMP	DS	2		;Save dir entry
TOTFIL	DS	2		;Total number of files
TOTSIZ	DS	2		;Total size of all files
VERFLG	DS	1		;CP/M version number (0=pre-CP/M 2)

	DS	60		;Stack area
STACK	DS	2		;Save old stack	pointer	here

ORDER	EQU	$		;Order table starts here

	END
    
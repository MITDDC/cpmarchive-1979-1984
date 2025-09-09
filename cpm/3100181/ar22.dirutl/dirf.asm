;		    DIRF.ASM ver 1.3
;		by Keith Petersen, W8SDZ
;		   (revised 12/19/80)
;
;	DIRECTORY FUNCTION FOR CP/M 1.4 OR 2.x PROGRAMS
;
;This file contains routines which can be included in any
;CP/M program to allow listing the directory.  No sorting
;is done because that would require use of more memory above
;the program.  These routines use the 80h default buffer for
;all operations so if you have data there be sure to move it
;before running this directory function.  Assume all registers
;destroyed when calling 'DIRF'.
;
;This module may be assembled as a stand-alone program for
;testing.  Execute program from CP/M, not DDT or L80.  It
;will return to the CCP after finishing.
;
;Remove the following ORG statement and the END statement
;when including this module in other programs
	ORG	100H	 ;TEMPORARY ORG FOR TESTING
;
;--->DIRF.LIB STARTS HERE
;
NPL	EQU	4	 ;NUMBER OF NAMES PER LINE
TAB	EQU	9	 ;HORIZONTAL TAB
CR	EQU	0DH	 ;CARRIAGE RETURN
LF	EQU	0AH	 ;LINE FEED
;
;BDOS Equates
;
RDCHR	EQU	1	 ;READ CHAR FROM CONSOLE
WRCHR	EQU	2	 ;WRITE CHR TO CONSOLE
PRINT	EQU	9	 ;PRINT CONSOLE BUFF
CONST	EQU	11	 ;CHECK CONS STAT
FSRCHF	EQU	17	 ;0FFH=NOT FOUND
FSRCHN	EQU	18	 ;   "	     "
CURDSK	EQU	25	 ;GET CURRENT DISK NAME
BDOS	EQU	5
FCB	EQU	5CH
;
;First, we preserve old stack pointer and set a new one
;because some functions take more stack space than may
;be available in the calling program.
DIRF:	LXI	H,0
	DAD	SP	 ;GET OLD STACK POINTER
	SHLD	STACK	 ;SAVE FOR LATER
	LXI	SP,STACK ;SET NEW STACK POINTER
;
;Check FCB for drive request
	LDA	FCB	 ;GET DRIVE NAME FROM FCB
	ORA	A	 ;ANY REQUESTED? (0=NO)
	JNZ	GOTDRV	 ;NOT ZERO MEANS WE HAVE NAME
;
;Get drive name
	MVI	C,CURDSK ;GET CURRENT DRIVE NAME
	CALL	BDOS
	INR	A	 ;MAKE 'A' RELATIVE TO 1 NOT 0
;
;Print signon message and drive name
GOTDRV:	ADI	40H	 ;MAKE IT ASCII
	STA	DNAME	 ;SAVE IT IN MESSAGE
	LXI	D,MSG	 ;POINT TO MESSAGE
	MVI	C,PRINT	 ;PRINT IT
	CALL	BDOS
;
;Make FCB all '?' to match any file
	LXI	H,FCB+1
	MVI	B,11	 ;FN+FT COUNT
;
QLOOP:	MVI	M,'?'	 ;STORE '?' IN FCB
	INX	H
	DCR	B
	JNZ	QLOOP
;
;Initialize number of names per line counter
	MVI	A,NPL	 ;NR. NAMES PER LINE
	STA	NNAMS	 ;INIT COUNTER
;
;Look up the FCB in the directory
	MVI	C,FSRCHF ;GET 'SEARCH FIRST' FNC
	LXI	D,FCB
	CALL	BDOS	 ;READ FIRST
	INR	A	 ;WERE THERE ANY?
	JNZ	SOME	 ;GOT SOME
	CALL	ERXIT
	DB	'++NOT FOUND$'
;
;Read more directory entries
MORDIR:	MVI	C,FSRCHN ;SEARCH NEXT
	LXI	D,FCB
	CALL	BDOS	 ;READ DIR ENTRY
	INR	A	 ;CHECK FOR END (0FFH)
	JZ	EXIT	 ;NO MORE - EXIT
;
;Point to directory entry
SOME:	DCR	A	 ;UNDO PREV 'INR A'
	ANI	3	 ;MAKE MODULUS 4
	ADD	A	 ;MULTIPLY...
	ADD	A	 ;..BY 32 BECAUSE
	ADD	A	 ;..EACH DIRECTORY
	ADD	A	 ;..ENTRY IS 32
	ADD	A	 ;..BYTES LONG
	LXI	H,81H	 ;POINT TO BUFFER
			 ;(SKIP TO FN/FT)
	ADD	L	 ;POINT TO ENTRY
	MOV	L,A	 ;SAVE (CAN'T CARRY TO H)
;
;Check for console break
	PUSH	H	 ;SAVE NAME POINTER
	MVI	C,CONST	 ;CK STATUS OF KBD
	CALL	BDOS
	POP	H	 ;RESTORE NAME POINTER
	ORA	A	 ;ANY KEY PRESSED?
	JNZ	ABORT	 ;YES, ABORT
;
;Print an entry
	MVI	B,8	 ;FILE NAME LENGTH
	CALL	TYPEIT	 ;TYPE FILENAME
	MVI	A,'.'	 ;PERIOD AFTER FN
	CALL	TYPE
	MVI	B,3	 ;GET THE FILETYPE
	CALL	TYPEIT
	LXI	H,NNAMS	 ;POINT TO NAMES COUNTER
	DCR	M	 ;ONE LESS ON THIS LINE
	PUSH	PSW
	CNZ	FENCE	 ;NO CR-LF NEEDED, DO FENCE
	POP	PSW
	CZ	CRLF	 ;CR-LF NEEDED
	JMP	MORDIR
;
;Print two spaces, fence character, then two more spaces
FENCE:	CALL	TWOSPC
	MVI	A,':'	 ;FENCE CHARACTER
	CALL	TYPE
;
;Print two spaces
TWOSPC:	CALL	SPACE
;
;Print one space
SPACE:	MVI	A,' '
;
;Type char in A register
TYPE:	PUSH	B
	PUSH	D
	PUSH	H
	MOV	E,A	 ;CHAR TO E FOR CP/M
	MVI	C,WRCHR	 ;WRITE CHAR TO CONSOLE FUNC
	CALL	BDOS
	POP	H
	POP 	D
	POP	B
	RET
;
;Type (B) characters from memory (HL)
TYPEIT:	MOV	A,M
	ANI	7FH	 ;REMOVE CP/M 2.x ATTRIBUTES
	CALL	TYPE
	INX	H
	DCR	B
	JNZ	TYPEIT
	RET
;
;CR-LF routine. HL=NNAMS upon entry
CRLF:	MVI	A,CR	 ;CR
	CALL	TYPE
	MVI	A,LF	 ;LF
	CALL	TYPE
	MVI	M,NPL	 ;NUMBER OF NAMES PER LINE
	RET
;
;Error exit
ERXIT:	POP	D	 ;GET MSG
	MVI	C,PRINT
	JMP	CALLB	 ;PRINT MSG, EXIT
;
;Abort - read char entered to clear it from CP/M buffer
ABORT:	MVI	C,RDCHR	 ;DELETE THE CHAR
;
;Fall into CALLB

CALLB:	CALL	BDOS
;
;Fall into EXIT
;
;Exit - All done, return to caller
EXIT:	LHLD	STACK	 ;GET OLD STACK
	SPHL		 ;MOVE TO STACK
	RET		 ;...AND RETURN
;
MSG:	DB	TAB,TAB,'    Directory for drive '
DNAME:	DB	'X:',CR,LF,'$'
;
;Temporary storage area
NNAMS:	DS	1	 ;NAMES PER LINE COUNTER
	DS	40	 ;ROOM FOR STACK
STACK:	DS	2	 ;OLD STACK STORED HERE
;
;Temporary end statement used only for testing DIRF module.
;Remove before including module in other programs.
	END	DIRF

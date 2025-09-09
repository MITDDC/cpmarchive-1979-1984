;Array exchange sort in place in memory.
;Copyright 1979,1980,1981 by C. E. Duncan. Written 1979 June 30.
;Taken from an original program written by E. W. Dijkstra on
;  the back of my business card at the international meeting
;  on software reliability at Los Angeles in 1975.
;Permission granted to copy for any non-commercial use.
;Revised 17:55 1981 February 10.
;
;This program, BSORT, is called as a CP/M .COM routine as follows:
;
;	BSORT <input file name> <output file name>
;
;  where file names are "[d:]name.typ" as usual in CP/M.
;  The user will be asked for record length and sort parameters
;  through a console dialog.
;
	PAGE	0		;defeats CP/M page count
	ORG	0100H		;program origin
BSORT:
;
;Set internal stacks
	LXI	H,BSTACK		;bounds stack
	SHLD	BSAVE
	LXI	H,PSTACK		;program stack
	SHLD	PSAVE
	SPHL
;Initialize
	CALL	INIT1
;Save default disk
	MVI	C,RTCDK		;return current disk number
	CALL	BDOS
	STA	CDSKSAV
;Set default disk to input file
	LDA	SFDN		;input file disk number
	MOV	E,A
	CALL	ASGDSK
;Read file and check further
	CALL	INIT2
;Do the sort
	CALL	PARTIT
;Assign output disk as default
	LDA	DFDN
	MOV	E,A
	CALL	ASGDSK
;Write output file
	CALL	WRTARY
;Close output
	LXI	D,DFCB
	MVI	C,CLOSE
	CALL	BDOS
;Restore default disk
	LDA	CDSKSAV
	MOV	E,A
	CALL	ASGDSK
	JMP	QUIT		;return to CP/M-CCP
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * *
INIT1:
;Initialize variables, read parameters, check values.
;Revised 20:10 1981 January 26.
;
;Move output file name to output FCB.
	MVI	A,12		;character count
	LXI	D,SFDA		;from
	LXI	H,DFDN		;to
	CALL	SMOVE
;Set current (next) record pointer to 0.
	XRA	A
	STA	SFCR		;input
	STA	DFCR		;output
	STA	DFEX		;file extent
	STA	ABRTF		;abort flags
	STA	STLV		;bounds stack level
;Check input file name
	LXI	D,SFCB		;input FCB
	CALL	CHKFN
	JNC	OK01
	LXI	H,ABRTF		;set abort flag
	INR	M
	LXI	D,FNIMSG
	CALL	PUTMSG
OK01:
; Check output file name
	LXI	D,DFCB		;output FCB
	CALL	CHKFN
	JNC	OK02
	LXI	H,ABRTF		;set abort flag
	INR	M
	LXI	D,FNOMSG
	CALL	PUTMSG
;
OK02:
;Abort if these names do not check
	LDA	ABRTF
	ORA	A
	JNZ	ABORT
; Calculate storage available
	LXI	H,AR		;array base address
	SHLD	ARBASE
	XCHG			;to DE
	LHLD	BDOS+1		;BDOS base
	CALL	DIFF2		;subtract
	DCR	H		;make room for temporary storage
	SHLD	MARSIZ		;available memory
; Check size of input file
	MVI	A,03FH		; "?" to insure match of
	STA	SFEX		;   all extents
	LXI	H,0		; Reset sector count
	SHLD	FSCNT
	LXI	D,SBUF		; Prepare a buffer for
	MVI	C,STDMAAD	;   directory information
	CALL	BDOS
	MVI	C,SRCHFST	; Bring in directory for first
	LXI	D,SFCB		;   extent. Returns 0,1,2 or 3
	CALL	BDOS		;   in 2.2, 0-3F in 1.4
	CPI	0FFH
	JNZ	OK03
	LXI	D,FNPMSG	;  not found so quit
	CALL	PUTMSG
	JMP	ABORT
OK03:
	ANI	3		; MOD 4 (needed by CP/M 1.4 only)
;Address directory entry (one of four in buffer), then
;  get sector count.  32 bytes per entry.
	ADD	A		; *2
	ADD	A		; *4
	ADD	A		; *8
	ADD	A		; *16
	ADD	A		; *32
	MVI	D,15		; plus offset to count byte
	ADD	D
	MOV	E,A		; add buffer base address
	MVI	D,0
	LXI	H,SBUF
	DAD	D
	MOV	A,M		; sector count
	MOV	E,A
	LHLD	FSCNT		; accumulate
	DAD	D
	SHLD	FSCNT
	CPI	080H		; Full track?
	JNZ	OK04		;   no, go on
	MVI	C,SRCHNXT	; Get information on
	LXI	D,SFCB		;   next extent
	CALL	BDOS
	CPI	0FFH		; No more entries when FF hex
	JNZ	OK03		; Get next entry
OK04:
	XRA	A		; Reset extent byte
	STA	SFEX		;   to zero
; Deduce input file size
	LHLD	FSCNT		; number of sectors
	MOV	A,H		; check for empty
	ORA	L
	JZ	ABORT		; nothing here
;Multiply by 128 bytes per sector
	DAD	H		; *2
	JC	OK05
	DAD	H		; *4
	JC	OK05
	DAD	H		; *8
	JC	OK05
	DAD	H		; *16
	JC	OK05
	DAD	H		; *32
	JC	OK05
	DAD	H		; *64
	JC	OK05
	DAD	H		; *128
	JNC	OK06
OK05:
	LXI	D,MULMSG	; multiply error
	CALL	PUTMSG
	JMP	ABORT
OK06:
; Last sector may have less than 128 bytes, will check later
	SHLD	BYIF
; Check that there is enough memory
	XCHG
	LHLD	MARSIZ		;memory available
	CALL	DIFF2
	ORA	A
	JP	OK07
	LXI	D,FSZMSG	; report file larger than memory
	CALL	PUTMSG
	JMP	ABORT
OK07:
;Calculate address of temporary record storage area
	LHLD	BYIF
	LXI	D,AR
	DAD	D
	SHLD	AWTP
; Open input file
	MVI	C,OPEN
	LXI	D,SFCB
	CALL	BDOS
	INR	A
	JNZ	OK08
	LXI	D,FNPMSG	; file not present
	CALL	PUTMSG
	JMP	ABORT
;Open output file
OK08:
	MVI	C,DELETE	;delete file of same name
	LXI	D,DFCB
	CALL	BDOS
	MVI	C,CREATE	;make new file
	LXI	D,DFCB
	CALL	BDOS
	INR	A
	JNZ	OK09
	LXI	D,NDSMSG	; signal no directory space
	CALL	PUTMSG
	JMP	ABORT
OK09:
; Ask for record length
	LXI	D,RCLMSG
	CALL	PUTMSG
	CALL	READCON		;read console input
	LXI	D,CONSIZ	;string response
	LXI	B,AR		;temporary buffer
	CALL	SCANBR		;extract number
	JC	OK09		;try again
	LDAX	B		;count
	INX	B		;1st character
	CALL	ROW1NBR		;convert to binary
	JC	OK09		;trouble
	MOV	A,L
	STA	RLEN
; calculate twos complement
	CMA
	INR	A
	STA	MRLEN
OK10:
; Ask for sort parameters.
	XRA	A		; reset parameter count
	STA	NBRFND
	LXI	D,PARMSG
	CALL	PUTMSG
	CALL	READCON		;read console input
	LDA	CONSIZ		;number of characters read
	ORA	A
	JZ	OK10		;no input, try again
	CALL	RDPARM		;read, convert and store sort parms
	JC	OK10		;try again
	CALL	CKPARM		;check parameters
	JC	OK10		;ask again
	RET			;end of INIT1
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * *
;
INIT2:
;Read input file to array, correct file size, final checks.
;Written by C. E. Duncan 1979 June 30.
;Revised 08:15 1981 February 4.
; Read input file to array
	CALL	RDARRAY
; Check and possibly correct file size calculation BYIF
; HL points to byte after last sector read.
	LDA	SFS1		; bytes remain in last sector
	ORA	A
	JNZ	OK12
	MVI	A,01AH		; must remove eof (1A) bytes
	LXI	B,0		; clear counter
OK11:
	DCX	H		; char in file
	CMP	M		; is it EOF?
	JNZ	OK13		; no
	INX	B		; count
	JMP	OK11
OK12:
	CMA			; subtract off eofs
	MOV	C,A
	MVI	B,0FFH		; minus sign
	JMP	OK14
OK13:
	MOV	A,B		; get twos complement
	CMA			;   to subtract
	MOV	B,A
	MOV	A,C
	CMA			; subtract off unused bytes
	MOV	C,A
OK14:
	INX	B		; twos complement
	LHLD	BYIF
	DAD	B		; subtract
	SHLD	BYIF
; Check that file size is multiple of record length
;  and calculate upper and lower bounds
	MOV	A,H		; check that there is a record
	ORA	L
	JZ	ABORT		; nothing here
	LDA	RLEN
	CALL	DIV12
	JNC	OK15
	LXI	D,DIVMSG
	CALL	PUTMSG
	JMP	ABORT
OK15:
	MOV	A,L		; check remainder
	CMP	H
	JZ	OK16
	LXI	D,RLMSG		;abort msg
	CALL	PUTMSG
	JMP	ABORT
OK16:
	MOV	H,B		; store quotient
	MOV	L,C		;   as UPB
	SHLD	AUPB
	SHLD	CUPB
	LXI	H,1		; LWB = 1
	SHLD	ALWB
	SHLD	CLWB
;Initialize array index calculation
;  A[I] has address = ARRAY BASE - (LWB A)*RLEN + I*RLEN
;                   = ARIF + I*RLEN
;
	LHLD	ALWB		;LWB of A
	XCHG			;   to DE
	LDA	RLEN
	CALL	MUL12
	JC	ABORT		;overflow
	XCHG
	LHLD	ARBASE		; calculate HL - DE
	CALL	DIFF2
	ORA	A		; check sign
	JP	OK17		; positive, ok
	MOV	A,H		; complement if negative
	CMA
	MOV	H,A
	MOV	A,L
	CMA
	MOV	L,A
	INX	H
OK17:
	SHLD	ARIF
;Addresses of sort strings in temporary area
	LHLD	AWTP		; temporary record store
	LDA	POOF1		; 1st sort offset
	MVI	B,0
	MOV	C,A
	DAD	B
	SHLD	KWTP1		; address of awtp[m:n]
	LDA	PARM3		; is there a 2nd sort?
	ORA	A
	RZ
	LDA	POOF2		; 2nd sort offset
	MOV	C,A
	LHLD	AWTP
	DAD	B
	SHLD	KWTP2		; address of awtp[u:v]
	RET
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * *
;
PARTIT:
;Partition sort based on a program by Dijkstra.
;Written by C. E. Duncan 1979 June 30.
;Revised 17:30 1981 February 8.
;
;   p = LWB a,  q = UPB a
;
;Algorithm:  partition and sort until q < p
;	WHILE p <= q
;	DO
;	  IF q = p
;	  THEN
;	    unstack
;	  ELSE
;	    IF q - p <= slim
;	    THEN
;  	      shorts		{insertion sort}
;	    ELSE
;	      parta		{partition left}
;		{makes two partitions: a[p] to a[s] and a[r] to a[q]}
;	    FI
;	  FI;
;	  IF s = p
;	  THEN
;	    p := r
;	  ELSE
;	    IF s < p
;	    THEN
;	      partb		{partition right}
;		{required if parta has no "small" element}
;	    ELSE
;	      IF q = r
;	      THEN
;		q := s
;	      ELSE
;		IF q < r
;		THEN
;		  unstack
;		ELSE
;		  IF q - r > s - p
;		  THEN
;		    stack right;
;		    q := s
;		  ELSE
;		    stack left;
;		    p := r
;		  FI
;		FI
;	      FI
;	    FI
;	  FI
;	OD
;
	LHLD	CLWB		; P = LWB current partition 
	XCHG		
	LHLD	CUPB		; Q = UPB current partition
	CALL	DIFF2		; compare
	ORA	A	
	RM			;sort complete when Q < P
	JZ	UNSTACK		; only one element
	XCHG
	LXI	H,SLIM		;low size limit
	CALL	DIFF2		;SLIM - (P - Q)
	ORA	A
	PUSH	PSW
	CP	SHORTS		;use insertion sort, small partition
	POP	PSW
	JP	UNSTACK		;this partition completed
	CM	PARTA		;partition leftward
; Check size of lower partition
STAR01:
	LHLD	CLWB		; P = LWB left
	XCHG
	LHLD	PS		; S = UPB left
	CALL	DIFF2		; S - P
	ORA	A
	JZ	STAR02		; only one element, finished
	JM	STAR04		; no small element
	SHLD	SMP
; Upper partition.
	LHLD	PR		; R = LWB right
	XCHG
	LHLD	CUPB		; Q = UPB right
	CALL	DIFF2		; Q - R
	ORA	A
	JZ	STAR03		; only one element, finished
	JM	UNSTACK		; finished with this partition
				;  because no large element after
				;  having no small element.
	SHLD	QMR
; Save bounds of larger partition.
; If Q - R > S - P then upper part is larger.
	LXI	H,0		; save program stack
	DAD	SP
	SHLD	PSAVE
	LHLD	BSAVE		; retrieve bounds stack
	SPHL
;
	LHLD	QMR		; Q - R
	XCHG
	LHLD	SMP		; S - P
	CALL	DIFF2		; (S-P) - (Q-R)
	ORA	A
	JM	STHI		; stack bunds for high side
STLO:
	LHLD	CLWB		; P, new lower bound
	PUSH	H
	LHLD	NUBL		; S, new upper bound
	PUSH	H
	LHLD	NLBH		; R, set new LWB for high side
	SHLD	CLWB
	JMP	REST		; restore program stack
STHI:
	LHLD	NLBH		; R, new lower bound
	PUSH	H
	LHLD	CUPB		; Q, new upper bound
	PUSH	H
	LHLD	NUBL		; S, new upper bouond for low side
	SHLD	CUPB
REST:
	LXI	H,0		; restore program stack
	DAD	SP
	SHLD	BSAVE
	LHLD	PSAVE
	SPHL
	LXI	H,STLV		; increment stack level
	INR	M
	JMP	PARTIT		; process next partition
;
; Process upper part
STAR02:
	LHLD	PR		; R is new lower bound
	SHLD	CLWB		;
	JMP 	PARTIT		;
STAR03:
; Process lower part
	LHLD	PS		; S is new upper bound
	SHLD	CUPB		;
	JMP	PARTIT		;
STAR04:
; Partition again, using R <= T and S > T in place of
;   R < T and S >= T respectively.
	CALL	PARTB		;
	JMP	STAR01		;
;
UNSTACK:
; Recover bounds of next section to be partitioned
	LXI	H,STLV		; check level
	DCR	M		; 
	RM			; stack empty, sort completed
	LXI	H,0		; save program stack
	DAD	SP		;
	SHLD	PSAVE		;
	LHLD	BSAVE		; get bounds stack
	SPHL			;
	POP	H		;
	SHLD	CUPB		; UPB
	POP	H		;
	SHLD	CLWB		; LWB
	LXI	H,0		; restore program stack
	DAD	SP		;
	SHLD	BSAVE		;
	LHLD	PSAVE		;
	SPHL			;
	JMP	PARTIT		; return, do next section
;
PARTA:
;Re-arrange array AR into two partitions the left of which contains
;  elements which precede a pivot element, and the right contains
;  those which do not.
;Written by C. E. Duncan 1979 June 30.
;Revised 15:06 1981 January 31.
;
;   R = LWB A,  S = UPB A,  T = (R+S) OVER 2.
;
;Algorithm:
;	WHILE LWB A <= R < S <= UPB A
;	DO
;	  SWAP A[R] and A[S];
;	  WHILE A[R] precedes A[T]
;	  DO
;	    R +:= 1
;	  OD;
;	  WHILE A[S] does not precede A[T]
;	  DO
;	    S -:= 1
;	  OD
;	OD
;
;Calculate addresses
	LDA	POOF1		; 1st sort parameter offset
	MVI	B,0
	MOV	C,A
	LHLD	CLWB		; current LWB
	SHLD	PR		; R
	XCHG
	CALL	INDXR		; calculate address
	SHLD	ACR		; .A[R]
	DAD	B
	SHLD	AQR1		; .A[R][M:N], 1st sort string
	LHLD	CUPB		; current LWB
	SHLD	PS		; S
	XCHG
	CALL	INDXR
	SHLD	ACS		; .A[S]
	DAD	B
	SHLD	AQS1		; .A[S][M:N]
	LHLD	PR		; R
	XCHG
	LHLD	PS		; S
	DAD	D		; R + S
	CALL	SHRHL		; divide by 2
	XCHG
	CALL	INDXR		; .A[T]
	XCHG			; move A[T], the pivot element, to
	LHLD	AWTP		;   a safe place
	LDA	RLEN
	CALL	SMOVE
; Take care of possible 2nd sort substring
	LDA	PARM3
	ORA	A
	JZ	PAR01		;not needed
	LDA	POOF2		;2nd ss offset
	MVI	B,0
	MOV	C,A
	LHLD	ACR		; .A[R]
	DAD	B
	SHLD	AQR2		; .A[R][V:W]
	LHLD	ACS
	DAD	B
	SHLD	AQS2		; .A[S][V:W]
PAR01:
;Check if finished
	LHLD	PS		; S
	XCHG
	LHLD	PR		; R
	CALL	DIFF2		; R - S
	ORA	A
	JP	PAR03		; finished
; Update addresses of A[R] and A[S]
	LHLD	PR		; R
	XCHG
	CALL	INDXR
	SHLD	ACR		; .A[R]
	LHLD	PS		; S
	XCHG
	CALL	INDXR
	SHLD	ACS		; .A[S]
; Swap
	LDA	RLEN
	LHLD	ACR		; .A[R]
	XCHG
	LHLD	ACS		; .A[S]
	CALL	SWAP
;  While A[R] precedes A[T], etc.
	LHLD	AQR1		; .A[R][M:N]
	XCHG
PAR01A:
	LDA	SPL1		;1st sort length
	LHLD	KWTP1		; .A[T][M:N]
	XCHG
	CALL	CMPSRW
	ORA	A
	JZ	PAR04		; check 2nd sort substring
PAR01B:
	PUSH	PSW
	LDA	SSEQ1		; check direction
	ORA	A
	JZ	PAR01C		; ascending
	POP	PSW		; descending
	JZ	PAR02
	JP	PAR01D		; A[R] precedes A[T], down
	JMP	PAR02
PAR01C:
	POP	PSW
	JP	PAR02		; A[R] does not precede A[T], up
PAR01D:
	LHLD	PR		; increment R
	INX	H
	SHLD	PR
	LDA	RLEN
	MVI	B,0
	MOV	C,A
	LDA	PARM3		;2nd sort?
	ORA	A
	JZ	PAR01E		;no
	LHLD	AQR2		;update .A[R][V:W], 2nd sort string
	DAD	B
	SHLD	AQR2
PAR01E:
	LHLD	AQR1		;update .A[R][M:N] 1st sort
	DAD	B
	SHLD	AQR1
	XCHG
	JMP	PAR01A
PAR02:
; While A[S] does not precede A[T] etc.
	LHLD	AQS1		; .A[S][M:N]
	XCHG
PAR02A:
	LDA	SPL1		; length of 1st sort
	LHLD	KWTP1		; 1st sort string address
	XCHG
	CALL	CMPSRW
	ORA	A
	JZ	PAR05		; check 2nd sort
PAR02B:
	PUSH	PSW
	LDA	SSEQ1		; check direction
	ORA	A
	JZ	PAR02C		; ascending
	POP	PSW
	JM	PAR02D
	JZ	PAR02D
	JMP	PAR01		; S precedes T
PAR02C:
	POP	PSW
	JM	PAR01
PAR02D:
	LHLD	PS		; decrement S
	DCX	H
	SHLD	PS
; Check array bound at lower limit, S < LWB
	XCHG
	LHLD	CLWB		; P = LWB A
	XCHG
	CALL	DIFF2		; S - P
	ORA	A
	JM	PAR03		; no small element
;Update addresses for next comparison
	LDA	MRLEN		; minus RLEN
	MVI	B,0FFH
	MOV	C,A
	LDA	PARM3		;check for 2nd sort
	ORA	A
	JZ	PAR02E		;no
	LHLD	AQS2
	DAD	B
	SHLD	AQS2
PAR02E:
	LHLD	AQS1
	DAD	B		; reduce address by RLEN
	SHLD	AQS1
	XCHG
	JMP	PAR02A
PAR03:
	LHLD	PR
	SHLD	NLBH		; new LWB for right partition
	LHLD	PS
	SHLD	NUBL		; new UPB for left partition
	RET
PAR04:
	LDA	PARM3
	ORA	A
	JZ	PAR01B		;no 2nd sort
	LHLD	KWTP2
	XCHG
	LHLD	AQR2
	LDA	SPL2
	CALL	CMPSRW
	ORA	A
	PUSH	PSW
	LDA	SSEQ2
	ORA	A
	JZ	PAR04A		; ascending
	POP	PSW
	JZ	PAR02
	JP	PAR01D
	JMP	PAR02
PAR04A:
	POP	PSW
	JM	PAR01D
	JMP	PAR02		; this one is out of order
;
PAR05:
	LDA	PARM3		; is there a 2nd sort?
	ORA	A
	JZ	PAR02B		; no
	LHLD	KWTP2
	XCHG
	LHLD	AQS2
	LDA	SPL2
	CALL	CMPSRW
	ORA	A
	PUSH	PSW
	LDA	SSEQ2
	ORA	A
	JZ	PAR05A
	POP	PSW
	JZ	PAR02D
	JM	PAR02D
	JMP	PAR01
PAR05A:
	POP	PSW
	JP	PAR02D
	JMP	PAR01
;
PARTB:
;Re-arrange array A into two partitions, the right of which contains
;  elements which follow a pivot element, and the left contains those
;  which do not.
;Written by C. E. Duncan 1979 June 30.
;Revised 18:50 1981 February 8.
;
;   R = LWB A,  S = UPB A,  T = (R+S) OVER 2
;
;Algorithm:
;	WHILE LWB A <= R < S <= UPB A
;	DO
;	  SWAP A[R] and A[S];
;	  WHILE A[R] does not follow A[T]
;	  DO
;	    R +:= 1
;	  OD;
;	  WHILE A[S] follows A[T]
;	  DO
;	    S -:= 1
;	  OD
;	OD
;
; Calculate addresses
	LDA	POOF1		; 1st sort offset
	MVI	B,0
	MOV	C,A
	LHLD	CLWB		; current LWB A
	SHLD	PR		; R
	XCHG
	CALL	INDXR
	SHLD	ACR		; .A[R]
	DAD	B		; .A[R][M:N]
	SHLD	AQR1
	LHLD	CUPB
	SHLD	PS		; S
	XCHG
	CALL	INDXR
	SHLD	ACS		; .A[S]
	DAD	B
	SHLD	AQS1		; .A[S][M:N]
	LHLD	PR		; R
	XCHG
	LHLD	PS		; S
	DAD	D		; R+S
	CALL	SHRHL		; shift right, OVER 2
	XCHG
	CALL	INDXR		; address of A[T]
	XCHG			; move A[T] to a safe place
	LHLD	AWTP
	LDA	RLEN
	CALL	SMOVE
; Take care of 2nd sort substring
	LDA	PARM3		; is there one?
	ORA	A
	JZ	PAB01		; no
	LDA	POOF2		; offset
	MVI	B,0
	MOV	C,A
	LHLD	ACR
	DAD	B
	SHLD	AQR2		; .A[R][V:W]
	LHLD	ACS
	DAD	B
	SHLD	AQS2		; .A[S][V:W]
PAB01:
; Check completion
	LHLD	PS		; S
	XCHG
	LHLD	PR		; R
	CALL DIFF2		; R-S
	ORA	A
	JP	PAB03		; finished
; Update addresses of A[R] and A[S]
	LHLD	PR		; R
	XCHG
	CALL	INDXR
	SHLD	ACR		; .A[R]
	LHLD	PS		; S
	XCHG
	CALL	INDXR
	SHLD	ACS		; .A[S]
; Swap Elements with indices R and S
	LDA	RLEN
	LHLD	ACR		; .A[R]
	XCHG
	LHLD	ACS		; .A[S]
	CALL	SWAP
; While A[R] does not follow A[T] increment R.
	LHLD	AQR1		; .A[R][M:M]
	XCHG
PAB01A:
	LDA	SPL1		; length sort 1
	LHLD	KWTP1		; .A[T][M:N]
	CALL	CMPSRW
	ORA	A
	JZ	PAB04		; check 2nd sort
PAB01B:
	PUSH	PSW
	LDA	SSEQ1		; direction
	ORA	A
	JZ	PAB01C
	POP	PSW		; descending
	JM	PAB01D
	JZ	PAB01D
	JMP	PAB02
PAB01C:
	POP	PSW
	JM	PAB02
PAB01D:
	LHLD	PR		; R
	INX	H
	SHLD	PR
; Check upper bound in case no large element
	XCHG
	LHLD	CUPB		; Q = UPB A
	CALL	DIFF2
	ORA	A
	JM	PAB03		; upper limit, no large element
; Update addresses, etc.
	LDA	RLEN
	MVI	B,0
	MOV	C,A
	LDA	PARM3
	ORA	A		; 2nd sort
	JZ	PAB01E		; no
	LHLD	AQR2		; .A[R][V:W]
	DAD	B
	SHLD	AQR2
PAB01E:
	LHLD	AQR1
	DAD	B
	SHLD	AQR1
	XCHG
	JMP	PAB01A
PAB02:
;While A[S] follows A[T] decrease S, etc.
	LHLD	AQS1		; .A[S][M:N]
	XCHG
PAB02A:
	LDA	SPL1
	LHLD	KWTP1
	CALL	CMPSRW
	ORA	A
	JZ	PAB05		; check for 2nd sort
PAB02B:
	PUSH	PSW
	LDA	SSEQ1
	ORA	A
	JZ	PAB02C
	POP	PSW
	JZ	PAB01
	JP	PAB02D
	JMP	PAB01		; A[S] <= A[T]
PAB02C:
	POP	PSW
	JP	PAB01
PAB02D:
	LHLD	PS		; decrement S
	DCX	H
	SHLD	PS
	LDA	MRLEN
	MVI	B,0FFH
	MOV	C,A
	LDA	PARM3		; 2nd sort?
	ORA	A
	JZ	PAB02E		; no
	LHLD	AQS2
	DAD	B
	SHLD	AQS2
PAB02E:
	LHLD	AQS1
	DAD	B
	SHLD	AQS1
	XCHG
	JMP	PAB02A
;
PAB03:
	LHLD	PR		
	SHLD	NLBH		; new LWB for right partition
	LHLD	PS
	SHLD	NUBL		; new UPB for left partition
	RET
PAB04:
	LDA	PARM3		; 2nd sort?
	ORA	A
	JZ	PAB01B		; no
	LHLD	AQR2
	XCHG
	LHLD	KWTP2
	LDA	SPL2
	CALL	CMPSRW
	ORA	A
	PUSH	PSW
	LDA	SSEQ2
	ORA	A
	JZ	PAB04A
	POP	PSW
	JM	PAB01D
	JZ	PAB01D
	JMP	PAB02
PAB04A:
	POP	PSW
	JP	PAB01D
	JMP	PAB02
;
PAB05:
	LDA	PARM3
	ORA	A
	JZ	PAB02B
	LHLD	AQS2
	XCHG
	LHLD	KWTP2
	LDA	SPL2
	CALL	CMPSRW
	ORA	A
	PUSH	PSW
	LDA	SSEQ2
	ORA	A
	JZ	PAB05A
	POP	PSW
	JZ	PAB01
	JP	PAB02D
	JMP	PAB01
PAB05A:
	POP	PSW
	JM	PAB02D
	JMP	PAB01
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
SHORTS:
;Insertion sort for small partitions.
;Written by C.  E. Duncan 1980 February 16, from Knuth volume 3
;  (Searching and Sorting) page 81.
;Revised 12:30 1981 February 8.
;
;Algorithm:
;
;	FOR j FROM 2 TO UPB(a)
;	DO
;	   IF a[j] < a[j - 1]
;	   THEN
;	      awtp := a[j];
;	      FOR i FROM j - 1 BY -1 TO LWB(a)
;		    WHILE at < a[i]
;	      DO
;		  a[i + 1] := a[i];
;		  k := i
;	      OD;
;	      a[k] := awtp
;	   FI
;	OD
;
;Initialize indices and addresses.
	LHLD	CLWB		;LWB of current partition
	SHLD	PS		; j
	XCHG
	CALL	INDXR
	SHLD	ACS		; address of a[j] = a[LWB]
	LDA	POOF1		;1st sort offset
	MVI	B,0
	MOV	C,A
	DAD	B
	SHLD	AQS1		;address of a[LWB][m:n]
	LDA	PARM3
	ORA	A
	JZ	SH01
	LDA	POOF2		;2nd sort offset
	MOV	C,A
	LHLD	ACS
	DAD	B
	SHLD	AQS2		;address of a[LWB][u:v]
SH01:
;Increment j, compare to UPB, set i := j - 1
	LHLD	PS		; j - 1
	SHLD	PR		; i := j - 1
	INX	H		; j +:= 1
	SHLD	PS		; j
;Check that j <= UPB
	XCHG
	LHLD	CUPB		; UPB of parttion
	CALL	DIFF2		;UPB - j
	ORA	A
	RM			;finished when J > UPB
;Update addresses
	LHLD	ACS		;old .a[j]
	SHLD	ACR		;new .a[i]
	LDA	RLEN
	MVI	B,0
	MOV	C,A
	DAD	B
	SHLD	ACS		; new a[j]
;Update sort string addresses
	LHLD	AQS1
	SHLD	AQR1		; a[i][m:n]
	DAD	B
	SHLD	AQS1		; a[j][m:n]
	LDA	PARM3
	ORA	A
	JZ	SH02
	LHLD	AQS2
	SHLD	AQR2		; a[i][u:v]
	DAD	B
	SHLD	AQS2		; a[j][u:v]
SH02:
;Compare a[j] with a[j - 1] = a[i]
	LHLD	AQR1
	XCHG
	LHLD	AQS1
	LDA	SPL1
	CALL	CMPSRW
	ORA	A
	JZ	SH05		; check 2nd sort
SH03:
	PUSH	PSW
	LDA	SSEQ1		; check direction
	ORA	A
	JNZ	SH04
	POP	PSW
	JM	SH07		; have to do some moves
	JMP	SH01		; ok where it is, go to next j
SH04:
	POP	PSW
	JM	SH01		; ok as is
	JZ	SH01		;  ditto
	JMP	SH07
SH05:
;Second compare for a[j] and a[j - 1]
	LDA	PARM3
	ORA	A
	JZ	SH03		; no 2nd compare
	LHLD	AQR2
	XCHG
	LHLD	AQS2
	LDA	SPL2
	CALL	CMPSRW
	ORA	A
	PUSH	PSW
	LDA	SSEQ2
	ORA	A
	JNZ	SH06
	POP	PSW
	JM	SH07
	JMP	SH01
SH06:
	POP	PSW
	JM	SH01
	JZ	SH01
	JMP	SH07
;
SH07:
;Move a[j] to a safe place: awtp := a[j]
	LHLD	ACS
	XCHG			; from
	LHLD	AWTP		; to
	LDA	RLEN
	CALL	SMOVE
SH08:
;Move a[i] up one place to position i + 1
	LDA	RLEN
	MVI	B,0
	MOV	C,A
	LHLD	ACR		; a[i]
	MOV	D,H		;   to DE, from
	MOV	E,L
	DAD	B		; a[i + 1]
	CALL	SMOVE
;Decrement i, check against LWB
	LHLD	CLWB		; LWB
	XCHG
	LHLD	PR		; i
	DCX	H		; i -:= 1
	SHLD	PR
	CALL	DIFF2		; i - LWB
	ORA	A
	JM	SH14		; at LWB, hence a[LWB] := awtp
;Decrement addresses and compare again
	LDA	MRLEN		; negative record length
	MVI	B,0FFH
	MOV	C,A
	LHLD	ACR
	DAD	B
	SHLD	ACR		; new address of a[i]
	LHLD	AQR1
	DAD	B
	SHLD	AQR1		; new 1st sort address
	LDA	PARM3
	ORA	A
	JZ	SH09
	LHLD	AQR2
	DAD	B
	SHLD	AQR2		; new 2nd sort address
SH09:
;Compare awtp = a[j] with a[i]
	LHLD	AQR1
	XCHG
	LHLD	KWTP1
	LDA	SPL1
	CALL	CMPSRW
	ORA	A
	JZ	SH12
SH10:
	PUSH	PSW
	LDA	SSEQ1
	ORA	A
	JNZ	SH11
	POP	PSW
	JM	SH08		; keep trying and comparing
	JMP	SH15		; found place for at in a[i + 1]
SH11:
	POP	PSW
	JM	SH15
	JZ	SH15
	JMP	SH08
;
SH12:
;Second compare for awtp = a[j] and a[i]
	LDA	PARM3
	ORA	A
	JZ	SH10
	LHLD	AQR2
	XCHG
	LHLD	KWTP2
	LDA	SPL2
	CALL	CMPSRW
	ORA	A
	PUSH	PSW
	LDA	SSEQ2
	ORA	A
	JNZ	SH13
	POP	PSW
	JM	SH08
	JMP	SH15
SH13:
	POP	PSW
	JM	SH15
	JZ	SH15
	JMP	SH08
;
SH14:
;Move awtp = a[j] into slot at a[LWB]
	LHLD	AWTP
	XCHG
	LDA	RLEN
	LHLD	ACR
	CALL	SMOVE
	JMP	SH01
SH15:
;Move awtp = a[j] into slot at a[i + 1]
	LHLD	AWTP
	XCHG
	LDA	RLEN
	MVI	B,0
	MOV	C,A
	LHLD	ACR
	DAD	B
	CALL	SMOVE
	JMP	SH01
;
;* * * * * * * * * * * * * * * * * * * * * *
;
ABORT:
;Return to CP/M
	LXI	D,ABMSG
	CALL	PUTMSG
	JMP	QUIT
;
ASGDSK:
;Assign default disk for faster input and output.
;  Must have desired disk number in E, and default disk number
;  in location CDSKSAV.
;Written by C. E. Duncan 1981 January 28.
	XRA	A		;get zero
	CMP	E
	JNZ	ASGD1
	LDA	CDSKSAV		;need default disk
	MOV	E,A
	JMP	ASGD2
ASGD1:
	DCR	E		;A-P = 1-16 become 0-15
ASGD2:
	MVI	C,SELDK		;select disk
	CALL	BDOS
	RET
;
CHAROW:
;Reset carry if character in C is present in row of character
;  whose address is in DE, length in B, else set carry.
;  Return position number in B.
;Written by C. E. Duncan 1981 January 23.
;Revised 09:00 1981 January 28.
	MOV	A,B			;row length
	CPI	0			;check zero length
	JZ	CHAR2
	XCHG				;row address in HL
	MOV	A,C			;character sought
	MVI	D,0			;position count
CHAR1:
	INR	D			;count
	CMP	M			;is this it?
	JZ	CHAR3			;yes
	DCR	B			;count off row
	INX	H			;next permitted
	JNZ	CHAR1			;more
CHAR2:
	STC				;signal not found
	RET
CHAR3:
	MOV	B,D			;position number
	ORA	A			;found, reset carry
	RET
;
CHKFN:
; Check file name for legal characters, FCB address in DE.
; Written by C. E. Duncan 1980 February 7.
; Revised 05:30 1981 February 4.
	LDAX	D		;drive
	CPI	5		;no more than 4 drives
	JNC	CHKFN2		;out of limits
	MVI	B,11		; Number of characters to check
	INX	D		;first character
	LDAX	D		; must be non-blank
	CPI	021H		;
	JC	CHKFN2		; not acceptable
	JMP	CHKFN3		;
CHKFN1:				;
	INX	D		; next character
	LDAX	D		;
	CPI	020H		; blank
	JC 	CHKFN2		; control character
CHKFN3:
	CPI	05BH		; [
	JNC	CHKFN2		; also unacceptable
	DCR	B		; count
	JNZ	CHKFN1		; return for next
	XRA	A		; signal ok
	RET			;
CHKFN2:				;
	STC			; signal presence of
	RET			;   unacceptable character
;
CKPARM:
;Check sort parameters. Each parameter one byte from PARM1.
;Written by C. E. Duncan 1981 January 21.
;Revised 13:37 1981 January 28.
;
;get parameters in registers
	LXI	H,PARM1		;address parameters
	MOV	B,M
	INX	H
	MOV	C,M
	INX	H
	MOV	D,M
	INX	H
	MOV	E,M
	LDA	RLEN
	MOV	H,A
;check parameters <= RLEN
	MOV	L,B
	CALL	KPR		;check range of parm1
	RC			;out of limits
	MOV	L,C
	CALL	KPR		;check parm2
	RC
	MOV	A,D		;is there a 2nd sort range?
	CPI	0
	JZ	KRR		;no
	MOV	L,D
	CALL	KPR		;check parm3
	RC
	MOV	L,E
	CALL	KPR
	RC
	JMP	KRR
KPR:
	MOV	A,L
	CPI	1
	RC			;< 1
	MOV	A,H
	SUB	L
	RET			;carry set if > RLEN
KRR:
;Calculate sort string lengths and check them
	MOV	A,C		;1st
	SUB	B
	RC			;negative length
	INR	A
	STA	SPL1		;length of 1st sort substring
	MOV	L,A
	MOV	A,H		;RLEN
	SUB	L
	RC			;substring longer than record
	MOV	A,B		;PARM1
	DCR	A
	STA	POOF1		;offset of sort substring in record
	MOV	A,D		;PARM3
	ORA	A
	RZ			;ok return, only one substring
;Have 2nd sort substring
	MOV	L,A
	MOV	A,E		;PARM4
	SUB	L
	RC			;negative length
	INR	A
	STA	SPL2
	MOV	L,A
	MOV	A,H
	SUB	L
	RC			;longer than RLEN
	MOV	A,D
	DCR	A
	STA	POOF2		;offset
;Check for sort field overlap
	MOV	A,E		;PARM4
	SUB	B		;PARM1
	JC	KRS		;ok
	MOV	A,C		;PARM2
	SUB	D		;PARM3
	JC	KRS		;ok
	STC			;overlap
	RET
KRS:
	XRA	A		;ok, reset carry
	RET
;
CMPSRW:
;Compare two rows of character of equal length.
;Registers DE and HL have addresses of the two rows of character,
;  register A the count.  Return -1, 0, +1 in register A as HL < DE, 
;  HL = DE, HL > DE respectively.
;Written by C. E. Duncan 1981 January 26.
	MOV	B,A		;count
	INR	B
CMPSRWA:
	DCR	B
	JZ	CMPSRWEQ	;equal
	LDAX	D
	CMP	M
	JC	CMPSRWGT	;HL > DE
	JNZ	CMPSRWLT	;HL < DE
	INX	D		;equal so far
	INX	H
	JMP	CMPSRWA
CMPSRWGT:
	MVI	A,1
	RET
CMPSRWEQ:
	XRA	A
	RET
CMPSRWLT:
	MVI	A,-1
	RET
;
DIFF2:
;Calculate difference of integers in DE and HL.  Put absolute
;   difference in HL.  Signal DE < HL, DE = HL, DE > HL with
;   +1, 0 -1 in A.
;Written by C. E. Duncan 1980 February 18.
;Revised 13:30 1981 January 29.
	MOV	A,D	
	CMP	H	
	JC	DIF1		; DE < HL
	JNZ	DIF2		; DE > HL
	MOV	A,E	
	CMP	L	
	JC	DIF1		; DE < HL
	JNZ	DIF2		; DE > HL
	LXI	H,0		; DE = HL
	XRA	A		; reset carry to signal equal
	RET
DIF1:
	MVI	B,1		; signal DE < HL
	JMP	DIF3
DIF2:
	MVI	B,0FFH		; signal DE > HL
	XCHG	
DIF3:
; Do subtraction
	MOV	A,L
	SUB	E
	MOV	L,A
	MOV	A,H
	SBB	D
	MOV	H,A
	MOV	A,B		; restore signal
	STC			; set carry to signal not equal
	RET
;
DIV12:
;Divide 16 bit integer in HL by eight bit SHORT INT in A;
;   return 16 bit quotient in BC, remainder in HL (L).
;20:05 10 February 1980.
	ORA	A		;test for zero divisor
	JZ	DIV03		;
	PUSH	A		;save divisor
	CMA			;twos complement
	INR	A		;  of divisor
	MOV	E,A		; to DE
	MVI	D,0FFH		;propagate negative sign
	LXI	B,0		;clear quotient
DIV01:
	DAD	D		;divide by subtraction
	JNC	DIV02		;
	INX	B		;
	JMP 	DIV01		;
DIV02:
	POP	A		;prepare
	MOV	E,A		;  remainder
	MVI	D,0		;  in HL
	DAD	D		;
	ORA	A		;reset carry to
	RET			;   signal ok
DIV03:
	STC			;signal zero
	RET			;   divisor
;
GETNBR:
;Extract an ASCII number (sequence of digits) from a row of character.
;  Enter with row address in DE, count in BUFCNT.  Return with
;  DE pointing to following characters, remaining count in BUFCNT
;  and extracted number converted to binary in C.  Carry set if
;  unsuccessful, else reset.
;Written by C. E. Duncan 1981 January 27.
;Revised 08:00 1981 January 28.
	LDA	BUFCNT		;get count
	ORA	A
	JNZ	GETN01
GETN00:
	STC			;signal zero length in or out
	RET
GETN01:
	LXI	B,AR-1		;temporary store
	XCHG
	INR	A		;count + 1
	MOV	D,A		; to D
	MVI	E,0		;output count
	DCX	H
GETN02:
	INX	H		;next character
	DCR	D		;count
	JZ	GETN04		;finished
	MOV	A,M
	CPI	030H
	JC	GETN02		;ignore
	CPI	03AH
	JNC	GETN02
;Have found a digit
GETN03:
	INX	B		;ASCII number output
	STAX	B
	INR	E		;count output
	INX	H		;address of next character
	DCR	D		;count input
	JZ	GETN04		;finished
	MOV	A,M
	CPI	030H
	JC	GETN04		;finished
	CPI	03AH
	JC	GETN03
;Windup
GETN04:
	MOV	A,D
	STA	BUFCNT		;remaining input count
	PUSH	H		;save current row address
	MOV	A,E		;output count
	LXI	B,AR		;recover output address
	CALL	ROW1NBR		;convert ASCII number at BC to binary
	POP	D		;recover address
	JC	GETN00		;problems
	MOV	C,L
	RET			;binary number in C
;
INDXR:
;Get address of array element with index given in DE. Return
;   address of element in HL.  Array base address is stored in
;   location ARBASE, RLEN, the record length is less than 256.
;   Address of AR[i] is given by ARIF + I*RLEN.
;   Index is checked against bounds.
	PUSH	D
	LHLD	ALWB		;check LWB
	DCX	H
	CALL	DIFF2
	ORA	A
	JM	IND02		; LWB <= I
IND01:
	LXI	D,INXMSG	;report index out
	CALL	PUTMSG		;  of bounds
	JMP	ABORT
IND02:
	LHLD	AUPB		;check UPB
	POP	D
	PUSH	D
	CALL	DIFF2
	ORA	A
	JM	IND01		;abort
	POP	D		;index ok, I <= UPB
	LDA	RLEN
	CALL	MUL12
	JC	ABORT		;overflow
	XCHG
	LHLD	ARIF
	DAD	D
	RET
;
MU111:
;Multiply 8-bit number in E by 8-bit number in A, returning
;  8-bit number in L. Set carry for overflow, else reset.
;Written by C. E. Duncan 1981 January 24.
	LXI	H,0		;zero result register
	MVI	D,0		;for double add
	MVI	B,8		;bit count
MU111A:
	DAD	H		;shift HL left
	RAL			;same for multiplier
	JNC	MU111B
	DAD	D
MU111B:
	DCR	B		;count
	JNZ	MU111A		;get next bit
	XRA	A		;check for overflow
	CMP	H
	RET			;carry set if H > 0
;
MUL12:
;Multiply 16-bit number in DE by 8-bit number in A, placing
;  16-bit result in HL.  Carry set for overflow, else reset.
;Revised 22:22 1980 February 25.
	LXI	H,0		;clear result register
	MVI	B,8		;bit count
MUL12A:
	DAD	H		;shift left
	RAL			;same for multiplier
	JNC	MUL12B		;this multiplier bit = 0
	DAD	D		;add multiplicand
	RC			;carry indicates overflow
MUL12B:
	DCR	B		;count bits
	JNZ	MUL12A		;continue
	ORA	A		;ok, reset carry
	RET
;
PUTMSG:
; Write message to console via BDOS, address in DE
	PUSH	D		;Save message address
	LXI	D,CCRLF		;CR and LF
	MVI	C,PCONBUF	;
	CALL	BDOS		;
	POP	D		;recover message
	MVI	C,PCONBUF	;Signal write to console
	CALL	BDOS		;
	RET			;
;
RDARRAY:
;Read disk file of typed, fixed length records to array AR.
;Written by C. E. Duncan 1980 February 3.
;Revised 08:30 1981 February 4.
; Initialize
	LXI	B,0FF80H	; -128
	LXI	H,AR		; array base
	DAD	B		;
	PUSH	H		;
	LXI	H,0		; Zero sector count
	SHLD	RSCNT		;
; Read loop
RDAL:				;
; Set DMA address
	LXI	B,128		; step pointer
	POP	H		;
	DAD	B		;
	PUSH	H		;
	XCHG			; DMA addr in DE for BDOS
	MVI	C,STDMAAD	;
	CALL	BDOS		;
; Read a sector
	LXI	D,SFCB		; Address FCB
	MVI	C,READSEQ	; 
	CALL	BDOS		;
	CPI	0		; check successful completion
	JNZ	RD1		; check further
	LHLD	RSCNT		; ok, count 
	INX	H		;
	SHLD	RSCNT		;
	JMP	RDAL		; return for next sector
RD1:	CPI	1		;
	JZ	RD2		; end of file
	JMP 	ABORT		; should not happen
RD2:
; Read complete
	POP	H		; Restore stack
	RET			;
;
RDPARM:
;Read parameters from console and store in suitable form.
;Written by C. E. Duncan 1981 January 27.
;Revised 12:20 1981 January 28.
	LXI	D,CONSIZ	;console buffer
	LDAX	D		;count
	ORA	A
	JZ	RDPFIN		;no input
	STA	BUFCNT		;count of unprocessed characters
	INX	D		;1st character
RDP1:
	LDAX	D		;examine character
	ORI	020H		;convert to lower case
	PUSH	D		;save row address
	MVI	B,14		;count of acceptable characters
	MOV	C,A		;character to be tested
	LXI	D,PRMCHRS	;list of ok characters
	CALL	CHAROW		;is it acceptable?
	MOV	A,C		;recover character
	POP	D
	JNC	RDP3		;ok
RDP2:
	INX	D		;point to next character
	LXI	H,BUFCNT	;update count
	DCR	M
	JNZ	RDP1		;keep trying
	JMP	RDPFIN		;no more
RDP3:
	CPI	'a'		;ascending?
	JZ	RDP7		;yes, no action
	CPI	'd'		;descending?
	JNZ	RDP9		;must be a number
	LDA	NBRFND		;which parameter?
	CPI	2		;is it 3rd?
	JZ	RDP4		;must be 5th or 6th
	CPI	4
	JZ	RDP5
	CPI	5
	JZ	RDP5
	JMP	RDP2		;ignore
RDP4:
	LXI	H,SSEQ1
	JMP	RDP6
RDP5:
	LXI	H,SSEQ2
RDP6:
	INR	M		;set descending
RDP7:
	LXI	H,NBRFND	;update parameter count
	INR	M
	JMP	RDP2		;return for more
RDP8:
	LXI	H,NBRFND	;update number of parameters found
	INR	M
	LDA	BUFCNT		;check for remaining characters
	ORA	A
	JZ	RDPFIN
	JMP	RDP1		;process next character
RDP9:
	CALL	GETNBR		;return binary in C, update buffer
	LDA	NBRFND		;parameter count
	CPI	0
	JNZ	RDP10
	MOV	A,C
	STA	PARM1
	JMP	RDP8
RDP10:
	CPI	1
	JNZ	RDP11
	MOV	A,C
	STA	PARM2
	JMP	RDP8
RDP11:
	CPI	2
	JNZ	RDP13
RDP12:
	MOV	A,C
	STA	PARM3
	JMP	RDP8
RDP13:
	CPI	3
	JNZ	RDP14
	LDA	PARM3
	ORA	A
	JZ	RDP12
RDP14:
	MOV	A,C
	STA	PARM4
	JMP	RDP8
RDPFIN:
	LDA	NBRFND		;all done?
	CPI	2		;at least 2
	RET			;carry set if not
;
READCON:
;Read console to console buffer CONBUF.
	LXI	D,CONBUF
	MVI	C,RCONBUF
	CALL	BDOS
	RET
;
ROW1NBR:
;Convert ASCII decimal row at (BC), length A, to 1-byte number
; in L. Set carry for overflow.
;Copyright 1980 by C. E. Duncan.
;Revised 12:20 1981 January 24.
	CPI	4		;check size
	JNC	RTN1A		;
	CPI	0		;
	JNZ	RTN1B		;
RTN1A:
	STC			;signal trouble
	RET			;
RTN1B:
	MOV	D,A		;count
	MVI	L,0		;reset result register
	MVI	E,10		;multiplier
RTN1C:
	MOV	A,L		;multiply by 10
	PUSH	B		;
	PUSH	D		;
	CALL	MU111		;A * E to L
	POP	D		;
	POP	B		;
	JC	RTN1A		;overflow
	LDAX	B		;next digit
	SUI	30H		;convert to binary
	JM	RTN1A		;not a digit
	CPI	10		;
	JNC	RTN1A		;not a digit
	ADD	L		;
	MOV	L,A		;
	INX	B		;next
	DCR	D		;count
	JNZ	RTN1C		;continue
	RET			;
;
SCANBR:
;Extract an ASCII number (sequence of digits) from a string.
;  Enter with address of string in DE.  Leave with BC pointing
;  to extracted ASCII number string, and DE pointing to remaining
;  row of characters with count in A.
;  String = LCCC...C.
;Written by C. E. Duncan 1981 January 23.
	LDAX	D		;get count
	ORA	A
	JNZ	SCNB01
SCNB00:
	STC			;signal zero length in or out
	RET
SCNB01:
	PUSH	B		;output string origin
	XCHG
	INR	A		;count + 1
	MOV	D,A		; to D
	MVI	E,0		;output count
SCNB02:
	DCR	D		;count
	JZ	SCNB04		;finished
	INX	H		;next character
	MOV	A,M
	CPI	030H
	JC	SCNB02		;ignore
	CPI	03AH
	JNC	SCNB02
;Have found a digit
SCNB03:
	INX	B		;ASCII number output
	STAX	B
	INR	E		;count output
	DCR	D		;count input
	JZ	SCNB04		;finished
	INX	H		;next input character
	MOV	A,M
	CPI	030H
	JC	SCNB04		;finished
	CPI	03AH
	JNC	SCNB04		;finished
	JMP	SCNB03
;Windup
SCNB04:
	POP	B		;recover output origin
	MOV	A,E		;output count
	ORA	A		;test for zero length
	JZ	SCNB00
	STAX	B
	MOV	A,D		;input count remaining
	XCHG
	RET			;ok, carry reset
;
SHRHL:
;Shift HL right one bit :=: divide HL by 2.
;Written by C.  E. Duncan 1979 June 30.
	ANA	A		;clear carry
	MOV	A,H
	RAR
	MOV	H,A
	MOV	A,L
	RAR
	MOV	L,A
	RET
;
SMOVE:
;Non-overlapping move, left to right.
;Register A has count of bytes, < 256, DE address of source and
;  HL address of destination.
;Written by C. E. Duncan 1980 February 18.
;Revised 17:30 1981 January 26.
	MOV	B,A		;count
	INR	B
SMOVE1:
	DCR	B
	RZ
	LDAX	D
	MOV	M,A
	INX	D
	INX	H
	JMP	SMOVE1
;
SWAP:
;Exchange two rows-of-character of equal length, addresses in
;   DE and HL, length in A.
;Written by C. E. Duncan 1980 February 18.
;Revised 08:40 1981 February 4.
	ORA	A		;check length
	RZ			;finished
	MOV	B,A		;count
SWAP1:
	MOV	C,M		;save byte from HL
	LDAX	D		;move byte from
	MOV	M,A		;  DE to HL
	MOV	A,C		;move byte from C
	STAX	D		;  (from HL) to DE
	INX	D
	INX	H
	DCR	B
	JNZ	SWAP1
	RET
;
WRTARY:
; Write array to disk file from AR.
; Written 1980 February 17.
; Revised 17:45 1981 January 28.
; Initialize
	LXI	B,0FF80H	; -128
	LXI	H,AR		; array base
	DAD	B		;
	PUSH	H		; array pointer
	LHLD	RSCNT		; sector count
	INX	H
	PUSH	H
	LXI	B,128		;DMA address increment
WRAL:
; Check count of sectors remaining
	POP	D		; get count
	DCX	D		; count
	MOV	A,D
	ORA	E
	JNZ	WR1		; more
	POP	H		; restore stack
	RET			;finished
WR1:
; Set DMA address
	POP	H
	LXI	B,128
	DAD	B
	PUSH	H
	PUSH	D		; count
	XCHG
	MVI	C,STDMAAD
	CALL	BDOS
; Write sector
	LXI	D,DFCB		; output FCB
	MVI	C,WRITSEQ	; sequential write
	CALL	BDOS
	CPI	0
	JZ	WRAL		; ok, continue
; Abort because of disk problems
	LXI	H,ABRTF		; Abort flags
	MOV	A,M
	ORI	80H
	MOV	M,A		; write failure
	JMP	ABORT		; quit
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
;Patch area
PATCH	DS	48
;
;Equates, literals and storage for ISORT.
;Written by C. E. Duncan 1979 June 30.
;Revised 07:25 1981 February 4.
;
;Console messages
;
CR:	EQU	13		;Carriage return
LF:	EQU	10		;Line feed
CCRLF:	DB	CR,LF,'$'
FNIMSG:	DB	'Unacceptable character in input file name.$'
FNOMSG:	DB	'Unacceptable character in output file name.$'
FNPMSG:	DB	'Input file not present.$'
NDSMSG:	DB	'No directory space for output file.$'
RCLMSG:	DB	'Enter record length: $'
PARMSG:	DB	'Enter sort parameters: $'
ABMSG:	DB	'Program discontinued.$'
MULMSG:	DB	'Overflow in multiply.$'
DIVMSG:	DB	'Divide by zero.$'
RLMSG:	DB	'File size not multiple of record length.$'
FSZMSG:	DB	'File larger than available memory.$'
INXMSG:	DB	'Array index out of bound.$'
;
; Storage
;
PRMCHRS: DB	'0123456789ad'	;permitted parameters
;
ARBASE:	DW	0	;array base address
RLEN:	DB	0	; record length - bytes
ALWB:	DW	0	; array lower bound
AUPB:	DW	0	; array upper bound
CLWB:	DW	0	; current lower bound
CUPB:	DW	0	; current upper bound
BUFCNT:	DB	0	;characters in buffer
NBRFND:	DB	0	;parameter number
QMR:	DW	0	; Q - R
SMP:	DW	0	; S - P
PARM1:	DB	0	; sort parameters
PARM2:	DB	0	;
PARM3:	DB	0	;
PARM4:	DB	0	;
POOF1:	DB	0	;1st sort substr offset
POOF2:	DB	0	;2nd sort substr offset
SPL1:	DB	0	;1st sort substr length
SPL2:	DB	0	;2nd sort substr length
SSEQ1:	DB	0	;1st sort direction, 0=A, 1=D
SSEQ2:	DB	0	;2nd sort direction
AQR1:	DW	0	; .A[R][M:N]
AQR2:	DW	0	; .A[R][V:W]
AQS1:	DW	0	; .A[S][M:N]
AQS2:	DW	0	; .A[S][V:W]
NLBH:	DW	0	; new LWB for right partition
NUBL:	DW	0	; new UPB for left partition
ARIF:	DW	0	;Array index calculation base
MARSIZ:	DW	0	; maximum available memory
BYIF:	DW	0	; Total input file size - bytes
ABRTF:	DS	1	;Abort flags
FSCNT:	DW	0	;Sectors in input file
RSCNT:	DW	0	;Sectors read count
KWTP1:	DW	0	;Temporary storage, .AR[J][M:N]
KWTP2:	DW	0	;Temporary storage, .AR[J][V:W]
AWTP:	DW	0	; address of temp record storage
PR:	DW	0	; R
PS:	DW	0	; S
ACR:	DW	0	; .A[R]
ACS:	DW	0	; .A[S]
MRLEN:	DB	0	; negative of RLEN
CDSKSAV: DB	0	;save default disk number
SLIM:	EQU	8	;partition size lower limit
;
DFCB:	DS	36	; output FCB
DFDN:	EQU	DFCB+0	; disk name
DFEX:	EQU	DFCB+12	; current extent
DFCR:	EQU	DFCB+32	; current/next/record number
;
; CONSOLE BUFFER
;
CONBUF:	DB	CONLEN	;
CONSIZ:	DS	1	;number current characters
CONLIN:	DS	254	;character buffer
SBUF:	EQU	CONSIZ	;temporary buffer for disk directory
CONLEN: EQU	$-CONSIZ
;
; Stack and pointers
;
BSTKDP:	EQU	16*4	;
PSTKDP:	EQU	16*2	;
	DS	BSTKDP	;Bounds stack
BSTACK:	DW	0	;Stack top
	DS	PSTKDP	; program stack
PSTACK:	DW	0	; base
STLV:	DS	1	; current stack depth
PSAVE:	DW	0	; program stack pointer
BSAVE:	DW	0	; bounds stack pointer
;
; LOGICAL I/O FUNCTION EQUATES
;
PCONBUF: EQU	9	;print to console from buffer
RCONBUF: EQU	10	; read console to buffer
SELDK:	EQU	14	;select disk
OPEN:	EQU	15	;open disk file
CLOSE:	EQU	16	;close disk file
SRCHFST: EQU	17	;search first occurrence of FCB in directory
SRCHNXT: EQU	18	;search next occurrence of FCB
DELETE:	EQU	19	;delete file
READSEQ: EQU	20	;read next disk record
WRITSEQ: EQU	21	;write next disk record
CREATE:	EQU	22	;create file and directory entry
RTCDK	EQU	25	;return current disk number
STDMAAD: EQU	26	;set DMA address
;
SFCB:	EQU	05CH	;Input (default) FCB 
SFDN:	EQU	SFCB+0	;disk number
SFEX:	EQU	SFCB+12	;current extent
SFS1:	EQU	SFCB+13	;bytes in last sector (maybe)
SFDA:	EQU	SFCB+16	;extent allocation vector
SFCR:	EQU	SFCB+32	;current/next/record number
;
QUIT:	EQU	0000H	;re-boot return to CPM
BDOS:	EQU	0005H	;DOS entry
; PROGRAM END
	DB		'BSORT 2-2.2 PROGRAM END'
AR:	DW	0	;Base of sort array
	END		;
  
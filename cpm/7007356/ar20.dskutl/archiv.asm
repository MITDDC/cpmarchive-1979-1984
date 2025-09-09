;               ARCHIVE - File Archive/Backup Utility
;               Version 1.0, 6-June-82 by Kelly Smith
; 
; 
;      ARCHIVE  is  a  user oriented disk maintenance  utility  for 
; archival  storage and file backup.   User facilities include  the 
; ability to selectively 'tag' files for archival (or non-archival) 
; attributes,  display  file  archive attributes,  or  backup  non-
; archive files to a selected disk.  Wild-card filenames (using '*' 
; and/or  '?')  may be used freely,  to select some or  all  (i.e., 
; '*.*') files for archiving.
; 
; 
;                      - Theory of Operation -
; 
;      Digital  Research's  MP/M-II and CP/M-86  Operating  Systems 
; utilize a file attribute for archival backup of any file addition 
; or update to the disk directory.   This attribute is 'reset' when 
; an  application  program is required to write a file to  a  disk.  
; The  actual 'mechanism' for this archive function is realized  by 
; controlling  the  most significant bit of the third character  of 
; the FCB (File Control Block) directory entry (i.e.,  position 11, 
; identified  as byte position T3,  with the Archive attribute  bit 
; (bit  7  of byte T3) identified as T3').   It is  then  a  simple 
; matter to identify a file as archived (e.g.,  backed-up) when T3' 
; is a 'one',  and non-archived (e.g.,  needs to be backed-up) when 
; T3'  is  a  'zero'.   The 'not-so-simple' part,  is  the  utility 
; required   to  keep  track  of  the  archive  attributes   on   a 
; disk...thats where ARCHIVE comes in, and works with CP/M-80 (with 
; the help of a little 'patch'),  as well as with MP/M-II and CP/M-
; 86 (when translated for 8086 CPU operation).    
; 
; 
;                       - Examples of Usage -
; 
;      At  the CP/M user command prompt,  (usually 'A>'),  the user 
; has the option for four single letter ARCHIVE command directives, 
; as follows:
; 
;                S - Set file archive attribute.
; 
;                R - Reset file archive attribute.
; 
;                D - Display file arcive attribute.
; 
;                B - Backup non-archived files.
; 
;      ARCHIVE  is  invoked by the user at the CP/M  command  level 
; therefore, as follows,
; 
;                    A>ARCHIVE FN.FT OPTION<cr>
; 
; ...where,  'FN.FT' is an amibiguous or un-ambiguous filename  and 
; filetype,  followed  by one of the single character options,  and 
; then a keyboard RETURN entry.  An actual example then might be:
; 
;                       A>archive b:*.* b<cr>
; 
; ...then,  we  are executing ARCHIVE from the 'A' disk drive,  for 
; all  filenames and filetypes on disk 'B' whose archive  attribute 
; has   been  'reset',   to  be  'backed-up'  to  some   (as   yet) 
; indeterminate destination disk.
; 
;      Options  'S',  'R' and 'D' (Set,  Reset,  and Display)  when 
; invoked,  will  cause each file found in the directory 'match' to 
; be  displayed by 'multiple extension'...that is,  each  directory 
; entry will be displayed,  with its 'extent' number,  followed  by 
; the archive attribute action/status as 'S' or 'R' (Set or Reset).
; 
;      Option  'B'  (Backup)  will  request the  user  to  enter  a 
; destination disk letter (A to P), then proceed to scan the source 
; disk  directory for 'reset' archive file  entries.   Any  'reset' 
; entries  will  then be 'set' (indicating that the file  has  been 
; archived)  and then these files will be copied to the destination 
; disk  (Note  however,  that  these  files  will  not  retain  any 
; previously  set  attributes of 'Read Only' or 'System'  had  they 
; been  set...all  files  copied to the destination  disk  will  be 
; 'tagged'  as archived only).   If a disk becomes full,  the  user 
; will  be requested to remove the disk from the destination  drive 
; and  insert another for completion of the  backup  process.   Any 
; file  that has not been completely copied to the destination disk 
; at the time that disk is detected as 'full', will be deleted from 
; that disk,  and the file copy will resume intact on the next disk 
; installed in the destination drive.
; 
;      Users of MP/M-II can use ARCHIVE immediately, with no system 
; modification  required  because it "knows" about file  archiving.  
; However,  for  CP/M-80 users,  they must patch there system  BDOS 
; (Basic Disk Operating System) to "teach" CP/M-80 file  archiving.  
; The following code must be edited and assembled,  then loaded (as 
; a  '.HEX'  file)  with DDT (Dynamic Debugging  Tool)  using  your 
; normal  system  installation  procedure for  merging  your  'Boot 
; Loader'  and  BIOS (Basic Input/Output System) into  your  system 
; "image"  for eventual SYSGEN'ing (this code assumes the  standard 
; SYSGEN position of address 980H for the start of the CCP (Console 
; Command   Processor,   with   a  CP/M-80  system  'size'  of   56 
; Kilobytes...change the value at label MSIZE to suit your needs).
; 
; 
;                           *+*+*+*+*+*+*
;                           *+         +*
;                           *+ WARNING +*
;                           *+         +*
;                           *+*+*+*+*+*+*
; 
;      You  must incorporate this 'archive patch' in an  unmodified 
; CP/M-80   (version   2.2)   BDOS   O-N-L-Y...any   other    prior 
; modifications  will (no doubt) be overlayed by this one,  causing 
; unpredictable results...'nuf said.
;                                              - KS -
;
;
;
; msize		equ	56		; size of this CP/M 2.2 system
; ;
; bdos$loc	equ	(msize-20)*1024+3c00h	; base address of BDOS
; wrsec		equ	bdos$loc+03b8h	; address of write sector routine
; pntdir	equ	bdos$loc+055eh	; address of directory pointer routine
; reset$archive	equ	bdos$loc+0df0h	; address of reset archive bit patch
; ;
; ccp$base	equ	0980h		; sysgen ccp base position
; bdos$entry	equ	ccp$base+0806h	; sysgen bdos entry position
; wrt$dir	equ	bdos$entry+05c8h; 'wrsec' call location, in DIR write routine
; scratch	equ	bdos$entry+0deah; scratch RAM inside bdos for patch
; 
; 	org	wrt$dir			; patch 'call wrsec'
; ;
; 	call	reset$archive		; call patch in scratch RAM
; ;
; 	org	scratch			; patch area for 'archive bit reset'
; ;
; 	call	pntdir			; point to directory entry in buffer
; 	lxi	d,11			; make offset to 't3' in FCB
; 	dad	d
; 	mov	a,m			; get 't3' character from FCB
; 	ani	07fh			; kill archive bit position
; 	mov	m,a			; return reset archive bit to FCB
; 	call	wrsec			; write directory sector
; 	ret				; return to 'wrt$dir' routine
; ;
; ;
; ;
; 	end
;
;
;
; *+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*
; *+                                                                     +*
; *+  ARCHIVE.ASM Utility Version 1.0,  as of 6-June-82, by Kelly Smith  +*
; *+                                                                     +*
; *+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*
;
;
; 
true	equ	-1		; define true
false	equ	not true	; define false
;
mpm	equ	not true	; conditional assembly for MP/M
;
bdos	equ	5		; CP/M entry point
exit	equ	0		; CP/M exit point
dfcb	equ	5ch		; CP/M default fcb
fcbext	equ	dfcb+12		; fcb extent byte
fcbrno	equ	dfcb+32		; fcb record number byte
dbuff	equ	80h		; default disk buffer
; 
coninp	equ	1		; console character input function
pchar	equ	2		; print character function
dircon	equ	6		; direct console i/o function
pmessg	equ	9		; print message function
constat	equ	11		; console status function
version	equ	12		; return version number function
rsetdsk	equ	13		; reset disk system function
seldsk	equ	14		; select drive function
open	equ	15		; open file function
close	equ	16		; close file function
srchfst	equ	17		; search for first file match function
srchnxt	equ	18		; search for next file match function
delete	equ	19		; delete file function
read	equ	20		; read record function
write	equ	21		; write record function
make	equ	22		; make file function
currdsk	equ	25		; return current logged disk function
stdma	equ	26		; set dma address function
attrib	equ	30		; set file attributes function
; 
tab	equ	09h		; tab character
lf	equ	0ah		; line feed character
cr	equ	0dh		; carriage return character
; 

	org	100h

;
; jump over authorship notice
;
	jmp	over
;
	db	cr,lf,'ARCHIVE Ver.1.0, 6-Jun-82:  Kelly Smith'
	db	cr,lf,'3055 Waco Avenue, Simi Valley, CA 93063'
	db	cr,lf,'Z'-40h	; force end-of-file for display
;
; make a new stack pointer at CP/M serial number
;
over:	lhld	bdos+1		; set up a stack
	sphl			; at top of tpa
;
; get curent logged disk, and save it
;
	mvi	c,currdsk	; return curent disk
	call	bdos
	sta	logdsk		; save as logged disk
;
; reset disk system in case someone swapped in new disk on the system
;
	mvi	c,rsetdsk	; reset disk system function
	call	bdos
;
; now return to original login disk
;
	lda	logdsk		; get logged in disk number
	mov	e,a		; do disk select
	mvi	c,seldsk
	call	bdos	
;
; announcing, the new and improved ARCHIVE...it beats as it sweeps, as it cleans
; 
	lxi	d,signon	; point to signon message
	mvi	c,pmessg	; print string fuction
	call	bdos		; print it
;
; check for proper environment, we only live for CP/M 2.2
;
	mvi	c,version	; check version number, must be 2.2
	call	bdos
	cpi	022h		; version number correct?
	lxi	d,bad$ver$num	; set-up bad version message, in case its not
	jnz	arcexit		; bail-out now, if wrong version number
;
	if	not mpm		; CP/M-80 does not know about archiving...
	lhld	bdos+1		; see if archiving installed in CP/M
	lxi	d,05c9h		; add offset to archive patch address
	dad	d
	shld	arch$addr	; save address for later
	mov	a,m		; get low byte content
	cpi	0b8h		; is this address for write sector routine?
	jnz	patch$bdos	; if not, patch it back into bdos
	lxi	d,noarch	; tell user that archive is not installed
	jmp	arcexit		; exit via CP/M warm boot
;
patch$bdos:
;
	lhld	bdos+1		; patch write sector address back to bdos
	lxi	d,03b2h		; add offset address of 'wrsec'
	dad	d
	xchg			; address patch info to [DE]
	lhld	arch$addr	; get address to patch in [HL]
	mov	m,e		; low byte address patched first
	inx	h		; bump pointer
	mov	m,d		; high byte address patched second
	endif			; endif MP/M
;
; check if filename specified, abort if not
;
	lda	dfcb+1		; this will be a space, if no filename
	cpi	' '
	jnz	gotname		; if not space, probably filename
	lxi	d,no$file$nam	; inform user of error of their way...
	mvi	c,pmessg
	call	bdos
	lxi	d,opts		; tell'em about backup options also
	jmp	arcexit		; bail-out now, no filename
;
; got a name, now check to see which (if any) disk specified
; 
gotname:lda	dfcb		; check for specific drive
	dcr	a
	mov	e,a		; set up for select disk call
	mvi	c,seldsk
	inr	a		; if no specified drive, skip call
	sta	src$dsk$num	; save drive specifier for later check
	cnz	bdos
	xra	a		; now zap out drive specifier
	sta	dfcb
	mvi	a,'?'		; force extent number wild
	sta	dfcb+12
	lda	dfcb+17		; get "B", "S", "R" or "D" option
	sta	option
	cpi	'B'		; backup operation?
	jz	okopt
	cpi	'S'		; set archive operation?
	jz	okopt
	cpi	'R'		; reset archive operation?
	jz	okopt
	cpi	'D'		; just display?
	jz	okopt
; 
badopt:	lxi	d,ilgopt	; let'em know it was an illegal option
arcexit:mvi	c,pmessg	; bitch, bitch, bitch... 
	call	bdos
	jmp	exit
; 
; findout now, if operation is for backup or general lobotomy
;
okopt:	lda	option		; get option specifier
	cpi	'B'
	jnz	arc$s$r		; if not backup, must be set/reset archive
dest:	lxi	d,req$dest	; request destination disk for backup files
	mvi	c,pmessg
	call	bdos
	mvi	c,coninp	; get console input character
	call	bdos
	ani	05fh		; force upper case
	sbi	'A'		; force binary digit
	cpi	16		; disk >P?
	jnc	dest		; must satisfy ourselves with 16 disks maximum
	lxi	h,logdsk	; is this jerk backing up to the same disk?
	ani	0fh		; strip high nibble for match to logged disk
	cmp	m
	push	psw		; save flags
	inr	a		; save re-adjusted disk number
	sta	dest$dsk$num
	pop	psw		; get flags
	jz	dsksame		; if same, tell'em so now
	inx	h		; bump pointer to destination disk
	mov	a,m		; get disk number
	inx	h		; bump pointer to source disk number
	cmp	m		; any chance he specified destination as source
	jnz	backup		; if not, we can (finally) proceed with backup
dsksame:lxi	d,same$dsk	; sob...(read this anyway you want)
	mvi	c,pmessg
	call	bdos
	jmp	dest		; computers never lose their patience...
;
; ready for directory write operations now...do archive set/reset
;
arc$s$r:call	crlf		; tidy up display
	xra	a		; zero out file count
	sta	filcnt
	lxi	d,dfcb		; find the first file and get its block map
	mvi	c,srchfst
	call	bdos
	inr	a		; search successful?
	jnz	gotfile		; yes, go process rest
	lxi	d,no$file$fnd	; oops, no file found
	jmp	arcexit		; exit via CP/M warm boot
; 
gotfile:dcr	a		; compensate for 'inr' above
	rrc			; file offset to bits 5 and 6
	rrc
	rrc
	ani	60h
	lxi	h,dbuff		; point to base of buffer
	mov	c,a
	mvi	b,0
	dad	b		; index by file offset
	push	h		; save directory entry, for the moment
	lxi	b,filetable	; point to base of file table
	call	filepoint	; get table pointer to [HL]
	xchg			; [DE] now points to place in table
	lda	filcnt		; keep track of number of files in table
	inr	a
	sta	filcnt		; bump file count
	pop	h		; [HL] points to directory entry
	mvi	b,32
	call	blkmov		; copy entry into table
getnext:mvi	c,srchnxt	; search for another entry
	lxi	d,dfcb
	call	bdos
	inr	a		; returns 0ffh at end of search
	jnz	gotfile		; got another one, go save it
; 
;  end of directory encountered, now process them
; 
tagfile:call	abort		; check for user abort of process
	lxi	b,filetable-32	; allow for file count one greater than desired
	call	filepoint
	push	h
	lxi	d,dfcb		; copy next name to default fcb
	mvi	b,32
	call	blkmov		; someday I will grow up to be a Z80...
	xra	a
	sta	dfcb		; clear drive number
	lxi	d,-20		; point back to extent field
	dad	d
	mvi	m,'$'		; tag end of print here
	pop	d		; get back pointer to start of entry
	inx	d		; bump forward to name
	mvi	c,pmessg
	call	bdos		; say what we're working on
	mvi	e,' '		; make space between filename.typ and extent
	mvi	c,pchar
	call	bdos
	lda	dfcb+12		; get extent number
	push	psw		; save it
	adi	'0'		; convert to ascii
	mov	e,a
	mvi	c,pchar		; display extent number
	pop	psw
	call	bdos
	lda	option		; get B, S, R, or D
	cpi	'D'		; display only?
	jz	nextfile
	rrc			; bit 7 = 0 for B, R, and D, 1 for S
	ani	80h
	mov	b,a		; save mask
	lxi	d,dfcb+11	; point to t3
	ldax	d		; get it
	ani	7fh		; strip t3'
	ora	b		; set bit if option was S
	stax	d		; put it back
	lxi	d,dfcb		; point to start of fcb
	xra	a		; zap out drive field
	stax	d
	mvi	c,attrib	; do set attributes function
	call	bdos
; 
nextfile:
; 
	lda	dfcb+11		; get t3
	rlc			; isolate t3'
	ani	1
	adi	'R'		; make an R or S
	sta	donmsg+1
	lxi	d,donmsg
	mvi	c,pmessg	; print completion message for this file
	call	bdos
	call	crlf		; tidy up display
	lxi	h,filcnt	; point to file counter
	dcr	m		; count it down
	jz	exit		; exit if done
	jmp	tagfile		; tag next file
;
; backup routine - does multiple file search and copy
;
backup:	call	crlf		; tidy up display
noback:	call	abort		; check for user abort of process
	call	mfname		; set-up multi-file search (seek and ye shall find?)
	jnc	movname		; file found, if no carry
	lda	mfflg1		; check if anything ever found...
	ora	a
	lxi	d,bakup$done	; set-up backup done message
	jnz	nofile		; if not...indicate, no file found
	lda	got$arc		; check archive found flag
	ora	a
	jnz	arcexit		; if not zero, must have found one (or more)
	lxi	d,narcs		; indicate no archive files found
	jmp	arcexit
nofile:	lxi	d,no$file$fnd	; oops, no file found
	jmp	arcexit		; exit with perturbed message
movname:lxi	h,dfcb+11	; point to t3 in filetype
	mov	a,m		; get t3 byte
	rlc			; archive bit set?
	jc	noback		; if so, no backup required
	rrc			; adjust back to normal
	sta	got$arc		; set archive file found flag with non-zero
	ori	080h		; set 'archived' status back
	mov	m,a		; put it back
	push	h		; save pointer
	lxi	d,dfcb		; point to start of fcb
	mvi	c,attrib	; do set attributes function
	call	bdos
	pop	h		; restore pointer
	dcx	h		; point to t2 in filetype
	mov	a,m		; get t2 byte
	ani	07fh		; strip-off t2'
	mov	m,a		; put it back
	dcx	h		; point to t1 in filetype
	mov	a,m		; get t1 byte
	ani	07fh		; strip-off t1'
	mov	m,a		; put it back
	lxi	h,dfcb+1	; point to filename for move and display
	lxi	d,fname		; display destination for filename
	mvi	b,8		; set-up to move 8 characters in filename
	call	blkmov		; too bad that 8080 is defacto standard
	lxi	h,dfcb+9	; point to filetype for move and display
	lxi	d,fname+9	; display destination for filetype
	mvi	b,3		; set-up to move 3 characters in filetype
	call	blkmov		; LDIR is so nifty...
dspname:lxi	d,fname		; display filename and filetype
	mvi	c,pmessg
	call	bdos
; 
; save first fcb for use later as destination file name
; 
	mvi	b,11	   	; number of characters to move
	lxi	h,dfcb+1	; from default fcb
	lxi	d,destfcb+1 	; to destfcb
	call	blkmov		; round'em up and head'em out
; 
; open the source file
; 
	lda	logdsk		; select disk, in case of disk full status
	mov	e,a
	mvi	c,seldsk	; select disk function
	call	bdos	
	lxi	d,dfcb		; point to source fcb
	mvi	c,open		; attempt open
	call	bdos
	cpi	0ffh		; file not found?
	jnz	openok
	lxi	d,src$open$err	; oops, source file open error
	jmp	arcexit		; exit via CP/M warm boot
; 
; open the destination file
; 
openok:	lxi	d,destfcb	; point to destination fcb
	lda	dest$dsk$num	; get destination disk number
	stax	d		; set-up destination disk fcb disk number
	mvi	c,delete	; erase any old file
	call	bdos
	lxi	d,destfcb
	mvi	c,make		; make the new one
	call	bdos
	cpi	0ffh		; succesfully created?
	jz	full		; oops, disk full...time for a new one
; 
; read source file to buffer, write to destination as copy
;
copy:	lxi	h,(table$end-filetable)/128	; save buffer size
	shld	bufmax
	xra	a		; clear eof flag
	sta	eof$flg
copy1:	call	abort		; check for user abort on ctrl-c
	lxi	h,0		; set current buffer counter to zero
	shld	bufcnt
	lxi	h,filetable	; set buffer start pointer to begin
	shld	bufpnt
; 
; file source reading loop to read all of buffer full or stop on eof
; 
copy2:	lhld	bufpnt		; set dma address to buffer pointer
	xchg
	mvi	c,stdma
	call	bdos
	lxi	d,dfcb		; point at default fcb for reading
	mvi	c,read		; function set for record read
	call	bdos
	ora	a		; check if read was o.k., or eof
	jnz	copy3		; end of file so set eof flag
	lhld	bufpnt		; set buffer pointer up one sector
	lxi	d,128
	dad	d
	shld	bufpnt
	lhld	bufcnt		; increase buffer sector count
	inx	h
	shld	bufcnt
	xchg			; check to see if memory is full
	lhld	bufmax		; maximum sector count
	call	cdehl		; compare
	jnz	copy2		; if not full go get next sector
	jmp	copy4		; go handle write operation
; 
; here if read operation indicates that the file is at its end on read
; 
copy3:	mvi	a,0ffh		; set eof flag
	sta	eof$flg
; 
; write output file processing loop to send memory buffer to destination disk file
; 
copy4:	lxi	h,filetable	; set buffer pointer to start
	shld	bufpnt
copy5:	call	abort		; check for user abort on ctrl-c
	lhld	bufcnt		; see if buffer is empty yet
	mov	a,h
	ora	l
	jz	copy6		; buffer empty so check eof flag
	dcx	h		; dec buffer sector count for each write
	shld	bufcnt
	lhld	bufpnt		; set up dma address
	push	h		; save for size bump
	xchg
	mvi	c,stdma
	call	bdos
	pop	h
	lxi	d,128		; increase address for sector size
	dad	d
	shld	bufpnt
	lxi	d,destfcb	; point to output file fcb
	mvi	c,write		; write record function code
	call	bdos		; go write
	ora	a   		; check if any error
	jz	copy5		; o.k., so do next record
	jmp	full		; oops...disk full, time for a new one
;
copy6:	lda	eof$flg		; buffer all written so go check eof
	ora	a
	jz	copy1		; go to read next buffer full
	lxi	d,destfcb	; point at fcb for file close
	mvi	c,close		; close file function code
	call	bdos
	cpi	0ffh		; check if close error
	jnz	backup		; if not, backup more files
	lxi	d,src$close$err	; oops, close error on destination disk
	jmp	arcexit		; exit with error message
;
; subroutine to compare [DE] to [HL], [Z] set if equal
;
cdehl:	mov	a,d		; high bytes equal?
	cmp	h
	rnz
	mov	a,e		; yes, how'bout low bytes?
	cmp	l
	ret			; set zero, if equal
;
; subroutine to allow disk change, to continue backup process
;
full:	lxi	d,destfcb	; delete partial file on destination disk
	mvi	c,delete
	call	bdos
	lxi	d,dsk$full	; indicate that disk (or dir) is full
	mvi	c,pmessg
	call	bdos
	lda	dest$dsk$num	; get destination disk number
	adi	040h		; ASCII'ize it
	mov	e,a		; display it
	mvi	c,pchar
	call	bdos
	lxi	d,now$full	; display remaining portion of full message
	mvi	c,pmessg
	call	bdos
req$cnt:lxi	d,enter$ret	; tell'em to remove/insert disk, hit return
	mvi	c,pmessg
	call	bdos
	mvi	c,coninp	; wait for user response
	call	bdos
	cpi	cr		; carriage return?
	jnz	req$cnt		; if not, leave reminder on what to do
	call	crlf		; tidy up screen
	mvi	c,rsetdsk	; reset disk system for newcomer
	call	bdos
	call	rset$fcb	; reset fcb for retry of previous file
	jmp	dspname		; continue on new disk, with last file
;
; Multi-file  access  subroutine.   Allows processing  of  multiple 
; files (i.e.  *.*) from disk.  This routine builds the proper name 
; in the fcb each time it is called.  Carry is set if no more names
; can be found. 
;
mfname:	mvi	c,stdma		; set dma address
	lxi	d,dbuff
	call	bdos
	xra 	a		; clear fcb extension and  record number
	sta	fcbext
	sta	fcbrno
	lda	mfflg1		; get multi-file flag
	ora	a
	jz	mfile1		; if zero, not 1st time flag
	lxi	h,dfcb		; save filename as requested name
	lxi	d,mfreq
	mvi	b,12
	call	blkmov
	lda	dfcb
	sta	mfcur		; save disk in current fcb
	lxi	h,mfreq		; set-up for filename search
	lxi	d,dfcb
	mvi	b,12
	call	blkmov
	mvi	c,srchfst	; do search first
	lxi	d,dfcb
	call	bdos
	jmp	mfile2		; check if file found
;
mfile1:	lxi	h,mfcur		; do search first on current filename
	lxi	d,dfcb
	mvi	b,12
	call	blkmov
	mvi	c,srchfst
	lxi	d,dfcb
	call	bdos
	lxi	h,mfreq		; do search next on requested filename
	lxi	d,dfcb
	mvi	b,12
	call	blkmov
	mvi	c,srchnxt
	lxi	d,dfcb
	call	bdos
mfile2:	inr	a		; return carry set, if file not found
	stc
	rz
;
; move name found to current filename
;
	dcr	a		; adjust location found
	ani	3
	add	a
	add	a
	add	a
	add	a
	add	a
	adi	81h
	mov	l,a		; make filename pointer
	mvi	h,0
	push	h		; save filename pointer
	lxi	d,mfcur+1
	mvi	b,11
	call	blkmov		; move filename to current filename
;
; move filename found to fcb
;
	pop	h		; get filename pointer
	lxi	d,dfcb+1
	mvi	b,11
	call	blkmov		; move filename to fcb
;
; setup fcb for subsequent file write operation
;
rset$fcb:
;
	lxi	d,dfcb		; point to source fcb
	lda	src$dsk$num	; force disk number, in case not logged disk
	stax	d
	xra	a		; clean-up for new file backup
	sta	fcbext
	sta	fcbrno
	sta	destfcb
	sta	destfcb+12
	sta	destfcb+32
	sta	mfflg1		; turn off 1st time flag
	ret
;
; 
; 
;  subroutine to do block moves
;
blkmov:	mov	a,m		; copy byte from [HL] to [DE]
	stax	d
	inx	h		; bump pointers
	inx	d
	dcr	b		; loop for count in [B]
	jnz	blkmov
	ret
; 
;  subroutine to index [BC] by file counter
;
filepoint:
;
	lhld	filcnt		; get file counter
	mvi	h,0		; force hi ord to 0
	dad	h		; multiply by 32
	dad	h
	dad	h
	dad	h
	dad	h
	dad	b		; use as index to file table
	ret
;
; subroutine to check for user abort (any key pressed)
;
abort:	push	h		; save all registers
	push	d
	push	b
	push	psw
	mvi	c,dircon	; check direct console i/o (status)
	mvi	e,0ffh		; input only
	call	bdos
	ora	a		; set flags
	jz	abortx		; return, if zero result
	cpi	'C'-40h		; control-c for abort?
	jnz	abortx		; just return, if not
	lxi	d,abort$process	; indicate we are aborting process
	mvi	c,pmessg
	call	bdos
	jmp	exit		; exit via CP/M warm boot
abortx:	pop	psw		; restore all registers
	pop	b
	pop	d
	pop	h
	ret
;
; subroutine to do carriage return/line feed
;
crlf:	lxi	d,crlf$msg
	mvi	c,pmessg
	call	bdos
	ret
; 
; 
; 
signon:		db	cr,lf,'ARCHIVE (CTRL-C to Abort) - Ver.1.0'
		db	cr,lf,cr,lf,'$'
; 
ilgopt:		db	'Invalid or Unspecified Option - Must Be Specified As:'
		db	cr,lf,cr,lf
opts:		db	tab,'B - Backup File Archive or,'
		db	cr,lf
		db	tab,'S - Set File Archive or,'
		db	cr,lf
		db	tab,'R - Reset File Archive or,'
		db	cr,lf
		db	tab,'D - Display File Archive'
		db	cr,lf,'$'
; 
no$file$fnd:	db	cr,lf,'File Not Found, Aborting$'
; 
donmsg:		db	'  ','$'
; 
crlf$msg:	db	cr,lf,'$'
; 
bad$ver$num:	db	'Must be CP/M Version 2.2 to Archive, Aborting$'
;
	if	not mpm		; archive must be 'installed' in CP/M-80
noarch:		db	'Archiving Not Installed, Aborting$'
	endif			; endif MP/M	
;
req$dest:	db	'Destination Disk for BACKUP Files (A to P)? $'
;
same$dsk:	db	cr,lf,'Can''t BACKUP to Source Disk You TWIT!',cr,lf,'$'
;
abort$process:	db	cr,lf,'User Abort of ARCHIVE Process$'
;
narcs:		db	cr,lf,'No ARCHIVE Files Found to BACKUP$' 
;
no$file$nam:	db	'No Filename or Option Specified - '
		db	'ARCHIVE must be invoked as:'
		db	cr,lf,cr,lf
		db	tab,'ARCHIVE FN.FT OPTION<cr>'
		db	cr,lf,cr,lf
		db	'Where;',tab,'FN.FT is Filename and Filetype '
		db	'(? and * allowed)'
		db	cr,lf,cr,lf
		db	'And;',tab,'OPTION is specified as:'
		db	cr,lf,cr,lf,'$'
; 
src$open$err:	db	cr,lf,'Oops, Can''t Open File on Source Disk$'
; 
dsk$full:	db	cr,lf,'Destination BACKUP Disk $'
;
now$full:	db	': is now FULL - Remove, insert NEW Disk$'
;
enter$ret:	db	cr,lf,'Enter RETURN when ready to continue BACKUP process: $'
; 
src$read$err:	db	cr,lf,'Oops, Read Error on Source Disk$'
; 
src$close$err:	db	cr,lf,'Oops, Bad Close on Destination Disk$'
;
bakup$done:	db	cr,lf,'BACKUP Complete',cr,lf,'$'
;
fname:		db	'            $'	; 11 spaces for filename.typ
;
got$arc:	db	0	; archive file found flag (1 = found)
;
mfflg1:		db	1	; 1st time flag for multi-file access
;
mfreq:		ds	12	; multi-file requested filename
;
mfcur:		ds	12	; multi-file current filename
;
arch$addr:	ds	2	; archive patch address
;
logdsk:		ds	1	; current logged-in disk number
; 
dest$dsk$num:	ds	1	; destination disk number
;
src$dsk$num:	ds	1	; source disk number
;
filcnt:		ds	1	; count of files in filetable
;
option:		ds	1	; storage for B, S, R or D option letter
;
destfcb:	ds	33	; destination disk file control block
;
bufmax:		ds	2	; buffer maximum size
;
bufcnt:		ds	2	; buffer sector count
;
bufpnt:		ds	2	; buffer pointer
;
eof$flg:	ds	1	; end-of-file flag
;
filetable	equ	$		; file table/buffer starts here
		ds	4*4096		; 16k buffer
table$end	equ	$		; file table/buffer ends here
; 
;
;
	end

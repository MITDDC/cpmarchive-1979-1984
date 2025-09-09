c
c		MODEM7-type program to send and
c		receive files with checksums or CRC and automatic
c		re-transmission of bad blocks.
c		translated to VAX Fortran V3.0 from TMODEM.C by
c		and enhanced according to time-outs and CRC
C		in XMODEM50.ASM
c		J.James Belonis II
c		Physics Hall FM-15
c		University of Washington
c		Seattle, WA 98195
c
c  1/17/83	touched up filename display and comments.
c  1/14/83	including timeouts and CTRL-X cancellation
c		and CRC capability
c
c  keeps a log file of error messages ( deletes it if no errors )
c  sets terminal driver to eightbit, passall
c  may need altypeahd if faster than 1200 baud works to 9600 baud at least.
c  needs PHY_IO privilege for passall ? apparently not on UWPhys VAX
c  nor on ACC VAX
c  many debugging statements left in as comments

c  declare variables
	include 'QIO.DCK'
	character*80 line, file
	byte sector(130), c, notc, checksumbyte, ck
	integer blocknumber, sloc, rloc, stat, inotc, ic
	integer notnotc, secbytes
	integer nakwait, testblock, testprev
	logical ttyinlim, charintime, getack, acked, firstsoh

	logical logdel
	common /logfile/logdel

	integer errorcount
	common /err/errorcount

	integer high,low
	common /crcval/high,low

	logical crc
	integer checksum
	common /checks/checksum,crc

	equivalence (checksum,checksumbyte)
	equivalence (ic,c)

c  define ascii characters
	parameter NUL=0		!ignore at SOH time
	parameter SOH=1		!start of header for sector
	parameter EOT=4		!end of transfer
	parameter ACK=6		!acknowlege sector
	parameter NAK=21	!not acknowlege sector
	parameter CAN=24	!cancel transfer
	parameter CRCCHAR='C'	!CRC indicating character

c  timeouts
	parameter respnaklim=10	!seconds to allow for response to NAK
	parameter naklim=10     !seconds to allow to receive first NAK
	parameter eotlim=10	!seconds to wait for EOT acknowlege

	parameter errlim=10	!max errors on a sector

c  define an exit routine to get control on all exits to turn off
c  passall and for debug cleanup
	external giveup
	call userex( giveup )

	print *,' XMODEM ver 5.0 on VAX [CRC capable]'
c  log file for debugging
	open(8,file='XMODEM.LOG',carriagecontrol='LIST',status='NEW')
c  assign terminal channel for QIO calls to send raw bytes.
	call sys$assign('TT',chan,,)

c  get command line
	call lib$get_foreign(line,'$_command: ',)
c  trim blanks
	do i=80,1,-1
		if(line(i:i).NE.' ') goto 25
		len=i
	enddo
  25	continue

c  send
	sloc=index(line,'S ')
	if(sloc.NE.0) then
		file=line(sloc+2:)
		len=len-2
		goto 50
	endif
c  receive with checksum
	rloc=index(line,'R ')
	if(rloc.NE.0) then
		file=line(sloc+2:)
		len=len-2
		crc=.false.
		secbytes=129
		goto 600
	endif
c  receive with CRC
	rcloc=index(line,'RC ')
	if(rcloc.NE.0) then
		file=line(sloc+3:)
		len=len-3
		crc=.true.
		secbytes=130
		goto 600
	endif

c  else bad command
	print *,' Invalid command.'
	print *,'    usage: xmodem  <s, r, or rc>  <file> '
	call exit

c  send file
  50	open(6,name=file(1:len),iostat=stat,status='OLD',READONLY)
c     1		carriagecontrol='NONE',recordtype='FIXED',recl=128)

	if(stat) then
		print *,'Can''t open',file(1:len),' for send.'
		call exit
	endif
	if(crc) then
		print *,' CRC mode'
	else
		print *,' Checksum mode'
	endif
	print *,file(1:len),' open, ready to send.  Run your receiver.'
	errorcount=0
	blocknumber=1

c  await first NAK (or 'C') indicating receiver is ready
  200	charintime=ttyinlim(c,1,naklim)		! return NUL if timeout
c	print *,' character=',c
	if( .NOT.charintime ) then
		nakwait=nakwait+1
c  give the turkey 80 seconds to figure out how to receive a file
		if(nakwait.EQ.80) call cancel
		goto 200
	elseif(c.EQ.NAK) then
		crc=.false.
	elseif(c.EQ.CRCCHAR) then
		crc=.true.
	elseif(c.EQ.CAN) then
		call cancel
	else
c  unrecognized character
		nakwait=nakwait+1
		if(nakwait.eq.80) call cancel
		goto 200
	endif
	
  300	continue
c  send new sector
	read(6,1000,end=500) (sector(i),i=1,128)
 1000	format(128a)
	errorcount=0
c	print *,' sector as read',sector
  400	continue
c  send sector
c	print *,' SOH '
	call ttyout(SOH,1)
	call ttyout(blocknumber,1)
	call ttyout( not(blocknumber),1 )
c	print *,' blocknumber=',blocknumber

	checksum=0
	call clrcrc
c  separate calls to slow down in case other end slow (can even introduce
c  delay between characters).
	do i=1,128
		call ttyout(sector(i),1)
	enddo
c  calc checksum or crc
	if(crc) then
c  put all bytes + two finishing zero bytes through updcrc
		sector(129)=0
		sector(130)=0
		call updcrc( sector,130 )
		call ttyout(high,1)
		call ttyout(low,1)
	else
		do i=1,128
			checksum=checksum+sector(i)
		enddo
c  this sends low order byte of checksum
		call ttyout(checksum,1)
c		print *,' checksum',checksum
	endif

c  sector sent, see if receiver acknowleges
c  function getack attempts to get ACK
c  if not, repeat sector
c	print*, ' should wait for ACK 10 seconds'
	call getack(acked)
c	print*, ' getack returned=',acked
	if(.NOT.acked) goto 400

c  ACK received, send next sector
	blocknumber=blocknumber+1
	goto 300

c  end of file during read.  finish up sending.
  500	continue
	call ttyout(EOT,1)
c  function getack attempts to get ACK up to errlim times
	call getack(acked)
	if( .NOT.acked ) goto 500

c	print *,' Sending complete.'
	call exit

c  receive file
  600	continue
	open(7,name=file(1:len),recl=128,status='NEW',iostat=stat,
     1		carriagecontrol='NONE',recordtype='FIXED')
	if(stat) then
		print *,' Can''t open ',file(1:len),' for recieve.'
		call exit
	endif

	print *,' Please send.'
	call passall(CHAN,.TRUE.)

	firstsoh=.false.
	errorcount=0
	blocknumber=1

c  start the sender by letting ttyinlim time-out in getack routine
c  so it sends a NAK or C
	goto 999

  800	continue
c	write(8,*) ' ready for SOH'
c  must allow enough time for other's disk read (xmodem50.asm allows 10 sec)
	charintime=ttyinlim(c,1,respnaklim)
c  if no char for a while, try NAK or C again
	if( .NOT.charintime ) then
c		print*,' no response to NAK or C, trying again'
		write(8,*) ' no response to NAK or C, trying again'
		goto 999
	endif
c  else received a char so see what it is
	if(c.eq.NUL) goto 800	! ignore nulls here for compatablity with old
				! versions of modem7
	if(c.EQ.CAN) then
		print *,' Canceled.  Aborting.'
		write(8,*) ' Canceled.  Aborting.'
		call exit
	endif
c	write(8,*) ' EOT or SOH character=',c
	if(c.NE.EOT) then
		IF(c.NE.SOH) then
			write(8,*) ' Not SOH, was decimal ',c
			goto 999
		endif
		firstsoh=.true.

c  character was SOH to indicate start of header
c  get block number and complement
		call ttyin(c,1)
c		write(8,*) ' block=',c

		call ttyin(notc,1)
c		write(8,*) ' block complement=',notc
		inotc=notc	! make integer for "not" function
		notnotc=iand( not(inotc),255 )	! mask back to byte

c  c is low order byte of ic via equivalence statement
		if(ic.NE.notnotc) then
			write(8,*) ' block check bad.'
			goto 999
		endif
c  block number valid but not yet checked against expected

c  clear checksum and CRC
		checksum=0
		call clrcrc

c  receive the sector and checksum bytes in one call (for speed).
c  secbytes is 129 for checksum, 130 for CRC
		call ttyin(sector,secbytes)

		if(crc) then
c  put data AND CRC bytes through updcrc
			call updcrc(sector,secbytes)
c  if result non-zero, BAD.
			if(iand(high,255).NE.0
	1		.OR.iand(low,255).NE.0) then
				write(8,*) ' CRC, high,low='
				write(8,3000) high,low
 3000				format(2z10)
				goto 999
			endif
		else
c  don't add received checksum byte to checksum
			do i=1,secbytes-1
				checksum=checksum+sector(i)
			enddo
			ck=sector(129)
c			write(8,2100) ck

c			write(8,2100) checksum
c			write(8,2100) checksumbyte
c2100			format(' checksum=',z10)
			if( checksumbyte.NE.ck ) then
				write(8,*) ' bad checksum'
				goto 999
			endif
		endif

c  received OK so we can believe the block number, see which block it was
c  mask it to be one byte
		testblock=iand(blocknumber,255)
		testprev=iand( blocknumber-1 ,255)
		if( ic.EQ.testprev) then
			write(8,*) ' prev. block again, out of synch'
c  already have this block so don't write it, but ACK anyway to resynchronize
			goto 985
		elseif( ic.NE.testblock ) then
			write(8,*) ' block number bad.'
			goto 999
		endif
c  else was expected block

c  write before acknowlege so not have to listen while write.
		write(7,2000,err=900) (sector(i),i=1,128)
 2000		format(128a)
		goto 975
  900		write(8,*) ' Can''t write sector. Aborting.'
		print*, ' Can''t write sector. Aborting.'
		call exit

  975		continue
c  recieved sector ok, wrote it ok, so acknowlege it to request next.
		blocknumber=blocknumber+1
c  comes here if re-received the previous sector
  985		continue
		errorcount=0
c		write(8,*) ' ACKing, sector was ok.'
		call ttyout(ACK,1)
		goto 800

c  else error so eat garbage in case out of synch and try again
  999		continue
		call eat
		write(8,*) ' receive error NAK, block=',blocknumber
		if(crc.AND..NOT.firstsoh) then
c  keep sending 'C'  'til receive first SOH
			call ttyout(CRCCHAR,1)
		else
			call ttyout(NAK,1)
		endif
		errorcount=errorcount+1
  998		if(errorcount.GE.errlim) then
			print*,' Unable to receive block. Aborting.'
			write(8,*) ' Not receive block. Aborting.'
c  delete incompletely received file
			close(7,dispose='DELETE')
			call exit
		endif
c  retry
		goto 800
	endif

c  EOT received instead of SOH so file done.
c  should keep sending ACK 'til no more EOT's ?
	close(6)
	close(7)
	call ttyout(ACK,1)
	call ttyout(ACK,1)
	call ttyout(ACK,1)

c	write(8,*) ' Completed.'
c	print *,   ' Completed.'
c  transfer ok, so delete the error log file.
	close(8,status='DELETE')
	call exit
	end
c-----------------------------------------------------------
	subroutine clrcrc
c  clears CRC
	integer high,low
	common /crcval/high,low

	high=0
	low=0
	return
	end
c-----------------------------------------------------------
	subroutine updcrc(bbyte,n)
	byte bbyte(*)
	integer n
c  updates the Cyclic Redundancy Code
c  uses x^16 + x^12 + x^5 + 1 as recommended by CCITT
c	and as used by CRCSUBS version 1.20 for 8080 microprocessor
c	and incorporated into the MODEM7 protocol of the CP/M user's group
c
c  during sending:
c  call clrcrc
c  call updcrc   for each byte
c  call fincrc   to finish (or just put 2 extra zero bytes through updcrc)
c  result to send is low byte of high and low in that order.
c
c  during reception:
c  call clrcrc
c  call updcrc   all bytes PLUS the two received CRC bytes must be passed
c       to this routine
c       then zero in high and low means good checksum
c
c  see Computer Networks, Andrew S. Tanenbaum, Prentiss-Hall, 1981
c
c  must declare integer to allow shifting
	integer byte
	integer high
	integer low
	common /crcval/high,low
	integer bit,bitl,bith

c	write(8,*) ' inside updcrc'
	do i=1,n
c		write(8,*) high,low,byte'
c		write(8,1000),high,low,bbyte
 1000		format(3z10)
		byte=bbyte(i)

		do j=1,8
c  get high bits of bytes so we don't lose them when shift
c  positive is left shift
			bit =ishft( iand(128,byte), -7)
			bitl=ishft( iand(128,low),  -7)
			bith=ishft( iand(128,high), -7)
c			write(8,*) 'bit,bitl,bith'
c			write(8,1000),bit,bitl,bith
c  get ready for next iteration
			newbyte=ishft(byte,1)
			byte=newbyte		! introduced dummy variable newb
yte
						! to avoid "access violation"
c			write(8,*) ' byte ready for next iteration'
c			write(8,1000),byte
c  shift those bits in
			low =ishft(low ,1)+bit
			high=ishft(high,1)+bitl
c			write(8,*),' high,low after shifting bits in'
c			write(8,1000),high,low

			if(bith.eq.1) then
				high=ieor(16,high)
				low=ieor(33,low)
c				write(8,*) ' high,low  after xor'
c				write(8,1000) high,low
			endif
		enddo
	enddo
	return
	end
c-----------------------------------------------------------
c	subroutine fincrc
c  finish CRC calculation for sending    result in high, low
c  merely runs updcrc with two  zero bytes
c	integer high,low
c	common /crcval/high,low
c
c	byte=0
c	call updcrc(byte)
c	call updcrc(byte)
c	return
c	end
c-----------------------------------------------------------
      SUBROUTINE TTYIN(LINE,N)
      BYTE LINE(*)
      INTEGER N
C              READ CHARACTERS FROM TERMINAL
C              MODIFIED BY BELONIS TO REMOVE PRIVILEGE
C              MAY HAVE PROBLEM WITH TYPE-AHEAD
c  should convert to time-out properly with loops in main ?
      INCLUDE 'QIO.DCK'
c      INCLUDE '($SSDEF)'
      parameter ss$_timeout='22c'x
      INTEGER I
      INTEGER SYS$QIOW
      INTEGER*4 terminators(2)

c      logical crc
c      integer checksum
c      common /checks/checksum,crc

      EXTERNAL IO$M_NOECHO,IO$_TTYREADALL,IO$M_TIMED
      DATA terminators/0,0/
C
	write(8,*) ' inside ttyin, N=',N
      I = SYS$QIOW(,           !EVENT FLAG
     -              %VAL(CHAN),         !CHANNEL
     -              %VAL(%LOC(IO$_TTYREADALL).OR.
     -                   %LOC(IO$M_NOECHO)),	     !   .OR.%LOC(IO$M_TIMED)),
     -              STATUS,,,
     -              LINE,       !BUFFER
     -              %VAL(N),	!LENGTH
     -              ,		! max time   beware other disk time
     -				!            and Quit or Retry time
     -              terminators,,)  !no terminators
c      if(crc) then
c         write(8,1000) (LINE(j),j=1,N)
c         write(8,*) ' status=',STATUS
c      else
c         write(8,2000) (line(j),j=1,N)
c         write(8,*) ' status=',status
c      endif
 1000 format(' ttyin=',6(20z3/),10z3)
 2000 format(' ttyin=',6(20z3/),9z3)
c      if(STATUS(1).EQ.SS$_TIMEOUT) THEN
c         write(8,*) ' 10 second timeout in ttyin'
c         print*,    ' 10 second timeout in ttyin'
c         call exit
c      endif

      IF (I) THEN
c        write(8,*) ' returning from ttyin'
         return
      endif
C
C              ERROR
      write(8,*) ' ttyin error.'
      CALL SYS$EXIT( %VAL(I) )
      END
c-----------------------------------------------------------
	subroutine eat
c  eats extra characters 'til 1 second pause   used to re-synch after error
	byte buffer(135)
	integer numchar
	logical i,ttyinlim
c
	parameter maxtime=1
c  in case mis-interpreted header, allow at least 1 block of garbage
	numchar=135

	i=ttyinlim(buffer,numchar,maxtime)
c	print*,' finished eating'
c	write(8,*) ' finished eating'
	return
	end
c-----------------------------------------------------------
      LOGICAL FUNCTION TTYINLIM(LINE,N,LIMIT)
      BYTE LINE(*)
      INTEGER N,LIMIT
C              READ CHARACTERS FROM TERMINAL
C              WITH TIME LIMIT, RETURN FALSE IF NO CHARACTERS
C              RECEIVED FOR LIMIT SECONDS
C              MODIFIED BY BELONIS TO REMOVE PRIVILEGE PROBLEM
C              MAY HAVE PROBLEM WITH TYPE-AHEAD
      INCLUDE 'QIO.DCK'
c      INCLUDE '($SSDEF)'	! defines error status returns
      parameter ss$_timeout='22c'x
      INTEGER I
      INTEGER SYS$QIOW
      INTEGER*4 terminators(2)
      EXTERNAL IO$M_NOECHO,IO$_TTYREADALL,IO$M_TIMED
      DATA TERMINATORS/0,0/
C
c	write(8,*) ' inside ttyinlim'
      TTYINLIM=.TRUE.          ! DEFAULT no delay over LIMIT seconds
      I = SYS$QIOW(,           !EVENT FLAG
     -              %VAL(CHAN),         !CHANNEL
     -              %VAL(%LOC(IO$_TTYREADALL).OR.
     -                   %LOC(IO$M_NOECHO).OR.%LOC(IO$M_TIMED)),
     -              STATUS,,,
     -              LINE,       !BUFFER
     -              %VAL(N),   !LENGTH
     -              %VAL(LIMIT),    !time limit in seconds
     -              terminators,,)  !no terminators
c     print*,' ttyinlim=',(LINE(j),j=1,N), ' STATUS=',STATUS
c     write(8,*) ' ttyinlim=',(LINE(j),j=1,N), ' STATUS=',STATUS
      if(STATUS(1).EQ.SS$_TIMEOUT) THEN
         TTYINLIM=.FALSE.
         write(8,*) ' timeout'
         return
      ENDIF

      IF (I) THEN
c        write(8,*) ' returning from ttyinlim'
         return
      endif
C
C              ERROR
      write(8,*) ' ttyinlim error.'
      CALL SYS$EXIT( %VAL(I) )
      END
c-----------------------------------------------------------
      SUBROUTINE TTYOUT(LINE,N)
      BYTE LINE(*)
      INTEGER*2 N
C  output N characters without interpretation
      INCLUDE 'QIO.DCK'
      INTEGER I
      INTEGER SYS$QIOW
      EXTERNAL IO$M_NOFORMAT
      EXTERNAL IO$_WRITEVBLK
C
      IF ( N.LE.0 ) RETURN
C
c	print *, ' to be sent by ttyout ', line(1)
      I = SYS$QIOW(,
     -              %VAL(CHAN),
     -              %VAL(%LOC(IO$_WRITEVBLK).OR.
     -                   %LOC(IO$M_NOFORMAT)),
     -              STATUS,,,
     -              LINE,
     -              %VAL(N),,
     -              %VAL(0),, )         !NO CARRIAGE CONTROL
      if(I) then
         return
      endif
C
C              ERROR
      write(8,*) ' ttyout error.'
      CALL SYS$EXIT( %VAL(I) )
      END
c--------------------------------------------------
	subroutine giveup
c  this exit routine used especially in case exited via QIO problem
	include 'qio.dck'

c  note: if want log file message, must re-open since
c  system already closed all files before this exit handler got control
c	open(8,file='XMODEM.LOG',access='APPEND')
c	write(8,*) ' Exit handler.'

c  turn off passall
	call passall(CHAN,.FALSE.)
	return
	end
c-----------------------------------------------------
	SUBROUTINE PASSALL(CHAN,SWITCH)
C  sets PASSALL mode for terminal connected to chanel CHAN, ON if switch true
	IMPLICIT INTEGER (A-Z)
c	INCLUDE '($TTDEF)'
	parameter tt$m_passall=1
	parameter tt$m_eightbit='8000'x
	parameter io$_sensemode='27'x
	parameter io$_setmode='23'x
c	INCLUDE '($IODEF)'
	LOGICAL SWITCH
	COMMON/CHAR/CLASS,TYPE,WIDTH,CHARAC(3),LENGTH	!byte reversed LENGTH
	BYTE CLASS,TYPE,CHARAC,LENGTH
	INTEGER*2 WIDTH,SPEED
	EQUIVALENCE(CHARACTER,CHARAC)

c  sense current terminal driver mode
	ISTAT=SYS$QIOW(,%VAL(CHAN),%VAL(IO$_SENSEMODE),,,,
	1 CLASS,,,,,)
	IF (.NOT.ISTAT) CALL ERROR('TERMINAL SENSEMODE',ISTAT)

	IF(SWITCH) THEN
c  turn on 8 bit passall
		CHARACTER=CHARACTER.OR.TT$M_PASSALL.OR.
	1				TT$M_EIGHTBIT
	ELSE
c  turn off 8 bit passall
		CHARACTER=CHARACTER.AND..NOT.TT$M_PASSALL.AND.
	1                               .NOT.TT$M_EIGHTBIT
	ENDIF
	SPEED=0	!LEAVE SPEED UNCHANGED
	PAR=0	!LEAVE PARITY UNCHANGED

c  set terminal mode with desired passall
	ISTAT=SYS$QIOW(,%VAL(CHAN),%VAL(IO$_SETMODE),,,,
	1               CLASS,,%VAL(SPEED),,%VAL(PAR),)
	IF (.NOT.ISTAT) CALL ERROR('TERMINAL SETMODE',ISTAT)
	RETURN
	END
c---------------------------------------------------
	SUBROUTINE ERROR(STRING,MSGID)
c		Types error message
	IMPLICIT INTEGER(A-Z)
	CHARACTER*(*) STRING
	CHARACTER*80 MESSAGE

	TYPE *,' *** ERROR: ',STRING
	write(8,*) ' *** ERROR: ',STRING
	CALL SYS$GETMSG(%VAL(MSGID),MSGLEN,MESSAGE,%VAL(15),)
	TYPE *,MESSAGE(1:MSGLEN),CRLF
	write(8,*) MESSAGE(1:MSGLEN),CRLF
	RETURN
	END
c-----------------------------------------------------------
	subroutine cancel
	INCLUDE 'QIO.DCK'
c  called to cancel send (at least)
	logical charintime,ttyinlim
	byte c
	parameter CAN=24
	parameter SPACE=32

c  eat garbage
  100	charintime=ttyinlim(c,1,1)
	if(.NOT.charintime) goto 100
c  cancel other end
	call ttyout(CAN,1)

c  eat garbage in case it didn't understand ?
  200	charintime=ttyinlim(c,1,1)
	if(.NOT.charintime) goto 200
c  clear the CAN from far end's input  ???? why ? xmodem50.asm does it
	call ttyout(SPACE,1)

c	print*,' XMODEM program canceled'
	write(8,*)' XMODEM program canceled'
	call exit
	end
c------------------------------------------------------
	subroutine getack(acked)
c  returns .TRUE. if gets ACK
	logical charintime, ttyinlim, acked
	byte sector(130),c

	integer errorcount
	common /err/errorcount

	parameter ACK=6
	parameter errlim=10	! max number of errors
	parameter eotlim=10	! seconds to wait for eot

c	print*,' inside getack'
c  empty typeahead in case garbage
c	charintime=ttyinlim(sector,130,0)
c  allow time for file close at other end.
	charintime=ttyinlim(c,1,eotlim)
c	print*,' getack got',c
	if( .NOT.charintime .OR. c.NE.ACK ) then
c		print*, ' not ACK, decimal=',c
		write(8,*) ' not ACK, decimal=',c
		errorcount=errorcount+1
		if(errorcount.GE.errlim) then
			write(8,*) ' not acknowleged in 10 tries.'
			print*,' Can''t send sector. Aborting.'
			call exit
		endif
		acked=.FALSE.
	else
c  received ACK
		acked=.TRUE.
	endif
	return
	end


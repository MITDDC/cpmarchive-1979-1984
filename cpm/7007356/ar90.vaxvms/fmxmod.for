
	program fromxmod
c  convert file of XMODEM 128 byte records with embedded <CR><LF>
c  marking end-of-line and CTRL-Z marking end-of-file
c  to carriage-control=LIST (normal VAX editable file)
c  6/21/83 increased output line buffer to 300 characters.

	character*300 line
	character*254 input,output
	character*1 CR,LF,recchar
	integer blank
	logical eof
	data eof/.false./

	CR=char(13)
	LF=char(10)
	call lib$get_foreign(line,'$_From  To: ',)

	blank=index(line,' ')
	input=line( 1:blank )
	output=line( blank:)

	open(6,file=input,status='OLD')
c  set maximum output record length to 300 (fortran default is 133)
	open(7,file=output,status='NEW',carriagecontrol='LIST',recl=300)

c  getchar (read new record if no input characters left)
c  if EOF on input, write line and exit
c  if CR then
c    if getchar LF then write line
c    else put back char and putchar CR into line (error if too long)
c    endif
c  else putchar (write error message if line too long)
c  endif
c  loop

  100	call getchar(recchar,eof)
	if(eof) goto 200
	if(recchar.eq.CR) then
c	PRINT *,' CR'
		call getchar(recchar,eof)
		if(eof.or.recchar.ne.LF) then
			call putback
			
			len=len+1
			if(len.gt.301) print *,' Out line too long.'
c	print*,' too long line=',line
			line(len:len)=recchar
		else
c  was LF
c	PRINT *,' LEN=',LEN
c	print*,' after LF, line=',line(1:len)
			write(7,2000) line(1:len)
			len=0
		endif
	else
c  not CR, was "ordinary" character
		len=len+1
		if(len.gt.301) then
			print *,' Out line too long.'
c			PRINT *,' LINE=',LINE(1:len)
		endif
		line(len:len)=recchar
	endif

	go to 100

c  flush last line and exit
  200	continue
	if(len.ne.0) then
		write(7,2000) line(1:len)
 2000		format(a)
	endif
	close(6)
	close(7)
	call exit

  	end
c------------------------------------------
	subroutine getchar(c,eof)
	character*1 c
	logical eof
c  point to next character in record (read record if necessary)
	character*128 record
	character*1 CTRLZ
	integer point
	logical firsttime
	common /reccom/point,record,firsttime
	data point/0/
	data firsttime/.true./

	CTRLZ=char(26)
	point=point+1
	if(point.gt.128.or.firsttime) then
		firsttime=.false.
  100		read(6,1000,end=200) record
 1000		format(a)
c		PRINT *,RECORD
		point=1
	endif
c  strip parity in case CP/M file had it
	c=char(iand(ichar(record(point:point)),127))
	if(c.eq.CTRLZ) eof=.true.
	return

  200	eof=.true.
	return
	end
c----------------------------------------------
	subroutine putback
c  point to previous input character so this character will be getchar result
c  even works if 1st char of record
	integer point
	logical eof
	common /reccom/point

	point=point-1
	return
	end

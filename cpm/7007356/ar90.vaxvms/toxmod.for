
	program toxmodem
c  convert VAX text file to
c  file of XMODEM 128 byte records with embedded <CR><LF>

	character*254 line,input,output
	character*1 CR,LF,c
	integer blank
	logical eof,eol
	data eof,eol/.false.,.false./

	CR=char(13)
	LF=char(10)
	call lib$get_foreign(line,'$_From  To: ',)

	blank=index(line,' ')
	input=line( 1:blank )
	output=line( blank:)

	open(6,file=input,status='OLD')
	open(7,file=output,status='NEW',carriagecontrol='LIST',
	1                  recl=128,recordtype='FIXED')

c  getchar (read new line if no input characters left)
c  putchar ( output record if full, close if EOF )
c  if EOL on input, putchar CR putchar LF (output record if full)
c  loop

  100	call getchar(c,eof,eol)
	if(.not.eol) then
		call putchar(c,eof)
	else
c  end of line
		call putchar(CR,eof)
		call putchar(LF,eof)
		eol=.false.
	endif
	go to 100

  	end
c-------------------------------------------
	subroutine getchar(inchar,eof,eol)
	character*1 inchar
	logical eof,eol
c  get character from input line (read line if necessary)
c  returns character and eol=.true. if no more char on line
c  returns eof if end of file (no character)
	character*255 line
	integer len, pos
	logical firsttime
	common/lincom/pos,len,line
	data pos/0/

	if(pos.eq.0) then
		read(6,1000,end=100)len,line(1:len)
 1000		format(q,a)
c		print*,' line=',line
	endif
	pos=pos+1
	if(pos.gt.len) then
		eol=.true.
		pos=0
		return
	endif
c	print*,' pos=',pos,' line(1:pos)=',line(1:pos)
c	print*,' line(pos:pos)=',line(pos:pos)
	inchar=line(pos:pos)
c	print*,' pos,char',pos,inchar
	return

c  EOF
  100	continue
	eof=.true.
	return
	end
c------------------------------------------
	subroutine putchar(c,eof)
	character*1 c
	logical eof
c  put character into record (write record if necessary)
c  if eof, fills out rest of record with CTRL-Z's and exits
	character*1 CTRLZ
	character*128 record
	integer point
	common /reccom/point,record
	data point/0/

	if(eof) goto 200
	point=point+1
c  strip parity in case VAX file had it
	record(point:point)=char(iand(ichar(c),127))
c	print*,' record(point:point)=',record(point:point)
c	print*,' point=',point
   50	if(point.ge.128) then
c		print*,' record=',record
  100		write(7,1000) record
 1000		format(a)
		point=0
	endif
	return		

c  EOF fill record with 26's (CTRL-Z, CP/M end of file mark for ASCII)
c  output last record and exit
  200	continue
c	print*,' in putchar EOF section'
	CTRLZ=char(26)
	do i=point+1,128
		record(i:i)=CTRLZ
	enddo
c	print*,' record=',record
	write(7,1000) record
	close(6)
	close(7)
	call exit
	end

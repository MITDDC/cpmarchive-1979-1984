
PROGRAM modem;
      {Written by Jack M. Wierda  Chicago Illinois
      This program is in the public domain.

      LANGUAGE: UCSD Pascal
      FILES:    MODEM3.PAS -- main program
                MDM3-Z80IO.Z80 -- serial line interface for Z80
                MDM3-8080IO.Z80 -- serial line interface for Intel 8080

      This program is basically a re-write in PASCAL of Ward Christensen's
Modem Program which was distributed in CP/M User's Group Volume 25. Identical
and compatible options are provided to allow this program to work directly
with Ward's program running under CP/M. One difference is that when sending
files the PASCAL or CP/M transfer mode must be selected. The PASCAL mode
transfers files between two systems running PASCAL, while the CP/M mode is
used when the receiving system is running CP/M. Basically the CP/M mode
provides the linefeeds required to make a PASCAL file compatible with CP/M.
When CP/M files are received they contain linefeeds, these can be deleted
using the editor to make the file compatible with PASCAL. CP/M files may also
contain tabs which the PASCAL editor does not expand.
      External assembly language routines are used to read the status, and read
or write the keyboard and modem ports. These routines are available as
separate files for the 8080 and Z80 processors. The port and flag definitions,
and the timing constant for the one second delay should be changed as required
for your particular hardware.
      The program has been tested with text files only, and may not work
correctly for code or other types of files.
      The PDP-10 mode transfers PASCAL files to a DEC SYSTEM-10 computer.}

CONST 
      nul = 0;
      soh = 1;
      ctrlc = 3;
      eot = 4;
      errormax = 5;
      retrymax = 5;
      ctrle = 5;
      ack = 6;
      tab = 9;
      lf = 10;
      cr = 13;
      ctrlq = 17;
      ctrls = 19;
      nak = 21;
      ctrlz = 26;
      space = 32;
      delete = 127;
      lastbyte = 127;
      timeout = 256;
      loopspersec = 1800       {1800 LOOPS PER SECOND AT 4MHZ};
      kbsp = 0           {KEYBOARD STATUS PORT};
      kbdrf = 128        {KEYBOARD DATA READY FLAG};
      kbdp = 1           {KEYBOARD DATA PORT};
      kbmask = 127       {KEYBOARD DATA MASK};
      dchdp = 128        {D. C. HAYES DATA PORT};
      dchmask = 255      {D. C. HAYES DATA MASK};
      dchsp = 129        {D. C. HAYES STATUS PORT};
      {STATUS PORT BIT ASSIGNMENTS}
      rrf     =    1   {RECEIVE REGISTER FULL};
      tre     =    2   {TRANSMIT REGISTER EMPTY};
      perr    =    4   {PARITY ERROR};
      ferr    =    8   {FRAMING ERROR};
      oerr    =    16  {OVERFLOW ERROR};
      cd      =    64  {CARRIER DETECT};
      nri     =    128 {NO RINGING INDICATOR};
      dchcp1 = 129       {D. C. HAYES CONTROL PORT 1};
      {CONTROL PORT 1 BIT ASSIGNMENTS}
      epe     =    1   {EVEN PARITY ENABLE};
      ls1     =    2   {LENGTH SELECT 1};
      ls2     =    4   {LENGTH SELECT 2};
      sbs     =    8   {STOP BIT SELECT};
      pi      =    16  {PARITY INHIBIT};
      dchcp2 = 130       {D. C. HAYES CONTROL PORT 2};
      {CONTROL PORT 2 BIT ASSIGNMENTS}
      brs     =    1   {BIT RATE SELECT};
      txe     =    2   {TRANSMIT ENABLE};
      ms      =    4   {MODE SELECT};
      es      =    8   {ECHO SUPPRESS};
      st      =    16  {SELF TEST};
      rid     =    32  {RING INDICATOR DISABLE};
      oh      =    128 {OFF HOOK};

VAR file1 : text;
    option, hangup, return, mode, baudrate, display, filemode : char;
    sector : ARRAY[0..lastbyte] OF integer;
    dchcw2 : integer;
    ovrn1, ovrn2, showrecv, showtrans : boolean;

FUNCTION stat(port,exr,mask:integer): boolean;
external;

FUNCTION input(port,mask:integer): integer;
external;

PROCEDURE output(port,data:integer);
external;

PROCEDURE sendline(sldata:integer);
BEGIN
  REPEAT
  UNTIL stat(dchsp,tre,tre);
  output(dchdp,sldata);
  IF showtrans
  THEN
    IF (sldata = cr) OR ((sldata >= space) AND (sldata <= delete))
    THEN
      write(chr(sldata))
END;

FUNCTION readline(seconds:integer): integer;

VAR j : integer;
BEGIN
  j := loopspersec * seconds;
  REPEAT
    j := j-1
  UNTIL (stat(dchsp,rrf,rrf)) OR (j = 0);
  IF j = 0
  THEN
    readline := timeout
  ELSE
    BEGIN
      j := input(dchdp,dchmask);
      IF showrecv
      THEN
	IF (j = cr) OR ((j >= space) AND (j <= delete))
	THEN
	  write(chr(j));
      readline := j
    END
END;

PROCEDURE sendstr(str:string);

VAR j: integer;
BEGIN
  FOR j := 1 TO length(str) DO
    sendline(ord(str[j]))
END;

FUNCTION uppercase(ch : char) : char;
BEGIN
  IF ch IN ['a'..'z']
  THEN
    uppercase := chr(ord(ch)-space)
  ELSE
    uppercase := ch
END;

PROCEDURE purgeline;

VAR j : integer;
BEGIN
  REPEAT
    j := input(dchdp,dchmask)      {PURGE THE RECEIVE REGISTER};
  UNTIL NOT stat(dchsp,rrf,rrf)
END;

PROCEDURE dchinitialize;
BEGIN
  writeln('Waiting for carrier');
  REPEAT
    BEGIN
      IF option IN ['R','S']
      THEN
	BEGIN
	  output(dchcp1,pi+ls2+ls1);
	  output(dchcp2,oh+rid+txe+dchcw2)
	END;
      IF option IN ['C','P','T']
      THEN
	BEGIN
	  output(dchcp1,ls2+epe);
	  output(dchcp2,oh+rid+txe+dchcw2)
	END
    END
  UNTIL (stat(dchsp,cd,cd)) OR (input(kbdp,kbmask) = ctrle);
  purgeline;
  writeln('Carrier detected')
END;

PROCEDURE makesector;

VAR j : integer;
    ch : char;
BEGIN
  j := 0;
  IF ovrn1
  THEN
    BEGIN
      sector[j] := cr;
      j := j+1
    END;
  IF ovrn2
  THEN
    BEGIN
      sector[j] := lf;
      j := j+1
    END;
  ovrn1 := false;
  ovrn2 := false;
  WHILE (NOT eof(file1)) AND (j <= lastbyte) DO
    BEGIN
      WHILE (NOT eoln(file1)) AND (j <= lastbyte) DO
	BEGIN
	  read(file1,ch);
	  IF ord(ch) <> lf
	  THEN
	    BEGIN
	      sector[j] := ord(ch);
	      j := j+1
	    END
	END;
      IF eoln(file1)
      THEN
	BEGIN
	  readln(file1);
	  IF filemode IN ['P']
	  THEN
	    IF j <= lastbyte
	    THEN
	      BEGIN
		sector[j] := cr;
		j := j+1
	      END
	    ELSE
	      ovrn1 := true
	  ELSE
	    BEGIN
	      IF j <= (lastbyte-1)
	      THEN
		BEGIN
		  sector[j] := cr;
		  sector[j+1] := lf;
		  j := j+2
		END
	      ELSE
		IF j = lastbyte
		THEN
		  BEGIN
		    sector[j] := cr;
		    j := j+1;
		    ovrn1 := true
		  END
		ELSE
		  IF j > lastbyte
		  THEN
		    BEGIN
		      ovrn1 := true;
		      ovrn2 := true
		    END
	    END
	END
    END;
  CASE filemode OF
    'P' : IF j <= lastbyte
	  THEN
	    FOR j := j TO lastbyte DO
	      sector[j] := space;
    'C' : IF j <= lastbyte
	  THEN
	    FOR j := j TO lastbyte DO
	      sector[j] := ctrlz
  END
END;

PROCEDURE termcomp;

VAR kbdata, dchdata : integer;
    crflag : boolean;
BEGIN
  crflag := false;
  dchinitialize;
  WHILE stat(dchsp,cd,cd) AND (kbdata <> ctrle) DO
    BEGIN
      IF stat(kbsp,kbdrf,kbdrf)
      THEN
	BEGIN
	  kbdata := input(kbdp,kbmask);
	  IF option IN ['C']
	  THEN
	    write(chr(kbdata));
	  output(dchdp,kbdata)
	END;
      IF stat(dchsp,rrf,rrf)
      THEN
	BEGIN
	  dchdata := input(dchdp,dchmask);
	  IF option IN ['C']
	  THEN
	    output(dchdp,dchdata);
	  IF dchdata = cr
	  THEN
	    crflag := true;
	  IF (dchdata = lf) AND crflag
	  THEN
	    crflag := false
	  ELSE
	    write(chr(dchdata))
	END
    END
END;

PROCEDURE pdp10;

VAR wait10 : boolean;
    dchdata : integer;
    ch : char;
    filename, pdp10file : string;
BEGIN
  showrecv := false;
  showtrans := true;
  wait10 := false;
  write('Filename.Ext ? ');
  readln(filename);
  reset(file1,filename);
  IF option IN ['P']
  THEN
    BEGIN
      write('PDP-10 Filename.Ext ? ');
      readln(pdp10file);
      dchinitialize;
      sendline(cr);
      sendstr('R PIP');
      sendline(cr);
      REPEAT
      UNTIL readline(5) IN [ord('*'),timeout];
      sendstr(pdp10file);
      sendstr('=TTY:');
      sendline(cr)
    END
  ELSE
    BEGIN
      write('UNIX Filename.Ext ? ');
      readln(pdp10file);
      dchinitialize;
      sendline(cr);
      sendstr('cat > ');
      sendstr(pdp10file);
      sendline(cr)
    END;
  WHILE (NOT eof(file1)) AND (stat(dchsp,cd,cd)) DO
    BEGIN
      WHILE NOT eoln(file1) DO
	BEGIN
	  IF NOT wait10
	  THEN
	    BEGIN
	      read(file1,ch);
	      sendline(ord(ch))
	    END;
	  IF stat(dchsp,rrf,rrf)
	  THEN
	    BEGIN
	      dchdata := input(dchdp,dchmask);
	      IF dchdata = ctrls
	      THEN
		wait10 := true;
	      IF dchdata = ctrlq
	      THEN
		wait10 := false
	    END
	END;
      readln(file1);
      sendline(cr)
    END;
  close(file1);
  REPEAT
  UNTIL readline(1)=timeout;
  IF option IN ['P']
  THEN
    BEGIN
      sendline(ctrlz);
      sendline(ctrlc);
    END
  ELSE
    BEGIN
      sendline(eot)
    END;
  termcomp
END;

PROCEDURE sendfile;

VAR j, k, sectornum, counter, checksum : integer;
    filename : string;
BEGIN
  write('Filename.Ext ? ');
  readln(filename);
  reset(file1,filename);
  sectornum := 1;
  dchinitialize;
  ovrn1 := false;
  ovrn2 := false;
  REPEAT
    counter := 0;
    makesector;
    REPEAT
      writeln;
      writeln('Sending sector ', sectornum);
      sendline(soh);
      sendline(sectornum);
      sendline(-sectornum-1);
      checksum := 0;
      FOR j := 0 TO lastbyte DO
	BEGIN
	  sendline(sector[j]);
	  checksum := (checksum + sector[j]) MOD 256
	END;
      sendline(checksum);
      purgeline;
      counter := counter + 1;
    UNTIL (readline(10) = ack) OR (counter = retrymax);
    sectornum := sectornum + 1
  UNTIL (eof(file1)) OR (counter = retrymax);
  IF counter = retrymax
  THEN
    BEGIN
      writeln;
      writeln('No ACK on sector')
    END
  ELSE
    BEGIN
      counter := 0;
      REPEAT
	sendline(eot);
	counter := counter + 1
      UNTIL (readline(10) = ack) OR (counter = retrymax);
      IF counter = retrymax
      THEN
	BEGIN
	  writeln;
	  writeln('No ACK on EOT')
	END
      ELSE
	BEGIN
	  writeln;
	  writeln('Transfer complete')
	END
    END;
  close(file1)
END;

PROCEDURE readfile;

VAR j, firstchar, sectornum,sectorcurrent, sectorcomp, errors,
    checksum : integer;
    errorflag : boolean;
    filename : string;
BEGIN
  write('Filename.Ext ? ');
  readln(filename);
  rewrite(file1,filename);
  sectornum := 0;
  errors := 0;
  dchinitialize;
  sendline(nak);
  sendline(nak);
  REPEAT
    errorflag := false;
      REPEAT
	firstchar := readline(20)
      UNTIL firstchar IN [soh,eot,timeout];
    IF firstchar = timeout
    THEN
      BEGIN
	writeln;
	writeln('SOH error');
      END;
    IF firstchar = soh
    THEN
      BEGIN
	sectorcurrent := readline(1);
	sectorcomp := readline(1);
	IF (sectorcurrent+sectorcomp)=255
	THEN
	  BEGIN
	    IF (sectorcurrent=sectornum+1)
	    THEN
	      BEGIN
		checksum := 0;
		FOR j := 0 TO lastbyte DO
		  BEGIN
		    sector[j] := readline(1);
		    checksum := (checksum+sector[j]) MOD 256
		  END;
		IF checksum=readline(1)
		THEN
		  BEGIN
		    FOR j := 0 TO lastbyte DO
		      write(file1,chr(sector[j]));
		    errors := 0;
		    sectornum := sectorcurrent;
		    IF display <> 'R'
		    THEN
		      BEGIN
			writeln;
			writeln('Received sector ',sectorcurrent)
		      END;
		    sendline(ack)
		  END
		ELSE
		  BEGIN
		    writeln;
		    writeln('Checksum error');
		    errorflag := true
		  END
	      END
	    ELSE
	      IF (sectorcurrent=sectornum)
	      THEN
		BEGIN
		  REPEAT
		  UNTIL readline(1)=timeout;
		  writeln;
		  writeln('Received duplicate sector ', sectorcurrent);
		  sendline(ack)
		END
	      ELSE
		BEGIN
		  writeln;
		  writeln('Synchronization error');
		  errorflag := true
		END
	  END
	ELSE
	  BEGIN
	    writeln;
	    writeln('Sector number error');
	    errorflag := true
	  END
      END;
    IF (errorflag=true)
    THEN
      BEGIN
	errors := errors+1;
	REPEAT
	UNTIL readline(1)=timeout;
	sendline(nak)
      END;
  UNTIL (firstchar IN [eot,timeout]) OR (errors = errormax);
  IF (firstchar = eot) AND (errors < errormax)
  THEN
    BEGIN
      sendline(ack);
      close(file1,lock);
      writeln;
      writeln('Transfer complete')
    END
  ELSE
    BEGIN
      close(file1);
      writeln;
      writeln('Aborting')
    END
END;
BEGIN
  writeln('Modem, 7-July-79');
  REPEAT
    REPEAT
      write('Option : C(omputer), P(DP-10), R(eceive), S(end), T(erminal)');
      write(', U(nix) ? ');
      read(option);
      option := uppercase(option);
      writeln
    UNTIL option IN ['C','P','R','S','T','U'];
    REPEAT
      write('Mode : A(nswer), O(riginate) ? ');
      read(mode);
      mode := uppercase(mode);
      writeln
    UNTIL mode IN ['A','O'];
    IF mode IN ['O']
    THEN
      dchcw2 := ms
    ELSE
      dchcw2 := 0;
    REPEAT
      write('Baud rate : 1(00), 3(00) ? ');
      read(baudrate);
      writeln
    UNTIL baudrate IN ['1','3'];
    IF baudrate='3'
    THEN
      dchcw2 := dchcw2+brs;
    IF option IN ['R','S']
    THEN
      BEGIN
	REPEAT
	  write('Display : N(o), R(eceived), T(ransmitted) data ? ');
	  read(display);
	  display := uppercase(display);
	  writeln
	UNTIL display IN ['N','R','T'];
	IF option = 'S'
	THEN
	  BEGIN
	    REPEAT
	      write('File mode : C(pm), P(ascal) ? ');
	      read(filemode);
	      filemode := uppercase(filemode);
	      writeln
	    UNTIL filemode IN ['C','P']
	  END;
	CASE display OF
	  'N': BEGIN
		 showrecv := false;
		 showtrans := false
	       END;
	  'R': BEGIN
		 showrecv := true;
		 showtrans := false
	       END;
	  'T': BEGIN
		 showrecv := false;
		 showtrans := true
	       END
	END
      END;
    CASE option OF
      'C': termcomp;
      'P': pdp10;
      'R': readfile;
      'S': sendfile;
      'T': termcomp;
      'U': pdp10
    END;
    REPEAT
      writeln;
      write('Hangup : Y(es), N(o) ? ');
      read(hangup);
      hangup := uppercase(hangup);
      writeln
    UNTIL hangup IN ['Y','N'];
    IF hangup IN ['Y']
    THEN
      output(dchcp2,0);
    REPEAT
      writeln;
      write('Return to system : Y(es), N(o) ? ');
      read(return);
      return := uppercase(return);
      writeln
    UNTIL return IN ['Y','N'];
  UNTIL return IN ['Y']
END
.

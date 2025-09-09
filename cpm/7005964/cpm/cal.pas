program calendar;
{*************************************************************************
Program:  CALENDAR
Author:  Richard Conn
Date:  23 Jan 82

Description:
	CALENDAR is used to display a Calendar to the user.  The
Calendar may be that of a particular Month in a particular Year
or that of all Months in a Particular Year.
	The Calendar display may be sent to the user's Console
(by default) or optionally to the user's LST: device or a disk file.

Usage:
		calendar [month] year [/o]
	where
		month may be one of january, february, ..., december
			(optional and only first three letters are req'd)
		year may be any year between byear and byear+88, inclusive
		o may be one of the following --
			p - send output to Printer
			d - send output to Disk
			(o is optional and defaults to Console if omitted)

Examples:
		CALENDAR JANUARY 1982 -- Calendar of Month of January of 1982
		CALENDAR JAN 1982 -- Same as Above
		CALENDAR 1982 -- Calendar of all months of 1982
		CALENDAR 1982 /P -- Same as Above but Output to Printer
		CALENDAR 1982 /D -- Same as Above but Output to Disk
		CALENDAR 1982 /P/D -- Same as Above but Output to Disk
			(Disk has priority)
*****************************************************************************}

{***************************************************************************

	'version' is the Version Number of CALENDAR.
	'byear' is the Base Year of CALENDAR.  This year MUST be a Leap
Year.  Since CALENDAR uses integer arithmetic to do its calculations,
the range of years that may be addressed by CALENDAR is from byear to
byear+88.
	'bday' is the Base Day of CALENDAR.  This is the number (1 to 7)
of the First Sunday in January of the Base Year.

****************************************************************************}
const
	version = 10;
	byear = 1980;  { Base Year for this program }
	bday = 6;      { Base Day for the Base Year }

{***********************************************
	Global Types and Variables
************************************************}
type
	strptr = ^string;
var
	ofile : text;
	filename : string[14];
	month1, year1, dow : integer;
	mposfnd, mpos, ypos : integer;
	mdays : array [1..12] of integer;
	month : array [1..12] of string[10];
	year : string;
	command : strptr;
	cmdline, yline : string;
	lyear : boolean;
	icount : integer;
	ver1, ver2 : integer;
	match, conout, diskout : boolean;

{****************************************************
	External PASCAL/MT+ System Functions
*****************************************************}
external function @cmd : strptr;

{**************************************************************************
	Function:  day_count
		Computes the number of days since the beginning of the year.
		(Jan 1 = Day 0)
	Input Parameters:
		day: integer in range 1-31
		month: integer in range 1-12
		year: integer
		mdays[i, 1<=i<=12 ]: number of days in month i, i=1=January
			(Global Parameter)
	Output Parameters:
		day_count: Number of days since 1st day of year (0=1st day)
***************************************************************************}
function day_count (day, month, year : integer) : integer;
var
	ndays, i : integer;
begin
	ndays := day - 1;  { Adjust for first day being day 0}
	if month <> 1 then for i:=1 to month-1 do ndays := ndays + mdays[i];
				{ Compute Number of Days since Year Start }
	day_count := ndays;
	lyear := false;  { Assume NOT Leap Year }
	if (year mod 4) <> 0 then exit;  { If not Leap Year, Done }
	lyear := true;  { Leap Year }
	if month < 3 then exit;  { If in Feb or Jan, Done }
	day_count := ndays + 1;  { Adjust for Leap Year }
end;

{*********************************************************************
	Function:  day_of_week
		Computes day of the week that a given date falls on.
	Input Parameters:
		day : integer in range 1-31
		month : integer in range 1-12
		year : integer
	Output Parameters:
		day_of_week : integer in range 1-7 (Friday = 1)
**********************************************************************}
function day_of_week (day, month, year : integer) : integer;
var
	ndays : integer;
begin
	ndays := day_count (day, month, year);  { Compute Number of Days }
	ndays := ndays + 365*(year - byear) + ((year - byear + 3) div 4);
	day_of_week := (ndays mod 7) + 1;
end;

{************************************************************************
	Function:  CLINE
		Print syntax of Command Line for Calendar Program.
	Input/Output Parameters:  None
*************************************************************************}
procedure cline;  { Print Syntax of Command Line }
begin
	writeln('	Calendar Command Line should be:');
	writeln('		calendar month year /o');
	writeln('	', byear, ' <= YEAR <= ', byear+88);
	writeln('	Only first three characters of MONTH are meaningful');
	writeln('	/O may be one of --');
	writeln('		/P to send output to Printer');
	writeln('		/D to send output to Disk File');
	writeln;
	writeln('	Examples:');
	writeln('		CALENDAR JAN 1982');
	writeln('		CALENDAR DECEMBER 2000');
	writeln('		CALENDAR 1982 /D');
	writeln('		CALENDAR 1984 /P');
end;

{*************************************************************************
	Function:  NUMBER
		Converts the input string of digits to an integer.
	Input Parameter:
		value:  string of digits
	Output Parameter:
		number:  value of digit string; evaluation stops at
			first non-digit character
**************************************************************************}
function number (valstr : string) : integer;
var
	idx, numb : integer;
	cont : boolean;
	digit : char;
	idigit : integer;
	val1 : string;
begin
	val1 := valstr; { Temp Variable }
	numb := 0;  { Initialize result }

	{ Test for Empty Input String; if empty, return zero value }
	if length(val1) = 0 then begin
		number := numb;  { Pass out value }
		exit;
	end;

	{ Extract each digit from string and convert into result }
	cont := true;
	idx := 1;
	while cont do begin
		digit := val1[idx];  { Get next digit }
		if (digit < '0') or (digit > '9') then idigit := 10 else
			idigit := ord(digit) - ord('0');  { Convert to bin }
		if idigit = 10 then cont := false;
		if cont then numb := numb * 10 + idigit;  { Update Value }
		idx := idx + 1;  { Increment Char Pointer }
		if length (val1) < idx then cont := false;
	end;
	number := numb;  { Final Value }
end;

{************************************************************************
	Function:  CAL
		Prints one line of the calendar.
	Input Parameters:
		dow: Day of the Week to Start On
		day: Number of Day in Month
		month:  Month of Year
		lyear:  Leap Year (T/F)
	Output Parameter:
		cal:  Number of next Day in Month (0=done)
************************************************************************}
function cal (dow, day, month : integer) : integer;
var
	i : integer;
	monlen, nday, ndays : integer;
begin
	{ If day is zero, print blank entry }
	if day=0 then begin
		for i:=1 to 7 do write(ofile, '   ');
		write(ofile, '  ');
		cal := 0;
		exit;
	end;

	{ Determine number of days in month }
	monlen := mdays[month];
	{ If month is Feb and it is a leap year, then add 1 }
	if (month=2) and lyear then monlen := monlen + 1;

	{ If number < Sunday, set dow to 7+ }
	if dow < bday then dow := dow + 7;

	{ If not Sunday, space over to proper starting column of month cal }
	if dow <> bday then for i:=1 to dow-bday do write(ofile, '   ');

	{ Compute number of days in current line }
	ndays := 7 - (dow-bday);
	{ If we exceed number of days in month, adjust to limit }
	if day+ndays > monlen then ndays := monlen-day+1;

	{ We are in proper position, to print day entries in Calendar line }
	if ndays<>0 then for i:=1 to ndays do begin
		nday := day + i - 1;
		write(ofile, nday:2, ' ');
	end;
	{ Fill out rest of line if end of calendar }
	if (day<>1) and (ndays<>7) then
		for i:=ndays+1 to 7 do write(ofile, '   ');

	{ Write ending spaces }
	write(ofile, '  ');

	{ Set return value to be day of month to start on or zero if done }
	if monlen < (ndays+day) then cal := 0 else cal := day + ndays;

end; { CAL }

{**********************************************************************
	Function:  DOMONTH
		Prints Calendar for Month 'month1' of Year 'year1'.
	Input Parameters:
		month1: month number (1 to 12)
		year1: year number (byear to byear+88)
	Output Parameters:
		- None -
***********************************************************************}
procedure domonth;
var
	day1 : integer;
begin
	{ Determine what day of the week the first day of month falls on }
	day1 := day_of_week (1,month1,year1);  { Day of 1st Day of Month }

	{ Write header for Calendar Month }
	writeln(ofile); writeln(ofile, 'Calendar for ',month[month1],' ',
		year1);
	writeln(ofile, 'Su Mo Tu We Th Fr Sa');

	{ Print first line of Calendar }
	day1 := cal (day1, 1, month1); writeln(ofile);

	{ Print rest of Calendar }
	while day1 <> 0 do begin
		day1 := cal (6, day1, month1);
		writeln(ofile);
	end;

end; { DOMONTH }

{**************************************************************
	Function:  DOYEAR
		Prints Calendar for Year 'year1'.
	Input Parameters:
		year1: year number
	Output Parameters:
		- None -
**************************************************************}
procedure doyear;
var
	dayx : array [1..3] of integer;
	idx, mbase, group3, group4 : integer;

begin
	{ Write Header for Calendar }
	writeln(ofile, '                       Calendar of Year ', year1);
	writeln(ofile);

	{ Loop over Calendar as 4 rows of three months each }
	for group3 := 1 to 4 do begin
		{ Compute Base Month Number }
		mbase := (group3-1) * 3 + 1;

		{ Page if output to CON: and beginning 3rd group of months }
		if (group3 = 3) and conout then begin
			write('Strike RETURN Key to Continue - ');
			readln; writeln;
		end;

		{ Print Heading of Each Month }
		writeln(ofile);
		for group4 := mbase to mbase+2 do
			write(ofile, 'Calendar for ',month[group4], ' ');
		if ((group3 = 1) or (group3 = 3)) and conout then
			writeln(ofile, year1) else writeln(ofile);
		for group4 := mbase to mbase+2 do begin
	        	write(ofile, 'Su Mo Tu We Th Fr Sa   ');
			idx := group4 mod 3; if idx=0 then idx := 3;
			dayx[idx] := day_of_week(1,group4,year1);
		end;
		writeln(ofile);

		{ Print first line of Calendar }
		dayx[1] := cal (dayx[1], 1, mbase);
		dayx[2] := cal (dayx[2], 1, mbase+1);
		dayx[3] := cal (dayx[3], 1, mbase+2);
		writeln(ofile);

		{ Print rest of Calendar }
		repeat
			dayx[1] := cal (6, dayx[1], mbase);
			dayx[2] := cal (6, dayx[2], mbase+1);
			dayx[3] := cal (6, dayx[3], mbase+2);
			writeln(ofile);
		until dayx[1]+dayx[2]+dayx[3] = 0;
		writeln(ofile);
	end;

end; { DOYEAR }

{Mainline}
begin
	{ Point to Command Line }
	command := @cmd;
	cmdline := command^;

	{ Number of days in each month }
	mdays[1]  := 31; mdays[2]  := 28; mdays[3]  := 31;
	mdays[4]  := 30; mdays[5]  := 31; mdays[6]  := 30;
	mdays[7]  := 31; mdays[8]  := 31; mdays[9]  := 30;
	mdays[10] := 31; mdays[11] := 30; mdays[12] := 31;

	{ Names of each month }
	month[1]  := 'JANUARY  '; month[2]  := 'FEBRUARY ';
	month[3]  := 'MARCH    '; month[4]  := 'APRIL    ';
	month[5]  := 'MAY      '; month[6]  := 'JUNE     ';
	month[7]  := 'JULY     '; month[8]  := 'AUGUST   ';
	month[9]  := 'SEPTEMBER'; month[10] := 'OCTOBER  ';
	month[11] := 'NOVEMBER '; month[12] := 'DECEMBER ';

	{ Print Banner }
	ver1 := version div 10; ver2 := version mod 10;
	writeln('Calendar,  Version ',ver1,'.',ver2);

	{ Determine Output Direction }
	diskout := false;  { Assume no disk output }
	conout := false;   { Assume no console output }
	if pos ('/D',cmdline) <> 0 then begin
		diskout := true;
		write('Name of Disk Output File? '); readln(filename); end
	else if pos ('/P',cmdline) <> 0 then filename := 'LST:'
		 else begin
			filename := 'CON:'; conout := true; end;

	{ Open Output File or Device }
	assign (ofile, filename);
	rewrite(ofile);
	if ioresult = 255 then begin
		writeln ('Fatal Error: Cannot Open ', filename, ' for Output');
		exit;
	end;
	writeln('Calendar Output File/Device is ',filename);

	{ Determine which month was specified in command line }
	month1 := 0;  { Assume none for all months }
	match := false;  { No match found }
	for icount:=1 to 12 do begin
		mpos := pos (copy (month[icount],1,3), cmdline);
		if mpos <> 0 then begin
			if match then begin
				writeln('Error -- More than one month given');
				exit;
			end;
			match := true;  { We have a match }
			month1 := icount;
			mposfnd := mpos;
		end;
	end;

	{ Extract Year from command line }
	yline := copy (cmdline, mposfnd, length(cmdline)-mposfnd+1);
	ypos := pos (' ', yline);
	year := copy (yline, ypos, length(yline)-ypos+1);
	while (length(year) <> 0) and (year[1] = ' ') do
		year := copy (year, 2, length(year)-1);
	year1 := number(year);  { Convert Year String into Number }

	{ If no year specified, give syntax of command }
	if year1 = 0 then begin
		cline;  { Print syntax of command line }
		exit;
	end;
	{ If year specified is out of range, say so }
	if (year1 < byear) or (year1 > byear+88) then begin
		write('Invalid Year Specification');
		writeln(' -- Year Specified was ',year1);
		writeln('Year MUST be in the Range of ', byear, ' <= Year <= ',
			byear+88);
		cline;  { Print syntax of command line }
		exit;
	end;

	{ Do Calendar }
	if ?match then doyear else domonth;
	if diskout then close (ofile, icount);

end. {Mainline}

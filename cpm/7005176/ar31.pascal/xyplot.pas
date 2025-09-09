module xyplot;

{

XYPLOT - Generate 2-D Plots of X,Y Data Pairs
	Derived from the FORTRAN IV Subroutine XYPLT in the Book
	"Digital Computations in Basic Circuit Theory" by L.P. Huelsman
	PASCAL/MT+ Coding and Algorithm Enhancements by Richard Conn

Calling Form --
	rcode = xyplot (device, ndata, nsx, nsy, nnp, x, y);

Passed Parameters --
	device	A String (STR) Specifying the Output Device/File; One of:
			CON:	= Console
			LST:	= Printer
			<File>	= Disk File, Like PLOT1.TXT or A:Plot
	ndata	Number of valid data points in the x,y rarrays
	nsx	Maximum Value of X Points
	nsy	Maximum Value of Y Points (Minimum Value = NSY - 100)
	nnp	Range of X Points (NSX - Minimum Value of X Points)
	x, y	rarrays of the X,Y input Point values

Result Codes (Type Integer) Returned --
	0	No Error
	1	Error in Opening Output File
	2	Error in Closing Output File

Special Types --
	See the following TYPE Definition for the types STR for the
	device name and RARRAY for the passed data.

}

const
	max_elt = 200; { Maximum Number of Array Elements Permitted }
	strl = 20; { Maximum Number of Characters in a String Vector STR }
type
	rarray = array [1..max_elt] of real;
	str = string[strl];

function xyplot (device : str; ndata, nsx, nsy, nnp : integer; x, y : rarray) :
	integer;

const
	jn = '-';
	jp = '+';
	ji = 'I';
	jb = ' ';
	jz = '$';
	jx = 'X';
var
	ofile : text;
	line : array [1..101] of char;
	i, j, l, np, dash, index : integer;
	nx, nx_next : integer;
	xns, yns, xnp : real;
	rcode : integer;

procedure clear (jint, jopen : char);
var
	i, j, idx : integer;
begin
	{ Initialize Line Image to Dashes }
	idx := 0;
	for i:=1 to 10 do begin
		idx := idx + 1;
		line[idx] := jint;  { Intersect Char }
		for j:=1 to 9 do begin
			idx := idx + 1;
			line[idx] := jopen;  { Level Char }
		end;
	end;
	line[101] := jint;  { Last Intersect Char }
end;

procedure capitalize (var s : str);
var	i : integer;
begin
	for i:=1 to strl do
		if (s[i] > 'a') and (s[i] <= 'z') then
			s[i] := chr(ord(s[i]) - ord('a') + ord('A'));
end;

procedure clrblank;
begin
	{ Initialize Line Image to Blanks }
	clear (ji, jb);
end;

procedure clrdash;
begin
	{ Initialize Line Image to Dashes }
	clear (jp, jn);
end;

procedure xchg (var a,b : real);
var
	temp : real;
begin
	{ Exchange real numbers A and B }
	temp := a;
	a := b;
	b := temp;
end;

procedure sety (idx : integer);
var
	ny : integer;
begin
	ny := trunc (y[idx] + 101.49999 - yns);
	if ny < 1 then line[1] := jz { Off Scale }
        	  else if ny > 101 then line[101] := jz
                	           else line[ny] := jx;
end;

procedure setx (idx : integer);
begin
	{ Scaled Value of Next X Element }
	nx_next := trunc (x[idx] * 0.6 - xns + xnp + 0.49999);
	if nx_next > np then nx_next := np; { Out of Range }
	if nx_next < 0 then nx_next := 0;   { Out of Range }
end;

procedure printline;
var
	i, nprint : integer;
begin
	if (dash mod 6) = 0 then begin
		nprint := ((dash * 10) div 6) + nsx - nnp;
		write(ofile, nprint:4); end
	else write(ofile, '    ');
	for i:=1 to 101 do write(ofile, line[i]); writeln(ofile);
	dash := dash + 1; { Increment Line Counter }
end;

begin { XYPLOT }

	{ Set Result Code to OK }
	rcode := 0;  { No Error }

	{ Assign Output Device }
	capitalize (device);  { Capitalize Output Device Name }
	assign (ofile, device);  { Assign Device to File Spec }
	rewrite (ofile);  { Rewind Device if Disk File }

	{ Check for Successful Open of Output File and Perform XYPLOT if so }
	if ioresult = 255 then rcode := 1  { Error in Opening File }
	else begin { XYPLOT Function }

	{ Arrange data in ascending order of X }
	for i:=1 to ndata-1 do
		for j:=i+1 to ndata do
			if x[i] > x[j] then begin { Exchange }
				xchg (x[i], x[j]);
				xchg (y[i], y[j]);
			end;

	{ Print Ordinate Scale Figures }
	write(ofile, ' ');  { Leading Space }
	for i:=1 to 11 do begin
		l := 10 * i - 110 + nsy;  { Compute Values }
		write(ofile, l:4, '      ');  { Write Values }
	end;
	writeln(ofile);  { New Line after Ordinate Scale Values }

	{ Initialize Key Values }
	dash := 0; { Initialize dash line indicator }
	np := (nnp div 10) * 6; xnp := np;
	xns := (nsx div 10) * 6; yns := nsy;
	index := 1;
	setx(index);  { Scaled Value of nx_next }

	repeat { Main Loop }
		{ Set up current line }
		if (dash mod 6) = 0 then clrdash else clrblank;

		{ Load Values into current line if X Coordinates Match }
		if dash >= nx_next then
		   repeat { Plot all Y Values which belong to current X }
			nx := nx_next;  { Scaled Value of Current X }

			{ Scaled Value of Current Y }
			sety(index);

			index := index + 1;  { Advance to next data elt }
			setx(index); { Compute Next X }
		   until (nx_next <> nx) or (index = ndata);

		if (index = ndata) and (nx_next = nx) then sety(index);

		printline;  { Print Graph }
	until index = ndata;

	if nx_next <> nx then begin
		sety(index);
		printline;
	end;

	{ Close Output File }
	close(ofile,i);
	if i=255 then rcode := 2;  { Error in Closing File }

	end; { XYPLOT Function }

	xyplot := rcode;  { Setup Return Code }

end; { XYPLOT }
modend.

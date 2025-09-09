program xydemo;  { Demo of XYPLOT }

{
	Sample SUBMIT File for Compiling this program with the libraries
		XYPLOT, TRANCEND, FPREALS, and PASLIB --

mtplus xydemo $$oa ea v
linkmt xydemo,xyplot,a:trancend,a:fpreals,a:paslib/s

}

type
	rarray = array [1..200] of real;
	str = string[20];
var
	i : integer;
	theta, r : real;
	x, y : rarray;
	dev : str;

external function xyplot (dev1 : str; ndata, nsx, nsy, nnp : integer;
	x, y : rarray) : integer;

begin { Test }
	writeln('XYDEMO:  Demo Program of XYPLOT Subroutine');
	writeln('Output Device Options are:');
	writeln('	CON:	= Console');
	writeln('	LST:	= Printer');
	writeln('	<File>	= Disk File, Like P.PLT or A:P');
	write  ('Option -- '); readln(dev);

	writeln('XYDEMO:  Computing --');
	for i:=1 to 90 do begin
		write('.');
		if (i mod 45) = 0 then writeln;
		theta := (i-1) * 4 * 3.14159 / 180;
		r := cos (2 * theta);
		x[i] := r * 50 * cos(theta);
		y[i] := r * 50 * sin(theta);
	end;
	writeln('XYDEMO:  Plotting --');
	if 0 <> xyplot (dev, 90, 50, 50, 100, x, y) then
		writeln('XYDEMO:  Error in Outputting File');
	writeln('XYDEMO:  Test Complete');
end.

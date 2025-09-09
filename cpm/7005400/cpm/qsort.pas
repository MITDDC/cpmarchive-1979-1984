{++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
{+  PROGRAM TITLE:	Quicksort Test			+}
{+							+}
{+  WRITTEN BY:		Raymond E. Penley		+}
{+  DATE WRITTEN:	October 6, 1980			+}
{+							+}
{+  Show use of the quicksort algorithm in a Pascal	+}
{+  program.						+}
{+							+}
{+	   Average sorting times in seconds *		+}
{+  No. of items   Shellsort    Quicksort  QQuicksort   +}
{+     1000	     15             8          7	+}
{+     2000	     34            20         14        +}
{+     5000	    112            50         37        +}
{+   10,000	    213           106         78        +}
{+							+}
{+	* Z80 CPU operating at 2 mcps			+}
{+							+}
{++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROGRAM Qsorttest;
CONST
  Max_N = 10000;		{Upper limit of all numbers}
TYPE
  index = 0..Max_N;
  Scalar = INTEGER;
VAR
  cix	: char;			{Global temp char variable}
  N,				{The number of numbers to be sorted}
  i, ix	: Scalar;		{Global indexers}
  A	: ARRAY [index] OF Scalar; {THE array to be sorted}

Procedure Show;
var
  i: index;
begin
  for i:=1 to N do
    begin
      write(A[i]);
      if i mod 8 = 0 then writeln;
    end;
  writeln;
end;




PROCEDURE QSORT( left,right: INTEGER );
{	The classic Quicksort method by C.A.R Hoare.
	Presented here in Pascal.		}
{
GLOBAL
  TYPE
    Index  = 1..N;
    Scalar = <Some scalar type>
  VAR
    A : array [Index] of Scalar;
}
VAR
  II, JJ : integer;
  Pivot, temp : Scalar;
BEGIN 				{$C-,M-,F-}
  II := left;
  JJ := right;
  Pivot := A[(II+JJ) DIV 2];
  REPEAT
    WHILE A[II] < Pivot DO II := II + 1;
    WHILE A[JJ] > Pivot DO JJ := JJ - 1;
    IF II <= JJ THEN 
      BEGIN
	temp := A[II]; A[II] := A[JJ]; A[JJ] := temp;
	II := II + 1;
	JJ := JJ - 1
      END
  UNTIL II > JJ;
  IF left < JJ THEN QSORT( left, JJ );
  IF II < right THEN QSORT( II, right )
END;{of QSORT}			{$C+,M+,F+}

BEGIN (* MAIN *)
  repeat
    writeln;
    writeln('Enter number of items to sort');
    writeln(' 10 <= n <= 10,000');
    write('?');
    readln(N);
  until (N >= 10) and (N <= Max_N);

  writeln;
  writeln('Please stand by while I set up.');
  ix := 113;				{$C-,M-,F- [ctrl-c OFF]}
  FOR i := 1 TO N DO
    BEGIN
      ix := (131*ix+1) mod 221;
      A[i] := ix;
      if (i mod 1000 = 0) then write(i);
    END;
  writeln;
  A[0] := -maxint;			{$C+,M+,F+ [ctrl-c ON]}

  writeln('Ready');
  WRITE('Press return when ready to start');
  readln(cix);
  writeln( CHR(7), 'START');
  {}
	  QSORT( 1, N );
  {}
  WRITELN( CHR(7), 'DONE!!!' );

  writeln;
  write('Print the array (Y/N)?');
  readln(cix);
  If (cix='Y') or (cix='y') then Show;
END.

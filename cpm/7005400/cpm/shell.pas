{++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
{+  PROGRAM TITLE:	Shell Sort Test			+}
{+							+}
{+  WRITTEN BY:		Raymond E. Penley		+}
{+  DATE WRITTEN:	5 October 1980			+}
{+							+}
{+  SUMMARY:						+}
{+	This program demonstrates the Shell sort	+}
{+	algorithm.					+}
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
PROGRAM Shellsorttest;
CONST
  Max_N = 10000;
TYPE
  INDEX = 0..Max_N;
  SCALAR = INTEGER;
  ScalarTyp = ARRAY [ INDEX ]  OF SCALAR;
VAR
  cix : char;		{Global temp for char inputs}
  A   : ScalarTyp;
  N,			{The number of numbers to be sorted.}
  i, ix : INTEGER;	{Global indexer}

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




PROCEDURE Shellsort(VAR A : ScalarTyp;
			n : INDEX);
{
The array A[1..n] is sorted in ascending order. The method is that
of D.A. Shell, (A high-speed sorting procedure, Comm. ACM 2 (1959),
30-32) with subsequences chosen as suggested by T.N. Hibberd.
}
VAR
  i, j, k, m	: integer;
  done 		: BOOLEAN;
  temp		: SCALAR;
begin (*$C-,M-,F-*)
  m := n;
  While m <> 0 do
    begin
      m := m DIV 2;
      k := n - m;
      for j:=1 to k do
	begin
	  i := j;
	  done := FALSE;
	  repeat
	    if A[i+m] >= A[i] then
	      done := TRUE
	    else
	      begin
		temp := A[i]; A[i] := A[i+m]; A[i+m] := temp;
		i := i - m;
	      end;
	  until (i<1) OR ( done );
	end{for j};
    end{While};
end;{Shellsort}{$C+,M+,F+}



BEGIN (* Main program SHELLSORT*)
  Repeat
    writeln;
    writeln('Enter number of items to sort');
    writeln(' 10 <= n <= 10,000');
    write('?');
    readln(N);
  Until (N >= 10) and (N <= Max_N);
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
	  Shellsort(A, N );
  {}
  WRITELN( CHR(7), 'DONE!!!' );

  writeln;
  write('Print the array (Y/N)?');
  readln(cix);
  If (cix='Y') or (cix='y') then Show;
END.

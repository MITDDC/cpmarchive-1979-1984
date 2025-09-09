{++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
{+  PROGRAM TITLE:	Quick sort with minimal storage +}
{+			Test Program			+}
{+							+}
{+  WRITTEN BY:		Raymond E. Penley		+}
{+  DATE WRITTEN:	October 5, 1980			+}
{+							+}
{+  A program to show the speed of the quick sort	+}
{+  with minimal storage algorithm.			+}
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
PROGRAM QuickerQuickSortTest;
CONST
  Max_N = 10000;
TYPE
  index = 0..Max_N;
  Scalar = INTEGER;
VAR
  cix	: char;
  N,
  i, ix	: Scalar;
  A	: ARRAY [index] OF Scalar;


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




PROCEDURE QQSORT( left, right : INTEGER );
{
+ WRITTEN BY:	Richard C. Singleton
+ DATE WRITTEN:	Sept 17, 1968
+
+ This procedure sorts the elements of array A[1..n] into
  ascending order.  The method used is similar to QUICKERSORT
  by R.S. Scowen, which in turn is similar to an algorithm given
  by Hibbard and to Hoare's QUICKSORT.
+
+ Modified 6 Oct 1980 for Pascal/Z.		+}
{
GLOBAL
  TYPE
    Index  = 1..N;
    Scalar = <Some scalar type>
  VAR
    A : array [Index] of Scalar;
}
VAR
  t, tt: Scalar;
  ii, ij, k, L, m : integer;
  IL, IU : array [0..20] of integer;{Permit sorting up to 2**(K+1)-1 elements}
  i, j, ix	: integer;
  alldone, d : BOOLEAN;
BEGIN 				{$C-,M-,F-}
  i := left;
  j := right;
  m := 0;
  ii := i;
  alldone := FALSE;
  REPEAT
     If ((j-i) > 10) OR ( (i = ii) and (i < j) ) then
       BEGIN
	  ij := (i+j) DIV 2;
	  t := A[ij];
	  k := i;
	  L := j;
	  If (A[i] > t) then
	    begin
	      A[ij] := A[i]; A[i] := t; t := A[ij]
	    end;
	  If (A[j] < t) then
	    begin
	      A[ij] := A[j]; A[j] := t; t := A[ij];
	      If (A[i] > t) then
		begin
		  A[ij] := A[i]; A[i] := t; t := A[ij]
		end;
	    end;
	  d := FALSE;
	  REPEAT
	    REPEAT
	      L := L - 1;
	    UNTIL A[L] <= t;
	    REPEAT
	      k := k + 1;
	    UNTIL A[k] >= t;
	    If (k <= L) then
	      begin
	        tt := A[L]; A[L] := A[k]; A[k] := tt;
	      end
	    Else
	      d := TRUE;
	  UNTIL d;
	  If (L-i) > (j-k) then
	    begin  IL[m] := i; IU[m] := L; i := k end
	  Else
	    begin IL[m] := k; IU[m] := j; j := L end;
	  m := m + 1;
       END
     Else
       BEGIN
	 For ix := (i+1) to j do
	   begin
	     t := A[ix];
	     k := ix - 1;
	     If A[k] > t then
	       begin
		 REPEAT
		   A[k+1] := A[k];
		   k := k - 1;
		 UNTIL A[k] <= t;
		 A[k+1] := t;
	       end;
	   end;{For ix}
	 m := m - 1;
	 If m >= 0 then
	   begin
	     i := IL[m];
	     j := IU[m];
	   end
         Else
	   alldone := TRUE;
       END;
  UNTIL alldone;
END;{of QQSORT}			{$C+,M+,F+}

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
  {$C-,M-,F- [ctrl-c OFF]}
  ix := 113;
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
	  QQSORT( 1, N );
  {}
  WRITELN( CHR(7), 'DONE!!!' );

  writeln;
  write('Print the array (Y/N)?');
  readln(cix);
  If (cix='Y') or (cix='y') then Show;
END.

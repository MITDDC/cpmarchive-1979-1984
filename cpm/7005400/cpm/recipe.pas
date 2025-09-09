{++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
**  PROGRAM TITLE	THE RECIPE SYSTEM
**
**  Translated by:	Raymond E. Penley from the BASIC
**			version into Pascal.
**
**  DATE WRITTEN:	23 FEB 1980
**
**  WRITTEN FOR:	Computer hobbyists
**
**  PROGRAM SUMMARY:
**
**  The recipe system stores recipes and retrives recipies
**  by means of a numeric key that represents the foods
**  used in the meal.  Foods are divided into four
**  categories according to their nutritional value.
**  For more comments see the original program.
**
**  INPUT AND OUTPUT FILES:
**	RCPDAT.XXX and RCPDAT.YYY
**		   - the DATA and the backup files
**	RCPDAT.MST - the statistics file
**
**  MODIFICATION RECORD:
**	28 Feb 80	-
**	 2 Jun 80	-Rewritten for Pascal/Z v 3.0
**	 8 Jun 80	-Rewrote SCAN
**
**  ORIGINAL PROGRAM:
**	T.G.LEWIS, 'THE MIND APPLIANCE'
**	HAYDEN BOOK COMPANY
**
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
PROGRAM RECIPE;

CONST
  default = 80;		(* Default length for strings *)
  str_len = 73;		(* Length of a recipe line plus one char *)
  StrMax  = 255;	(* Max Length of strings allowed   *)
  EOS	  = '|';	(* End of String marker *)
  Master  = 'RCPDAT.MST';
  Tab20	  = 20 ;
  Tab15	  = 15 ;
  INPUT   = 0;		(*****   PASCAL/Z ver 3.n   *****)

TYPE
  ALFA	   = STRING 10 ;
  BYTE	   = 0..255;
  LINE	   = string default;
  Mstring  = string 255 ;
  DataType = record
		 MR,		(* MaxRecords	*)
		 CR : integer;	(* Curr_Rcds	*)
		 F1,		(* current_ID	*)
		 F2,		(* backup_ID	*)
		 date : string 14 (* last_update *)
	     end;
  S$0   = STRING 0 ;		{ zero length string }
  S$255 = STRING 255 ;		{ max string length  }

VAR
  adding_recipies,	(* adding recipies state flag *)
  comanding,		(* Command mode flag *)
  done			(* Program execution flag *)
		: boolean;
  bell,			(* ASCII bell char *)
  ch,
  command	: char;
  data		: datatype;
  End_of_File,		(* End of File flag *)
  End_of_Text		(* End of Text flag *)
		: boolean;
  error_flag	: BYTE;
  CRT_width,	(* Width of video display *)
  Curr_Rcds,	(* No. of current active records *)
  Hash,		(* Computed Index value of Recipe *)
  ix,		(* global indexer *)
  Last,		(* length of last line read *)
  MaxRecords,	(* Maximum records allowed *)
  TTY_width	(* Width of teletype device *)
		: integer;
  Last_update	: string 14; (* date of last file update *)
  matrix	: packed array[1..5] of LINE;
	(*  File Identifiers <FID>  *)
  current_ID,			(* Current file ID *)
  backup_ID	:string 14;	(* Back up file ID *)
	(* File descriptor <FCB> *)
  stats		:FILE of datatype;

	{$C- [ctrl-c checking OFF]}
	{$F- [floating point error checking OFF]}
	{$M- [integer mult & divd checking OFF]}

(*---Required for Pascal/Z supplied string functions---*)
FUNCTION LENGTH(X: S$255): INTEGER; EXTERNAL;
PROCEDURE SETLENGTH(VAR X :S$0; Y :INTEGER); EXTERNAL;



(*----------------------------------------------*)
(*		  DISK I/O			*)
(*----------------------------------------------*)



Procedure OPEN_MASTER;
begin
  (* OPEN file RECIPE.MST for READ assign stats *)
	  RESET(master, stats);
  READ(stats, data );
  with data do begin
    MaxRecords := MR;
    Curr_Rcds  := CR;
    current_ID	:= F1;
    backup_ID	:= F2;
    last_update := date
    end(* with *)
end;

Procedure UPDATE_MASTER;
begin
  (* OPEN file RECIPE.MST for WRITE assign stats *)
	  REWRITE(master, stats);
  with data do begin
    MR := MaxRecords;
    CR := Curr_Rcds;
    F1 := current_ID ;
    F2 := backup_ID ;
    date := last_update
    end(* with *);
  WRITE(stats, data )
end;

Procedure GETLINE(VAR fx : TEXT;
		  VAR INBUFF : LINE );
{ This Procedure gets a line of text from a disk file.
  Returns:
	End_of_Text = true if the input buffer length
			exceeded.
	End_of_File = true if EOF
	INBUFF    = input buffer		}
VAR	CH   : CHAR;
	ix, length : integer;
begin
  length := 0;
  End_of_Text := FALSE;
  SETLENGTH(INBUFF,0);
  WHILE NOT EOF(fx) AND (CH <> EOS) DO
    begin
    If length < str_len then
      begin(* valid *)
	READ(fx, CH );
	length := SUCC(length);
	APPEND(INBUFF,CH)
      end(* If *)
    ELSE
	End_of_Text := TRUE;
    end(* WHILE *);
    If length >= last then
      last:=length
    Else
      REPEAT
	APPEND(INBUFF,EOS);
	last := PRED(last)
      UNTIL last=length;
  End_of_File := EOF(fx)
end(*---of GetLine---*);

Procedure PUTLINE( VAR fx   : TEXT;
		   VAR this : LINE );
{ This Procedure puts a line of text to a disk file }
VAR	CH  : char;
	pos : integer;
begin
  pos := 0;
  REPEAT
    pos := SUCC(pos);
    CH := this[ pos ];
    If CH <> EOS then Write(fx, CH)
  UNTIL (CH = EOS) OR (pos = str_len);
  Write(fx, EOS) (* Mark the End of String *)
end(*---of PUTLINE---*);

Procedure PUT_RECORD( VAR fx	: TEXT;
		      VAR Index : integer );
VAR	jx : integer;
begin
  Writeln(fx, Index:5);
  For jx:=1 to 5 do
    PUTLINE(fx,matrix[jx] );
end(*---of PUT_RECORD---*);

Procedure GET_RECORD(VAR fx : TEXT;
		     VAR Index : integer );
VAR	JJ : integer;
begin
  READLN (fx, Index);
  FOR JJ := 1 to 5 DO
    GETLINE(fx,matrix[JJ]);
end(*---of GET_RECORD---*);



(*----------------------------------------------*)
(*		CONSOLE I/O			*)
(*----------------------------------------------*)



Procedure KEYIN(VAR CIX : char); EXTERNAL;
(*---Single char input directly from keyboard---*)

Procedure PRINT(this : Mstring);
(*	Print the string 'this' until EOS 	*)
VAR
  CH : CHAR;
  pos : integer;
begin
  pos := 0;
  REPEAT
    pos := SUCC(pos);
    CH := this[ pos ];
    If CH <> EOS then Write(CH)
  UNTIL (CH = EOS) OR (pos = str_len);
  Writeln
end(*---of PRINT---*);

Procedure SCAN( VAR Arg_string	: LINE ;
		    count	: integer ;
		VAR status	: BYTE  );
(*----------------------------------------------*)
(* version: 3.1 /8 JUN 80/ by R.E.Penley	*)
(*----------------------------------------------*
** Scan will scan your input line and return:
	STATUS:
	  0	-OK, valid inputs
	  1	-an attempt was made to exceed "count"
		 characters - so I truncated the string at
		 count chars for you.
	  2	-an invalid character was detected.
		 You figure out what to do with it!
    LENGTH(arg string) = 0 means a null string input.
**
    Valid Alphanumeric chars are the ASCII char set
    starting at the space [ CHR(32) ] and
    ending at the tilde [ CHR(126) ].
 *----------------------------------------------*
GLOBAL  StrMax = 255;
	BYTE   = 0..255;
	LINE   = STRING Default;
 *----------------------------------------------*)
VAR	loop	: (scanning, found, notfound);
	ix	: 1..StrMax;
begin
  { return status = 0 if no errors detected. }
  status := 0;
  { return status = 1 if requested length is exceeded }
  If LENGTH(arg_string) > count then
    begin
    status := 1;
    SETLENGTH(arg_string,count)
    end;
  loop := scanning;
  ix := 1;
  While (loop=scanning) do
  { return status = 2 if any invalid chars found }
    begin
    If ix > LENGTH(arg_string) then
      loop := notfound{excellent - no invalid chars}
    Else
      If arg_string[ix] IN [' '..'~'] then{good show - keep going}
	ix := SUCC(ix)
      Else
	begin
	loop := found{invalid char};
	status := 2
	end
    end{while}
End(*---of SCAN 3.1---*);



(*----------------------------------------------*)
(*		UTILITY ROUTINES		*)
(*----------------------------------------------*)


Function YORN : boolean ;
{
	YES/NO INPUT MODULE
Returns:
	TRUE FOR 'Y' or 'y' INPUT
	FALSE FOR 'N' or 'n' INPUT
}
VAR
  ans : ALFA;
  valid : boolean;
begin
  REPEAT
    valid := true;
    READ(ans);
    CASE ans[1] of
    'Y','y':	YORN := true;
    'N','n':	YORN := false;
    Else:	begin
		  valid := false;
		  Writeln(BELL, 'Please answer ''Y'' or ''N'' ')
		end
    end{case}
  Until valid{response}
End(*---of YORN---*);

Procedure CLEAR;
(* Device dependent procedure	*)
begin
  Write( CHR(26) )
end;

Procedure SKIP(L1 : integer);
VAR ix : integer;
begin
  FOR ix:=1 to L1 do Writeln
end;

Procedure PAUSE;
CONST	sign = 'Type return to continue:';
VAR	dummy : char;
begin
  SKIP(4);
  Write(sign);
  Readln(dummy)
end;

Procedure BREAK;
begin
  CLEAR;
  SKIP(5)
end;

Procedure DRAW(picture : Mstring; count : integer );
{ Draw a picture count times }
VAR ix : integer;
begin
  FOR ix:=1 to count DO Write( picture );
  Writeln
end(*---of DRAW---*);

Procedure ShowRecipe;
VAR JJ : integer;
begin
  FOR JJ := 1 to 5 DO
    PRINT(matrix[JJ]) ;
  Writeln
end(*--of ShowRecipe--*);

Procedure Display_One(VAR Index : integer);
begin
  Writeln;
  Writeln( 'Recipe #', Index:5 );
  Writeln;
  DRAW( '- ', 20);
  Writeln;
  ShowRecipe;
  skip(4)
end(*---of Display_One---*);


(*----------------------------------------------*
 *		   ADD MODULE			*
 *----------------------------------------------*)

	{$C+ [ctrl-c checking ON]}

Procedure InputFeatures(VAR I : integer);
(******************************************
 *	Input Features of Recipe	  *
 ******************************************)
(*
RETURNS:
  Hash value computed for various choices
**)
CONST	Msg1	= 'None of these' ;
VAR	F, D, V, P :integer;

	Function QUIRY(X2 : integer) : integer;
	VAR ix : integer;
	    cix : char;
	begin
	  REPEAT
	    Writeln;
	    Write('Enter Choice (1 to', X2:2, ') ');
	    KEYIN(cix);write(cix);
	    ix := (ORD(cix) - ORD('0'))
	  UNTIL (ix>=1) AND (ix<=X2) ;
	  QUIRY := ix
	end;

begin
  Writeln;
  Writeln( ' Enter number of choice :');
  Writeln;
  Writeln( ' ':Tab15, 'Fibre Foods' );
  Writeln;
  Writeln( ' ':Tab15, '1.  Bread (flour)');
  Writeln( ' ':Tab15, '2.  Oats' );
  Writeln( ' ':Tab15, '3.  Rice');
  Writeln( ' ':Tab15, '4.  Corn' );
  Writeln( ' ':Tab15, '5.  Macaroni');
  Writeln( ' ':Tab15, '6.  Noodles' );
  Writeln( ' ':Tab15, '7.  Spaghetti');
  Writeln( ' ':Tab15, '8.  ', Msg1 );
  F := QUIRY(8);
  BREAK;
  Writeln;
  Writeln( ' ':Tab15, 'Protein' );
  Writeln;
  Writeln( ' ':Tab15, '1.  Beef');
  Writeln( ' ':Tab15, '2.  Poultry' );
  Writeln( ' ':Tab15, '3.  Fish');
  Writeln( ' ':Tab15, '4.  Eggs' );
  Writeln( ' ':Tab15, '5.  Beans');
  Writeln( ' ':Tab15, '6.  Nuts' );
  Writeln( ' ':Tab15, '7.  ', Msg1 );
  P := QUIRY(7);
  BREAK;
  Writeln;
  Writeln( ' ':Tab15, 'Dairy' );
  Writeln;
  Writeln( ' ':Tab15, '1.  Milk');
  Writeln( ' ':Tab15, '2.  Cheese' );
  Writeln( ' ':Tab15, '3.  Cottage Cheese');
  Writeln( ' ':Tab15, '4.  Cream' );
  Writeln( ' ':Tab15, '5.  Sour Cream');
  Writeln( ' ':Tab15, '6.  ', Msg1 );
  D := QUIRY(6);
  BREAK;
  Writeln;
  Writeln( ' ':Tab15, 'Fruits and Vegetables' );
  Writeln;
  Writeln( ' ':Tab15, '1.  Citrus');
  Writeln( ' ':Tab15, '2.  Melon' );
  Writeln( ' ':Tab15, '3.  Juices');
  Writeln( ' ':Tab15, '4.  Greens' );
  Writeln( ' ':Tab15, '5.  Yellows & Reds' );
  Writeln( ' ':Tab15, '6.  ', Msg1 );
  V := QUIRY(6);
  CLEAR;

   {*****************************************}
   {  Compute the index value by assigning   }
   {  a weight to each digit in the set.     }
   {*****************************************}

	I := 252*F + 36*P + 6*D + V - 295

   {******************************************}

end{of InputFeatures};



Procedure InputRecipe;
(*---------------------------------------*
 *	Input individual recipies	 *
 *---------------------------------------*)
LABEL
  99; (*---EXIT---*)
CONST
  prompt = '>';
VAR
  state  : (absent, done, adding) ;
  ix, jx : integer;
  temp	 : STRING 14;
  One_Line : LINE;
  YES	 : boolean;
	(* File descriptors <FCB> *)
  current,
  backup : TEXT;

  PROCEDURE CORRECT;
  CONST   question = 'Are there any corrections to be made';
	  msg1 = 'Enter <cr> return if correct or Reenter the line';
  begin
    REPEAT
      BREAK;
      Writeln(bell,' ':(TTY_width DIV 2) -10, 'HERE IS YOUR RECIPE');
      Writeln;
      ShowRecipe;
      Writeln;
      Writeln(question);
      YES := YORN;
      If YES then
	begin
	  BREAK;
	  Writeln(msg1);
	  Writeln;
	  For ix:=1 to 5 do
	    begin
	      REPEAT
		PRINT(matrix[ix]);
		SETLENGTH(one_line,0);
		READLN(one_Line);
		SCAN(one_Line, str_len - 1, error_flag);
		If (LENGTH(one_Line) > 0) AND (error_flag=0) then
		  begin
		  APPEND(one_Line,EOS);
		  matrix[ix] := one_Line
		  end;
		If error_flag IN [1,2] then
		  CASE error_flag of
		    1: writeln('Invalid length, please reinput');
		    2: writeln('Alpha numerics only, please reinput')
		  End{case}
	      Until error_flag=0;
	    end{for}
	end(* If *)
    Until not YES
  end(*---of Correct---*);

	Function adding_desired : boolean ;
	CONST	addquest = 'Do you want to ADD recipies? ';
	begin
	  PAUSE;
	  BREAK;
	  Write(addquest);
	  adding_desired := YORN;
	  CLEAR
	end;

begin(*---InputRecipe---*)
  If not adding_desired then{EXIT}goto 99;
  adding_recipies := true ;
  state := adding ;
  (* OPEN file backup_ID for WRITE assign backup *)
	REWRITE(backup_ID, backup);
  (* OPEN file current_ID for READ assign current *)
	RESET(current_ID, current);

	{$C- [ctrl-c checking OFF]}

  If NOT EOF(current) then
    begin(* COPY current to back_up *)
      ix := 0 ;
      While ix < Curr_Rcds do
	begin
	  ix := SUCC(ix);
	  GET_RECORD(current,hash);
	  PUT_RECORD(backup,hash)
	end(* while *)
    end(* COPY current to back_up *);

	{$C+ [ctrl-c checking ON]}

(*---Input/Enter additional recipies until done---*)
(*---or curr_records > Max_Records allowed     ---*)

  REPEAT
  If Curr_Rcds > MaxRecords then
    state := done
  Else
    begin(*---add more recipies---*)
      Writeln('Identify Recipe with features. First ');
      InputFeatures(HASH);
      BREAK;
      Writeln('Now Enter 5 lines of the recipe');
      Writeln;
      For jx := 1 to 5 DO
	begin
	  REPEAT
	    write(prompt);
	    SETLENGTH(one_line,0);
	    READLN(one_line);
	    SCAN(one_Line, str_len - 1, error_flag);
	    If error_flag IN [1,2] then
	      CASE error_flag of
	      1:   writeln('Invalid length, please reinput');
	      2:   writeln('Alpha numerics only, please reinput')
	      End{case}
	  Until error_flag=0;
	  APPEND(one_Line,EOS);
	  matrix[jx] := one_Line
	end{For};
      Correct(* if required *);
      Curr_Rcds := SUCC(Curr_Rcds);
      PUT_RECORD(backup,hash);
      If not adding_desired then state := done;
    end(*---add more recipies---*)
  UNTIL state<>adding;
(*--------------------------------------------*)
(*		SWAP file ID`s		      *)
(*	Back Up file is now the Current file  *)
(*--------------------------------------------*)
  temp := backup_ID;
  backup_ID := current_ID;
  current_ID := temp;

  UPDATE_MASTER;(*--status file--*)

99:(* Come here if do not desire to add *)
End{*--of InputRecipe--*};


(*--------------------------------------*)
(*	      DUMP/FIND MODULE		*)
(*--------------------------------------*)

PROCEDURE FILE_SCAN ;
(*
GLOBAL
  MaxRecords = maximum allowed records
  Curr_Rcds = # of recipes in file
*)
VAR
  state : (absent, found, searching) ;
  Rcds,
  index : integer;
  fa	: TEXT;  (* FCB. File descriptor *)

	Procedure DUMP;
	(**********************************)
	(*  OUTPUT all Recipes from file  *)
	(**********************************)
	begin
	  REPEAT
	    If Rcds > Curr_Rcds then
	      state := absent
	    Else
	      begin
		Rcds := SUCC(Rcds);
		GET_RECORD(fa,hash);
		Display_One(hash);
		PAUSE
	      end(* else *)
	  UNTIL state<>searching
	end(*--of DUMP--*);

	Procedure FIND;
	(************************************)
	(*	Lookup recipes from file    *)
	(************************************)
	begin			{$C- [ctrl-c checking OFF]}
	  InputFeatures(Index);
	  REPEAT
	    If Rcds > Curr_Rcds then
	      state := absent
	    Else
	      begin
		Rcds := SUCC(Rcds);
		GET_RECORD(fa,hash);
		If HASH=Index then
		  begin
		    CLEAR;
		    Display_One(hash);
		    PAUSE
		  end
	      end(* else *)
	  Until state<>searching
	end(*--of Lookup--*);	{$C+ [ctrl-c checking ON]}

begin(*---File_Scan---*)
  CLEAR;
  state := absent;
  If adding_recipies then{read in new stats}
    OPEN_MASTER;
  (* OPEN file current_ID for READ assign fa *)
	  RESET(current_ID, fa);
  If NOT EOF(fa) then
    If Curr_rcds=0 then
      state := absent
    Else
      begin
	state := searching ;
	Rcds := 1 ;
	CASE command of
	  'O', 'o':	DUMP;
	  'F', 'f':	FIND
	End{case commmand of}
      end(* else *);
  If state=absent then
    begin
    BREAK;
    Writeln('That''s all the Recipes on File')
    end;
  PAUSE
end(*---of File_Scan---*);

(*--------------------------------------*)
(*	      INITIALIZATION		*)
(*--------------------------------------*)


Procedure INIT1;
begin
  bell		:= CHR(7) ;
  CRT_width	:= 80 ;
  TTY_width	:= 72 ;
  last		:= str_len ;
  MaxRecords	:= 75 ;
(*	maximum number of records =
		# BYTES per Record  times  # of records
	# BYTES per record = 
		# chars per line + overhead per line times
		# of lines.				***)
  Curr_Rcds	:=  0 ;
  Last_Update	:= 'YY/MM/DD      ';
  current_ID	:= 'RCPDAT.XXX    ';
  backup_ID	:= 'RCPDAT.YYY    ';
  adding_recipies := false;
end;

Procedure INIT2;
begin
   (* OPEN file `RECIPE.MST` for READ assign stats *)
	  RESET(master, stats);
  If EOF(stats) then(* not found *)
    (* OPEN file `RECIPE.MST` for WRITE assign stats *)
	  UPDATE_MASTER
  Else
    begin(* READ in data record *)
      READ(stats, data );
      with data do begin
        MaxRecords := MR;
        Curr_Rcds  := CR;
        current_ID := F1;
        backup_ID  := F2;
        last_update := date
        end(* with *)
    end(* READ in data record *);
  SKIP(5);
  Writeln('Last update of Recipe data file was ', last_update);
  Writeln('File currently consists of ', Curr_Rcds:4, ' Recipies');
  Writeln;
  Write('Please enter todays date <YY/MM/DD>  ');
  last_update := '              ';{<<<=== 14 spaces required ===}
  For ix:=1 to 8 do
    begin
      if (ix=3) or (ix=6) then
	ch := '/'
      else
	KEYIN(ch);
      write(ch);
      last_update[ix] := ch
    end{for};
  writeln
end(*--of INIT2---*);

(*----------------------------------------------*
 *		MAIN PROGRAM			*
 *----------------------------------------------*)

BEGIN
  INIT1;	(* start the initialization process here *)
  CLEAR;
  DRAW('************',TTY_width DIV 12);
  Writeln;
  Writeln( ' ':22, 'The Recipe System');
  Writeln;
  DRAW('************',TTY_width DIV 12);
  INIT2;	(* finish init now *)
  { Now execute the program until done }
  done := false;
  While not done do
    begin
    CLEAR;
    DRAW('************',TTY_width DIV 12);
    SKIP(3);
    Writeln( ' ':Tab15, 'Select One of the following:');
    Writeln;
    Writeln( ' ':Tab20, 'I(nput Recipes');
    Writeln( ' ':Tab20, 'O(utput all Recipes');
    Writeln( ' ':Tab20, 'F(ind a Recipe');
    Writeln( ' ':Tab20, 'S(top');
    comanding := true;
    WHILE comanding do
      begin
      comanding := false;
      Writeln;
      Write(' ':(Tab15), 'Enter choice   ' );
      KEYIN(command);write(command);
	CASE command of
	  'I', 'i':	InputRecipe;
	  'O', 'o',
	  'F', 'f':	File_Scan;
	  'S', 's':	done := true;
	Else:		begin
			Write(BELL);
			comanding := true
			end
	End{ case }
      end{while comanding}
    end{ while not done }
End{---of Program Recipe---}.

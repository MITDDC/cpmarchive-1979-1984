
; M712NM.ASM  Telephone number overlay file for MDM712  07/27/83
;
; This file can be edited to make a new library of telephone numbers.
; Each entry must be 34 bytes long and only 26 (A-Z) telephone numbers
; are allowed.  Follow the format for the library entries already in the
; file.  (Be sure to use spaces, not tabs.)
;
; Room has been left if your phone system requires extra characters such
; as:  1-313-846-6127 rather than the 313-846-6127 used in some areas.
;
; This number list is of value even to those not using the PMMI auto-
; dialing system.  If "NUM" is typed while in the command mode, it will
; show the list of stored numbers you can manually dial.  (If the PMMI
; board is used, type "CAL" to initiate an auto-dialed call.  This also
; lists the telephone numbers but in a slightly different format.)  "NUM"
; does not work for PMMI, and "CAL" does not work for non-PMMI.
;
; NOTE: 'R' at the end of a number indicates a ringback system.
;
;
;	TO USE: First edit this file filling in answers for your own
;		equipment.  Then assemble with ASM.COM or equivalent
;		assembler.  Then use 'DDT' to overlay the the results
;		of this program to the original .COM file:
;
;		A>DDT MDM712.COM
;		DDT VERS 2.2
;		NEXT  PC
;		4300 0100
;		-IM712NM.HEX		(note the "I" command)
;		-R			("R" loads in the .HEX file)
;		NEXT  PC
;		4300 0000
;		-G0			(return to CP/M)
;		A>SAVE 66 MDM712.COM	(now have a modified .COM file)
;
;
; NOTE: For those revising the main program, check the location of
;          NUMBLIB to see if the ORG value used here is correct.  If
;          not, change as needed.
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
; 07/27/83  Updated for MDM712		- Irv Hoff
;	    Added 'MCI' and/or 'SPRINT'
; 07/01/83  Updated for MDM711		- Irv Hoff
; 06/22/83  Updated for MDM710		- Irv Hoff
; 05/27/83  Updated for MDM709		- Irv Hoff
; 05/15/83  Updated for MDM708		- Irv Hoff
; 04/17/83  Updated for MDM707		- Irv Hoff
; 04/04/83  Updated for MDM706		- Irv Hoff
; 02/27/83  Updated for MDM705		- Irv Hoff
; 02/17/83  Updated for MDM704		- Irv Hoff
; 02/07/82  Updated for MDM703		- Irv Hoff
; 01/27/83  Updated for MDM702		- Irv Hoff
; 01/10/83  Updated for MDM701		- Irv Hoff
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
;
	  ORG	0C00H-48
;
;
; Long distance alternate dialing such as MCI, SPRINT, etc.  Must end
; with a '$', use as many commas (2 seconds delay, each) as needed to
; let the alternate dialing code return with a new dial tone.  Fill in
; any character (periods are fine) after the $ to keep number of columns
; to 24, i.e.,  '1234567,,,,12345,,$.....'   --   the first group is the
; MCI or SPRINT access number, the second group is the user number. (A
; small delay is usually required after the user number also.)
;
ALTDIAL1: DB	'xxxxxxx,,,,,,xxxxxxxx,,$'   ;accessed by a < character
;
ALTDIAL2: DB	'xxxxxxx,,,,,,xxxxxxxx,,$'   ;accessed by a > character
;
;
; Phone number library table for auto-dialing.  Each number must be as
; long as "LIBLEN" (EQU at start of program).  Some areas require extra
; characters such as:   1-313-846-7127.  Room is left for those.  Use
; a (<) for alternate dialing system #1, and a (>) for alternate dialing
; system #2.  Either would preceed the acutal number.  For example:
;
; 	  DB    'A=Alan Alda..........<123-456-7890'    ;'A'
;
; -     -     -     -     -     -     -     -     -     -     -     -
;
;
;		'----5---10---15---20---25---30--34'
NUMBLIB:  DB	'A=Amrad.............1-703-734-1387'	;'A'
	  DB	'B=Al Mehr...........1-408-238-9621'	;'B'
	  DB	'C=CBBS Pasadena.....1-213-799-1632'	;'C'
	  DB	'D=PMMI..............1-703-379-0303'	;'D'
	  DB	'E=Tech. CBBS........1-313-846-6127'	;'E'
	  DB	'F=Tim Cannon........1-312-359-8080'	;'F'
	  DB	'G=Gasnet NASA.......1-301-344-9156'	;'G'
	  DB	'H=Dave Hardy........1-313-846-6127'	;'H'
	  DB	'I=Wayne Hammerly....1-301-953-3753'	;'I'
	  DB	'J=RBBS Pasadena.....1-213-577-9947'	;'J'
	  DB	'K=David Kozinn......1-216-334-4604'	;'K'
	  DB	'L=Program Store.....1-202-337-4694'	;'L'
	  DB	'M=Kelly Smith.......1-805-527-9321'	;'M'
	  DB	'N=Byron McKay.......1-415-965-4097'	;'N'
	  DB	'O=Ken Stritzel......1-201-584-9227'	;'O'
	  DB	'P=Keith Petersen...1-313-759-6569R'	;'P'
	  DB	'Q=Bruce Ratoff......1-201-272-1874'	;'Q'
	  DB	'R=Bill Earnest......1-215-398-3937'	;'R'
	  DB	'S=Edward Svoboda....1-408-732-9190'	;'S'
	  DB	'T=Paul Traina.......1-408-867-1243'	;'T'
	  DB	'U=Kirk de Haan......1-408-408-6158'	;'U'
	  DB	'V=Chuck Forsberg....1-503-621-3193'	;'V'
	  DB	'W=L.A. Heath Group..1-213-749-8442'	;'W'
	  DB	'X=David Morgen......1-503-641-7276'	;'X'
	  DB	'Y=Jud Newell........1-416-213-9538'	;'Y'
	  DB	'Z=John Secor........1-714-774-7860'	;'Z'
;		'----5---10---15---20---25---30--34'
;
	  END
;

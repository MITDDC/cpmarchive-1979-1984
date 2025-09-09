Modification to ZCPR to prompt the user before erasing files.

With this modification installed, ZCPR will prompt the user with
'OK?' after printing the filenames to be erased.  A response of 'y'
or 'Y' will result in the erasure of the files.  Any other character
aborts the ERA command.

ERA1:	;This is the original code.
	CALL	SLOGIN		;LOG IN SELECTED DISK IF ANY
	XRA	A		;PRINT ALL FILES (EXAMINE SYSTEM BIT)
	MOV	B,A		;NO SYS-ONLY OPT TO DIRPR
	CALL	DIRPR		;PRINT DIRECTORY OF ERASED FILES

;INSERT THE FOLLOWING FOR PROMPT AFTER PRINTING DIRECTORY

	MOV	A,E		;E CONTAINS NUMBER OF ENTRIES PRINTED
	ORA	A
	JZ	RESTRT		;DON'T PROMPT USER IF NO FILES
	CALL	PRINTC		;PROMPT USER BEFORE ERASING
	DB	'OK','?'+80H
	CALL	CONIN
	CPI	'Y'		;IF 'y' OR 'Y' THEN ERASE
	JNZ	RESTRT		;ELSE DON'T ERASE FILES

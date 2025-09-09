;
;			BYEBELOW.MOD
;		        by P.L.Kelley
;
;To safely run BYE below CP/M insert the following code in
;BYE.ASM (or SUPERBYE.ASM) after the ORG 100.
;
;This code allows programs such as TYPESQ to be used with
;BYE running below CP/M.
;
;
	LXI	H,OLDBD		;old location stored in 6 and
				;7 for jump from BDOS call
	SHLD	DEST-2		;store it just above BYE
	LXI	H,DEST-3	;point to three bytes above
				;BYE
	MVI	M,0C3H		;put a JMP there
	SHLD	0006H		;store DEST-3 for BDOS JMP
	SHLD	WMLOC		;store DEST-3 in your BIOS
				;for use on warm boot
;
;You will need to find WMLOC in your BIOS. It resides in the
;section of code which restores the BDOS jump at 0005 on warm
;boot. OLDBD is the value stored at WMLOC and WMLOC+1 on cold
;boot.

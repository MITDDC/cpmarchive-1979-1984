/*  Terminal Initialization for TVI 950 by Richard Conn

	The purpose of this program is to quickly initialize the TVI 950
	to a desired state.  Only a file name is allowed, and this program
	has to be reassembled in order to change the initialization
	parameters.
*/

#define	version	11	/* Version Number */

/* Header File */
#include	"a:bdscio.h"

/*  File Name and Mode Strings  */
#define	configfile	"STD.CFG"		/* File Name */
#define	configtype	".CFG"			/* Data File Type */
#define	configmode	0			/* Read/Only */

/*  Basic Constants  */
#define	strlen	100	/* Max number of chars in a string */
#define	ESC	0x1b	/* Escape code */
#define	CR	'\r'	/* Carriage Return */
#define	BEL	0x07	/* Ring Bell */
#define	CTRLH	0x08	/* Backspace Char */
#define	CTRLL	0x0c	/* Cursor Back */
#define	CTRLU	0x15	/* Delete Line Char */
#define	CTRLX	0x18	/* Delete Line Char */
#define	RUBOUT	0x7f	/* Backspace Char */

#define	FALSE	0
#define	TRUE	-1
#define	echo	TRUE
#define	noecho	FALSE
#define	YES	'Y'
#define	NO	'N'

/*  Buffer Sizes  */
#define	ullen	81	/*  User Line Length of ULBUFFER  */
#define	tablen	80	/*  Length of TABBUFFER  */
#define	fkeylen	464	/*  Length of FKEYBUFFER  */

/*  Cursor Positioning  */
#define	gotoxy	'='	/* Position Cursor */

/*  Clear Screen  */
#define	clear	'+'	/* Clear screen */

/*  Function Keys  */
#define	fctkey	'|'	/* Begin function key definition */
#define	fctend	0x19	/* Ctrl-Y for end function key definition */
#define	ctrlp	0x10	/* Control-P for char ESCAPE in Fct Key cmd */

/*  User Line  */
#define	loadusr	'f'	/* Load User Line */
#define	dispusr	'g'	/* Display User Line */
#define	dispst	'h'	/* Display Status Line */

/*  Scrolling  */
#define	sscroll	'8'	/* Enable Smooth Scrolling */
#define	hscroll	'9'	/* Enable Hard Scrolling (no Smooth Scrolling) */

/*  Tabs  */
#define	tabclr	'3'	/* Clear All Tabs */
#define	tabset	'1'	/* Set Tab at Cursor */

/*  Video  */
#define	vidnorm	'd'	/* Normal (white on black) Video */
#define	vidrev	'b'	/* Reverse (black on white) Video */

/*  Key Click  */
#define	clkon	'>'	/* Keyclick ON */
#define	clkoff	'<'	/* Keyclick OFF */

/*  Cursor Type  */
#define	curs	'.'	/* Set cursor attribute */

/*  Single-char settings  */
#define	cls	'+'	/* Clear Screen */
#define	unlock	'"'	/* Unlock Keyboard */
#define	nograph	'%'	/* Graphics Mode OFF */
#define	noprot	0x27	/* Protect Mode OFF */
#define	normi	'('	/* Normal Intensity */
#define	notabs	'3'	/* Clear All Tabs */
#define	noclick	'<'	/* Key Click OFF */
#define	nocopy	'A'	/* Copy Print Mode OFF */
#define	cmode	'C'	/* Conversation Mode ON (Block Mode OFF) */
#define	fdx	'F'	/* Full Duplex */
#define	nomonit	'X'	/* Clear Monitor Mode */
#define	nobufpr	'a'	/* Buffer Print OFF */
#define	vid1	'd'	/* White on Black */
#define	nopage	'w'	/* Auto Page OFF */

/*  String Settings  */
#define	videom	"G0"	/* Normal Video */
#define	insert	"e "	/* Set Insert Char to <SP> */

char	iobuf[BUFSIZ];
char	ulbuffer[ullen], tabbuffer[tablen], fkeybuffer[fkeylen];
char	cursor, click, scroll, uline, video, tabs, fkeys;

main(argc,argv)
int	argc;
char	**argv;
{
	char *argstr;

	banner();  /* Print Banner */
	tinit();  /* Initialize terminal */
	switch (argc) {
	   case 1  :	readfile(configfile);  /* Program from default */
			program();
			break;
	   case 2  :	argstr = argv[1];  /* Pt to first arg */
			if (*argstr == '/') help();
			else {
				readfile(argstr);  /* Program from file */
				program();
				}
			break;
	   default :	help(); break;
	   }
	exit(TRUE);
}  /* End of Mainline */

help()  /* HELP File */
{
	banner();  /* Print Banner */
	printf("\nTerminal Initialization for TVI 950");
	printf("\n\n\tThis program is invoked in one of two ways --");
	printf("\n\t\tTINIT  <-- Initialize from %s File",configfile);
	printf("\n\t\tTINIT filename.typ  <-- Initialize from file");
	printf("\n\t\t\t\t(typ defaults to CFG)\n");
}

banner()  /* Print Banner of Program */
{
	printf("\nTINIT Version %d.%d\n",version/10,version%10);
}

readfile(name)  /* Read Indicated File */
char *name;
{
	int fd, i, type, inch;
	char newfile[20], filename[20], *ptr;

	ptr = name;  /* Copy passed name into FILENAME */
	type = FALSE;
	i = 0;
	while (*ptr != '\0') {
		if (*ptr == '.') type = TRUE;  /* Note if file type given */
		filename[i++] = *ptr++;
		}
	filename[i] = '\0';
	if (!type) strcat (filename,configtype);  /* Set default file type */

	fd = fopen (filename, iobuf);  /* Try to open file */
	if (fd == ERROR) {  /* If failure, try to open file on A: */
		newfile[0] = '\0';
		strcat (newfile,"A:");
		strcat (newfile,filename);
		fd = fopen (newfile, iobuf);
		if (fd == ERROR) {  /* If this fails, give error */
			printf("File %s not found", filename);
			exit (FALSE);
			}
		}

	/* Read in parameters from disk file */
	inch = getc(iobuf); if (inch == ERROR) abort();
	cursor = inch;
	inch = getc(iobuf); if (inch == ERROR) abort();
	fkeys = inch;
	inch = getc(iobuf); if (inch == ERROR) abort();
	click = inch;
	inch = getc(iobuf); if (inch == ERROR) abort();
	scroll = inch;
	inch = getc(iobuf); if (inch == ERROR) abort();
	tabs = inch;
	inch = getc(iobuf); if (inch == ERROR) abort();
	uline = inch;
	inch = getc(iobuf); if (inch == ERROR) abort();
	video = inch;
	getc(iobuf); getc(iobuf);  /* Ignore <CR> <LF> */
	if (uline == YES) readbuffer (ulbuffer, ullen);
	if (tabs == YES) readbuffer (tabbuffer, tablen);
	if (fkeys == YES) readbuffer (fkeybuffer, fkeylen);
	fclose(iobuf);
}

readbuffer (bufname, buflen)  /* Read into the buffer pted to by bufname */
char *bufname;
int buflen;
{
	int i, inch;
	char *bptr;

	bptr = bufname;
	for (i=1;i<=buflen;i++) {
		inch = getc(iobuf);
		if (inch == ERROR) abort();
		*bptr++ = inch;
		}
	getc(iobuf); getc(iobuf);  /* Flush <CR> <LF> */
}

program()  /* Program the Terminal */
{
	char *pstr;
	int i;
	char fch;

	printf("%c%c%c",ESC,curs,cursor);  /* Config Cursor Type */
	if (fkeys == YES) {  /* Program Function Keys */
		for (i=1;i<=22;i++) {
			pstr = fkeybuffer + (i-1)*20;
			fch = i+'1'-1;
			if (*pstr != '\0')
			   printf("%c%c%c%s%c",ESC,fctkey,fch,pstr,fctend);
			}
		}
	cmnd(click);  /* Set Key Click */
	cmnd(scroll);  /* Set Scrolling */
	if (tabs == YES) {  /* Set Tab Stops */
		cmnd(tabclr);  /* Clear ALL Tab Stops */
		printf("\n");
		pstr = tabbuffer;
		for (i=1;i<=80;i++) {
			if (*pstr++ == '.') cmnd(tabset); 
			putchar(' ');
			}
		printf("\n"); sleep(2);  /* Delay 0.2 sec */
		}
	if (uline == YES) {  /* Program User Line */
		printf("%c%c%s%c",ESC,loadusr,ulbuffer,'\r');
		cmnd(dispusr);
		}
	sleep(2);  /* Delay 0.2 sec */
	cmnd(video);
	cmnd(cls);  /* New Screen */
}

tinit()  /* Initialize Terminal */
{
	cmnd (unlock);
	cmnd (nograph);
	cmnd (noprot);
	cmnd (normi);
	cmnd (notabs);
	cmnd (noclick);
	cmnd (nocopy);
	cmnd (cmode);
	cmnd (fdx);
	cmnd (nomonit);
	cmnd (nobufpr);
	cmnd (vid1);
	cmnd (nopage);
	cmnds (videom);
	cmnds (insert);
	sleep(2);  /* Delay 0.2 sec */
}

abort()  /* Abort to CP/M */
{
	printf("\nFatal Error in Data File -- Aborting\n");
	exit(FALSE);
}

cmnd (ch)  /* Issue single-character command */
char ch;
{
	putchar(ESC); putchar(ch);
}

cmnds (st)  /* Issue String command */
char *st;
{
	printf("%c%s",ESC,st);
}

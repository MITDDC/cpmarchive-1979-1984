/*
	Directed I/O package for BDS C v1.45   LZ -- 12/81

	The following functions make up the directed I/O library:

	1. dioinit(&argc,argv)		Make this the first thing you do in
					your "main" function, to process
					redirection commands on the CP/M
					command line.

	2. getchar()			Gets a character from the keyboard,
					or from a directed input file if one
					was specified on the command line.

	3. putchar(c)			Puts a character out to the console,
					or to a directed output file if one
					was specified on the command line.

	4. dioflush()			Flushes directed output file, if open,
					and closes all directed I/O files (if
					any.) This must be called before your
					program exits or returns to CP/M.

	To activate redirection: Four special arguments may be given
	on the command line to the generated COM file...

		>foo	causes "putchar" to place characters into the file
			named "foo" instead of to the console.

		+foo	like >foo except that the characters are ALSO sent
			to the console.

		<foo	causes "getchar" to return characters from the file
			named "foo" instead of from the keyboard.

	 command |prog	causes the standard output of the command specified in
			"command" to be fed into the standard input of another
			program, "prog". (BOTH "command" and "prog" must be
			compiled with DIO)

	(Note that there must never be any spaces between >,+,< or | and the
	 corresponding filename.)

	When no "<" or "|" operator is used, standard input comes from the
	console and all standard line editing characters are recognized (a 
	new feature of v1.45). To indicate end-of-file, you must type
		^Z <CR>
	(control-Z followed by	a carriage-return.)

	When no ">" or "|" operator is used, standard output goes to the
	console.
	 
	A program allowing redirection must have the following form:

		#include "bdscio.h"		/* standard header file	*/
		#include "dio.h"		/* directed I/O header	*/

		...				/* other externals, if any */

		main(argc,argv)
		char **argv;
		{
			...			/* declarations		*/
			dioinit(&argc,argv)	/* initialize redirection */
			...			/* body of program	*/
			dioflush();
		}
			
	NOTES:

	0. The console input may be raw (unbuffered, one char. at a time) or
	   buffered (entire line must be typed before chars are returned,
	   allowing standard editing features, and characters come back one
	   at a time AFTER the entire line is typed). The default is raw; to
	   have buffered console input, uncomment the "#define BUF_CONS" line
	   in DIO.H and recompile this file and all files in your program.

	1. Redirection and pipes work only for TEXT. This mechanism should
	   not be used for binary data.

	2. Use "-f sio" to link the program; this ensures that the proper
	   versions of "getchar" and "putchar" are used. Do not define
	   your own "getchar" or "putchar", or things will get confused.

	3. Multiple pipes may be chained on one command line. For example,
	   the following command feeds the output of program "foo" into the
	   input of program "bar", the output of "bar" into the input of
	   program "zot", and the output of "zot" into a file called "output":

		A>foo arg1 |bar |zot arg2 arg3 >output <cr>

	   "arg1" is an actual argument to "foo", and "arg2" and "arg3" are
	   actual arguments to "zot". This illustrates how actual arguments
	   may be interspersed with redirection commands. The programs see
	   the actual arguments, but command line preprocessing handled by the
	   "dioinit" function cause the programs to never need to know about
	   the redirection commands. Note that all three programs ("foo", "bar"
	   and "zot") must have been compiled and linked to use the "DIO"
	   package.
*/

#include "bdscio.h"
#include "dio.h"

#define CON_INPUT	1		/* BDOS call to read console	   */
#define CON_OUTPUT	2		/* BDOS call to write to console   */
#define CON_STATUS	11		/* BDOS call to interrogate status */

#define CONTROL_C	3		/* Quit character		   */
#define STDERR		4		/* Standard Error descriptor (sorry,
					   Unix fans, 2 was already used.) */
#define INPIPE		2		/* bit setting to indicate directed
					   input from a temp. pipe file    */
#define VERBOSE		2		/* bit setting to indicate output is to
					   go to console AND directed output */

/* 
	The "dioinit" function must be called at the beginning of the
	"main" function:
*/

#define argc *argcp

dioinit(argcp,argv)
int *argcp;
char **argv;
{
	int i,j, argcount;

	_diflag = _doflag = _pipef = FALSE;  /* No directed I/O by default   */
	_nullpos = &argv[argc];

#ifdef BUF_CONS
	_conbuf[0] = 0;			/* no characters in buffer yet	*/
	_conbufp = _conbuf;		/* point to null buffer 	*/
#endif

	argcount = 1;

	for (i = 1; i < argc; i++)	/* Scan the command line for > and < */
	{
		if (_pipef) break;
		switch(*argv[i]) {

		   case '<':		/* Check for directed input:	*/
			if (!argv[i][1]) goto barf;
			if (fopen(&argv[i][1], _dibuf) == ERROR)
			{
				fprintf(STDERR,"Can't open %s\n",&argv[i][1]);
				exit();
			}
			_diflag = TRUE;
			if (strcmp(argv[i],"<TEMPIN.$$$") == 0)
				 _diflag |= INPIPE;
			goto movargv;

		   case '|':	/* Check for pipe: */
			_pipef++;
			_pipedest = &argv[i][1]; /* save prog name for execl */
			if (argv[i][1]) 
			{
				argv[i] = ".TEMPOUT.$$$";  /* temp. output */
				_savei = &argv[i];
			}
			goto foo;

		   case '+': 
			_doflag |= VERBOSE;
			
	     foo:   case '>':	/* Check for directed output	*/
		
			if (!argv[i][1]) 
			{
		    barf:   fprintf(STDERR,"Bad redirection/pipe specifier");
			    exit();
			}
			unlink(&argv[i][1]);
			if (fcreat(&argv[i][1], _dobuf) == ERROR)
			{
			       fprintf(STDERR,"Can't create %s\n",&argv[i][1]);
			       exit();
			}
			_doflag++;

	     movargv:	if (!_pipef) {
				for (j = i; j < argc; j++) argv[j] = argv[j+1];
				(argc)--;
				i--;
				_nullpos--;
			 } else {
				argc = argcount;
				argv[argc] = 0;
			 }
			break;

		    default:	/* handle normal arguments: */
			argcount++;
		}
	}
}


#undef argc

/*
	The "dioflush" function must be called before exiting the program:
*/

dioflush()
{
	if (_diflag)
	{
		fclose(_dibuf);
		if (_diflag & INPIPE) unlink("tempin.$$$");
	}

	if (_doflag)
	{
		putc(CPMEOF,_dobuf);
		fflush(_dobuf);
		fclose(_dobuf);
		unlink("tempin.$$$");	/* in case previous pipe was aborted */
		rename("tempout.$$$","tempin.$$$");
		if (_pipef) 
		{
			*_savei = "<TEMPIN.$$$";
			*_nullpos = NULL;
			if (execv(_pipedest,_savei) == ERROR)
			{
				fprintf(STDERR,"Broken pipe\n");
				exit();
			}
		}
	}
}


/*
	This version of "getchar" replaces the regular version when using
	directed I/O. Note that the "BUF_CONS" defined symbol (in DIO.H)
	controls whether the console input is to be raw or buffered (see
	item 0. in NOTES above)
*/

getchar()
{
	char c;

	if (_diflag) {
		if ((c = getc(_dibuf)) == '\r') c = getc(_dibuf);
	}
	else

#ifdef BUF_CONS		/* For buffered console input, get a line of text   */
	{		/* from the BDOS (using "gets"), & insert newline:  */
		if (!*_conbufp) {   
			gets(_conbufp = _conbuf);
			_conbuf[strlen(_conbuf) + 1] = '\0';
			_conbuf[strlen(_conbuf)] = '\n';
		}
		c = *_conbufp++;
	}
#else			/* for raw console input, simulate normal "getchar": */
		if ((c = bdos(CON_INPUT)) == CONTROL_C) exit();
#endif

	if (c == CPMEOF) return EOF;	     /* Control-Z is EOF key 	*/

	if (c == '\r') 
	{
		c = '\n';
#ifndef BUF_CONS
		if (!_diflag) bdos(2,'\n');  /* echo LF after CR to console */
#endif
	}
	return c;
}


/*
	This version of "putchar" replaces the regular version when using
	directed I/O:
*/

putchar(c)
char c;
{
	if (_doflag)
	{
		if (c == '\n') putc('\r',_dobuf);
		if(putc(c,_dobuf) == ERROR)
		{
			fprintf(STDERR,"File output error; disk full?\n");
			exit();
		}
		if (!(_doflag & VERBOSE)) return;
	}

	if (bdos(CON_STATUS) && bdos(CON_INPUT) == CONTROL_C) exit();
	if (c == '\n') bdos(CON_OUTPUT,'\r');
	bdos(CON_OUTPUT,c);
}

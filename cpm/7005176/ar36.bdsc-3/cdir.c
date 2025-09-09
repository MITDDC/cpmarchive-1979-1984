/*
	CDIR.C - A CP/M 2.2 utility that allows operators to switch
between user numbers by specifiying a name, rather than a number. This
has the effect of simulating sixteen named directories in a convenient
manner.

	When used in conjunction with ZCPR, and DUPUSR, CDIR can make
CP/M a lot more livable until an operating system with a nice
directory structure arrives.

	CDIR.C - (C) 1982 by Barry A. Dobyns.
	Commercial use (sales) of this program is prohibited,
	however, private use by individuals is encouraged.

-----------------------------------------------------------------
USAGE:
	cdir	<dirname>
		changes to the user number that corresponds to dirname

	cdir /l
		lists available dirnames and the corresponding numbers

	cdir /s <dirname> <number>
		sets dirname to correspond to number

	cdir	/d <dirname>
		deletes dirname

	cdir	/z
		deletes all dirnames

-----------------------------------------------------------------
Usage notes:

	CDIR keeps the correspondence table in a data area stored with
the com file. a /s /z or /d operation forces CDIR to write itself back
out to disk.

	Also, CDIR has a list of 'internal' names that are not kept in
the list. This list includes names '0'-'15', 'a'-'f' and 'root'. Any
name occuring in the internal list cannot be set or deleted.

	Remember to zero out the table before using CDIR.

	If using CDIR with ZCPR or any CP/M hack that searches other
drives, be careful when using /s /d and /z. Also, CDIR restricts the
use of these switches to user 0.

-----

	create:
		A>cc cdir.c			;compile
		A>l2 cdir.c			;link
		A>noboot cdir.c		;fix CP/M boot problem
		A>cdir /z				;zero out names table

	As best as I can determine, CP/M loses the user number set from
within an application program iff the program terminates with a warm
boot instead of a ret. In other words, in the code below, the program
on the left leaves one in user 15, as expected. The program on the
right leaves one in whatever the previously selected user area was.

		;I win					;I lose
		;						;
		org	100H					org	100H
		mvi	c,32					mvi	c,32
		mvi	e,15					mvi	e,15
		call	5					call	5
		ret						jmp	0

	Anyone know why?? Therefore, CDIR must be run over with NOBOOT so
that it returns and does not boot, otherwise it isn't very useful.

-----
*/

#define	ERROR	(-1)
#define	FALSE	0
#define	TRUE		1
#define	CDIR		"CDIR.COM"
#define	DIRMAX	50

struct entry {
	char	dvalid;			/* whether or not it is active. */
	char	dnumber;			/* the corresponding user number */
	char	dname[20];		/* the directory name */
	} dirlist[DIRMAX];

int tmp;

main(argc,argv)
	int argc;
	char **argv;
{

	if (argc == 2) {				/* one argument */
		if (match(argv[1],"/L")) {	/* either list */
			list();
			}
		else if ( match(argv[1],"/Z")
				&& inzero() ) {	/* or zero */
			zero();
			}
		else switchto(argv[1]);		/* or switch to */
		} /* end (argc == 2) */

	else if ( (argc == 3) && match(argv[1],"/D")
			&& inzero() ) {		/* delete */
		delete(argv[2]);
		} /* end (argc == 3) */

	else if ( (argc == 4) && match(argv[1],"/S")
			&& inzero() ) {		/* set */
		set(argv[2],atoi(argv[3]));
		}

	else usage();					/* bad commands */

	puts("Done.");

	}	/* end of main */

list()	/* print a list of all the names */
{
	for (tmp = 0; tmp < DIRMAX; tmp++){
		if (dirlist[tmp].dvalid)
			printf("\t%s\t%d\n", dirlist[tmp].dname, dirlist[tmp].dnumber);
		}

	}	/* end of list() */

zero()	/* zero (initialize) the table */
{

	setmem(codend(),endext()-codend(),0);

	wrtcdir();

	}	/* end of zero() */

switchto(name)	/* switch to the user area associated with name */
char *name;
{
	if ( (tmp=internal(name)) != ERROR ) {	/* if it's internal */
		setuser(tmp);					/* do it now */
		return;
		}

	else for (tmp = 0; tmp < DIRMAX; tmp++){ /* find it in list */
		if ( (dirlist[tmp].dvalid) && match(name,dirlist[tmp].dname) ){
			setuser(dirlist[tmp].dnumber);
			return;
			}
		}
	/* can't find name */
	printf("Can't find name %s \n",name);
	}	/* end of switchto(name) */


delete(name)	/* remove name from list */
char *name;
{
	if ( (tmp=internal(name)) != ERROR ) return;

	else for (tmp = 0; tmp < DIRMAX; tmp++){
		if ( (dirlist[tmp].dvalid) && match(name,dirlist[tmp].dname) ){
			dirlist[tmp].dvalid = FALSE;
			wrtcdir();
			return;
			}
		}
	/* can't find name */
	printf("Can't find name %s \n",name);
	}	/* end of delete(name) */

set(name,number)	/* install name in list */
char *name,number;
{
	if ( (tmp=internal(name)) != ERROR ) return;

	else for (tmp = 0; tmp < DIRMAX; tmp++){
		if ( !(dirlist[tmp].dvalid) ){
			dirlist[tmp].dvalid = TRUE;
			dirlist[tmp].dnumber = number & 0x0f;
			strcpy(dirlist[tmp].dname,name);
			wrtcdir();
			return;
			}
		}
	/* no more space */
	printf("No space to add name %s \n",name);
	}	/* end of set(name,number) */

setuser(number)
char number;
{

	number &= 0x0F;		/* mask it */
	bdos(32,number);		/* set it */
	number = bdos(32,0xff);	/* make sure. */
	printf("user %d\n",number);
	}

wrtcdir()
{
	int nscts;

	nscts= (endext() + 128) / 128;

	if ( ( (tmp = open(CDIR,1)) == ERROR)
		||  ( seek(tmp,0,0) == ERROR )
		||  ( write(tmp,0x100,nscts) != nscts)
		||  ( close(tmp) == ERROR) )
		printf("Fatal Error - cannot write %s !",CDIR);

	}	/* end of wrtcdir() */

usage()
{
	puts("USAGE:\n");
	puts("\tcdir <dirname>\n");
	puts("\t\tchanges to the user number that corresponds to dirname\n\n");
	puts("\tcdir /l\n");
	puts("\t\tlists available dirnames and the corresponding numbers\n\n");
	puts("\tcdir /s <dirname> <number>\n");
	puts("\t\tsets dirname to correspond to number\n\n");
	puts("\tcdir /d <dirname>\n");
	puts("\t\tdeletes dirname \n\n");
	puts("\tcdir /z\n");
	puts("\t\tdeletes all dirnames \n\n");
	} /* end of usage() */

badob()
{
	return("(C) Copyright 1982 by Barry A. Dobyns");
	} /* end of badob() */

match (s1, s2)				/* case-independent string equality */
	char *s1, *s2;
{
	while (TRUE) {
		if (toupper (*s1) != toupper (*s2)) return (FALSE);
		if (!*s1++ || !*s2++) return (TRUE);
		}
	}

internal(name)
char *name;
{
	if ( (match(name,"root")) ||  (match(name,"0")) )
		return(0);

	else if (match(name,"1"))
		return(1);

	else if (match(name,"2"))
		return(2);

	else if (match(name,"3"))
		return(3);

	else if (match(name,"4"))
		return(4);

	else if (match(name,"5"))
		return(5);

	else if (match(name,"6"))
		return(6);

	else if (match(name,"7"))
		return(7);

	else if (match(name,"8"))
		return(8);

	else if (match(name,"9"))
		return(9);

	else if (match(name,"9"))
		return(9);

	else if (  (match(name,"10")) || (match(name,"a")) )
		return(10);

	else if (  (match(name,"11")) || (match(name,"b")) )
		return(11);

	else if (  (match(name,"12")) || (match(name,"c")) )
		return(12);

	else if (  (match(name,"13")) || (match(name,"d")) )
		return(13);

	else if (  (match(name,"14")) || (match(name,"e")) )
		return(14);

	else if (  (match(name,"15")) || (match(name,"f")) )
		return(15);

	else return(ERROR);
	}	/* end of internal(name) */

inzero()	/* true if we're in user 0 */
{
	return(bdos(32,0xff) == 0);
	}	/* end inzero() */

/* end of cdir.c */

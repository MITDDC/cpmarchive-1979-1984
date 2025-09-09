/*		Find Pattern
 *
 *	This is a program which prints out all lines in a file with a
 * given pattern.  It can be conditionally compiled for either CP/M or
 * Unix.  In either case, it is invoked by:
 *
 *		fp <pattern> <file(s)>
 *
 *	The <file(s)> specification can use normal file widcards, as
 * defined by wildexp in CP/M and the shell in Unix.
 *	The <pattern> is a string of characters, some of which have special
 * meanings:
 *
 *		<char> - any character not listed below matches exactly that
 *			 character.
 *		? - matches any single character.
 *		* - matches zero or more of any character.
 *		[...] - matches one of any of the characters included between
 *			the brackets; character ranges can also be indicated
 *			by <char>-<char>.  E.g., [a-z0-9] will match any
 *			letter or digit.
 *		[-...] - matches one of any of the characters not included
 *			 between the brackets.
 *
 *	Also, backslash (\) can be used to quote characters (i.e., keep them
 * from being interpreted specially).
 *
 *	To compile and load the program, make sure that one of UNIX or CPM
 * is defined (not both!) in fp.c, and that you have pat.h and pat.c (and
 * wildexp.crl).  On CP/M, then do:
 *
 *		cc1 pat.c
 *		cc1 fp.c
 *		clink fp pat wildexp
 *
 *	On Unix, then do:
 *
 *		cc -O -o fp fp.c pat.c
 *
 *	Note: On Unix, fp runs about three times slower than grep, so it's
 * not clear why you'd want to use it.  This is probably because I use
 * recursion.  Maybe I'll do a non-recursive version later, but this way
 * is much simpler.
 *
 *
 *	Initial coding 8/18/82 by Harry R. Chesley.
 *
 *
 *	Copyright 1982 by Harry R. Chesley.
 *	Unlimited permission granted for non-profit use only.
 */

#include "pat.h"

/* UNIX - defined for use on Unix.
 * CPM - defined for use on CP/M (with BDS-C).
 *
 * MAXBSZ - max size of text buffer (big to minimize IO); should be a multiple
 *	    of 128 for CPM, but doesn't really have to be.  One more char is
 *	    allocated so that a zero byte can be appended when printing
 *	    strings.
 * MAXPSZ - max size of pattern string.
 */

#define UNIX
/*#define CPM*/

#define MAXBSZ 10240+1
#define MAXPSZ 100

/*	main()
 *
 *	Function: Invoked by "fp <pattern> <files>".  Prints every line in
 * each file containing the pattern.
 *
 *	Algorithm: Use srchpat() to locate each subsequent line to be output.
 *
 *	Comments: The only tricky things here are: (1) The search pattern is
 * surrounded with "*"s because srchpat() will only do exact matches;
 * inserting the "*"s makes it match the pattern anywhere on the line.  And
 * (2) when we find outselves at the end of a buffer, we read in a new buffer
 * of text, but keep any partial lines to concatenate with the next buffer
 * load.
 *	I use puts() in the CP/M version because BDS-C printf breaks on long
 * lines.  I don't use it in the Unix version because Unix puts() appends
 * newlines to the string.
 */

main(argc,argv)

int argc;
char *argv[];

{
	int fd;			/* File descriptor. */
	char tbuf[MAXBSZ];	/* Input buffer. */
	char pat[MAXPSZ];	/* Search pattern. */
	char *pptr;		/* Pattern string pointer. */
	char *aptr;		/* Argv pattern pointer. */
	char *nptr;		/* New pointer (in copying partials). */
	char *tptr;		/* Text pointer (while searching). */
	char *retstr;		/* Srchpat() return value. */
	char *eosret;		/* EOS pointer return from srchpat(). */
	char ctmp;		/* Temp storage. */
	int sz, osz;		/* Bytes remaining sizes. */

#ifdef CPM
	/* Fake command name. */
	argv[0] = "FP";
#endif

	/* Verify proper calling procedure: */
	if (argc < 3) {
		printf("Usage: %s <pattern> <file(s)>\n",argv[0]);
		exit(1);
	};

	/* Copy search pattern, prepend and postpend "*". */
	pptr = pat;
	*pptr++ = '*';
	for (aptr = argv[1]; *aptr != 0; *pptr++ = *aptr++);
	*pptr++ = '*';
	*pptr = 0;

	/* Compile search pattern; normal EOL, ignore case. */
	comppat(pat,'\n',TRUE);

#ifdef CPM
	/* Remove search pattern from argv, and expand file names. */
	argv[1] = "NOARG";
	wildexp(&argc, &argv);
#endif

	/* Go thru the files one by one. */
	argc--; argv++; argc--; argv++;	/* Skip command name and pattern. */
	while (argc-- > 0) {
		if ((fd = open(argv[0],0)) == -1) {
			printf("Bad file name: %s!\n",argv[0]);
			argv++;
			continue;
		};
		
		/* Read & write, read & write, ... */
		osz = 0;
#ifdef UNIX
		while ((sz = read(fd,tbuf+osz,(MAXBSZ-1)-osz)) > 0) {
#endif
#ifdef CPM
		while ((sz = 128*read(fd,tbuf+osz,((MAXBSZ-1)-osz)/128)) > 0){
#endif
			osz += sz;
			tptr = tbuf;

			/* While there's something worth printing. */
			while ((retstr = srchpat(tptr,osz,&eosret)) != 0) {
				ctmp = *eosret;
				*eosret = 0;
#ifdef UNIX
				printf("%s: %s",argv[0],retstr);
#endif
#ifdef CPM
				puts(argv[0]); puts(": "); puts(retstr);
#endif
				*eosret = ctmp;
				osz -= eosret - tptr;
				tptr = eosret;
			};

			/* Find partial line at end. */
			tptr += osz-1;
			for (sz = 0; sz != osz; sz++) {
				if (*tptr == '\n') break;
				tptr--;
			};

			/* Copy partial. */
			tptr++;
			osz = sz;
			for (nptr = tbuf; sz != 0; sz--) *nptr++ = *tptr++;
		};

		close(fd);
		argv++;
	};
}

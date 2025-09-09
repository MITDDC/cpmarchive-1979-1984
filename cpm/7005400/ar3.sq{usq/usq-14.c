/* Program to unsqueeze files formed by sq.com
 *
 * Useage:
 *	USQ item ...
 * where ... represents more (optional) items and
 * "item" is either:
 *	drive:		to change the output drive
 *	file		input file
 *	drive:file	input file
 *	-count		Previewing feature: redirects output
 * 			files to standard output with parity stripped
 *			and unprintables except CR, LF, TAB and  FF
 *			converted to periods. Limits each file
 *			to first count lines and appends FF.
 *			Defaults to console, but see below how
 *			to capture all in one file for further
 *			processing, such as by PIP.
 *			Count defaults to a very high value.
 *			No CRC check is performed when previewing.
 *			Use drive: to cancel this.
 *
 * If no such items are given on the command line you will be
 * prompted for commands (one at a time). An empty command
 * terminates the program.
 *
 * USQ uses the dio package, so input and output can be redirected
 * by special items on the command line such as:
 *	<file		reads console input from file
 *	>file		sends console output to file
 *	+file		sends console output to console and file
 * Also console output of another program using dio can be piped
 * to the input of USQ or vice-versa. Example:
 *	A>fls parameters |usq
 * where fls might be a program that expands patterns like *.asm
 * to a list of specific file names for usq to unsqueeze.
 *
 * The unsqueezed file name is recorded in the squeezed file.
 * 
 * Examples:
 *	A>USQ GRUMP.QQQ		writes on a:
 *	A>USQ D:CRAP.XQZ	writes on A:
 *	A>USQ B: D:CRAP.CQM	writes on B:
 *	B>USQ X.AQ C: Y.BQ	writes X.?? on B: and Y.?? on C:
 */
/* CHANGE HISTORY:
 * 1.3	Close inbuff to avoid exceeding maximum number of
 *	open files. Includes rearranging error exits.
 * 1.4	Add -count option to allow quick inspection of files.
 */

#include <bdscio.h>
#include <dio.h>
#include "sqcom.h"
#include "usq.h"
#define VERSION "1.4   07/03/81"
#define STDERR 4	/*Error output stream (always cxonsole) */

/* This must follow all include files */
unsigned dispcnt;	/* How much of each file to preview */

main(argc, argv)
int argc;
char *argv[];
{
	int i,c;
	int getchar();		/* Directed io version */
	char inparg[16];	/* parameter from input */

	dioinit(&argc, argv);	/* obey directed to args */

	dispcnt = 0;	/* Not in preview mode */

	fprintf(STDERR, "File unsqueezer version %s by\n\tRichard Greenlaw\n\t251 Colony Ct.\n\tGahanna, Ohio 43230\n", VERSION);
	fprintf(STDERR, "Accepts redirection and pipes.\nOmit other parameters for help and prompt\n");

	/* Initialize output drive to default drive */
	outdrv[0]  = '\0';
	/* But prepare for a specific drive */
	outdrv[1] = ':';
	outdrv[2] = '\0';	/* string terminator */

	/* Process the parameters in order */
	for(i = 1; i < argc; ++i)
		obey(argv[i]);

	if(argc < 2) {
		fprintf(STDERR, "Parameters are from command line or one-at-a-time from standard input and are output drives and input file names. Empty to quit.\n");
		do {
			fprintf(STDERR, "\n*");
			for(i = 0; i < 16; ++i) {
				if((c = getchar()) == EOF)
					c = '\n';	/* force empty (exit) command */
				if((inparg[i] = c) == '\n') {
					inparg[i] = '\0';
					break;
				}
			}
			if(inparg[0] != '\0')
				obey(inparg);
		} while(inparg[0] != '\0');
	}
	dioflush();	/* clean up any directed io */
}

obey(p)
char *p;
{
	char *q;

	if(*p == '-') {
		/* Set number of lines of each file to view */
		dispcnt = 65535;	/* default */
		if(*(p+1))
			if((dispcnt = atoi(p + 1)) == 0)
				fprintf(STDERR, "\nBAD COUNT %s", p + 1);
		return;
	}	

	if(*(p + 1) == ':') {
		/* Got a drive */
		if(isalpha(*p)) {
			if(*(p+2) == '\0') {
				/* Change output drive */
				dispcnt = 0;	/* cancel previewing */
				printf("\nOutput drive =%s",p);
				outdrv[0] = *p;
				return;
			}
		} else {
			fprintf(STDERR, "\nERROR - Ignoring %s", p);
			return;
		}
	}

	/* Check for ambiguous (wild-card) name */
	for(q = p; *q != '\0'; ++q)
		if(*q == '*' || *q == '?') {
			fprintf(STDERR, "\nCan't accept ambiguous name %s", p);
			return;
		}

	unsqueeze(p);
}


unsqueeze(infile)
char *infile;
{
	struct _buf inbuff, outbuff;	/* file buffers */
	int i, c;
	char cc;

	char *p;
	unsigned filecrc;	/* checksum */
	int numnodes;		/* size of decoding tree */
	char outfile[16];	/* output file name */
	unsigned linect;	/* count of number of lines previewed */

	if(fopen(infile, &inbuff) == ERROR) {
		fprintf(STDERR, "Can't open %s\n", infile);
		return;
	}
	/* Initialization */
	linect = 0;
	crc = 0;
	init_cr();
	init_huff();

	/* Process header */
	if(getw(&inbuff) != RECOGNIZE) {
		fprintf(STDERR, "%s is not a squeezed file\n", infile);
		goto closein;
	}

	filecrc = getw(&inbuff);

	/* Get original file name */
	p = origname;	/* send it to array */
	do {
		*p = getc(&inbuff);
	} while(*p++ != '\0');

	/* Combine with output drive */
	outfile[0] = '\0';		/* empty */
	strcat(outfile, outdrv);	/* drive */
	strcat(outfile, origname);	/* name */

	printf("\n%s -> %s: ", infile, outfile);


	numnodes = getw(&inbuff);

	if(numnodes < 0 || numnodes >= NUMVALS) {
		fprintf(STDERR, "%s has invalid decode tree size\n", infile);
		goto closein;
	}

	/* Initialize for possible empty tree (SPEOF only) */
	dnode[0].children[0] = -(SPEOF + 1);
	dnode[0].children[1] = -(SPEOF + 1);

	/* Get decoding tree from file */
	for(i = 0; i < numnodes; ++i) {
		dnode[i].children[0] = getw(&inbuff);
		dnode[i].children[1] = getw(&inbuff);
	}

	if(dispcnt) {
		/* Use standard output for previewing */
		putchar('\n');
		while(((c = getcr(&inbuff)) != EOF) && (linect < dispcnt)) {
			cc = 0x7f & c;	/* strip parity */
			if((cc < ' ') || (cc > '~'))
				/* Unprintable */
				switch(cc) {
				case '\r':	/* return */
					/* newline will generate CR-LF */
					goto next;
				case '\n':	/* newline */
					++linect;
				case '\f':	/* formfeed */
				case '\t':	/* tab */
					break;
				default:
					cc = '.';
				}
			putchar(cc);
		next: ;
		}
		putchar('\f');	/* formfeed */
	} else {
		/* Create output file */
		if(fcreat(outfile, &outbuff) == ERROR) {
			fprintf(STDERR, "Can't create %s\n", outfile);
			goto closeall;
		}
		/* Get translated output bytes and write file */
		while((c = getcr(&inbuff)) != EOF) {
			crc += c;
			if((putc(c, &outbuff)) == ERROR) {
				fprintf(STDERR, "Write error in %s\n", outfile);
				goto closeall;
			}
		}

		if(filecrc != crc)
			fprintf(STDERR, "ERROR - checksum error in %s\n", outfile);


	closeall:
		fflush(&outbuff);
		fclose(&outbuff);
	}

closein:
	fclose(&inbuff);
}


#Unix(TM) version of crck along with some other handy programs
#for Unix - CP/M(TM) file transfers.
#
echo x - comhex.1t
cat >comhex.1t <<'!E!O!F!'
.TH COMHEX 1T "3/23/82 Tek Local"
.SH NAME
comhex \-  convert from cp/m* .com file to .hex file format
.SH SYNOPSIS
.B comhex
[file] ...
.SH DESCRIPTION
.I Comhex
reads .com format from the named files
(standard input is default),
converts it to the Intel format and writes it on stdout.
The output format is fixed and is suitable for input to the cp/m*
LOAD utility.
.PP
.SH EXAMPLES
To convert a cp/m* .com file format
.I m.com
to .hex format file
.I t.hex.
.br
.tl ''comhex < m.com > t.hex''
.SH DIAGNOSTICS
Makes no complaints about any input conditions except those
recognized by 'cat'.
Does not care about the actual 'extensions' to the filenames used.
.SH HISTORY
Comhex is a corruption of cat.c.
Corruptions originally made by Robert S. Broughton, Tektronix, Inc.
.sp 3
* cp/m is a trademark of Digital Research, Inc.
!E!O!F!
echo x - comhex.c
cat >comhex.c <<'!E!O!F!'
/*%cc -n -O % -o comhex
 * comhex - convert .com files to (intel) .hex format
 *
 * operates just like 'cat'
 *
 */

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>

char	stdbuf[BUFSIZ];

main(argc, argv)
char **argv;
{
	int fflg = 0;
	register FILE *fi;
	register c;
	register cx;
	int ccount;
	int address;
	int checksum;
	int dev, ino = -1;
	struct stat statb;

	setbuf(stdout, stdbuf);
	for( ; argc>1 && argv[1][0]=='-'; argc--,argv++) {
		switch(argv[1][1]) {
		case 0:
			break;
		case 'u':
			setbuf(stdout, (char *)NULL);
			continue;
		}
		break;
	}
	fstat(fileno(stdout), &statb);
	statb.st_mode &= S_IFMT;
	if (statb.st_mode!=S_IFCHR && statb.st_mode!=S_IFBLK) {
		dev = statb.st_dev;
		ino = statb.st_ino;
	}
	if (argc < 2) {
		argc = 2;
		fflg++;
	}
	while (--argc > 0) {
		if (fflg || (*++argv)[0]=='-' && (*argv)[1]=='\0')
			fi = stdin;
		else {
			if ((fi = fopen(*argv, "r")) == NULL) {
				fprintf(stderr, "comhex: can't open %s\n", *argv);
				continue;
			}
		}
		fstat(fileno(fi), &statb);
		if (statb.st_dev==dev && statb.st_ino==ino) {
			fprintf(stderr, "comhex: input %s is output\n",
			fflg?"-": *argv);
			fclose(fi);
			continue;
		}
		ccount = 0;
		address = 0x0100;	/* cpm load offset */

		while ((c = getc(fi)) != EOF){
			if (ccount < 1){
				printf(":10");	/* lead-in, 16 bytes follow */
				puthex(address,4);	/* first address */
				printf("00");		/* record type */
				checksum = (address/256) + (address%256) + 16;
			}
			cx = (c & 0x00ff);
			puthex(cx,2);		/* the byte in two nibbles */

			checksum += cx;
			ccount++;
			address++;

			if (ccount > 15){ 
				checksum = -checksum;
				puthex( checksum, 2);	/* the checksum */
				printf("\n");
				checksum = 0;
				ccount = 0;
			}
		}
		printf(":0000000000\n");	/* this is the end record */

		if (fi!=stdin)
			fclose(fi);
	}
	return(0);
}

puthex(cx,cols)

int cx;
int cols;

{
	char h;
	int i;
	int pos;

	for (i = 0; i < cols; i++){
		pos = cols - i - 1;
		h = ((cx >> (pos * 4)) & 0x000f);
		h = h + (h < 10 ? '0' : '7');
		putchar( h & 0x7f);
	}
}
!E!O!F!
echo x - cpmcat.1t
cat >cpmcat.1t <<'!E!O!F!'
.TH CPMCAT 1T "6/17/82 Tek Local"
.SH NAME
cpmcat \-  convert from cp/m* text file to UNIX file format
.SH SYNOPSIS
.B cpmcat
[file] ...
.SH DESCRIPTION
.I cpmcat
reads cp/m text format from the named files
(standard input is default),
converts it to the UNIX text format and writes it on stdout.
All the features of cat are available for use (i.e. line numbering).
.PP
.SH EXAMPLES
To convert a cp/m* text file format
.I test.asm
to UNIX text format file
.I test.s.
.br
.tl ''cpmcat < test.asm > test.s''
.SH DIAGNOSTICS
Makes no complaints about any input conditions except those
recognized by 'cat'.
Does not care about the actual 'extensions' to the filenames used.
.SH HISTORY
Comhex is a corruption of cat.c.
Corruptions originally made by Andy Crump, Tektronix, Inc.
.sp 3
* cp/m is a trademark of Digital Research, Inc.
!E!O!F!
echo x - cpmcat.c
cat >cpmcat.c <<'!E!O!F!'
/*% /bin/env - ncc -n -O % -o cpmcat
*/
static char MySccsId[] = "@(#)cpmcat.c	1.4";

	/*
	 *  CPMCAT - Translate CP/M text files to UNIX text files.
	 *
	 *     usage: same as cat.
	 */

/*
 * Concatenate files.
 */
static	char *Sccsid = "@(#)cat.c	4.2 (Berkeley) 10/9/80";

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#define CPMEOF '\032'

char	stdbuf[BUFSIZ];
int	bflg, eflg, nflg, sflg, tflg, vflg;
int	spaced, col, lno, inline;

main(argc, argv)
char **argv;
{
	int fflg = 0;
	register FILE *fi;
	register c;
	int dev, ino = -1;
	struct stat statb;

	lno = 1;
	setbuf(stdout, stdbuf);
	for( ; argc>1 && argv[1][0]=='-'; argc--,argv++) {
		switch(argv[1][1]) {
		case 0:
			break;
		case 'u':
			setbuf(stdout, (char *)NULL);
			continue;
		case 'n':
			nflg++;
			continue;
		case 'b':
			bflg++;
			nflg++;
			continue;
		case 'v':
			vflg++;
			continue;
		case 's':
			sflg++;
			continue;
		case 'e':
			eflg++;
			vflg++;
			continue;
		case 't':
			tflg++;
			vflg++;
			continue;
		}
		break;
	}
	fstat(fileno(stdout), &statb);
	statb.st_mode &= S_IFMT;
	if (statb.st_mode!=S_IFCHR && statb.st_mode!=S_IFBLK) {
		dev = statb.st_dev;
		ino = statb.st_ino;
	}
	if (argc < 2) {
		argc = 2;
		fflg++;
	}
	while (--argc > 0) {
		if (fflg || (*++argv)[0]=='-' && (*argv)[1]=='\0')
			fi = stdin;
		else {
			if ((fi = fopen(*argv, "r")) == NULL) {
				fprintf(stderr, "cpmcat: can't open %s\n", *argv);
				continue;
			}
		}
		fstat(fileno(fi), &statb);
		if (statb.st_dev==dev && statb.st_ino==ino) {
			fprintf(stderr, "cpmcat: input %s is output\n",
			   fflg?"-": *argv);
			fclose(fi);
			continue;
		}
		copyopt(fi);
		if (fi!=stdin)
			fclose(fi);
	}
	if (ferror(stdout))
		fprintf(stderr, "cpmcat: output write error\n");
	return(0);
}

copyopt(f)
	register FILE *f;
{
	register int c;

top:
	c = getc(f);
	if (c == EOF || c == CPMEOF)
		return;
	if (c == '\r') goto top;
	if (c == '\n') {
		if (inline == 0) {
			if (sflg && spaced)
				goto top;
			spaced = 1;
		}
		if (nflg && bflg==0 && inline == 0)
			printf("%6d\t", lno++);
		if (eflg)
			putchar('$');
		putchar('\n');
		inline = 0;
		goto top;
	}
	if (nflg && inline == 0)
		printf("%6d\t", lno++);
	inline = 1;
	if (vflg) {
		if (tflg==0 && c == '\t')
			putchar(c);
		else {
			if (c > 0177) {
				printf("M-");
				c &= 0177;
			}
			if (c < ' ')
				printf("^%c", c+'@');
			else if (c == 0177)
				printf("^?");
			else
				putchar(c);
		}
	} else
		putchar(c);
	spaced = 0;
	goto top;
}
!E!O!F!
echo x - crck.1
cat >crck.1 <<'!E!O!F!'
.TH CRCK CDI 
.SH NAME
crck \- checksum files
.SH SYNOPSIS
.B crck
file ...
.SH DESCRIPTION
.I Crck\^
calculates and prints a 16-bit checksum and
.SM CP/M
sector count for the named files.
It is typically used to validate files transferred between
.SM Unix
and
.SM CP/M
type operating systems.
.I Crck\^
uses a checksum compatible with the
.SM CP/M
and
.SM CP/M-86
versions of crck prior to 5.0,
as well as the crck command in 8 bit versions of yam.
When comparing copies of a file on
.SM Unix
and
.SM CP/M
or similar systems,
the
.SM Unix
file must be in
.SM CP/M
format, with carriage returns and padding to make the length
divisable by 128.
If
.I crck
encounters a file whose length is not a multiple of 128,
the 032 padding which would result from transmission with yam
(without the k option) is included in the calculation.
.B Mkbin(tek)
may be used to convert a
.SM Unix
source file to a format which can be
stored in exactly the same format on a
.SM CP/M
system.
.SH DIAGNOSTICS
Prints ``Not in CP/M Format'' if the file is not an integral number of
.SM CP/M
128 byte sectors.
.SH BUGS
Has not been rigorusly tested.
May not produce correct results with all processor types.
This checksum detects all single bit errors
and most, but not all, multiple bit errors.
This checksum does not detect all two bit errors, unlike the CRC used
with standard synchronous communications protocols.
Files with different data may still produce the same crck value.
.SH "SEE ALSO"
mkbin(tek), sum(1), wc(1).
.SH DIAGNOSTICS
``Not in CP/M Format'' for files whose lengths are not exact multiples of 128.
!E!O!F!
echo x - crck.c
cat >crck.c <<'!E!O!F!'
/*% env - /bin/ncc -O % -o crck
*/

/*
 * Copyright 1983 Computer Development Inc Beaverton Or USA
 *  All rights reserved
 */
#include <stdio.h>

main(argc, argp)
char **argp;
{
	register errors = 0;
	while( --argc > 0)
		errors |= crckfile( *++argp);
	exit(errors != 0);
}

/* Accumulate and print a "crck" for a file */
crckfile(name)
char *name;
{
	unsigned short crck();
	register ffil;
	register int st;
	register unsigned short oldcrc;
	unsigned char crbuf[128];
	int notcpm = 0;
	int nsec;

	if((ffil=open(name, 0)) == -1) {
		perror(name);
		return(-1);
	}

	nsec=0; oldcrc=0;
	while((st=read(ffil, crbuf, 128)) >0) {
		oldcrc=crck(crbuf, st, oldcrc);
		++nsec;
		if (st != 128)
			notcpm++;
	}
	close(ffil);
	if(st != 0)
		perror(name);
	else if (notcpm)
		printf("%04X %4d %s Not in CP/M Format\n", oldcrc, nsec, name);
	else
		printf("%04X %4d %s\n", oldcrc, nsec, name);
	return(st);
}

/*
 * uses algrithim of CRCK.COM previous to 5.0
 */
unsigned crck(crbuf, count, ldcrc)
register unsigned char *crbuf;
register count;
register unsigned ldcrc;
{
	register unsigned n;

	while (--count >= 0) {
		n= (ldcrc << 1);
		n = (n & 0xFF00) | (( n + *crbuf++ ) & 0xFF);
		if(ldcrc & 0x8000)
			n ^= 0xA097;
		ldcrc = n;
	}
	return ldcrc;		
}
!E!O!F!
echo x - mkbin.1t
cat >mkbin.1t <<'!E!O!F!'
.TH MKBIN 1T "6/17/82 Tek Local"
.SH NAME
mkbin \-  convert from UNIX text file format to cp/m* text file format.
.SH SYNOPSIS
.B mkbin
[file] ...
.SH DESCRIPTION
.I Mkbin
reads the named UNIX files and replaces them with corresponding
cp/m text file format files.
.PP
.SH EXAMPLES
To convert a UNIX file
.I test.asm
to cp/m text format file
.I test.asm
.br
.tl ''mkbin test.asm''
.SH DIAGNOSTICS
Makes no complaints about any input conditions.
Does not care about the actual 'extensions' to the filenames used.
.SH HISTORY
Written by Andy Crump, Tektronix, Inc.
.sp 3
* cp/m is a trademark of Digital Research, Inc.
!E!O!F!
echo x - mkbin.c
cat >mkbin.c <<'!E!O!F!'

/*% cc -n -O % -o mkbin
 * MKBIN  - converts UNIX text files to CP/M text files.
 *
 *     usage: mkbin files
 *
 *   Will replace named files with converted ones.
 */

char SCCS_id[] = "@(#)mkbin.c	1.5";


#include <stdio.h>

main(argc, argv)
int argc;
char *argv[];
{
	char *mktemp();
	FILE *fopen();
	register int n = 0;
	register int i;
	register char c;
	FILE *sid;
	FILE *oid;
	int nbytes, xtra;
	char *temp;
	char ibuf[BUFSIZ];
	char obuf[BUFSIZ];

	for (i = 1; i < argc; i++) {
		nbytes = 0;
		if ((sid = fopen(argv[i], "r")) == NULL) {
			perror(argv[0]);
			continue;
		}
		setbuf(sid, ibuf);
		temp = mktemp(",binXXXXXX");
		if ((oid = fopen(temp, "w")) == NULL) {
			perror(argv[0]);
			exit(1);
		}
		setbuf(oid, obuf);
		while ((c = fgetc(sid)) != EOF) {
			if ((char)(c) == '\n') {
				fputc('\r', oid);
				nbytes++;
				fputc('\n', oid);
				nbytes++;
			} else {
				fputc((char)(c), oid);
				nbytes++;
			}
		}
		xtra = 128 - (nbytes % 128);
		for (n = 0; n < xtra; n++) {
			fputc('\032', oid);
		}
		fclose(sid);
		fclose(oid);
		if (unlink(argv[i]) != 0) {
			perror(argv[0]);
			exit(2);
		}
		if (link(temp, argv[i]) != 0) {
			perror(argv[0]);
			exit(3);
		}
		if (unlink(temp) != 0) {
			perror(argv[0]);
			exit(4);
		}
	}
	exit(0);
}
!E!O!F!

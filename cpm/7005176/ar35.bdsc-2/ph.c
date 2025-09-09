/*
 *	ph.c
 *
 *	Last Modified : November 30, 1981
 *
 *	By: Larry A. Marek		Aug. 10, 1980
 *	Modified by: Doug Porter	Nov. 30, 1981
 *
 * "PH" is a derivative of the program "Unload" by Larry Marek.
 *
 * "Unload" Copyright (c) by Larry A. Marek  Not for commercial use.
 * Portions of "Ph" Copyright (c) by Doug Porter.
 * This program may not be bought or sold.  For hobbiest use only!
 *
 *
 *
 * PH (Punch Hex) is intended as a partial solution to the problem
 * of how to get a file onto a CP/M system which has no telecommun-
 * ications software.  It is particularly useful for getting that
 * critical first smart terminal package downline.
 * 
 *
 */





/*


			Transmitting a File Using PH


	To place the cart firmly before the horse, let's note that
	the receiving system must be ready to accept the file being
	transmitted before you can run PH.

	The command line:

		 ph foo.bar

	will read the file "foo.bar" and send an Intel hex equivalent
	to the punch device.  Every 10,000 characters an XOFF is
	transmitted, followed by a delay which is hopefully sufficient
	to allow PIP, running on a CP/M system which is receiving
	the hex file, to flush its buffer properly.  The resulting
	ascii file can be later re-LOADed to working object code.

	It may be necessary to change the IOBYTE using STAT, or
	something similar, to assign the logical PUN: device to a
	serial port.



			Receiving a File Using PH


	Like the transmitting system, the receiving system may require
	that a serial line be assigned to one of the logical input
	devices to allow PIP to read the incoming file.

	After a serial line has been associated with a logical input
	device, such as RDR:, a command line such as:

		pip foo.hex=rdr:[b]

	will buffer the incoming Intel hex character stream until PIP
	detects an XOFF character or the CP/M end of file character,
	^Z.  If the character was XOFF, PIP will then flush its buffer
	to disk and return for more characters.  When PIP detects
	the ^Z end of file character, it will flush its buffers and
	close the file.  Then the command line

		load foo

	will create a binary file once more from the hex file.  This
	file will, of course, be named foo.com.  If the file is
	not a CP/M command file, simply rename it:

		ren foo.bar=foo.com

	Remember that a file in Intel hex format is about 3 times as
	large as its equivalent binary file.  This means that if both
	the hex file and the final file are to be on the same disk,
	you need to have about four times as much disk space as you
	would need for the binary file alone.

	PH will not properly transmit a file which has non-contiguous
	random records.  For CP/M command files, this matters not at
	all.
	from a serial port.
 */

#include "bdscio.h"

#define CLOCK_MHZ 4	/* set this for the clock speed of your system */

#define DELAY	20	/* number of seconds to delay after a block */
#define XON	17	/* ASCII Xon character */
#define XOFF	19	/* ASCII Xoff character */

main(argc, argv)
int	argc;
char	**argv;
{
	if (argc != 2) {
		printf("\nUsage: ph file\n");
	} /* if */

	else {
		doit(*++argv);
	} /* else */

}


doit(file_name)
char *file_name;
{
	char	cksum;
	int i, c, fdi, fdo;
	int charcount;
	unsigned addr;
	char	infile[BUFSIZ][BUFSIZ];

/*
 * take the filename given and open that
 * file for reading
 */

	fdi = fopen(file_name, infile);
	if (fdi == ERROR) {
		printf("can't access '%s'\n", file_name);
		exit();
	}

/*
 * the main work loop
 *
 * Here the start of every line has the address and
 * other load information, then sixteen hexadecimal
 * ascii bytes.  Last on the line is the checksum and
 * a carriage return, linefeed.
 */

	addr = 0x100;		/* cp/m transients start here */

	charcount = 0;		/* no characters sent yet */

	while ((c = getc(infile)) != EOF) {

		if (charcount >= 10000) {	/* if block, */
			punchc(XOFF);		/* send Xoff and delay */
			sleep(DELAY * (CLOCK_MHZ / 2) * 10);
			charcount = 0;
		}

		if ((addr % 16) == 0) {
			cksum = 0;
			punchc(':');	/* record mark */
			charcount++;

			punchc('1');
			punchc('0');	/* 16 frames to come */
			charcount += 2;
			cksum -= 0x10;

			/* the load address */
			punchc(tohex(addr >> 12));
			punchc(tohex(addr >> 8));
			charcount += 2;
			cksum -= (addr >> 8);
			punchc(tohex(addr >> 4));
			punchc(tohex(addr));
			charcount += 2;
			cksum -= (addr & 0xff);

			punchc('0');	/* record type */
			punchc('0');
			charcount += 2;
		}

		punchc(tohex(c >> 4));
		punchc(tohex(c));
		charcount += 2;
		cksum -= c;

		++addr;
		if ((addr % 16) == 0) {
			punchc(tohex(cksum >> 4));
			punchc(tohex(cksum));
			punchc('\r');
			punchc('\n');
			charcount += 4;
		}

	}

/*
 * The unlikely (in cp/m) case the End-o-file was
 * reached before writing a full line to the punch
 * device.
 */

	if ((addr % 16) != 0) {
		while ((addr % 16) != 0) {
			punchc('0');
			charcount++;
			++addr;
		}
		punchc(tohex(cksum >> 4));
		punchc(tohex(cksum));
		punchc('\r');
		punchc('\n');
		charcount += 4;
	}

/*
 * to show the end of the hex file -  a zero length
 * line
 */

	punchc(':');
	charcount++;
	for (i = 0; i <= 1; i++) {
		punchc('0');
		charcount++;
	}
	punchc(CPMEOF);	/* cp/m end of file */
	charcount++;
}

/*
 * "tohex" converts it's input to an ascii hex digit.
 *  Input range is made to fit.
 */

tohex(c)
char	c;
{
	c &= 0xf;		/* range 0 - F */

	if (c <= 9)
		c += '0';
	else
		c += ('A' - 10);
	return(c);
}


punchc(c)	/* send c to the punch device */
char c;
{
	bdos(4, c);
}

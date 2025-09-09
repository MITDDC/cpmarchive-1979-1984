/*
	"Tabify"
	written by Leor Zolman

	command format: A>tabify oldfile newfile

	This program takes a text file and converts
	sequences of spaces into tabs wherever possible,
	in order to reduce the size of the file (and the
	time it takes to transmit it using TELNET.)

	There shouldn't be any control characters within
	the file, except for carriage returns and linefeeds,
	or things will get all screwed up.

	Also, there shouldn't be any double quotes (")
	within the file except as string delimiters; i.e,
	tabify shouldn't be used on itself because of the
	quote in this sentence and the double quotes enclosed
	within single quotes further down in the file.

	The input file isn't altered; the result is a new
	file named by the second argument.
	The most common use of this program is to tabify
	text files which you've loaded in over the phone
	from a computer system (like UNIX) that tends to
	turn all tabs into spaces for 300 baud DECwriters.

*/

main(argc,argv)
char **argv;
{
	int scount, column, ifd, ofd, i;
	int c;
	char ibuf[134], obuf[134];

	if (argc != 3) {
		printf("usage: tabify oldfile newfile\n");
		exit();
	}
	ifd = fopen(argv[1],ibuf);
	ofd = fcreat(argv[2],obuf);
	if (ifd == -1 || ofd == -1) {
		printf("Can't open file(s)\n");
		exit();
	}

	scount = column = 0;

	do {
		c = getc(ibuf);
		if (c == -1) {
			putc(0x1a,obuf);
			break;
		 }
		switch(c) {
		   case 0x0d:	putc1(c,obuf);
				scount = column = 0;
				break;
		   case 0x0a:	putc1(c,obuf);
				scount = 0;
				break;
		   case ' ':	column++;
				scount++;
				if (!(column%8)) {
				   if (scount > 1)
					putc1('\t',obuf);
				   else
					putc1(' ',obuf);
					scount = 0;
				 }
				break;
		   case '\t':	scount = 0;
				column += (8-column%8);
				putc1('\t',obuf);
				break;
		    case '"':   for (i=0; i<scount; i++)
					putc1(' ',obuf);
				putc1('"',obuf);
				do {
				   c = getc(ibuf);
				   if (c == -1) {
				    printf("Quote error.\n");
				    exit();
				   }
				   putc1(c,obuf);
				} while (c != '"');
				do {
					c = getc(ibuf);
					putc1(c,obuf);
				} while (c != 0x0a);
				column = scount = 0;
				break;
		   case 0x1a:	putc(0x1a,obuf);
				break;
		   default:	for (i=0; i<scount; i++)
					putc1(' ',obuf);
				scount = 0;
				column++;
				putc1 (c,obuf);
		 }
	 } while (c != 0x1a);

	fflush(obuf);
	close(obuf);
	close(ibuf);
}

putc1(c,buf)
char c;
{
	putchar(c);
	if (putc(c,buf) < 0) {
		printf("\n\ntabify: disk write error.");
		exit();
	}
}


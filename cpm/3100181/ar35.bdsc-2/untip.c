/*
	UNTIP.C
	written sometime in 1980 by Leor Zolman

	This program takes a file of text that was accumulated during
	a session on ITS where carriage-motion optimization was in effect,
	meaning that there are "linefeed-backspace-backspace...text" sequences
	all through it and it can't be edited using normal CP/M editors,
	and turns it into normal text.

	Usage:
		A>untip sourcefile [destfile] <cr>

	If only one name is given, a temp file is created and renamed at the
	end to be the same as the source file (i.e., if something goes wrong,
	you might lose the file...but probably not.)
*/

#include <bdscio.h>
#define TB 0x09
#define EOF 255
#define CR 0x0d
#define BS 0x08
#define LF 0x0a

char ibuf[BUFSIZ], obuf[BUFSIZ];
int col, maxcol;
int fd1, fd2;
char lbuf[132];
char c;
int i;

main(argc,argv)
char **argv;
{
	if (argc < 2 || argc > 3) {
		printf("usage: untip sourcefile [destfile] <cr>\n");
		exit();
	}

	fd1 = fopen(argv[1],ibuf);

	if (argc == 2) argv[2] = "untip.tmp";
	fd2 = fcreat(argv[2],obuf);

	if (fd1 == ERROR || fd2 == ERROR) {
		printf("Open error.\n");
		exit();
	}
	col = maxcol = 0;
	while ((c=getc(ibuf)) != EOF && c != CPMEOF) {
		if (col > maxcol) maxcol = col;
		switch(c) {
		 	case CR: col = 0;
				 continue;

			case BS: col--;
				 continue;

			case LF: putl(lbuf,obuf);
				 for (i=0; i<col; i++) lbuf[i] = ' ';
				 maxcol = col;
				 continue;

			case TB: do { lbuf[col++] = ' ';
				  }   while (col%8);
				 continue;

			default: lbuf[col++] = c;
		 }
	 }
	putl(lbuf,obuf);
	putc(CPMEOF,obuf);
	fflush(obuf);
	fclose(ibuf);
	fclose(obuf);
	if (argc == 2) {
		unlink(argv[1]);
		rename(argv[2],argv[1]);
	}
}

putl(line,obuf)
char *line, *obuf;
{
	int i;
	for (i = 0; i < maxcol; i++) {
		putc(*line++,obuf);
	}
	putc(CR,obuf);	
	putc(LF,obuf);
	putchar('*');
}

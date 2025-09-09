/*
	WC.C
	Written by Leor Zolman, 3/16/82

	Text analysis utility. Given a list of text files, WC prints
	out total number of characters, words and lines in each file
	and in all files together. "Words", here, are simply delimited
	by blanks, tabs or newlines.

	Maximum number of words and lines are each 65535, but the char
	count is virtually unlimited.

	compile & link by:
		cc1 wc.c -e2000 -o
		{clink | l2}  wc wildexp
*/

#include "bdscio.h"

unsigned lo_totchars, hi_totchars, totwords, totlines;
char ibuf[BUFSIZ];

main(argc,argv)
char **argv;
{
	wildexp(&argc,&argv);
	if (argc == 1) exit(puts("Usage: wc <list of files>\n"));

	lo_totchars = hi_totchars = totwords = totlines = 0;

	puts("\n\t\tchars\twords\tlines\n");
	while (--argc) dofile(*++argv);
	puts("\nTotals:");
	if (hi_totchars) printf("\t\t%d%04d",hi_totchars,lo_totchars);
	else printf("\t\t%d",lo_totchars);
	printf("\t%u\t%u\n",totwords,totlines);
}

dofile(name)
char *name;
{
	char inword;
	int c;
	unsigned  lo_tch, hi_tch, twords, tlines;

	if (fopen(name,ibuf) == ERROR)
		return printf("Can't open %s\n",name);

	printf("%s:\t",name);
	if (strlen(name) < 7)
		putchar('\t');
	
	inword = lo_tch = hi_tch = twords = tlines = 0;

	while ((c = getc(ibuf)) != EOF && c != CPMEOF) {

		if (++lo_tch == 10000) {
			lo_tch = 0;
			hi_tch++;
		}

		if (isspace(c)) {
			if (inword) {
				inword = 0;
				twords++;
			}
		} else
			if (!inword)
				inword = 1;
		
		if (c == '\n')
			tlines++;
	}
	fabort(ibuf->_fd);

	if (hi_tch) printf("%d%04d",hi_tch,lo_tch);
	else printf("%d",lo_tch);
	printf("\t%u\t%u\n",twords,tlines);

	if ((lo_totchars += lo_tch) >= 10000) {
		lo_totchars -= 10000;
		hi_totchars++;
	}
	hi_totchars += hi_tch;
	totwords += twords;
	totlines += tlines;
}

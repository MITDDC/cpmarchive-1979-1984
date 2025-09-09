/*
	STRIPC.C
	Written by Leor Zolman, 3/82

	This program takes an assembly language source file as input,
	and writes out the same file stripped of comments. Everything between
	a semicolon and the end of the line is stripped, plus the tabs
	before the semicolon.
	If a line contains an odd number of single quote (') characters before
	the first semicolon, then the line is left intact.
*/

#include "bdscio.h"
char ibuf[BUFSIZ], obuf[BUFSIZ];

main(argc,argv)
char **argv;
{
	char iname[30], oname[30];
	char linbuf[200];

	int i,j,k;

	if (argc != 3) exit(puts("usage: stripc <infile> <outfile>\n"));
	if (!strcmp(argv[1],argv[2])) exit(puts("Names must be distinct\n"));

	strcpy(iname,argv[1]);
	strcpy(oname,argv[2]);

	strcat(iname,".ASM");
	strcat(oname,".ASM");

	if (fopen(iname,ibuf) == ERROR)
		exit(puts("\7Can't open input file\n"));

	if (fcreat(oname,obuf) == ERROR)
		exit(puts("\7Can't create output file\n"));

	while (fgets(linbuf,ibuf)) {
		if ((i = index(linbuf,";")) != ERROR)
		{
		   if (!i)
		   {
			*linbuf = '\0';
		   }
		   else
		   {
			if (index(linbuf,"'") < i)
			{
				k = 0;	/* quote count */
				for (j = 0; j < i; j++)
					if (linbuf[j] == '\'')
						k++;
				if (k & 1) goto lineout;
			}
			while (i && isspace(linbuf[i-1]))
				i--;
			linbuf[i++] = '\n';
			linbuf[i] = '\0';
		   }
		}
  lineout:	if (fputs(linbuf,obuf) == ERROR)
			exit(puts("\7Error writing output file"));
		putchar('.');
	}
	putc(CPMEOF,obuf);
	fflush(obuf);
	fclose(obuf);
	fclose(ibuf);
	puts("All done.\n");
}

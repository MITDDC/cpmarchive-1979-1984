/*
	Alphabetize a file by lines.
	Usage:
		alph <inputfile> <outputfile>
*/

#include "bdscio.h"
#include "dio.h"
#define stderr 4

#define MAXLINES   2000		/* max number of lines */

int strcmp();
char iobuf[BUFSIZ];
char *ltab[MAXLINES];
int lcount;
char *allocp;

main(argc,argv)
int argc;
char **argv;
{
	int i;
	char linbuf[300];

	dioinit(&argc,argv);

	if (argc > 1)
		if(fopen(argv[1],iobuf)== ERROR)
			exit(fputs("Can't open input file\n",stderr));

	lcount = 0;
	for (i = 0; i < MAXLINES; i++)
	{
		if (argc > 1) {
			if (!fgets(linbuf,iobuf)) break;
		}
		else
			if (!gets2(linbuf)) break;
		
		if ((allocp = sbrk(strlen(linbuf) + 1))	== ERROR)
			exit(fputs("Out of allocation space\n",stderr));
		ltab[lcount++] = allocp;
		strcpy(allocp,linbuf);
	}

	if (argc > 1)
		fclose(iobuf);

	if (i == MAXLINES) exit(fputs("Too many lines. Change MAXLINES\n"
							,stderr));

	qsort(ltab,lcount,2,&strcmp);

	if (argc > 2) {
		if (fcreat(argv[2],iobuf) == ERROR)
			exit(fputs("Can't creat output file\n",stderr));
	}
	else fputs("******** Alphabetized: *********\n",stderr);

	for (i = 0; i < lcount; i++)
		if (argc > 2)
			fputs(ltab[i],iobuf);
		else
			puts(ltab[i]);
	if (argc > 2) {
		putc(CPMEOF,iobuf);
		fflush(iobuf);	
		fclose(iobuf);
	}	
	fputs("\n*********** All done ***********\n",stderr);
	dioflush();
}

int gets2(str)
char *str;
{
	int c;

	if ((c = getchar()) == EOF) return NULL;
	do {
		if ((*str++ = c) == '\n')
			break;;
	} while (c = getchar());
	*str = '\0';
	if (c == EOF) return NULL;
	return 1;
}


int strcmp(s,t)
char **s, **t;
{
	char *s1, *t1;
	s1 = *s;
	t1 = *t;
	int i;
	i = 0;
	while (s1[i] == t1[i])
		if (s1[i++] == '\0')
			return 0;
	return s1[i] - t1[i];
}

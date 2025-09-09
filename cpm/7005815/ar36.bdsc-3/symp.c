/*
	SYMP.C
	Written by Leor Zolman, 3/82

	Given a SYM file put out by ASM86, this aplphabetizes the
	symbols, eliminates all symbols starting with "L0", and writes
	the result into T.SYM.
*/

#include <bdscio.h>

char iobuf[BUFSIZ];
int strcmp();

main(argc,argv)
char **argv;
{
	char iname[30];
	int i,j,c;
	unsigned valtab[1000], newval;
	char *namtab[1000], newnam[30];
	int count;
	int ncols, colno;

	if (argc == 1) exit(puts("Usage:\nsymp <symnane> [ncols]\n"));
	ncols = 80;
	if (isdigit(argv[2][0])) ncols = atoi(argv[2]);

	strcpy(iname,argv[1]);
	strcat(iname,".SYM");

	if (fopen(iname,iobuf) == ERROR) exit(puts("Can't open input file"));

	count = 0;

	while (1) {
		while (isspace(c = getc(iobuf)))   /* skip leading space */
			;
		if (c == EOF || c == CPMEOF)
			break;

		if (!ishexd(c)) {
			printf("Bad 1st char of value: %c\n",c);
			printf("Read %d symbols, last was: %s\n",
					count, namtab[count-1]);
			exit();
		}

		newval = 0;
				/* accumulate new hex value */
		do {
		   newval = newval * 16 + (c < ':' ? (c - '0') : (c - '7'));
		   c = getc(iobuf);
		} while (ishexd(c));

			/* skip white space between value and symbol */
		while (isspace(c)) c = getc(iobuf);

				/* collect up new symbol name */
		i = 0;
		do {
			newnam[i++] = c;
		} while (!isspace(c = getc(iobuf)));
		newnam[i] = '\0';

		valtab[count] = newval;
		namtab[count] = sbrk(strlen(newnam) + 1);
		strcpy(namtab[count++],newnam);
	}

	qsort(namtab,count,2,&strcmp,valtab);	/* alphabetize */

	fclose(iobuf);
	if (fcreat("T.SYM",iobuf) == ERROR) exit(puts("Can't creat T.SYM"));

	colno = 1;
	for (i = 0; i < count; i++) {
		if (namtab[i][0] == 'L' && namtab[i][1] == '0')
			continue;
		fprintf(iobuf, "%04x %-8s  ",valtab[i],namtab[i]);
		colno += 15;
		if (colno + 15 >= ncols) {
			fputs("\n",iobuf);
			colno = 1;
		}
	}
	fputs("\n",iobuf);
	putc(CPMEOF,iobuf);
	fflush(iobuf);
	fclose(iobuf);
	puts("T.SYM is ready for action...\n");
}

isspace(c)
char c;
{
	return (c == ' ' || c == '\t' || c == 0x0d || c == 0x0a);
}

qsort(base, nel, width, compar,base2)
char *base; int (*compar)();
unsigned width,nel;
{	int i, j;
	unsigned gap, ngap, t1;
	int jd, t2;

	t1 = nel * width;
	for (ngap = nel / 2; ngap > 0; ngap /= 2) {
	   gap = ngap * width;
	   t2 = gap + width;
	   jd = base + gap;
	   for (i = t2; i <= t1; i += width)
	      for (j =  i - t2; j >= 0; j -= gap) {
		if ((*compar)(base+j, jd+j) <=0) break;
			 _swp(base+j, jd+j);
			 _swp(base2+j,base2+gap+j);
	      }
	}
}

_swp(a,b)
int *a, *b;
{
	int temp;
	temp = *a;
	*a = *b;
	*b = temp;	
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

int ishexd(c)
char c;
{
	return isdigit(c) || (c >= 'A' && c <= 'F');
}

/*
	ECHO.C
	Written by Leor Zolman, 3/82

	Gives display of computed command line, after WILDEXP has been
	applied. Can be used in conjunction with directed output to yield
	a file containing the disk directory for the current drive and user
	area, or just to check which files match a given wildcard pattern
	before using the wildcard in an actual command such as "cp".

	link by:
		A>clink echo wildexp -f dio
	(or)	A>l2 echo wildexp dio
*/

#include "bdscio.h"
#include "dio.h"

main(argc,argv)
char **argv;
{
	char c;
	int count, colno, i;
	wildexp(&argc,&argv);
	dioinit(&argc,argv);

	colno = 1;
	
	puts("Drive: ");
	putchar(bdos(25) + 'A');

	puts("   User area: "); putdec(bdos(32,0xff));
	puts("   Count = "); putdec(argc - 1);
	puts("\n\n");

	while (argv++,--argc)
	{
		count = 0;
		while (c = *(*argv)++)
			putchar(tolower(c)),count++;
		for (i = count; i < 15; i++) putchar(' ');
		if ((colno += 15) > 65)
			putchar('\n'),colno = 1;
	}
	putchar('\n');
	dioflush();
}

putdec(n)
{
	int pow10;
	char pflag;

	pflag = 0;

	if (n < 0)
	{
		n = -n;
		putchar('-');
	}

	for (pow10 = 10000; pow10; pow10 /= 10)
	{
		if ((n > pow10 - 1) || pflag) 
		{
			putchar(n/pow10 + '0');
			pflag = 1;
			n -= n/pow10 * pow10;
		}
	}
	if (!pflag) putchar('0');
}

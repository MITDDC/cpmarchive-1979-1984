/*
	Concatenate text files listed on command line onto the standard
	output, or else  take standard input and send it to standard output.
	For example,

		cat file1 file2 file3 >file4

	creates "file4" consisting of the concatenation of file1,file2, and
	file3 (which must all be text files).

	Link by:
		clink cat -f dio
*/

#include "bdscio.h"
#include "dio.h"

#define STDERR 4

main(argc,argv)
char **argv;
{
	int c;
	int i;
	char ibuf[BUFSIZ];

	dioinit(&argc,argv);

	if (argc == 1)
		while ((c = getchar()) != EOF) putchar(c);
	else
		for (i = 1; i < argc; i++)
		{
			if (fopen(argv[i],ibuf) == ERROR)
			{
				fprintf(STDERR,"\7Can't open %s\n",argv[i]);
				continue;
			}
			while ((c = getc(ibuf)) != EOF && c != CPMEOF)
				putchar(c);
		}
	dioflush();
}

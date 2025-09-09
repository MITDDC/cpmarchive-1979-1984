/*
	RMF.C
	Written by Leor Zolman, 2/82

	Given a filename and a set of extensions, remove all files that match.
	Usage: rmf <filename> <ext1> <ext2> <ext3> ...
*/

#include "bdscio.h"

main(argc,argv)
char **argv;
{
	int i;
	char fnambuf[20];
	char nambuf[30];
	if (argc < 3) {
		puts("Usage:\nrmf <filename> <ext1> [<ext2> <ext3> ...]\n");
		puts("(Any extension may have a filename on it also)\n");
		exit();
	}

	strcpy(fnambuf,argv[1]);

	for (i = 2; i < argc; i++)
	{
		if (hasdot(argv[i])) unlink2(argv[i]);
		else
		{
			strcpy(nambuf,fnambuf);
			strcat(nambuf,".");
			strcat(nambuf,argv[i]);
			unlink2(nambuf);
		}
	}
}

int hasdot(str)
char *str;
{
	while (*str) if (*str++ == '.') return 1;
	return 0;
}

unlink2(filename)
char *filename;
{
	puts("Unlinking "); puts(filename); puts("...\n");	
	if (unlink(filename) < 0)
	{
		puts(filename);
		puts(" \7 doesn't exist\n");
	}
}

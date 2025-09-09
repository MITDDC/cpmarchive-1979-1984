/*
	RMX.C
	Written by Leor Zolman, 11/81

	Remove all given files having a certain extension.
	Usage: rmx <ext> <name1> <name2> <name3> ...
*/

#include "bdscio.h"

main(argc,argv)
char **argv;
{
	int i;
	char extbuf[5];
	char nambuf[30];
	if (argc < 3) {
		puts("Usage:\nrmx <ext> <name1> [<name2> <name3> ...]\n");
		puts("(any name may have it's own explicit extension)\n");
		exit();
	}

	strcpy(extbuf,argv[1]);

	for (i = 2; i < argc; i++)
	{
		if (hasdot(argv[i])) unlink2(argv[i]);
		else
		{
			strcpy(nambuf,argv[i]);
			strcat(nambuf,".");
			strcat(nambuf,extbuf);
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
		puts(" \7doesn't exist\n");
	}
}
	
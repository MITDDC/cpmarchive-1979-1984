/*
	Remove all listed files
*/

#include "bdscio.h"

main(argc,argv)
char **argv;
{
	int i, j;

	wildexp(&argc,&argv);

	if (argc == 1) exit(puts("No such files to remove."));

	puts("Removing files:");

	for (i=1; i < argc; i++) {
		if (!((i-1) % 6)) putchar('\n');
		puts(argv[i]);
		for (j = strlen(argv[i]); j < 13; j++) putchar(' ');
	}
	puts("\nOK to remove all these?");
	if (toupper(getchar()) != 'Y') exit();
	for (i = 1; i < argc; i++)
	{	unlink(argv[i]); putchar('.'); }
}


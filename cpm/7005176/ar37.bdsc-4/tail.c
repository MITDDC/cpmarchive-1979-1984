/*
	TAIL.C 	--   Print last several lines of a text file.
	Written by Leor Zolman, 3/83

	****************************
	*   Requires BDS C v1.5    *
	****************************

	Usage: tail [-n] <filename>

	where n, if specified, gives number of lines before EOF at
	which to begin printing. Defaults to 22.
*/

#include <bdscio.h>

#define LINES_DEF 22	/* number of lines before EOF to display	*/
#define NBSECTS 20	/* number of sectors before EOF to buffer 	*/
#define TXTBUFSIZE (BSECTS * SECSIZ + 1) /* size of working text buffer	*/

main(argc,argv)
char **argv;
{
	int i, fd, sects;
	unsigned filsiz;
	int lineno, lincnt;
	char txtbuf[NBSECTS * SECSIZ + 1];	/* sector buffer */
	char c, *txtptr, *lastsec, *filnam, *temp;

	filnam = NULL;
	lineno = LINES_DEF;

	for (i = 1; i < argc; i++)
	{
		if (argv[i][0] == '-')
		{
			if (!(lineno = atoi(&argv[i][1])))
				goto abort;
		}
		else if (filnam)
			goto abort;
		else
			filnam = argv[i];
	}			


	if (argc < 2 || !filnam || lineno < 0)
	{
   abort:	puts("Usage: tail [-#] <filename>\n");
		exit();
	}

	if ((fd = open(filnam, 0)) == ERROR)
	{
		printf("Cannot open %s\n",filnam);
		exit();
	}

	filsiz = cfsize(fd);		/* find size of file in sectors */

	seek(fd, (NBSECTS < filsiz) ? -NBSECTS : -filsiz, 2); /* seek to EOF */

	if (!(sects = read(fd, txtbuf, NBSECTS)))
	{
		printf("%s is an empty file.\n",filnam);
		exit();
	}

	lastsec = txtbuf + ((sects-1) * SECSIZ);
	lastsec[SECSIZ] = '\0';
	for (txtptr = lastsec; !lastchar(*txtptr); txtptr++)
		;
	--txtptr;	/* txtptr now points to last char of text */

	lincnt = 0;

	while (1)
	{
		if (txtptr < txtbuf)
		{
			puts("Text buffer not large enough. Aborting.\n");
			exit();
		}
		if (*txtptr == '\n')
			lincnt++;
		if (lincnt == lineno)
			break;
		txtptr--;		
	}

	while (!lastchar(c = *txtptr++))
			putchar(c);

	close(fd);
}
				


int lastchar(c)
char c;
{
	return (!c) || (c == CPMEOF);
}

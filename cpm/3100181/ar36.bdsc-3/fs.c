/*--------------------------------------
 *
 *	fs  - find string
 *
 *	Usage:	fs str files ....
 *
 *	Description:
 *		Finds the string "str" in the 
 *	named files.  Ignores cases.
 *	Gives line numbers "str" is found on.  
 *	Uses directed io, so one can use:
 *	"fs str1 file |fs str2".
 *
 *	Author:	Dan Sunday
 *	Date:	11-1-81
 *--------------------------------------*/

#include "a:bdscio.h"
#include "b:dio.h"

FILE	*infile;
char	inbuf [BUFSIZ],
	line [128];


main (argc,argv)	/* fs string file1 file2 ... */
char **argv;
begin
	int i,k,n,f;
	char *ap,**p,*pat;

	dioinit(&argc,argv);
	infile = inbuf;

	if (argc < 2)
	begin
		fprintf (4,"Usage: 'fs string file1 [file2 ...]'");
		dioflush();
		exit (ERROR);
	end

	p = argv + 1;
	pat = *p++;
	f = 1;

	if (argc==2)
	begin
		infile = 0;
		ap = "\0";
		getchar(); ungetch();
		goto StdIn;
	end

	while (++f < argc)
	begin
		ap = *p++;
		if (fopen (ap,infile) == ERROR)
		begin
			printf ("can't open %s\n",ap);
			dioflush();
			exit (ERROR);
		end
StdIn:
		for (i=1;;++i)
		begin
			if (fgets (line,infile) == NULL)
				break;
			if (substr (pat,line))
			begin
				putchar('!');
				printf ("%s :%d: %s",
					ap, i, line);
			end
		end
	end

	dioflush();
	exit (OK);
end


substr (pat,str)
char *pat,*str;
begin
	int i,j,k,l;
	char *p,*q;
	i = 0;
	k = strlen (pat);
	l = strlen (str);

	while (i+k < l)
	begin
		p = pat + k;
		q = str + i + k;
		j = k;

		while (j--)
			if (*--p != toupper(*--q))
				break;
			else if (j==0) return TRUE;
		++i;
	end

	return FALSE;
end

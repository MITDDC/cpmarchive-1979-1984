/*  LCHECK by Richard Conn

	LCHECK displays to the user the nesting level number of each
BEGIN/END ({/}) group, thereby helping him to identify problem areas
in his C programs.  It recognizes quoted material and comments and
ignores { and } within these.

*/

#define	vers	12	/* Version Number */

#include	"a:bdscio.h"

#define	SSCROLL	TRUE	/* Set TRUE for Smooth Scrolling on TVI 950 */

#define	quote	0x27	/* Single Quote */
#define	dquote	0x22	/* Double Quote */
#define	BS	0x08	/* Back Space Char */
#define	TAB	0x09	/* Tab Char */
#define	LF	0x0a	/* Line Feed Char */
#define	CR	0x0d	/* Carriage Return Char */
#define	YES	'Y'
#define	NO	'N'
#define	ovfl	YES	/* Line Overflow */
#define	noovfl	NO	/* No Line Overflow */

char	iobuf[BUFSIZ];
int	level, chval, pos, nroutines;

main(argc,argv)
int argc;
char **argv;
{
	int done;

	if (argc == 1) {
		printf("LCHECK, Version %d.%d\n",vers/10,vers%10);
		printf("Format of Command Line is --\n");
		printf("  LCHECK filename.typ");
		exit(FALSE);
		}
	if (fopen(argv[1],iobuf) == ERROR) {
		printf("Cannot Find File %s\n",argv[1]);
		exit(FALSE);
		}
	if (SSCROLL) printf("%c%c",ESC,'8');  /* Smooth Scroll */
	printf("LCHECK, Version %d.%d -- File:  %s\n",vers/10,
	   vers%10,argv[1]);
	level = 0; nroutines = 0;  /* Init nesting level, routine count */
	prlevel();  /* Print level number */
	do {
		getit();  /* Get next char */
		if (chval == quote) do {  /* If quote, flush to end quote */
				getit();
			} while (chval != quote);
		if (chval == dquote) do {  /* If dquote, flush to dquote */
				getit();
			} while (chval != dquote);
		if (chval == '/') {  /* Possible comment */
			getit();
			if (chval == '*') {  /* Yes, it is a comment */
				getit();
				done = FALSE;
				do {
					if (chval == '*') {  /* End comment? */
						getit();
						if (chval == '/')  /* Yes */
							done = TRUE;
						}
					else getit();
				} while (!done);
				}
			}
		if (chval == '{') level++;  /* BEGIN */
		if (chval == '}') {  /* END */
			level--;
			if (level == 0) {
				nroutines++;
				printf("\n** Routine %d **", nroutines);
				}
			}
	} while ((chval != CPMEOF) && (chval != ERROR));

	printf("\nProgram Level Check is ");
	if (level == 0) printf("OK");
		else printf("NOT OK");
	printf("\nNumber of Routines Encountered: %d",--nroutines);
	if (SSCROLL) printf("%c%c",ESC,'9');  /* Hard Scroll */
}

getit()  /* Get and Echo Character */
{
	chval = getc(iobuf);
	if ((pos >= TWIDTH) & (chval != CR)) prlevel(ovfl);
	if (chval != CPMEOF) echo(chval);
}

echo(chval)  /* Echo Char with tabulation */
char chval;
{
	switch (chval) {
		case TAB : putchar(' '); pos++;
			   while (pos%9 != 0) {
				putchar(' ');
				pos++;
				}
			   break;
		case BS  : putchar(BS);
			   pos--;
			   break;
		case LF  : prlevel(noovfl);
			   break;
		case CR  : putchar(CR);
			   pos = 0;
			   break;
		default  : if (chval >= ' ') {
				putchar(chval);
				pos++;
				}
			   break;
		}
}

prlevel(ovfl_flag)  /* Print Level Number and Set Col Count */
char ovfl_flag;
{
	putchar(LF);
	if (level < 10) printf(" %d",level);
		else printf("%d",level);
	if (ovfl_flag == YES) putchar('-');
		else putchar(':');
	putchar(' ');
	pos = 5;
}

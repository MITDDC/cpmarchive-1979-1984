/*
	New functions for BDS C v1.4x: "lprintf" and "lputs"
	Written 1/18/81 by Leor Zolman
*/

#include <bdscio.h>
#define LISTDEV 2

/*
	Formatted output to the list device. Usage:

	lprintf(format, arg1, arg2, ...)
	char *format;

	Works just like "printf", except the output line is written
	to the lineprinter instead of to the console.
*/

lprintf(format)
char *format;
{
	char txtlin[MAXLINE];
	_spr(txtlin,&format);
	lputs(txtlin);
}

/*
	Put a line out to the list device. Usage:

	lputs(str)
	char *str;

	Works just like "puts", except the output line goes to the
	printer instead of to the console:
*/

lputs(str)
char *str;
{
	char c;
	while (c = *str++) {
		if (c == '\n') putc('\r',LISTDEV);
		putc(c,LISTDEV);
	}
}


/* SCOTT.C	Scott Layson's personal miscellaneous-function
			library

	This code is in the public domain.
	Created from functions in STDLIB?.C 81.10.29 Gyro

*/


#include "bdscio.h"


	/* This deletes elements in the array <ary>, which consists of
        <len> elements of <eltsize> bytes; elements from <dello>
        through <delhi> - 1 are deleted. */
arydel (ary, len, eltsize, dello, delhi)
	char *ary;
	int len, eltsize, dello, delhi;
{
	movmem (ary + delhi * eltsize,
		   ary + dello * eltsize,
		   (len - delhi) * eltsize);
	}


match (s1, s2)				/* case-independent null-term compare */
	char *s1, *s2;
{
	do if (toupper (*s1) != toupper (*s2)) return (FALSE);
		while ((s1++, *s2++));
	return (TRUE);
	}


upcase (str)			/* convert a string to upper case */
	char *str;
{
	for (;*str; ++str) *str = toupper (*str);
	}


/* The version of this in STDLIB2.C is bugous!!! */
int
fscanf(iobuf,format)
char *format;
struct _buf *iobuf;
{
	char text[MAXLINE];
	if (!fgets(text,iobuf)) return /* 0 NO!!! */ -1;
	return _scn(text,&format);
}


/* This is the standard one, except: if the character after "%s" in the format
string is a '%', the %s breaks on any whitespace.  */
int
_scn(line,fmt)
char *line, **fmt;
{
	char sf, c, base, n, *sptr, *format, matchchar;
	int sign, val, **args;

	format = *fmt++;	/* fmt first points to the format string */
	args = fmt;		/* now it points to the arg list */

	n = 0;
	while (c = *format++) {
	   _igs (&line);
	   if (!*line) return n;	/* if end of input string, return */
	   if (isspace(c)) continue;	/* skip white space in format string */
	   if (c != '%') {		/* if not %, must match text */
		if (c != _igs(&line)) return n;
		else line++;
	    }
	   else {			/* process conversion */
		sign = 1;
		base = 10;
		sf = 0;
		if ((c = *format++) == '*') {
			sf++;		/* if "*" given, supress assignment */
			c = *format++;
		 }
		switch (toupper(c)) {
		   case 'X': base = 16;
			     goto doval;

		   case 'O': base = 8;
			     goto doval;

		   case 'D': if (_igs(&line) == '-') {
				sign = -1;
				line++;
			      }

	   doval:  case 'U': val = 0;
			     if (_bc(_igs(&line),base) == ERROR)
				return n;
			     while ((c = _bc(*line++,base)) != 255)
				val = val * base + c;
			     line--;
			     break;

		   case 'S': _igs(&line);
			     sptr = *args;
				if (*format != '%') matchchar = *format++;
				else matchchar = '\0';
			     while (c = *line++)   {
					if (matchchar ? c == matchchar : isspace (c)) break;
					if (!sf) *sptr++ = c;
			      }				
			     if (!sf) {
				n++;
				*sptr = '\0';
				args++;
			      }
			     continue;

		   case 'C': if (!sf) {
				poke(*args++, *line);
				n++;
			     }
			     line++;
			     continue;

		   default:  return n;
		 }
		if (!sf) {
			**args++ = val * sign;
			n++;
		 }
	}}
	return n;
}


/* This one doesn't leave a trailing newline on the end.  It also doesn't
   care about CRs at all. */
char *
fgets(s,iobuf)
	char *s;
	struct _buf *iobuf;
{
	int count, c;
	char *cptr;
	
	count = (MAXLINE - 1);
	cptr = s;
	if ((c = getc(iobuf)) == CPMEOF  ||  c == EOF) return NULL;
	do {
		if (c == '\r') continue;
		if (c == '\n') break;
		*cptr++ = c;
		}
		while (--count  &&  (c = getc(iobuf)) != EOF  &&  c != CPMEOF);
	if (c == CPMEOF) ungetc(c,iobuf);	/* push back control-Z */
	*cptr = '\0';
	return s;
}



/* End of SCOTT.C */

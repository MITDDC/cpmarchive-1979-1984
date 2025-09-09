/*		Pattern Search Utility
 *
 *	This utility will search for regular expressions in text streams.
 * First a function is called to "compile" the search pattern into a form
 * easier to search with.  Then a function is called with the text to be
 * searched; it returns a pointer to the first line within the text which
 * matches the pattern (or 0 if none did).  This second function can be
 * called repeatedly, with successive pointers to find all lines which
 * match the pattern.  The second function also returns a pointer to the
 * memory location just past the matched string, making repeated searches
 * easier.
 *	For example:
 *
 *		comppat("*one*",'\n',FALSE);
 *		sptr = srchpat(textbuf,bufsz,endptr);
 *
 *	will set sptr to the first line in textbuf containing the string
 * "one" anywhere in it, and endptr to the point just past the matched
 * line; or else it will return zero if there was no matching line.
 *	Although the line must match the pattern exactly, searching for
 * a pattern anywhere in the line can be done by prefixing and postfixing
 * the pattern with "*".  Also, comppat() can be told (via the third
 * parameter) to ignore case when comparing letters.
 *
 *	Characters in the regular expressions have the following meanings:
 *
 *		<char> - unless one of the ones below, match exactly <char>.
 *		? - match any single character.
 *		* - match zero or more of any character.
 *		[<char_set>] - match any of the characters in the set.
 *		[-<char_set>] - match any of the characters not in the set.
 *			<char_set> ::= <char>		match <char>
 *				       <char1>-<char2>	match any char in the
 *							range <char1>-<char2>
 *	"\" can be used to quote characters (i.e., prevent them from being
 * interpretted specially).
 *
 *
 *	Initial coding 8/18/82 by Harry R. Chesley.
 *
 *
 *	Copyright 1982 by Harry R. Chesley.
 *	Unlimited permission granted for non-profit use only.
 */

#include "pat.h"

/*	comppat(pat,eolchar,anycase)
 *
 *	Function: Compile the regular expression pattern given in pat
 * into a series of pattern elements; append an element which matches
 * the eolchar.  If anycase is TRUE, ignore case on letters.
 *
 *	Algorithm: Parse pat for regular expression special characters,
 * constructing a compiled version in cpat.  The following transformations
 * are made to get from the original pattern to the compiled series of
 * elements:
 *		<char> - if anycase FALSE, pel_type = MONEC, pel_c = <char>;
 *			 if anycase TRUE, pel_type = MSET, set = [<char>,
 *				other case of <char>].
 *		? - pel_type = MONEA.
 *		* - pel_type = MMANY.
 *		[...] - pel_type = MSET, set = indicated characters.
 *		[-...] - pel_type = MSET, set = all but indicated characters.
 *
 *	Also, eolchar is not allowed in any but the last element.
 *
 *	Comments: This routine compiles into the global cpat, and also
 * sets cptop and eolch.  Therefore, it is not reentrant, and it is not
 * possible to be using more than one pattern at a time.
 */

comppat(pat,eolchar,anycase)

char *pat;
char eolchar;
int anycase;

{
	int negflg;	/* Used in [...] processing to remember leading -. */
	char c1, c2, ct; /* Used in [...] for <char>-<char> processing. */

	eolch = eolchar;	/* Remember end-of-line char. */
	cptop = cpat;		/* Start with nothing. */

	/* Go thru pattern 'til end of string. */
	while (*pat != 0) {

		/* Never allow the EOL character in the search pattern. */
		if (*pat == eolch) {
			pat++;
			continue;
		};

		/* Look for special characters. */
		switch (*pat++) {

			/* Zero or more of anything. */
			case '*':
				cptop->pel_type = MMANY; /* Zero or more. */
				break;

			/* One of anything. */
			case '?':
				cptop->pel_type = MONEA; /* One of anything.*/
				break;

			/* Character sets. */
			case '[':
				cptop->pel_type = MSET; /* Any in set. */
				clrall(cptop);	/* Start with nothing. */
				/* Check for "any but". */
				if (*pat == '-') {
					pat++;
					negflg = TRUE;
				} else negflg = FALSE;
				/* Figure the set. */
				while ((*pat != ']') && (*pat != 0)) {
					if (*pat == '\\')
						if (*(++pat) == 0) break;
					/* Check for <char>-<char>. */
					if (*(pat+1) == '-') {
						if (*(pat+2) != 0) {
							if ((c1 = *pat) >
							    (c2 = *(pat+2))) {
								ct = c1;
								c1 = c2;
								c2 = ct;
							};
							do if (anycase)
							     setnoc(cptop,c1);
							else
							     setmem(cptop,c1);
							while (c1++ < c2);
							pat += 2;
						} else pat++;
					} else {
						if (anycase)
							setnoc(cptop,*pat);
						else setmem(cptop,*pat);
					};
					pat++;
				};
				if (negflg) negset(cptop);
				if (*pat == ']') pat++;
				/* Never match the EOL char. */
				clrmem(cptop,eolch);
				break;

			/* Quote. */
			case '\\':
				if (*pat != 0) pat++;
				/* Fall thru to match single processing. */

			/* Anything else: match only it. */
			default:
				if (anycase) {
					cptop->pel_type = MSET;
					clrall(cptop);
					setnoc(cptop,*(pat-1));
				} else {
					cptop->pel_type = MONEC;
					cptop->pel_c = *(pat-1);
				};
				break;
		};

		cptop++;	/* Next element. */
	};

	/* Last of all, match EOL. */
	cptop->pel_type = MONEC;
	cptop->pel_c = eolchar;

#ifdef DEBUG
	/* Print out the pattern we just compiled. */
	prtpat();
#endif
}

/*	srchpat(strng,sz,eosptr)
 *
 *	Function: Using the previously compiled pattern, search the string
 * strng (of size sz) for a line exactly matching the pattern.  Return a
 * pointer to that line, or 0.  On a non-zero return, return in eosptr a
 * pointer to the next character after the matched string.
 *
 *	Algorithm: Repeatedly call match() on each successive line until a
 * line matching the pattern is found, or we run out of data.
 *
 *	Comments: See comments on comppat().
 *	The eosptr return value is passed from match by side-effect.
 */

char *srchpat(strng,sz,eosptr)

register char *strng;
register unsigned sz;
char **eosptr;

{
	/* While we've still got something to search thru. */
	while (sz != 0) {
		/* If this one matches, return it. */
		if (match(strng,sz,cpat)) {
			*eosptr = nextstr;
			return(strng);
		};
		/* Otherwise, find the next line, and try it. */
		while (*strng != eolch) {
			strng++; sz--;
			if (sz == 0) return(0);
		};
		strng++; sz--;	/* Skip EOL. */
	};
	return(0);
}

/*	match(sptr,sz,cpptr)
 *
 *	Function: Return TRUE if the string sptr (of size sz) exactly
 * matches the compiled search pattern cpptr.  If returning TRUE, also
 * return the next character past the match in nextstr.
 *
 *	Algorithm: Match only the first element (shortest string first),
 * recursively calling ourself to match the remainder of the string.
 *
 *	Comments: This function is used by srchpat() only.  The user should
 * never call it directly.
 *	nextstr is a side-effect return, which is not generally a nice idea.
 * However, match() is the most crucial routine in this package with regard
 * to execution-time efficiency, and passing another parameter thru the whole
 * recursive search would severly slow things down.
 *	The recursive depth of this routine is bounded by the maximum size
 * of the search pattern.  I.e., with a max pattern size of 100, this routine
 * will never call itself more than 100 times (or is it 101 times?).
 */

match(sptr,sz,cpptr)

register char *sptr;
register unsigned sz;
register struct pel *cpptr;

{
	struct pel *cpp1;	/* cpptr + 1. */

	/* If there's nothing left of the string, we can't match it. */
	if (sz == 0) return(FALSE);

	/* Calculate next cpptr for later use. */
	cpp1 = cpptr+1;

	/* Switch on type of element. */
	switch (cpptr->pel_type) {

		/* Match one exactly. */
		case MONEC:
			if (*sptr != cpptr->pel_c) return(FALSE);
			break;

		/* Match any one. */
		case MONEA:
			if (*sptr == eolch) return(FALSE);
			break;

		/* Match any in set. */
		case MSET:
			if (! inset(cpptr,*sptr)) return(FALSE);
			break;

		/* Match zero or more. */
		case MMANY:
			/* Try matching 0, 1, 2, ... */
			do {
				if (match(sptr,sz,cpp1)) return(TRUE);
				if (*sptr++ == eolch) break;
			} while (--sz);
			return(FALSE);

		/* We'd better not get here! */
		default:
#ifdef DEBUG
			printf("Illegal pel_type in match().\n");
#endif
			exit(1);
	};

	/* It matched so see if we're at the end or the rest matches. */
	if (cpptr == cptop) {
		nextstr = sptr+1;	/* Return next char past line. */
		return(TRUE);
	};

	/* See if the rest matches. */
	if (match(sptr+1,sz-1,cpp1)) return(TRUE);

	/* No match. */
	return(FALSE);
}

/*	setall(sptr), clrall(sptr), negset(sptr), setmem(sptr,mem),
 *	setnoc(sptr,mem)
 *
 *	Function: Set operations: set all bits, clear all, complement all,
 * clear one member bit, set one member bit, and set one member bit and it's
 * other case equivalent if a letter.
 *
 *	Algorithm: Obvious.
 *
 *	Comments: One other set operation (inset) is define as a macro
 * for speed.
 */

setall(sptr)

struct pel *sptr;

{
	int i;
	int *iptr;

	for (i = SETMAX, iptr = sptr->pel_set; i-- > 0; *iptr++ = 0xFFFF);
}

clrall(sptr)

struct pel *sptr;

{
	int i;
	int *iptr;

	for (i = SETMAX, iptr = sptr->pel_set; i-- > 0; *iptr++ = 0);
}

negset(sptr)

struct pel *sptr;

{
	int i;
	int *iptr;

	for (i = SETMAX, iptr = sptr->pel_set; i-- > 0;
		*iptr = ~*iptr, iptr++);
}

clrmem(sptr,mem)

struct pel *sptr;
char mem;

{
	sptr->pel_set[(mem>>4)&7] &= ~(1<<(mem&15));
}

setmem(sptr,mem)

struct pel *sptr;
char mem;

{
	sptr->pel_set[(mem>>4)&7] |= (1<<(mem&15));
}

setnoc(sptr,mem)

struct pel *sptr;
char mem;

{
	if ((mem >= 'a') && (mem <= 'z')) setmem(sptr,mem+('A'-'a'));
	else if ((mem >= 'A') && (mem <= 'Z')) setmem(sptr,mem+('a'-'A'));
	setmem(sptr,mem);
}

/*	prtpat()
 *
 *	Function: Print the current pattern is a readable form.
 *
 *	Algorithm: Obvious to the casual observer.
 *
 *	Comments: This is for debugging purposes only, and is only compiled
 * or called if DEBUG is defined.
 */

#ifdef DEBUG

prtpat()

{
	struct pel *cpptr;
	char c;

	for (cpptr = cpat; cpptr <= cptop; cpptr++) {
		printf("** Prtpat: ");
		switch (cpptr->pel_type) {
			case MMANY:
				printf("*");
				break;
			case MONEA:
				printf("?");
				break;
			case MONEC:
				if (cpptr->pel_c < ' ')
					printf("\\%3.3o",cpptr->pel_c);
				else printf("%c",cpptr->pel_c);
				break;
			case MSET:
				printf("[");
				for (c = 0; c <= 128; c++ )
					if (inset(cpptr,c))
						if (c < ' ')
							printf(" \\%3.3o",c);
						else printf(" %c",c);
				printf("]");
				break;
			default:
				printf("Illegal pel_type in prtpat!\n");
				break;
		};
		printf("\n");
	};
}

#endif

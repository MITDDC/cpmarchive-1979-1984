/*		Pattern Search Defines & Globals
 *
 *	This file contains defines, macros, and global declarations for
 * a simple pattern searcher.  See pat.c for more details.
 *
 *
 *	Initial coding 8/18/82 by Harry R. Chesley.
 *
 *
 *	Copyright 1982 by Harry R. Chesley.
 *	Unlimited permission granted for non-profit use only.
 */

/* DEBUG - if defined, turn on various debugging print-outs.
 *
 * SETMAX - size of sets (128 elements (one per possible char)/16 elements
 *	    per word = 8 words).
 * PATMAX - maximum size of pattern.
 *
 * TRUE, FALSE - logical values.
 */

/*#define DEBUG*/

#define SETMAX 8
#define PATMAX 100

#define TRUE 1
#define FALSE 0

struct pel {			/* Pattern "elements". */
	int pel_type;		/* Type of element (see below). */
	char pel_c;		/* Character for match-one elements. */
	unsigned pel_set[SETMAX]; /* Set for match-set elements. */
};

/* Values for pel_type above:
 *
 *	MONEC - match exactly one of set_c.
 *	MONEA - match exactly one of any character (except EOL).
 *	MMANY - match one for more of anything (except EOL).
 *	MSET - match any character in set.
 */

#define MONEC 0
#define MONEA 1
#define MMANY 2
#define MSET 3

/* Operations on sets:
 *
 *	inset(sptr,mem) - returns TRUE if mem is in set, FALSE otherwise.
 */

#define inset(s,m) (s->pel_set[(m>>4)&7] & (1<<(m&15)))

/* Globals:
 */

struct pel cpat[PATMAX];	/* The compiled search pattern. */

struct pel *cptop;		/* Pointer to last element in pattern. */

char eolch;			/* End-of-line character. */

char *nextstr;			/* First char past matched string. */

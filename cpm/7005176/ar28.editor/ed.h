/* Screen editor:  non-user defined globals
 *
 * Source:  ed.h
 * Version: May 15, 1980.
 */


/* Define global constants */

/* Define constants describing a text line */

#define MAXLEN	133	/* max chars per line */
#define MAXLEN1	134	/* MAXLEN + 1 */

/* Define operating system constants */

#define SYSFNMAX 15	/* CP/M file name length + 1 */

/* Define misc. constants */

#define EOS	0	/* code sometimes assumes \0 */
#define ERR	-1	/* must be same as ERROR */
#define YES	1	/* must be nonzero */
#define NO	0
#define CR	13	/* carriage return */
#define LF	10	/* line feed */
#define TAB	9	/* tab character */
#define HUGE	32000	/* practical infinity */


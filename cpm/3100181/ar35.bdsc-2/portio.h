/* PORTIO.H - I/O buffer data type and related definitions for use
   with the I/O routines in PORTIO.C.  */

struct iobuf {
	int fd;
	int isect;			/* currently buffered sector */
	int nextc;			/* index of next char in buffer */
	char written;			/* anything written in current sector? */
	char buff [128];
	};
#define	ABSOLUTE	0		/* seek codes */
#define	RELATIVE	1

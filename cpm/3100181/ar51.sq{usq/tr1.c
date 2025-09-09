#include <bdscio.h>
#include <dio.h>
#include "sqcom.h"
#include "sq.h"

/* First translation - encoding of repeated characters
 * The code is byte for byte pass through except that
 * DLE is encoded as DLE, zero and repeated byte values
 * are encoded as value, DLE, count for count >= 3.
 */

init_ncr()	/*initialize getcnr() */
{
	state = NOHIST;
}

int
getcnr(iob)
struct _buf *iob;
{
	switch(state) {
	case NOHIST:
		/* No relevant history */
		state = SENTCHAR;
		return lastchar = getc_crc(iob);   
	case SENTCHAR:
		/* Lastchar is set, need lookahead */
		switch(lastchar) {
		case DLE:
			state = NOHIST;
			return 0;	/* indicates DLE was the data */
		case EOF:
			return EOF;
		default:
			for(likect = 1; (newchar = getc_crc(iob)) == lastchar && likect < 255; ++likect)
				;
			switch(likect) {
			case 1:
				return lastchar = newchar;
			case 2:
				/* just pass through */
				state = SENDNEWC;
				return lastchar;
			default:
				state = SENDCNT;
				return DLE;
			}
		}
	case SENDNEWC:
		/* Previous sequence complete, newchar set */
		state = SENTCHAR;
		return lastchar = newchar;
	case SENDCNT:
		/* Sent DLE for repeat sequence, send count */
		state = SENDNEWC;
		return likect;
	default:
		puts("Bug - bad state\n");
		exit(1);
	}
}

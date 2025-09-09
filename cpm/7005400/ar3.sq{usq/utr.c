#include <bdscio.h>
#include <dio.h>
#include "sqcom.h"
#include "usq.h"

/* initialize decoding functions */

init_cr()
{
	repct = 0;
}

init_huff()
{
	bpos = 99;	/* force initial read */
}

/* Get bytes with decoding - this decodes repetition,
 * calls getuhuff to decode file stream into byte
 * level code with only repetition encoding.
 *
 * The code is simple passing through of bytes except
 * that DLE is encoded as DLE-zero and other values
 * repeated more than twice are encoded as value-DLE-count.
 */

int
getcr(ib)
struct _buf *ib;
{
	int c;

	if(repct > 0) {
		/* Expanding a repeated char */
		--repct;
		return value;
	} else {
		/* Nothing unusual */
		if((c = getuhuff(ib)) != DLE) {
			/* It's not the special delimiter */
			value = c;
			if(value == EOF)
				repct = LARGE;
			return value;
		} else {
			/* Special token */
			if((repct = getuhuff(ib)) == 0)
				/* DLE, zero represents DLE */
				return DLE;
			else {
				/* Begin expanding repetition */
				repct -= 2;	/* 2nd time */
				return value;
			}
		}
	}
}

/* Decode file stream into a byte level code with only
 * repetition encoding remaining.
 */

int
getuhuff(ib)
struct _buf *ib;
{
	int i;
	int bitval;

	/* Follow bit stream in tree to a leaf*/
	i = 0;	/* Start at root of tree */
	do {
		if(++bpos > 7) {
			if((curin = getc(ib)) == ERROR)
				return ERROR;
			bpos = 0;
			/* move a level deeper in tree */
			i = dnode[i].children[1 & curin];
		} else
			i = dnode[i].children[1 & (curin >>= 1)];
	} while(i >= 0);

	/* Decode fake node index to original data value */
	i = -(i + 1);
	/* Decode special endfile token to normal EOF */
	i = (i == SPEOF) ? EOF : i;
	return i;
}

/* Portable I/O Package functions */
/* Written by EBM on 13 DEC 1981  */

/* i/o buffer data type */
#include "portio.h"

#define	TRUE		(-1)
#define	FALSE	0

int copen (buf, name)
	struct iobuf *buf;
	char *name;

{	buf->isect = -1;	/* set values to force initial read */
	buf->nextc = 128;
	buf->written = FALSE;
	return (buf->fd = open (name, 2));
	}

int ccreat (buf, name)
	struct iobuf *buf;
	char *name;

{	buf->isect = 0;	/* don't force initial write! */
	buf->nextc = 0;
	buf->written = FALSE;
	if ((buf->fd = creat (name)) < 0 || close (buf->fd) < 0) return (-1);
	return (buf->fd = open (name, 2));
	}

int cclose (buf)
	struct iobuf *buf;

{	if (cforce (buf) < 0) return (-1);
	return (close (buf->fd));
	}

int cread (buf, loc, len)
	struct iobuf *buf;
	char *loc;
	unsigned len;

{	char *oldloc;
	unsigned amt;

	oldloc = loc;
	while (len) {
		if ((amt = min (len, 128 - buf->nextc)) <= 0) {
			if (cforce (buf) < 0  ||
			    seek (buf->fd, ++buf->isect, ABSOLUTE) < 0  ||
			    read (buf->fd, buf->buff, 1) != 1) break;
			buf->nextc = 0;
			continue;
			}
		movmem (&buf->buff[buf->nextc], loc, amt);
		buf->nextc += amt;
		loc += amt;
		len -= amt;
		}
	return (loc - oldloc);
	}

int cwrite (buf, loc, len)
	struct iobuf *buf;
	char *loc;
	int len;

{	char *oldloc;
	unsigned amt;

	oldloc = loc;
	while (len) {
		if ((amt = min (len, 128 - buf->nextc)) <= 0) {
			if (cforce (buf) < 0) break;
			++buf->isect;
			buf->nextc = 0;
			continue;
			}
		movmem (loc, &buf->buff[buf->nextc], amt);
		buf->nextc += amt;
		loc += amt;
		len -= amt;
		buf->written = TRUE;
		}
	return (loc - oldloc);
	}

int cforce (buf)
	struct iobuf *buf;

{	if (buf->nextc > 0 && buf->written &&
	    (seek (buf->fd, buf->isect, ABSOLUTE) < 0  ||
	     write (buf->fd, buf->buff, 1) <= 0)) return (-1);
	buf->written = FALSE;
	return (1);
	}

int cflush (buf)
	struct iobuf *buf;

{	if (buf->nextc & 0x7f) {
		setmem (&buf->buff[buf->nextc], 128 - buf->nextc, ('Z' - '@'));
		buf->written = TRUE;
		}
	return (cforce (buf));
	}

int cseek (buf, amt, mode)
	struct iobuf *buf;
	int amt, mode;

{	int newsect, newpos;

	if (mode == RELATIVE)
		{if (amt < 0) {		/* backwards */
			amt = -amt;
			newsect = buf->isect - (amt >> 7);
			newpos = buf->nextc - (amt & 0x7f);
			while (newpos < 0) {
				newpos += 128;
				--newsect;
				}
			if (newsect < 0) return (-1);
			}
		else	{
			newsect = buf->isect + (amt >> 7);
			newpos = buf->nextc + (amt & 0x7f);
			while (newpos >= 128) {
				newpos -= 128;
				++newsect;
				}
			}
		}
	else if (mode == ABSOLUTE) {
		if (amt < 0) return (-1);
		newsect = (amt >> 7);
		newpos = (amt & 0x7f);
		}
	else return (-1);
	if (newsect != buf->isect  &&
	    (cforce (buf) < 0  ||
		seek (buf->fd, newsect, ABSOLUTE) < 0  ||
		read (buf->fd, buf->buff, 1) != 1)) return (-1);
	buf->isect = newsect;
	buf->nextc = newpos;
	buf->written = FALSE;
	return (1);
	}

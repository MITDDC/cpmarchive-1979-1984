/* Screen editor:  buffer module
 *                 BDS C version
 *
 * Source:  ed10.c
 * Version: May 15, 1981.
 */

/* define globals */

#include ed.h
#include bdscio.h
#include ed1.ccc
#include edext.cc

/* globals used by this module -----

int bufcflag;		main buffer changed flag
char *bufp;		start of current line
char *bufpmax;		end of last line
char *bufend;		last byte of buffer
int bufline;		current line number
int bufmaxln;		number of lines in buffer
char buffer[1];		start of buffer

----- */

/* This code is built around several invariant
 * assumptions:
 * First, the last line is always completely empty.
 * When bufp points to the last line there is NO
 * CR following it.
 * Second, bufp points to the last line if and only if
 * bufline==bufmaxln+1.
 * Third, bufline is always greater than zero.
 * Line zero exists only to make scanning for the
 * start of line one easier.
 */


/* Clear the main buffer */

bufnew()
{
	/* point past line 0 */
	bufp=bufpmax=buffer+1;
	/* point at last byte of buffer */
	/* allow space for stack */
	bufend=sysend()-1000;
	/* at line one. no lines in buffer */
	bufline=1;
	bufmaxln=0;
	/* line zero is always a null line */
	buffer[0]=CR;
	/* indicate no need to save file yet */
	bufcflag=NO;
}

/* return current line number */

bufln()
{
	return(bufline);
}

/* return YES if the buffer (i.e., file) has been
 * changed since the last time the file was saved.
 */

bufchng()
{
	return(bufcflag);
}

/* the file has been saved.  clear bufcflag. */

bufsaved()
{
	bufcflag=NO;
}

/* return number of bytes left in the buffer */

buffree()
{
	return(bufend-bufp);
}

/* Position buffer pointers to start of indicated line */

bufgo(line) int line;
{
	/* put request into range. prevent extension */
	line=min(bufmaxln+1,line);
	line=max(1,line);
	/* already at proper line? return. */
	if (line==bufline) {
		return(OK);
	}
	/* move through buffer one line at a time */
	while (line<bufline) {
		if (bufup()==ERR) {
			return(ERR);
		}
	}
	while (line>bufline) {
		if (bufdn()==ERR) {
			return(ERR);
		}
	}
	/* we have reached the line we wanted */
	return(OK);
}

/* move one line closer to front of buffer, i.e.,
 * set buffer pointers to start of previous line.
 */

bufup()
{
char *oldbufp;
	oldbufp=bufp;
	/* can't move past line 1 */
	if (bufattop()) {
		return(OK);
	}
	/* move past CR of previous line */
	if (*--bufp!=CR) {
		syserr("bufup: missing CR");
		bufp=oldbufp;
		return(ERR);
	}
	/* move to start of previous line */
	while (*--bufp!=CR) {
		;
	}
	bufp++;
	/* make sure we haven't gone too far */
	if (bufp<(buffer+1)) {
		syserr("bufup: bufp underflow");
		bufp=oldbufp;
		return(ERR);
	}
	/* success!  we ARE at previous line */
	bufline--;
	return(OK);
}

/* Move one line closer to end of buffer, i.e.,
 * set buffer pointers to start of next line.
 */

bufdn()
{
char *oldbufp;
	oldbufp=bufp;
	/* do nothing silly if at end of buffer */
	if (bufatbot()) {
		return(OK);
	}
	/* scan past current line and CR */
	while (*bufp++!=CR) {
		;
	}
	/* make sure we haven't gone too far */
	if (bufp>bufpmax) {
		syserr("bufdn: bufp overflow");
		bufp=oldbufp;
		return(ERR);
	}
	/* success! we are at next line */
	bufline++;
	return(OK);
}

/* Insert a line before the current line.
 * p points to a line of length n to be inserted.
 * Note: n does not include trailing CR.
 */

bufins(p,n) char *p; int n;
{
int k;
	/* make room in the buffer for the line */
	if (bufext(n+1)==ERR) {
		return(ERR);
	}
	/* put the line and CR into the buffer */
	k=0;
	while (k<n) {
		*(bufp+k)=*(p+k);
		k++;
	}
	*(bufp+k)=CR;
	/* increase number of lines in buffer */
	bufmaxln++;
	/* special case: inserting a null line at
	 * end of file is not a significant change.
	 */
	if ((n==0)&&(bufnrbot())) {
		;
	}
	else {
		bufcflag=YES;
	}
	return(OK);
}

/* delete the current line */

bufdel()
{
	return(bufdeln(1));
}

/* delete n lines, starting with the current line */

bufdeln(n) int n;
{
int oldline;
int k;
char *oldbufp;
	/* remember current buffer parameters */
	oldline=bufline;
	oldbufp=bufp;
	/* scan for first line after deleted lines */
	k=0;
	while ((n--)>0) {
		if (bufatbot()) {
			break;
		}
		if (bufdn()==ERR) {
			bufline=oldline;
			oldbufp=bufp;
			return(ERR);
		}
		k++;
	}
	/* compress buffer.  update pointers */
	bufmovup(bufp,bufpmax-1,bufp-oldbufp);
	bufpmax=bufpmax-(bufp-oldbufp);
	bufp=oldbufp;
	bufline=oldline;
	bufmaxln=bufmaxln-k;
	bufcflag=YES;
	return(OK);
}

/* replace current line with the line that
 * p points to.  The new line is of length n.
 */

bufrepl(p,n) char *p; int n;
{
int oldlen, k;
char *nextp;
	/* do not replace null line.  just insert */
	if (bufatbot()) {
		return(bufins(p,n));
	}
	/* point nextp at start of next line */
	if (bufdn()==ERR) {
		return(ERR);
	}
	nextp=bufp;
	if (bufup()==ERR) {
		return(ERR);
	}
	/* allow for CR at end */
	n=n+1;
	/* see how to move buffer below us;
	 * up, down, or not at all.
	 */
	oldlen=nextp-bufp;
	if (oldlen<n) {
		/* move buffer down */
		if (bufext(n-oldlen)==ERR) {
			return(ERR);
		}
		bufpmax=bufpmax+n-oldlen;
	}
	else if (oldlen>n) {
		/* move buffer up */
		bufmovup(nextp,bufpmax-1,oldlen-n);
		bufpmax=bufpmax-(oldlen-n);
	}
	/* put new line in the hole we just made */
	k=0;
	while (k<(n-1)) {
		bufp[k]=p[k];
		k++;
	}
	bufp[k]=CR;
	bufcflag=YES;
	return(OK);
}

/* copy current line into buffer that p points to.
 * the maximum size of that buffer is n.
 * return k=length of line in the main buffer.
 * if k>n then truncate n-k characters and only
 * return n characters in the caller's buffer.
 */

bufgetln(p,n) char *p; int n;
{
int k;
	/* last line is always null */
	if (bufatbot()) {
		return(0);
	}
	/* copy line as long as it not too long */
	k=0;
	while (k<n) {
		if (*(bufp+k)==CR) {
			return(k);
		}
		*(p+k)=*(bufp+k);
		k++;
	}
	/* count length but move no more chars */
	while (*(bufp+k)!=CR) {
		k++;
	}
	return(k);
}

/* move buffer down (towards HIGH addresses) */

bufmovdn(from,to,length) char *from, *to; int length;
{
	/* this code needs to be very fast.
	 * use an assembly language routine.
	 */

	sysmovdn(to-from+1,to+length,to);
}

/* the call to sysmovdn() is equivalent to the following code:

int k;
	k=to-from+1;
	while ((k--)>0) {
		*(to+length)=*to;
		to--;
	}

 */

/* move buffer up (towards LOW addresses) */

bufmovup(from,to,length) char *from, *to; int length;
{
	/* this code must be very fast.
	 * use an assembly language routine.
	 */

	sysmovup(to-from+1,from-length,from);
}

/* the call to sysmovup() is equivalent to the following code:

int k;
	k=to-from+1;
	while ((k--)>0) {
		*(from-length)=*from;
		from++;
	}

 */

/* return true if at bottom of buffer.
 * NOTE 1: the last line of the buffer is always null.
 * NOTE 2: the last line number is always bufmaxln+1.
 */

bufatbot()
{
	return(bufline>bufmaxln);
}

/* return true if at bottom or at the last
 * real line before the bottom.
 */

bufnrbot()
{
	return(bufline>=bufmaxln);
}

/* return true if at top of buffer */

bufattop()
{
	return(bufline==1);
}

/* put nlines lines from buffer starting with
 * line topline at position topy of the screen.
 */

bufout(topline,topy,nlines) int topline, topy, nlines;
{
int l,p;
	/* remember buffer's state */
	l=bufline;
	p=bufp;
	/* write out one line at a time */
	while ((nlines--)>0) {
		outxy(0,topy++);
		bufoutln(topline++);
	}
	/* restore buffer's state */
	bufline=l;
	bufp=p;
}

/* print line of main buffer on screen */

bufoutln(line) int line;
{
	/* error message does NOT go on prompt line */
	if (bufgo(line)==ERR) {
		fmtsout("disk error: line deleted",0);
		outdeol();
		return;
	}
	/* blank out lines below last line of buffer */
	if (bufatbot()) {
		outdeol();
	}
	/* write one formatted line out */
	else {
		fmtsout(bufp,0);
		outdeol();
	}
}

/* simple memory version of bufext.
 * create a hole in buffer at current line.
 * length is the size of the hole.
 */

bufext(length) int length;
{
	/* make sure there is room for more */
	if ((bufpmax+length)>=bufend) {
		error("main buffer is full");
		return(ERR);
	}
	/* move lines below current line down */
	bufmovdn(bufp,bufpmax-1,length);
	bufpmax=bufpmax+length;
	return(OK);
}

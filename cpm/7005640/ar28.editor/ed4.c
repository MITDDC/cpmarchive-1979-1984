/*
 * Screen editor:  window module
 *
 * Source:  ed4.cc
 * Version: August 21, 1981.
 */

/* define global constants, variables */

#include ed.h
#include bdscio.h
#include ed1.ccc
#include edext.cc

/* data global to this module -----

char	editbuf[MAXLEN];	the edit buffer
int	editp;			cursor: buffer index
int	editpmax;		length of buffer
int	edcflag;		buffer change flag

----- */

/* abort any changes made to current line */

edabt()
{
	/* get unchanged line and reset cursor */
	edgetln();
	edredraw();
	edbegin();
	edcflag = NO;
}

/* put cursor at beginning of current line */

edbegin()
{
	editp = 0;
	outxy(0,outgety());
}

/* change editbuf[editp] to c
 * don't make change if line would become to long
 */

edchng(c) char c;
{
char oldc;
int k;
	/* if at right margin then insert char */
	if (editp >= editpmax) {
		edins(c);
		return;
	}
	/* change char and print length of line */
	oldc = editbuf[editp];
	editbuf[editp] = c;
	fmtadj(editbuf,editp,editpmax);
	k = fmtlen(editbuf,editpmax);
	if (k > SCRNW1) {
		/* line would become too long */
		/* undo the change */
		editbuf[editp] = oldc;
		fmtadj(editbuf,editp,editpmax);
	}
	else {
		/* set change flag, redraw line */
		edcflag = YES;
		editp++;
		edredraw();
	}
}

/* delete the char to left of cursor if it exists */

eddel()
{
int k;
	/* just move left one column if past end of line */
	if (edxpos() < outgetx()) {
		outxy(outgetx()-1, outgety());
		return;
	}
	/* do nothing if cursor is at left margin */
	if (editp == 0) {
		return;
	}
	edcflag = YES;
	/* compress buffer (delete char) */
	k = editp;
	while (k < editpmax) {
		editbuf[k-1] = editbuf[k];
		k++;
	}
	/* update pointers, redraw line */
	editp--;
	editpmax--;
	edredraw();
}

/* edit the next line.  do not go to end of buffer */

eddn()
{
int oldx;
	/* save visual position of cursor */
	oldx = outgetx();
	/* replace current edit line */
	if (edrepl() != OK) {
		return(ERR);
	}
	/* do not go past last non-null line */
	if (bufnrbot()) {
		return(OK);
	}
	/* move down one line in buffer */
	if (bufdn() != OK) {
		return(ERR);
	}
	edgetln();
	/* put cursor as close as possible on this
	 * new line to where it was on the old line.
	 */
	editp = edscan(oldx);
	/* update screen */
	if (edatbot()) {
		edsup(bufln()-SCRNL2);
		outxy(oldx, SCRNL1);
	}
	else {
		outxy(oldx, outgety()+1);
	}
	return(OK);
}

/* put cursor at the end of the current line */

edend()
{
	editp = editpmax;
	outxy(edxpos(),outgety());
	
	/* comment out ----- put cursor at end of screen
	outxy(SCRNW1, outgety());
	----- end comment out */
}

/* start editing line n
 * redraw the screen with cursor at position p
 */

edgo(n, p) int n, p;
{
	/* replace current line */
	if (edrepl() == ERR) {
		return(ERR);
	}
	/* go to new line */
	if (bufgo(n) == ERR) {
		return(ERR);
	}
	/* prevent going past end of buffer */
	if (bufatbot()) {
		if (bufup() == ERR) {
			return(ERR);
		}
	}
	/* redraw the screen */
	bufout(bufln(),1,SCRNL1);
	edgetln();
	editp = min(p, editpmax);
	outxy(edxpos(), 1);
	return(OK);
}

/* insert c into the buffer if possible */

edins(c) char c;
{
int k;

	/* do nothing if edit buffer is full */
	if (editpmax >= MAXLEN) {
		return;
	}
	/* fill out line if we are past its end */
	if (editp == editpmax && edxpos() < outgetx()) {
		k = outgetx() - edxpos();
		editpmax = editpmax + k;
		while (k-- > 0) {
			editbuf [editp++] = ' ';
		}
		editp = editpmax;
	}
	/* make room for inserted character */
	k = editpmax;
	while (k > editp) {
		editbuf[k] = editbuf[k-1];
		k--;
	}
	/* insert character. update pointers */
	editbuf[editp] = c;
	editp++;
	editpmax++;
	/* recalculate print length of line  */
	fmtadj(editbuf,editp-1,editpmax);
	k = fmtlen(editbuf,editpmax);
	if (k > SCRNW1) {
		/* line would become too long */
		/* delete what we just inserted */
		eddel();
	}
	else {
		/* set change flag, redraw line */
		edcflag = YES;
		edredraw();
	}
}

/* join (concatenate) the current line with the one above it */

edjoin()
{
int k;

	/* do nothing if at top of file */
	if (bufattop()) {
		return;
	}
	/* replace lower line temporarily */
	if (edrepl() != OK) {
		return;
	}
	/* get upper line into buffer */
	if (bufup() != OK) {
		return;
	}
	k = bufgetln(editbuf, MAXLEN);
	/* append lower line to buffer */
	if (bufdn() != OK) {
		return;
	}
	k = k + bufgetln(editbuf+k, MAXLEN-k);
	/* abort if the screen isn't wide enough */
	if (k > SCRNW1) {
		/* bug fix */
		bufgetln(editbuf,MAXLEN);
		return;
	}
	/* replace upper line */
	if (bufup() != OK) {
		return;
	}
	editpmax = k;
	edcflag = YES;
	if (edrepl() != OK) {
		return;
	}
	/* delete the lower line */
	if (bufdn() != OK) {
		return;
	}
	if (bufdel() != OK) {
		return;
	}
	if (bufup() != OK) {
		return;
	}
	/* update the screen */
	if (edattop()) {
 		edredraw();
	}
	else {
		k = outgety() - 1;
		bufout(bufln(),k,SCRNL-k);
		outxy(0,k);
		edredraw();
	}
}

/* delete chars until end of line or c found */

edkill(c) char c;
{
int k,p;
	/* do nothing if at right margin */
	if (editp == editpmax) {
		return;
	}
	edcflag = YES;
	/* count number of deleted chars */
	k = 1;
	while ((editp+k) < editpmax) {
		if (editbuf[editp+k] == c) {
			break;
		}
		else {
			k++;
		}
	}
	/* compress buffer (delete chars) */
	p = editp+k;
	while (p < editpmax) {
		editbuf[p-k] = editbuf[p];
		p++;
	}
	/* update buffer size, redraw line */
	editpmax = editpmax-k;
	edredraw();
}

/* move cursor left one column.
 * never move the cursor off the current line.
 */

edleft()
{
int k;

	/* if past right margin, move left one column */
	if (edxpos() < outgetx()) {
		outxy(max(0, outgetx()-1), outgety());
	}
	/* inside the line.  move left one character */
	else if (editp != 0) {
		editp--;
		outxy(edxpos(),outgety());
	}
}

/* insert a new blank line below the current line */

ednewdn()
{
int k;
	/* make sure there is a current line and 
	 * put the current line back into the buffer.
	 */
	if (bufatbot()) {
		if (bufins(editbuf,editpmax) != OK) {
			return;
		}
	}
	else if (edrepl() != OK) {
			return;
	}
	/* move past current line */
	if (bufdn() != OK) {
		return;
	}
	/* insert place holder:  zero length line */
	if (bufins(editbuf,0) != OK) {
		return;
	}
	/* start editing the zero length line */
	edgetln();
	/* update the screen */
	if (edatbot()) {
		/* note: bufln()  >= SCRNL */
		edsup(bufln()-SCRNL2);
		outxy(edxpos(),SCRNL1);
	}
	else {
		k = outgety();
		bufout(bufln(),k+1,SCRNL1-k);
		outxy(edxpos(),k+1);
	}
}

/* insert a new blank line above the current line */

ednewup()
{
int k;
	/* put current line back in buffer */
	if (edrepl() != OK) {
		return;
	}
	/* insert zero length line at current line */
	if (bufins(editbuf,0) != OK) {
		return;
	}
	/* start editing the zero length line */
	edgetln();
	/* update the screen */
	if (edattop()) {
		edsdn(bufln());
		outxy(edxpos(),1);
	}
	else {
		k = outgety();
		bufout(bufln(),k,SCRNL-k);
		outxy(edxpos(),k);
	}
}

/* move cursor right one character.
 * never move the cursor off the current line.
 */

edright()
{
	/* if we are outside the line move right one column */
	if (edxpos() < outgetx()) {
		outxy (min(SCRNW1, outgetx()+1), outgety());
	}
	/* if we are inside a tab move to the end of it */
	else if (edxpos() > outgetx()) {
		outxy (edxpos(), outgety());
	}
	/* move right one character if inside line */
	else if (editp < editpmax) {
		editp++;
		outxy(edxpos(),outgety());
	}
	/* else move past end of line */
	else {
		outxy (min(SCRNW1, outgetx()+1), outgety());
	}
}

/* split the current line into two parts.
 * scroll the first half of the old line up.
 */

edsplit()
{
int p, q;
int k;

	/* indicate that edit buffer has been saved */
	edcflag = NO;
	/* replace current line by the first half of line */
	if (bufatbot()) {
		if (bufins(editbuf, editp) != OK) {
			return;
		}
	}
	else {
		if (bufrepl(editbuf, editp) != OK) {
			return;
		}
	}
	/* redraw the first half of the line */
	p = editpmax;
	q = editp;
	editpmax = editp;
	editp = 0;
	edredraw();
	/* move the second half of the line down */
	editp = 0;
	while (q < p) {
		editbuf [editp++] = editbuf [q++];
	}
	editpmax = editp;
	editp = 0;
	/* insert second half of the line below the first */
	if (bufdn() != OK) {
		return;
	}
	if (bufins(editbuf, editpmax) != OK) {
		return;
	}
	/* scroll the screen up and draw the second half */
	if (edatbot()) {
		edsup(bufln()-SCRNL2);
		outxy(1,SCRNL1);
		edredraw();
	}
	else {
		k = outgety();
		bufout(bufln(), k+1, SCRNL1-k);
		outxy(1, k+1);
		edredraw();
	}
}

/* move cursor right until end of line or
 * character c found.
 */

edsrch(c) char c;
{
	/* do nothing if at right margin */
	if (editp == editpmax) {
		return;
	}
	/* scan for search character */
	editp++;
	while (editp < editpmax) {
		if (editbuf[editp] == c) {
			break;
		}
		else {
			editp++;
		}
	}
	/* reset cursor */
	outxy(edxpos(),outgety());
}

/* move cursor up one line if possible */

edup()
{
int oldx;
	/* save visual position of cursor */
	oldx = outgetx();
	/* put current line back in buffer */
	if (edrepl() != OK) {
		return(ERR);
	}
	/* done if at top of buffer */
	if (bufattop()) {
		return(OK);
	}
	/* start editing the previous line */
	if (bufup() != OK) {
		return(ERR);
	}
	edgetln();
	/* put cursor on this new line as close as
	 * possible to where it was on the old line.
	 */
	editp = edscan(oldx);
	/* update screen */
	if (edattop()) {
		edsdn(bufln());
		outxy(oldx, 1);
	}
	else {
		outxy(oldx, outgety()-1);
	}
	return(OK);
}

/* delete the current line */

edzap()
{
int k;
	/* delete the line in the buffer */
	if (bufdel() != OK) {
		return;
	}
	/* move up one line if now at bottom */
	if (bufatbot()) {
		if (bufup() != OK) {
			return;
		}
		edgetln();
		/* update screen */
		if (edattop()) {
			edredraw();
		}
		else {
			outdelln();
			outxy(0,outgety()-1);
		}
		return;
	}
	/* start editing new line */
	edgetln();
	/* update screen */
	if (edattop()) {
		edsup(bufln());
		outxy(0,1);
	}
	else {
		k = outgety();
		bufout(bufln(),k,SCRNL-k);
		outxy(0,k);
	}
}

/* return true if the current edit line is being
 * displayed on the bottom line of the screen.
 */

edatbot()
{
	return(outgety() == SCRNL1);
}

/* return true if the current edit line is being
 * displayed on the bottom line of the screen.
 */

edattop()
{
	return(outgety() == 1);
}

/* redraw edit line from index to end of line */
/* reposition cursor */

edredraw()
{
	fmtadj(editbuf,0,editpmax);
	fmtsubs(editbuf,max(0,editp-1),editpmax);
	outxy(edxpos(),outgety());
}

/* return the x position of the cursor on screen */

edxpos()
{
	return(min(SCRNW1,fmtlen(editbuf,editp)));
}


/* fill edit buffer from current main buffer line.
 * the caller must check to make sure the main
 * buffer is available.
 */

edgetln()
{
int k;
	/* put cursor on left margin, reset flag */
	editp = 0;
	edcflag = NO;
	/* get edit line from main buffer */
	k = bufgetln(editbuf,MAXLEN);
	if (k > MAXLEN) {
		error("line truncated");
		editpmax = MAXLEN;
	}
	else {
		editpmax = k;
	}
	fmtadj(editbuf,0,editpmax);
}

/* replace current main buffer line by edit buffer.
 * the edit buffer is NOT changed or cleared.
 * return ERR is something goes wrong.
 */

edrepl()
{
	/* do nothing if nothing has changed */
	if (edcflag == NO) {
		return(OK);
	}
	/* make sure we don't replace the line twice */
	edcflag = NO;
	/* insert instead of replace if at bottom of file */
	if (bufatbot()) {
		return(bufins(editbuf,editpmax));
	}
	else {
		return(bufrepl(editbuf,editpmax));
	}
}

/* set editp to the largest index such that
 * buf[editp] will be printed <= xpos
 */

edscan(xpos) int xpos;
{
	editp = 0;
	while (editp < editpmax) {
		if (fmtlen(editbuf,editp) < xpos) {
			editp++;
		}
		else {
			break;
		}
	}
	return(editp);
}

/* scroll the screen up.  topline will be new top line */

edsup(topline) int topline;
{
	if (outhasup() == YES) {
		/* hardware scroll */
		outsup();
		/* redraw bottom line */
		bufout(topline+SCRNL2,SCRNL1,1);
	}
	else {
		/* redraw whole screen */
		bufout(topline,1,SCRNL1);
	}
}

/* scroll screen down.  topline will be new top line */

edsdn(topline) int topline;
{
	if (outhasdn() == YES) {
		/* hardware scroll */
		outsdn();
		/* redraw top line */
		bufout(topline,1,1);
	}
	else {
		/* redraw whole screen */
		bufout(topline,1,SCRNL1);
	}
}


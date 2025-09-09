/* Screen editor:  output format module
 *
 * Source: ed5.cc
 * Version: May 15, 1981.
 */

/* define globals */

#include ed.h
#include bdscio.h
#include ed1.ccc
#include edext.cc

/* variables global to this module -----

int fmttab;		maximal tab length
int fmtdev;		device flag -- YES/NO = LIST/CONSOLE
int fmtwidth;		devide width.  LISTW/SCRNW1

fmtcol[i] is the first column at which buf[i] is printed.
fmtsub() and fmtlen() assume fmtcol[] is valid on entry.

int fmtcol[MAXLEN1];

----- */

/* direct output from this module to either the console or
 * the list device.
 */

fmtassn(listflag) int listflag;
{
	if (listflag==YES) {
		fmtdev=YES;
		fmtwidth=LISTW;
	}
	else {
		fmtdev=NO;
		fmtwidth=SCRNW1;
	}
}

/* adjust fmtcol[] to prepare for calls on
 * fmtout() and fmtlen()
 *
 * NOTE:  this routine is needed as an efficiency
 *        measure.  Without fmtadj(), calls on
 *        fmtlen() become too slow.
 */

fmtadj(buf,minind,maxind) char *buf; int minind,maxind;
{
int k;
	/* line always starts at left margin */
	fmtcol[0]=0;
	/* start scanning at minind */
	k=minind;
	while (k<maxind) {
		if (buf[k]==CR) {
			break;
		}
		fmtcol[k+1]=fmtcol[k]+fmtlench(buf[k],fmtcol[k]);
		k++;
	}
}

/* return column at which at which buf[i] will be printed */

fmtlen(buf,i) char *buf; int i;
{
	return(fmtcol[i]);
}

/* print buf[i] ... buf[j-1] on current device so long as
 * characters will not be printed in last column.
 */

fmtsubs(buf,i,j) char *buf; int i, j;
{
int k;
	if (fmtcol[i]>=fmtwidth) {
		return;
	}
	outxy(fmtcol[i],outgety());	/* position cursor */
	while (i<j) {
		if (buf[i]==CR) {
			break;
		}
		if (fmtcol[i+1]>fmtwidth) {
			break;
		}
		fmtoutch(buf[i],fmtcol[i]);
		i++;
	}
	outdeol();	/* clear rest of line */
}

/* print string which ends with CR or EOS to current device.
 * truncate the string if it is too long.
 */

fmtsout(buf,offset) char *buf; int offset;
{
char c;
int col,k;
	col=0;
	while (c=*buf++) {
		if (c==CR) {
			break;
		}
		k=fmtlench(c,col);
		if ((col+k+offset)>fmtwidth) {
			break;
		}
		fmtoutch(c,col);
		col=col+k;
	}
}

/* return length of char c at column col */

fmtlench(c,col) char c; int col;
{
	if (c==TAB) {
		/* tab every fmttab columns */
		return(fmttab-(col%fmttab));
	}
	else if (c<32) {
		/* control char */
		return(2);
	}
	else {
		return(1);
	}
}

/* output one character to current device.
 * convert tabs to blanks.
 */

fmtoutch(c,col) char c; int col;
{
int k;
	if (c==TAB) {
		k=fmtlench(TAB,col);
		while ((k--)>0) {
			fmtdevch(' ');
		}
	}
	else if (c<32) {
		fmtdevch('^');
		fmtdevch(c+64);
	}
	else {
		fmtdevch(c);
	}
}

/* output character to current device */

fmtdevch(c) char c;
{
	if (fmtdev==YES) {
		syslout(c);
	}
	else {
		outchar(c);
	}
}

/* output a CR and LF to the current device */

fmtcrlf()
{
	if (fmtdev==YES) {
		syslout(CR);
		syslout(LF);
	}
	else {
		/* kludge: this should be in out module */
		/* make sure out module knows position */
		outxy(0,SCRNL1);
		syscout(CR);
		syscout(LF);
	}
}

/* set tabs at every n columns */

fmtset(n) int n;
{
	fmttab=max(1,n);
}

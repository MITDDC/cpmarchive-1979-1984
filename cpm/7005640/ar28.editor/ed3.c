/*
 * Screen editor:  command mode commands -- enhanced
 *
 * Source: ed3.bds
 * Version: December 20, 1981.
 * Transliteration of small-C version of September 5, 1981
 *
 */

/* define globals */

#include ed.h
#include bdscio.h
#include ed1.ccc
#include edext.cc

/* data global to these routines */

/* comment out -----
char filename [SYSFNMAX];
----- end comment out */


/* append command.
 * load a file into main buffer at current location.
 * this command does NOT change the current file name.
 */

append(args) char *args;
{
char buffer [MAXLEN];		/* disk line buffer */
int file;
int n;
int topline;
char locfn [SYSFNMAX];		/* local file name */
	/* get file name which follows command */
	if (name1(args,locfn) == ERR) {
		return;
	}
	if (locfn [0] == EOS) {
		message("no file argument");
		return;
	}
	/* open the new file */
	if ((file=sysopen(locfn,"r")) == ERR) {
		message("file not found");
		return;
	}
	/* read the file into the buffer */
	while ((n=readline(file,buffer,MAXLEN)) >= 0) {
		if (n > MAXLEN) {
			message("line truncated");
			n=MAXLEN;
		}
		if (bufins(buffer,n) == ERR) {
			break;
		}
		if (bufdn() == ERR) {
			break;
		}
	}
	/* close the file */
	sysclose(file);
	/* redraw the screen so topline will be at top
	 * of the screen after command() does a CR/LF.
	 */
	topline=max(1,bufln()-SCRNL2);
	bufout(topline,2,SCRNL2);
	bufgo(topline);
}

/* global change command */

change(args) char *args;
{
char oldline [MAXLEN1];		/* reserve space for EOS */
char newline [MAXLEN1];
char oldpat [MAXLEN1];
char newpat [MAXLEN1];
int from, to, col, n, k;
	if (get2args(args,&from,&to) == ERR) {
		return;
	}
	/* get search and change masks into oldpat, newpat */
	fmtsout("search mask ?  ",0);
	getcmnd(oldpat,15);
	fmtcrlf();
	if (oldpat [0] == EOS) {
		return;
	}
	pmtline();
	fmtsout("change mask ?  ",0);
	getcmnd(newpat,15);
	fmtcrlf();
	/* make substitution for lines between from, to */
	while (from <= to) {
		if (chkkey() == YES) {
			break;
		}
		if (bufgo(from++) == ERR) {
			break;
		}
		if (bufatbot() == YES) {
			break;
		}
		n=bufgetln(oldline,MAXLEN);
		n=min(n,MAXLEN);
		oldline [n]=EOS;
		/* '^' anchors search */
		if (oldpat [0] == '^') {
			if (amatch(oldline,oldpat+1,0) == YES) {
				k=replace(oldline,newline,
					oldpat+1,newpat,0);
				if (k == ERR) {
					return;
				}
				fmtcrlf();
				putdec(bufln(),5);
				fmtsout(newline,5);
				outdeol();
				bufrepl(newline,k);
			}
			continue;
		}
		/* search oldline for oldpat */
		col=0;
		while (col < n) {
			if (amatch(oldline,oldpat,col++) == YES){
				k=replace(oldline,newline,
					oldpat,newpat,col-1);
				if (k == ERR) {
					return;
				}
				fmtcrlf();
				putdec(bufln(),5);
				fmtsout(newline,5);
				outdeol();
				bufrepl(newline,k);
				break;
			}
		}
	}
	fmtcrlf();
}

/* clear main buffer and file name */

clear()
{
	/* make sure it is ok to clear buffer */
	if (chkbuf() == YES) {
		filename [0]=0;
		pmtfile("");
		outclr();
		outxy(0,SCRNL1);
		bufnew();
		message("buffer cleared");
	}
}

/* multiple line delete command */

delete(args) char *args;
{
int from, to;
	if (get2args(args,&from,&to) == ERR) {
		return;
	}
	if (from > to) {
		return;
	}
	/* go to first line to be deleted */
	if (bufgo(from) == ERR) {
		return;
	}
	/* delete all line between from and to */
	if (bufdeln(to-from+1) == ERR) {
		return;
	}
	/* redraw the screen */
	bufout(bufln(),1,SCRNL1);
}

/* search all lines below the current line for a pattern
 * return -1 if pattern not found.
 * otherwise, return column number of start of pattern.
 */

find()
{
	return(search1(bufln()+1,HUGE,YES));
}

/* list lines to list device */

list(args) char *args;
{
char linebuf [MAXLEN1];
int n;
int from, to, line, oldline;
	/* save the buffer's current line */
	oldline=bufln();
	/* get starting, ending lines to print */
	if (get2args(args,&from,&to) == ERR) {
		return;
	}
	/* print lines one at a time to list device */
	line=from;
	while (line <= to) {
		/* make sure prompt goes to console */
		fmtassn(NO);
		/* check for interrupt */
		if (chkkey() == YES) {
			break;
		}
		/* print line to list device */
		fmtassn(YES);
		if (bufgo(line++) != OK) {
			break;
		}
		if (bufatbot()) {
			break;
		}
		n=bufgetln(linebuf,MAXLEN1);
		n=min(n,MAXLEN);
		linebuf [n]=CR;
		fmtsout(linebuf,0);
		fmtcrlf();
	}
	/* redirect output to console */
	fmtassn(NO);
	/* restore cursor */
	bufgo(oldline);
}

/* load file into buffer */

load (args) char *args;
{
char buffer [MAXLEN];	/* disk line buffer */
char locfn  [SYSFNMAX];  /* file name until we check it */
int n;
int file;
int topline;
	/* get filename following command */
	if (name1(args,locfn) == ERR) {
		return;
	}
	if (locfn [0] == EOS) {
		message("no file argument");
		return;
	}
	/* give user a chance to save the buffer */
	if (chkbuf() == NO) {
		return;
	}
	/* open the new file */
	if ((file=sysopen(locfn,"r")) == ERR) {
		message("file not found");
		return;
	}
	/* update file name */
	syscopfn(locfn, filename);
	pmtfile(filename);
	/* clear the buffer */
	bufnew();
	/* read the file into the buffer */
	while ((n=readline(file,buffer,MAXLEN)) >= 0) {
		if (n > MAXLEN) {
			message("line truncated");
			n=MAXLEN;
		}
		if (bufins(buffer,n) == ERR) {
			break;
		}
		if (bufdn() == ERR) {
			break;
		}
	}
	/* close the file */
	sysclose(file);
	/* indicate that the buffer is fresh */
	bufsaved();
	/* set current line to line 1 */
	bufgo(1);
	/* redraw the screen so that topline will be
	 * on line 1 after command() does a CR/LF.
	 */
	topline=max(1,bufln()-SCRNL2);
	bufout(topline,2,SCRNL2);
	bufgo(topline);
}

/* change current file name */

name(args) char *args;
{
	name1(args,filename);
	pmtfile(filename);
}

/* check syntax of args.
 * copy to filename.
 * return OK if the name is valid.
 */

name1(args,filename) char *args, *filename;
{
	/* skip command */
	args=skiparg(args);
	args=skipbl(args);
	/* check file name syntax */
	if (syschkfn(args) == ERR) {
		return(ERR);
	}
	/* copy filename */
	syscopfn(args,filename);
	return(OK);
}

/* save the buffer in an already existing file */

resave()
{
char linebuf [MAXLEN];
int file, n, oldline;
	/* make sure file has a name */
	if (filename [0] == EOS) {
		message("file not named");
		return;
	}
	/* the file must exist for resave */
	if ((file=sysopen(filename,"r")) == ERR) {
		message("file not found");
		return;
	}
	if (sysclose(file) == ERR) {
		return;
	}
	/* open the file for writing */
	if ((file=sysopen(filename,"w")) == ERR) {
		return;
	}
	/* save the current position of file */
	oldline=bufln();
	/* write out the whole file */
	if (bufgo(1) == ERR) {
		sysclose(file);
		return;
	}
	while (bufatbot() == NO) {
		n=bufgetln(linebuf,MAXLEN);
		n=min(n,MAXLEN);
		if (pushline(file,linebuf,n) == ERR) {
			break;
		}
		if (bufdn() == ERR) {
			break;
		}
	}
	/* indicate if all buffer was saved */
	if (bufatbot()){
		bufsaved();
	}
	/* close file and restore line number */
	sysclose(file);
	bufgo(oldline);
}

/* save the buffer in a new file */

save()
{
char linebuf [MAXLEN];
int file, n, oldline;
	/* make sure the file is named */
	if (filename [0] == EOS) {
		message("file not named");
		return;
	}
	/* file must NOT exist for save */
	if ((file=sysopen(filename,"r")) != ERR) {
		sysclose(file);
		message("file exists");
		return;
	}
	/* open file for writing */
	if ((file=sysopen(filename,"w")) == ERR) {
		return;
	}
	/* remember current line */
	oldline=bufln();
	/* write entire buffer to file */
	if (bufgo(1) == ERR) {
		sysclose(file);
		return;
	}
	while (bufatbot() == NO) {
		n=bufgetln(linebuf,MAXLEN);
		n=min(n,MAXLEN);
		if (pushline(file,linebuf,n) == ERR) {
			break;
		}
		if (bufdn() == ERR) {
			break;
		}
	}
	/* indicate buffer saved if good write */
	if (bufatbot()) {
		bufsaved();
	}
	/* restore line and close file */
	bufgo(oldline);
	sysclose(file);
}

/* global search command */

search(args) char *args;
{
int from, to;

	if (get2args(args,&from,&to) == ERR) {
		return;
	}
	search1(from, to, NO);
}

/* search lines for a pattern.
 * if flag  ==  YES: stop at the first match.
 *                 return -1 if no match.
 *                 otherwise return column number of match.
 * if flag  ==  NO:  print all matches found.
 */

search1(from, to, flag) int from, to, flag;
{
char pat   [MAXLEN1];		/* reserve space for EOS */
char line  [MAXLEN1];
int col, n;
	/* get search mask into pat */
	fmtsout("search mask ?  ",0);
	getcmnd(pat,15);
	fmtcrlf();
	if (pat [0] == EOS) {
		return;
	}
	/* search all lines between from and to for pat */
	while (from <= to) {
		if (chkkey() == YES) {
			break;
		}
		if (bufgo(from++) == ERR) {
			break;
		}
		if (bufatbot() == YES) {
			break;
		}
		n=bufgetln(line,MAXLEN);
		n=min(n,MAXLEN);
		line [n]=EOS;
		/* ^ anchors search */
		if (pat [0] == '^') {
			if (amatch(line,pat+1,0) == YES) {
				if (flag == NO) {
					fmtcrlf();
					putdec(bufln(),5);
					fmtsout(line,5);
					outdeol();
				}
				else {
					return(0);
				}
			}
			continue;
		}
		/* search whole line for match */
		col=0;
		while (col < n) {
			if (amatch(line,pat,col++) == YES) {
				if (flag == NO) {
					fmtcrlf();
					putdec(bufln(),5);
					fmtsout(line,5);
					outdeol();
					break;
				}
				else {
					return(col-1);
				}
			}
		}
	}
	/* all searching is finished */
	if (flag == YES) {
		return(-1);
	}
	else {
		fmtcrlf();
	}
}

/* set tab stops for fmt routines */

tabs(args) char *args;
{
int n, junk;
	if (get2args(args,&n,&junk) == ERR) {
		return;
	}
	fmtset(n);
}

/* return YES if buffer may be drastically changed */

chkbuf()
{
	if (bufchng() == NO) {
		/* buffer not changed. no problem */
		return(YES);
	}
	fmtsout("buffer not saved. proceed ?  ",0);
	pmtline();
	if (tolower(syscout(syscin())) != 'y') {
		fmtcrlf();
		message("cancelled");
		return(NO);
	}
	else {
		fmtcrlf();
		return(YES);
	}
}

/* print message from a command */

message(s) char *s;
{
	fmtsout(s,0);
	fmtcrlf();
}

/* get two arguments the argument line args.
 * no arguments imply 1 HUGE.
 * one argument implies both args the same.
 */

get2args(args,val1,val2) char *args; int *val1, *val2;
{
	/* skip over the command */
	args=skiparg(args);
	args=skipbl(args);
	if (*args == EOS) {
		*val1=1;
		*val2=HUGE;
		return(OK);
	}
	/* check first argument */
	if (number(args,val1) == NO) {
		message("bad argument");
		return(ERR);
	}
	/* skip over first argument */
	args=skiparg(args);
	args=skipbl(args);
	/* 1 arg: arg 2 is HUGE */
	if (*args == EOS) {
		*val2=HUGE;
		return(OK);
	}
	/* check second argument */
	if (number(args,val2) == NO) {
		message("bad argument");
		return(ERR);
	}
	else {
		return(OK);
	}
}

/* skip over all except EOS, and blanks */

skiparg(args) char *args;
{
	while (*args != EOS && *args!=' ') {
		args++;
	}
	return(args);
}

/* skip over all blanks */

skipbl(args) char *args;
{
	while (*args == ' ') {
		args++;
	}
	return(args);
}

/* return YES if the user has pressed any key.
 * blanks cause a transparent pause.
 */
chkkey()
{
int c;
	c=syscstat();
	if (c == 0) {
		/* no character at keyboard */
		return(NO);
	}
	else if (c == ' ') {
		/* pause.  another blank ends pause */
		pmtline();
		if (syscin() == ' ') {
			return(NO);
		}
	}
	/* we got a nonblank character */
	return(YES);
}

/* anchored search for pattern in text line at column col.
 * return YES if the pattern starts at col.
 */

amatch(line,pat,col) char *line, *pat; int col;
{
int k;
	k=0;
	while (pat [k] != EOS) {
		if (pat [k] == line[col]) {
			k++;
			col++;
		}
		else if (pat [k] == '?' && line[col] != EOS) {
			/* question mark matches any char */
			k++;
			col++;
		}
		else {
			return(NO);
		}
	}
	/* the entire pattern matches */
	return(YES);
}

/* replace oldpat in oldline by newpat starting at col.
 * put result in newline.
 * return number of characters in newline.
 */

replace(oldline,newline,oldpat,newpat,col)
char *oldline, *newline, *oldpat, *newpat; int col;
{
int k;
char *tail, *pat;
	/* copy oldline preceding col to newline */
	k=0;
	while (k < col) {
		newline [k++]=*oldline++;
	}
	/* remember where end of oldpat in oldline is */
	tail=oldline;
	pat=oldpat;
	while (*pat++ != EOS) {
		tail++;
	}
	/* copy newpat to newline.
	 * use oldline and oldpat to resolve question marks
	 * in newpat.
	 */
	while (*newpat != EOS) {
		if (k > MAXLEN-1) {
			message("new line too long");
			return(ERR);
		}
		if (*newpat != '?') {
			/* copy newpat to newline */
			newline [k++]=*newpat++;
			continue;
		}
		/* scan for '?' in oldpat */
		while (*oldpat != '?') {
			if (*oldpat == EOS) {
				message(
				"too many ?'s in change mask"
				);
				return(ERR);
			}
			oldpat++;
			oldline++;
		}
		/* copy char from oldline to newline */
		newline [k++]=*oldline++;
		oldpat++;
		newpat++;
	}
	/* copy oldline after oldpat to newline */
	while (*tail != EOS) {
		if (k >= MAXLEN-1) {
			message("new line too long");
			return(ERR);
		}
		newline [k++]=*tail++;
	}
	newline [k]=EOS;
	return(k);
}


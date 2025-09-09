/* Screen editor:  main program -- BDS C version
 *
 * Source:  ed2.bds
 * Version: August 8, 1982.
 * Transliteration of small-C version of September 5, 1981
 */

/* define globals */

#include ed.h
#include bdscio.h
#include ed1.ccc
#include edext.cc

/* define signon message */

#define	SIGNON "BDS C Editor, version 2:  August 1982."

/* the main program dispatches the routines that
 * handle the various modes.
 */

#define CMNDMODE 1	/* enter command mode flag */
#define INSMODE  2	/* enter insert modes flag */
#define EDITMODE 3	/* enter edit mode flag */
#define EXITMODE 4	/* exit editor flag */

main(argc,argv)
int argc;
char *argv[];
{
int mode;
	/* fmt output by default goes to screen */
	fmtassn(NO);
	/* set tabs, clear the screen and sign on */
	fmtset(8);
	outclr();
	outxy(0,SCRNL1);
	message(SIGNON);
	outxy(0,1);
	/* clear filename [] for save(), resave() */
	name("");
	/* clear the main buffer */
	bufnew();
	/* start off in command mode */
	mode=CMNDMODE;
	/* set flag for startup command execution */
	startup = YES;
	argcount=argc; /* set startup argument count */
	if (argcount==2)
		strcpy(sname,argv[1]);
	/* get null line 1 for edit() */
	edgetln();
		while(1){
		if (mode == EXITMODE) {
			break;
		}
		else if (mode == CMNDMODE) {
			mode=command();
		}
		else if (mode == EDITMODE) {
			mode=edit();
		}
		else if (mode == INSMODE) {
			mode=insert();
		}
		else {
			syserr("main: no mode");
			mode=EDITMODE;
		}
	}
}

/*
 * handle edit mode.
 * dispatch the proper routine based on one-character commands.
 */

edit()
{
char buffer [SCRNW1];
int v;
int x,y;
char c;
int oldline, topline;
	/* beware of edgetln() or edgo() here because
	 * those calls reset the cursor.
	 */
	pmtedit();
	while(1){
		/* get command */
		c=tolower(syscin());

		if (c == ESC1 || c=='c') {
			/* enter command mode. */
			return(CMNDMODE);
		}
		else if (c == INS1 || c=='i') {
			/* enter insert mode */
			return(INSMODE);
		}
		else if (special(c) == YES) {
			if (c == UP1 || c == DOWN1) {
				return(INSMODE);
			}
			else {
				continue;
			}
		}
		else if (control(c) == YES) {
			continue;
		}
		else if (c == ' ') {
			edright();
			pmtcol();
		}
		else if (c == 'b') {
			edbegin();
			pmtcol();
		}
		else if (c == 'd') {
			/* scroll down */
			pmtmode("edit: scroll");
			oldline=bufln();
			y=outgety();
			topline=oldline-y+1;
			x=outgetx();
			edgo(topline+SCRNL1,x);
			pmtedit();
		}
		else if (c == 'e') {
			edend();
			pmtcol();
		}
		else if (c == 'g') {
			/* save x,y in case don't get number */
			x=outgetx();
			y=outgety();
			pmtcmnd("edit: goto: ",buffer);
			if(number(buffer,&v)) {
				edgo(v,0);
			}
			else {
				outxy(x,y);
			}
			pmtedit();
		}
		else if (c == 'k') {
			pmtmode("edit: kill");
			c=syscin();
			if (special(c) == NO &&
			    control(c) == NO) {
				edkill(c);
			}
			pmtedit();
		}
		else if (c == 's') {
			pmtmode("edit: search");
			c=syscin();
			if (special(c) == NO &&
			    control(c) == NO) {
				edsrch(c);
			}
			pmtedit();
		}
		else if (c == 'u') {
			/* scroll up */
			pmtmode("edit: scroll");
			oldline=bufln();
			y=outgety();
			topline=oldline-y+1;
			x=outgetx();
			edgo(topline-SCRNL1,x);
			pmtedit();
		}
		else if (c == 'x') {
			pmtmode("edit: eXchange");
			c=syscin();
			if (special(c) == NO &&
			    control(c) == NO) {
				edchng(c);
			}
			pmtedit();
		}
		/* do nothing if command not found */
	}
}

/* insert mode.
 * in this mode the UP1, UP2 keys reverse their roles,
 * as do the DOWN1, and DOWN2 keys.
 */

insert()
{
char c;
	pmtmode("insert");
	while (1) {
		/* get command */
		c=syscin();
		if (c == ESC1) {
			/* enter command mode */
			return(CMNDMODE);
		}
		else if (c == EDIT1) {
			/* enter edit mode */
			return(EDITMODE);
		}
		else if (c == INS1) {
			/* do nothing */
			;
		}
		else if (special(c) == YES) {
			if (c == UP2 || c == DOWN2) {
				return(EDITMODE);
			}
			else {
				continue;
			}
		}
		else if (control(c) == YES) {
			/* ignore non-special control chars */
			continue;
		}
		else {
			/* insert one char in line */
			edins(c);
			pmtcol();
		}
	}
}

/* return YES if c is a control char */

control(c) char c;
{
	if (c == TAB) {
		return(NO);	/* tab is regular */
	}
	else if (c>=127) {
		return(YES);	/* del or high bit on */
	}
	else if (c < 32) {
		return(YES);	/* control char */
	}
	else {
		return(NO);	/* normal */
	}
}

/*
 * handle the default actions of all special keys.
 * return YES if c is one of the keys.
 */

special(c) char c;
{
int k;
	if (c == JOIN1) {
		edjoin();
		pmtline();
		return(YES);
	}
	if (c == SPLT1) {
		edsplit();
		pmtline();
		return(YES);
	}
	if (c == ABT1) {
		edabt();
		pmtcol();
		return(YES);
	}
	else if (c == DEL1) {
		eddel();
		pmtcol();
		return(YES);
	}
	else if (c == ZAP1) {
		edzap();
		pmtline();
		return(YES);
	}
	else if (c == UP2) {
		/* move up */
		edup();
		pmtline();
		return(YES);
	}
	else if (c == UP1) {
		/* insert up */
		ednewup();
		pmtline();
		return(YES);
	}
	else if (c == DOWN2) {
		/* move down */
		eddn();
		pmtline();
		return(YES);
	}
	else if (c == DOWN1) {
		/* insert down */
		ednewdn();
		pmtline();
		return(YES);
	}
	else if (c == LEFT1) {
		edleft();
		pmtcol();
		return(YES);
	}
	else if (c == RIGHT1) {
		edright();
		pmtcol();
		return(YES);
	}
	else {
		return(NO);
	}
}

/*
 * command() dispatches command routines while
 * in command mode.
 */

command()
{
int v;
char c;
char args [SCRNW1];
char *argp;
int topline;
int ypos;
int oldline;
int k;
	/* command mode commands may move the current line.
	 * command mode must save the current line on entry
	 * and restore it on exit.
	 */
	edrepl();
	/* remember how the screen was drawn on entry */
	oldline=bufln();
	ypos=outgety();
	topline=oldline-ypos+1;
	while(1) {
		outxy(0,SCRNL1);
		fmtcrlf();
		pmtmode("command:");

		/* if filname on command line use it */
		if (startup == YES && argcount == 2) {
			strcpy(args,"load ");
			strcat(args,sname);
			startup = NO;
		}
		else	getcmnd(args,0);
		fmtcrlf();
		pmtline();
		c=args [0];
		if (c == EDIT1 || c==INS1) {
			/* redraw screen */
			if (oldline == bufln()) {
				/* get current line */
				edgetln();
				/* redraw old screen */
				bufout(topline,1,SCRNL1);
				outxy(0,ypos);
			}
			else {
				/* update line and screen */
				edgo(bufln(),0);
			}
			if (c == EDIT1) {
				return (EDITMODE);
			}
			else {
				return (INSMODE);
			}
		}
		else if (tolower(args [0]) == 'g'){
			argp=skipbl(args+1);
			if (argp [0] == EOS) {
				edgo(oldline,0); 
				return(EDITMODE);
			}
			else if (number(argp,&v) == YES) {
				edgo(v,0);
				return(EDITMODE);
			}
			else {
				message("bad line number");
			}
		}
		else if (lookup(args,"append")) {
			append(args);
		}
		else if (lookup(args,"change")) {
			change(args);
		}
		else if (lookup(args,"clear")) {
			clear();
		}
		else if (lookup(args,"delete")) {
			delete(args);
		}
		else if (lookup(args,"dos")) {
			if (chkbuf() == YES) {
				return (EXITMODE);
			}
		}
		else if (lookup(args,"find")) {
			if ((k = find()) >= 0) {
				edgo(bufln(),k);
				return(EDITMODE);
			}
			else {
				/* get current line */
				bufgo(oldline);
				edgetln();
				/* stay in command mode */
				message("pattern not found");
			}
		}
		else if (lookup(args,"list")) {
			list(args);
		}
		else if (lookup(args,"load")) {
			load(args);
		}
		else if (lookup(args,"name")) {
			name(args);
		}
		else if (lookup(args,"resave")) {
			resave();
		}
		else if (lookup(args,"save")) {
			save();
		}
		else if (lookup(args,"search")) {
			search(args);
		}
		else if (lookup(args,"tabs")) {
			tabs(args);
		}
		else {
			message("command not found");
		}
	}
}

/* return YES if line starts with command */

lookup(line,command) char *line, *command;
{
	while(*command) {
		if (tolower(*line++) != *command++) {
			return(NO);
		}
	}
	if(*line == EOS || *line == ' ' || *line == TAB) {
		return(YES);
	}
	else {
		return(NO);
	}
}

/* get next command into argument buffer */

getcmnd(args,offset) char *args; int offset;
{
int j,k;
char c;
	outxy(offset,outgety());
	outdeol();
	k=0;
	while ((c=syscin()) != CR) {
		if (c == EDIT1 || c == INS1) {
			args [0]=c;
			return;
		}
		if (c == DEL1 || c == LEFT1) {
			if (k>0) {
				outxy(offset,outgety());
				outdeol();
				k--;
				j=0;
				while (j < k) {
					outchar(args [j++]);
				}
			}
		}
		else if (c == ABT1) {
			outxy(offset,outgety());
			outdeol();
			k=0;
		}
		else if (c != TAB && (c < 32 || c == 127)) {
			/* do nothing */
			continue;
		}
		else {
			if (k+offset < SCRNW1) {
				args [k++]=c;
				outchar(c);
			}
		}
	}
	args [k]=EOS;
}

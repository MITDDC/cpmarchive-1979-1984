/*
 * Screen editor:  external definitions
 *
 * Source: edext.cc
 * Version: August 8, 1982.
 *
 */

/* define flag for sUartup of editor -- ed2.bds */

int	startup;	/* flag for editor startup */
int	argcount;	/* global argc */
char	sname[SYSFNMAX]; /* command line filename */

/* define statics for the command module -- ed3.cc */

char filename[SYSFNMAX];	/* file name for (re)save */

/* define statics for the window module -- ed4.cc */

char	editbuf[MAXLEN]; /* the edit buffer */
int	editp;		/* cursor: buffer index */
int	editpmax;	/* length of buffer */
int	edcflag;	/* buffer change flag */

/* define statics for the format module -- ed5.cc */

int fmttab;		/* max length of tab character */
int fmtdev;		/* device -- YES/NO = LIST/CONSOLE */
int fmtwidth;		/* devide width.  LISTW/SCRNW1 */

/* fmtcol[i] is the first column at which buf[i] is printed.
 * fmtsub() and fmtlen() assume fmtcol[] is valid on entry.
 */

int fmtcol[MAXLEN1];

/* define statics for the terminal module -- ed6.ccc */

int outx, outy;		/* coordinates of the cursor */

/* define statics for the prompt line module -- ed7.cc */

char pmtln[MAXLEN];	/* mode */
char pmtfn[SYSFNMAX];	/* file name */

/* define statics for the operating system module -- ed8.cc */

/* constants defined in bdscio.h -----
#define NSECTS 8
#define SECSIZ 128
#define BUFSIZ	(NSECTS * SECSIZ + 6)
----- */

int  iormode;		/* YES if file is read mode */
char iobuf1[BUFSIZ];	/* file buffer */

/* define statics for the buffer module -- ed10.cc */

/*
 * buffer[] must be the last external variable and it must
 * have a nonzero dimension.
 */

int bufcflag;		/* main buffer changed flag */
char *bufp;		/* start of current line */
char *bufpmax;		/* end of last line */
char *bufend;		/* last byte of buffer */
int bufline;		/* current line number */
int bufmaxln;		/* number of lines in buffer */
char buffer[1];		/* start of buffer */

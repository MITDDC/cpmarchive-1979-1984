/* Screen editor:  operating system module
 *		   BDS C version
 *
 * Source:  ed8.cc
 * Version: June 19, 1981.
 */

/* dfine globals */

#include ed.h
#include bdscio.h
#include ed1.ccc
#include edext.cc

/* globals used by this module -----

#define NSECTS 8
#define SECSIZ 128
#define BUFSIZ (NSECTS * SECSIZ + 6)

int  iormode;		'r' 'w' or 'c'
char iobuf1[BUFSIZ];	file buffer

----- */

/* all calls to the operating system are made here.
 * only this module will have to be
 * rewritten for a new operating system.
 */

/* the routines syscstat(), syscin() and syscout() come in
 * two flavors:  CP/M version 2.2 and CP/M version 1.4.
 * Comment out which ever you don't use.
 */

/* CP/M 2.2 versions of syscstat(), syscin(), syscout() */

/* return -1 if no character is ready from the console. 
 * otherwise, return the character.
 */

syscstat()
{
	return(bdos(6,-1));
}

/* wait for next character from the console.
 * do not echo it.
 */

syscin()
{
int c;
	while ((c=bdos(6,-1))==0) {
		;
	}
	return(c);
}

/* print character on the console */

syscout(c) char c;
{
	bdos(6,c);
	return(c);
}

/*---------- start comment out
/* CP/M 1.4 versions of syscstat(), syscin(), syscout() */

syscstat()
{
	if (bios(2,0)==255) {
		return(-1);
	}
	else {
		return(0);
	}
}

syscin()
{
	return(bios(3,0));
}

syscout(c) char c;
{
	bios(4,c);
	return(c);
}

--------- end of comment out */

/* print character on the printer */

syslout(c) char c;
{
	bdos(5,c);
	return(c);
}

/*
 * return address of last usable memory location.
 */

sysend()
{
	return(topofmem());
}

/* open a file */

sysopen(name,mode) char *name, *mode;
{
int file;
int m;
	m=tolower(mode[0]);
	if (m=='r') {
		if ((file=fopen(name,iobuf1))==-1) {
			iormode='c';
			fclose(iobuf1);
			return(ERR);
		}
		else {
			iormode=m;
			return(iobuf1);
		}
	}
	else if (m=='w') {
		if ((file=fcreat(name,iobuf1))==-1) {
			iormode='c';
			fclose(iobuf1);
			return(ERR);
		}
		else {
			iormode=m;
			return(iobuf1);
		}
	}
	else {
		iormode='c';
		syserr("fopen: bad mode");
		return(ERR);
	}
}

/* close a file */

sysclose(file) int file;
{
	if (iormode=='w') {
		/* write end of file byte */
		putc(0x1a,iobuf1);
		fflush(iobuf1);
	}
	iormode='c';
	fclose(iobuf1);
	return(OK);
}

/* read next char from file */

sysrdch(file) int file;
{
int c;
	while ((c=sysrdc1())==LF) {
		;
	}
	return(c);
}

sysrdc1()
{
int c;
	if (iormode!='r') {
		error ("sysrdch:  read in w mode");
		return(ERR);
	}
	if ((c=getc(iobuf1))==-1) {
		return(EOF);
	}
	else if (c==0x1a) {
		return(EOF);
	}
	else {
		return(c);
	}
}

/* write next char to file */

syspshch(c,file) char c; int file;
{
	if (c!=CR) {
		return(syspshc1(c,file));
	}
	else if (syspshc1(c,file)==ERR) {
		return(ERR);
	}
	else {
		return(syspshc1(LF,file));
	}
}

syspshc1(c,file) char c; int file;
{
	if (iormode!='w') {
		error("syspshch:  write in r mode");
		return(ERR);
	}
	if (putc(c,iobuf1)==-1) {
		error("disk write failed");
		return(ERR);
	}
	else {
		return(c);
	}
}

/* read one char from END of file */

syspopch(file) int file;
{
	error("syspopch() not implemented");
	return(ERR);
}

/* check file name for syntax */

syschkfn(args) char *args;
{
	return(OK);
}

/* copy file name from args to buffer */

syscopfn(args,buffer) char *args, *buffer;
{
int n;
	n=0;
	while (n<(SYSFNMAX-1)) {
		if (args[n]==EOS) {
			break;
		}
		else {
			buffer[n]=args[n];
			n++;
		}
	}
	buffer[n]=EOS;
}

/* move a block of n bytes down (towards HIGH addresses).
 * block starts at source and the first byte goes to dest.
 * this routine is only called from bufmovdn() as follows:
 *	sysmovdn( n=to-from+1, dest=to+length, source=to);
 */

sysmovdn(n,dest,source) int n; char *dest, *source;
{
	if (n>0) {
		movmem(source-n+1,dest-n+1,n);
	}
}

/* move a block of n bytes up (towards LOW addresses).
 * the block starts at source and the first byte goes to dest.
 * this routine is called only from bufmovup() as follows:
 * 	sysmovup( n=to-from+1, dest=from-length, source=from);
 */

sysmovup(n,dest,source) int n; char *dest, *source;
{
	if (n>0) {
		movmem(source,dest,n);
	}
}


/*
	TELEDIT.C	v1.1		(see TELEDIT.DOC)

	A telecommunications program using Ward Christensen's
	"MODEM" File Transfer Protocol.

 	Modified by Nigel Harrison and Leor Zolman from XMODEM.C,
	which was written by:  Jack M. Wierda,
               modified by Roderick W. Hart and William D. Earnest

	Note that Modem port numbers, masks, etc., are taken from BDSCIO.H,
	which must have the correct values for your system.	
*/

/*
	Converted to HDOS by Al Bolduc
*/

#include	console.h
#include	printf.h

/*
	The following three defines must be customized by the user:
*/
#define HC	"\33H*"			/* Home cursor and print a "*"	*/
#define	SPECIAL	'^'-0x40		/* Gets out of terminal mode	*/
#define	CPUCLK	2			/* CPU clock rate, in MHz 	*/

/*
	The rest of the defines need not be modified
*/

#define	EOF	-1
#define	NULL	0
#define	TRUE	1
#define	FALSE	0
#define	ERROR	-1
#define	BUFSIZ	256
#define	CPMEOF	0X1A
#define	MDATA	0330
#define	MSTAT	0335
#define	CLEARS	"\033E"
#define	SECSIZ	128
#define	NSECTS	2
#define	MAXLINE	100
#define	SOH 1
#define	EOT 4
#define	ACK 6
#define	ERRORMAX 10
#define	RETRYMAX 10
#define	LF 10
#define	CR 13
#define	SPS 1500           		/*loops per second */
#define	NAK 21
#define	TIMEOUT -1
#define	TBFSIZ NSECTS*SECSIZ
#define	ML 1000				/* maximum source lines */

char linebuf[MAXLINE];			/* string buffer */
char fnambuf[50];			/* name of file for text collection */
int nlines, nl;				/* number of lines	*/
int linect;				/* current line	*/
char fflg;				/* text collection file flag */
char echoflg;				/* whether to echo		*/
char sflg;				/* transmit flag		*/
char	*textbuf;			/* Text buffer			*/
char	*textend;			/* End of text buffer		*/
unsigned	textind;		/* Index into text buffer	*/
int	baud = 300;			/* Baudrate (set to default)	*/

int moready()	/* return TRUE if the modem is ready for output */
{
	return(in(MSTAT) & 040);
}

int miready() 	/* return TRUE if input is present on the modem */
{
	return (in(MSTAT) & 01);
}

send(data)	/* send char to modem */
char data;
{
	while(!moready())
		;
	out(data,MDATA);
}

main(argc,argv)
char *argv[];
{
	int i, j, k, l;			/* scratch integers */
	char *lineptr[ML];		/* allow ML source lines */
	char *inl[ML];			/* inserted line pointers */
	char *p;			/* scratch pointer */
	int	fdes;			/* I/O file descriptor */
	int  inchar;			/* collect characters at inchar */
	char *alloc();			/* storage allocator */
	char *getm();			/* memory procuror */

	linect = nlines = i = 0;
	fflg = echoflg = FALSE;
	lineptr[i] = (char *)NULL;
	init();

	while(1)
	{
		lnmode();
		printf(CLEARS);
		printf("Teledit ver 1.1\n\n");

		printf("\tT: Terminal mode - no text collection\n");
		printf("\tX: terminal mode with teXt collection\n");
		printf("\t\tIn terminal mode:\n");
		printf("\t\tSPECIAL (control-^): return to menu\n");
		printf("\t\tcontrol-E: enter editor\n");
		printf("\tB: Baudrate (currently set to: %d)\n",baud);
		printf("\tG: toGgle echo mode (currently set to: %secho)\n",
		echoflg ? "" : "no ");
		printf("\tE: Edit collected text\n");
		printf("\tF: Flush text buffer to text collection file\n");
		printf("\tS: Send a file, MODEM protocol\n");
		printf("\tR: Receive a file, MODEM protocol\n");   
		printf("\tQ: quit\n");
		printf("\tSPECIAL: send SPECIAL char to modem\n");
		printf("\nCommand: ");
		chmode();

		inchar = 0XDF & getchar();
		putchar(inchar);
		putchar('\n');

		switch(inchar)
		{
		case SPECIAL:
			send(SPECIAL);
			break;
		case 'T':
			rawmode();
			terminal();
			break;
		case 'X':
			if (fflg)
	printf("Text collection already in effect (filename '%s')\n", fnambuf);
			else
			{
				printf("Collection text filename = ");
				gets(fnambuf);

				printf("Wait...");
				if((fdes = fopen(fnambuf,"r")) != NULL)
				{	
					fclose(fdes);
					printf("\nFile already exists; do you want to ");
					if(!ask("overwrite it"))       
						break;
				}
				else
					fclose(fdes);
				if((fdes = fopen(fnambuf, "w")) == NULL)
				{	
					printf("\nCan't create %s", fnambuf);
					break;
				}

				fflg = TRUE;	
			}
			printf("\nReady\n");

			rawmode();	
			while(1)	
			{	
				if(miready())
				{	
					putchar (inchar = 0177 & in(MDATA));

					if(i > (MAXLINE + 5))
						inchar = CR;
					if(inchar >= ' ')
						linebuf[i++] = inchar;
					else
					{	
						if(inchar == CR)
						{	
							linebuf[i++] = '\n';
							linebuf[i] = NULL;
							p = getm(linebuf);
							if(p == NULL) continue;
							lineptr[nlines++] = p;
							lineptr[nlines] = NULL;
							if(nlines > 500) putchar('\7');
							i = 0;
						}
						else if(inchar == '\t' || in == '\f')
							linebuf[i++] = inchar;
						else
							continue;
					}
				}
				if(inchar = chrdy())
				{
					if(echoflg)
						putchar(inchar);

					if(inchar == SPECIAL)
						break;
					else if(inchar == ('E' & 037))
					{
						chmode();
						ed(lineptr);
						printf("Terminal mode:\n\n");
						rawmode();
					}
					else
						send(inchar);
				}
			}
			break;
		
		case 'S':
		case 'R':
			printf("File to %s = ", (inchar == 'S') ? "send" : "receive");
			gets(linebuf);

			if(inchar == 'R')
				readfile(linebuf);
			else
			{
				if((fdes = fopen(linebuf, "r")) == NULL)
				{	
					printf("\7Teledit: can't open %s\n", linebuf);
					break;
				}
				sendfile(linebuf);
			}
			putchar(7);			/* beep when done */
			sleep(15);
			break;
		
		case 'E':
			ed(lineptr);
			break;
		
		case 'F':
			dump(lineptr,fdes);
			break;

		case 'B':
			printf("Baudrate: ");
			gets(linebuf);
			baud = atoi(linebuf);
			if(baud < 300 || baud > 9600)
				baud = 300;
			initmod();
			break;

		case 'G':
			echoflg = !echoflg;
			break;

		case 'Q':
			if (fflg) {
				printf("\nSave file \"%s\" to ",fnambuf);
				if (ask("disk"))
				{	
					dump(lineptr,fdes);
					fclose(fdes);
				}
			}
			lnmode();
			out(0,MDATA + 4);
			exit();
		}
	}
}

init() {	/* Initialize modem and allocate memory */
	unsigned	size;

	size = 0XFF00 & (szofram() - 1000);
	textbuf = alloc(size);
	textend = textbuf + size;
	textind = 0;
       	initmod();
}

initmod() {	/* Initialize modem port */
	int	tmp;

	tmp = 11520 / (baud / 10);
#asm
	DI
#endasm
	out(0,MDATA + 1);		/* Disable interupts	*/
	out(0200,MDATA + 3);		/* Divisor latch access	*/
	out(tmp & 0377,MDATA);		/* LSB			*/
	out((tmp >> 8) & 0377,MDATA + 1);  /* MSB		*/
	out(3,MDATA + 3);		/* * bits		*/
	out(1,MDATA + 4);		/* Turn on DTR		*/
	in(MDATA);			/* Clear USART		*/
#asm
	EI
#endasm
}

dump(lineptr,fdes)	/* dump text buffer	*/
char *lineptr[];
int	fdes;
{
	int i;

	for(i = 0; lineptr[i] != NULL; i++)
		if(fprintf(fdes,lineptr[i]) == ERROR)
			printf("\n\7Error writing txt, disk full?\n");

	lineptr[0] = linect = nlines = textind = 0;
}

ed(lineptr)	/* editor */
char **lineptr;
{
	char inchar, *inl[ML], *p;
	int i, j, k, l,fdes;

	if(!fflg)
	{	
		printf("\n\7No text buffer to edit.\n");
		return;
	}
	
	printf("\nedit\n*");
	nl = 22;

	while (inchar = getchar()) {
		putchar(inchar);
		switch (tolower(inchar)) {
		case 'a':
			printf("Filename to yank = ");
			gets(linebuf);
			if((fdes = fopen(linebuf, "r")) == NULL) {
				printf ("\r  Cannot open %s.\r*", linebuf);
				continue;
			}

			for(i = 0; fgets(linebuf,fdes); i++) {
				inl[i] = getm(linebuf);
				if(inl[i] == NULL) break;
			}

			inl[i] = NULL;
			iblock(lineptr, inl, linect);
			show (lineptr, linect, nl);
			continue;
		case 'b':
			linect = 0;
			show (lineptr, linect, nl);
			continue;
		case 'q':
			printf(CLEARS);
			return;
		case 'f':
			gets(linebuf);
			if((i = find(lineptr, linect)) >= 0) {
				linect = i;
				show (lineptr, linect, nl);
			}
			else if((i = find(lineptr, 0)) >= 0) {
				linect = i;
				show (lineptr, linect, nl);
			}
			else
			{	
				printf(HC);
				printf("  not found\r*");
			}
			continue;
		case 'i':
			j = min(linect, 5);
			if(j == 0)
				printf(CLEARS);
			else {
				show(lineptr, (linect - j), j);
				j++;
				printf("\b ");
				for(; j; j--)
					putchar('\n');
			}
			while(1) {
				gets(linebuf);
				for(i = 0; linebuf[i]; i++)  
					if(linebuf[i] == EOF)  
						break;
				if(linebuf[i] == EOF) break;
				linebuf[i++] = '\n';
				linebuf[i] = NULL;
				inl[j++] = getm(linebuf);
			}
			inl[j] = NULL;
			iblock(lineptr, inl, linect);
			show (lineptr, linect, nl);
			continue;
		case 'k':
			putchar('\n');
			show1(lineptr, linect);
			kill(lineptr, linect, 1);
			continue;
		case 'l':
			gets(linebuf);
			if((i = lfind(lineptr, linect)) >= 0) {
				linect = i;
				show(lineptr, linect, nl);
			}
			else if((i = lfind(lineptr, 0)) >= 0) {
				linect = i;
				show(lineptr, linect, nl);
			}
			else {
				printf(HC);
				printf("  not found\r*");
			}
			continue;
		case 'o':
			putchar('\n');
			i = linect;
			while(gets(linebuf)) {
				for(j = 0; linebuf[j]; j++)
					if(linebuf[j] == EOF) break;
				if(linebuf[j] == EOF) break;
				linebuf[j++] = '\n';
				linebuf[j] = NULL;
/*
				if(lineptr[i])
					free(lineptr[i]);

*/
				lineptr[i++] = getm(linebuf);
				if(i > nlines) lineptr[++nlines] = NULL;
			}
			show (lineptr, linect, nl);
			continue;
		case 'p':
			linect = min((linect + nl), nlines);
			show (lineptr, linect, nl);
			continue;
		case 's':
			gets(linebuf);
			nl = max((atoi(linebuf)), 1);
			show (lineptr, linect, nl);
			continue;
		case 'z':
			linect = nlines;
			show(lineptr, linect, nl);
			continue;
		case '1': 
		case '2': 
		case '3': 
		case '4': 
		case '5':
		case '6': 
		case '7': 
		case '8': 
		case '9': 
		case '-':
			linebuf[0] = inchar;
			for (i = 1; (isdigit(inchar = getchar())); i++)
				linebuf[i] = inchar;
			linebuf[i] = NULL;
			i = atoi(linebuf);
			if (i < 0)
				j = max((linect + i), 0);
			else
				j = min((linect + i), nlines);
			inchar = tolower(inchar);
			if(j > linect && inchar == 'k')
				kill(lineptr, linect, (j - linect));
			else
				linect = j;
			if (inchar == 'p') linect = max((linect-nl), 0);
			show (lineptr, linect, nl);
			continue;
		case '#':
			printf (" of lines: %d\r*", nlines);
			continue;
		case '\n':
			if (lineptr[linect] != NULL) {
				show1(lineptr, linect);
				linect++;
			}
			else
				printf (HC);
			continue;
		case ' ':
			if(linect)
				linect--;
			show(lineptr, linect, nl);
			continue;
		case ('E'&037):
			send(inchar);
			printf("\n^E sent\n");
			return;
		default:
			printf(" ?\r*");
		}
	}
}

shocrt(sec,try,tot)
int sec,try,tot;
{
	if(sflg)
		printf("Sending #%d (Try=%d Errs=%d)  \r", sec, try, tot);
	else
		printf("Awaiting #%d (Try=%d, Errs=%d)  \r", sec, try, tot);

	if(try && tot) putchar('\n');
}

receive(seconds)
int seconds;
{ 
	int lpc,seccnt;
	for (lpc = 0; lpc < CPUCLK; lpc++)
	{ 
		seccnt = seconds * SPS;
		while (!miready() && seccnt--);
		if(seccnt >= 0)
		{ 
			return(in(MDATA));   
		}
	}
	return(TIMEOUT);
}

purgeline()
{ 
	while (miready())
		in(MDATA);	/* purge the receive register	*/
}

readfile(file)
char *file;
{ 
	int j, firstchar, sectnum, sectcurr, sectcomp, errors;
	int toterr,checksum;
	int errorflag, fd;
	int bufctr;
	char buffer[BUFSIZ];

	sflg = FALSE;
	fd = fopen(file,"w");

	if(fd == NULL)
	{	
		printf("Teledit: cannot create %s\n", file);
		exit(1);
	}

	printf("\nReady to receive %s\n", file);
	sectnum = 0;
	errors = 0;
	toterr = 0;
	bufctr = 0;
	purgeline();
	shocrt(0,0,0);
	send(NAK);
	do
	    { 
		errorflag = FALSE;
		do
		    firstchar = receive (10);
		while(firstchar != SOH && firstchar != EOT && firstchar != TIMEOUT);

		if(firstchar == TIMEOUT)
			errorflag = TRUE;
		if(firstchar == SOH)
		{ 
			sectcurr = receive (1);
			sectcomp = receive (1);
			if((sectcurr + sectcomp) == 255)
			{ 
				if(sectcurr == sectnum + 1)
				{ 
					checksum = 0;
					for(j = bufctr;j < (bufctr + SECSIZ);j++)
					{ 
						buffer[j] = receive (1);
						checksum = (checksum + buffer[j]) & 0xff;
					}
					if(checksum == receive (1))
					{ 
						errors = 0;
						sectnum = sectcurr;
						bufctr = bufctr + SECSIZ;
						if(bufctr == TBFSIZ)
						{ 
							bufctr = 0;
							write(fd, buffer, TBFSIZ);
						}
						shocrt(sectnum,errors,toterr);
						send(ACK);
					}
					else
						errorflag = TRUE;
				}
				else
					if(sectcurr == sectnum)
					{ 
						do;
						while(receive (1) != TIMEOUT) 
							;
						send(ACK);
					}
					else
						errorflag = TRUE;
			}
			else
				errorflag = TRUE;
		}
		if(errorflag == TRUE)
		{ 
			errors++;
			if(sectnum)
				toterr++;
			while(receive (1) != TIMEOUT);
			shocrt(sectnum,errors,toterr);
			send(NAK);
		}
	}
	while(firstchar != EOT && errors != ERRORMAX);

	if((firstchar == EOT) && (errors < ERRORMAX))
	{ 
		send(ACK);
		while(bufctr < TBFSIZ)
			buffer[bufctr++] = 0;
		write(fd, buffer, TBFSIZ);
		printf("\nDone -- returning to menu:\n");
	}
	else
		printf("\n\7Aborting\n\n");
	fclose(fd);
}

sendfile(file)
char *file;
{ 
	char *npnt;
	int j, sectnum, sectors, attempts;
	int toterr,checksum;
	int bufctr, fd;
	char buffer[BUFSIZ];

	sflg = TRUE;
	fd = fopen(file,"r");

	if(fd == NULL)
	{ 
		printf("\nTeledit: %s not found\n", file);
		return;
	}
/*
	else
		printf("\nFile is %d sectors long.\n",rcfsiz(fd));
*/

	purgeline();
	attempts=0;
	toterr = 0;
	shocrt(0,0,0);

	while((receive (10) != NAK) && (attempts != 8))
	{ 
		attempts++;
		shocrt(0,attempts,0);
	}
	if (attempts == 8)
	{ 
		printf("\nTimed out awaiting initial NAK\n");
		exit();
	}
	attempts = 0;
	sectnum = 1;
		
	while((sectors = read(fd, buffer, BUFSIZ)) && (attempts != RETRYMAX))
	{ 
		if(sectors == -1)
		{ 
			printf("\nFile read error.\n");
			break;
		}
		else
		{ 
			sectors /= SECSIZ;
			bufctr = 0;
			do
			    { 
				attempts = 0;
				do
				    { 
					shocrt(sectnum,attempts,toterr);
					send(SOH);
					send(sectnum);
					send(-sectnum-1);
					checksum = 0;
					for(j = bufctr;j < (bufctr + SECSIZ);j++)
					{ 
						send(buffer[j]);
						checksum = (checksum + buffer[j]) & 0xff;
					}
					send(checksum);
					purgeline();
					attempts++;
					toterr++;
				}
				while((receive (10) != ACK) && (attempts != RETRYMAX));
				bufctr = bufctr + SECSIZ;
				sectnum++;
				sectors--;
				toterr--;
			}
			while((sectors != 0) && (attempts != RETRYMAX));
		}
	}
	if(attempts == RETRYMAX)
		printf("\nNo ACK on sector, aborting\n");
	else
	{ 
		attempts = 0;
		do
		    { 
			send(EOT);
			purgeline();
			attempts++;
		}
		while((receive (10) != ACK) && (attempts != RETRYMAX));
		if(attempts == RETRYMAX)
			printf("\nNo ACK on EOT, aborting\n");
	} 
	fclose(fd);
	printf("\nDone -- Returning to menu:\n");
}

ask(s)
char *s;
{

	char c;

again:	
	printf("%s (y/n)? ", s);
	c = 0XDF & getchar();
	putchar(c);
	if(c == 'Y') {
		printf("es\n");
		return 1;
	}

	else if(c == 'N')
		printf("o\n");
	else
	{
		printf("  \7Yes or no, please...\n");
		goto again;
	}
	return 0;
}

find(lineptr, linect)	/*Find a line having the pattern in linebuf        */
char *lineptr[];
int linect;
{
	int i;

	for(i = linect; lineptr[i] != NULL; i++)
		if(pat(lineptr[i], linebuf) >= 0)
			return(i);
	return(-1);
}

kill(lineptr, linect, nl)	/* erase lines */
char *lineptr[];
int linect, nl;
{
	int i, j;

	for (i = linect; lineptr[i] != NULL && nl > 0; i++, nl--) {
/*
		free(lineptr[i]);
*/
		nlines--;
	}
	lineptr[linect] = NULL;
	if(lineptr[i] != NULL) {
		j = (nlines - linect) * 2;
		movmem(&lineptr[i], &lineptr[linect], j + 2); 
	}
}

lfind(lineptr, linect) 		/* find pattern at beginning of a line */
char *lineptr[];
int linect;
{
	int i, j;
	char line[MAXLINE];

	j = strlen(linebuf);
	for (i = linect; lineptr[i] != NULL; i++) {
		strcpy(line, lineptr[i]);
		line[j] = NULL;
		if(strcmp(line, linebuf) == 0)
			return i;
	}
	return -1;
}


pat(s, t)	/* pattern match..*/
char s[], t[];
{
	int i, j, k;

	for(i = 0; s[i] != '\0'; i++)
	{
		for(j = i, k=0; t[k] != '\0' && s[j] == t[k]; j++, k++)
			;
		if(t[k] == '\0')
			return(i);
	}
	return(-1);
}

show (lineptr, linect, nl)	/* screen current frame */
char *lineptr[];
int linect, nl;
{
	int i;

	printf (CLEARS);
	putchar('\n');

	for (i = linect; i < (linect+nl) && lineptr[i] != NULL; i++)
		printf("%s", lineptr[i]);
	printf (HC);
	return(i);
}

show1(lineptr, linect)
char **lineptr;
int linect;
{
	int i;

	for(i = 0; i < nl; i++)
		putchar('\n');

	if((linect + nl) >= nlines)
		putchar('\n');
	else
		printf("%s", lineptr[linect+nl]);

	printf(HC);

	for(i = 0; i < 78; i++)
		putchar(' ');

	printf("\r*");
}

terminal()	/* terminal mode, no text */
{
	int inchar;

	while(1)
	{
		if(miready())
			putchar(in(MDATA));
		if(inchar = chrdy())
		{
			if(echoflg)
				putchar(inchar);

			if(inchar == SPECIAL)
				return;
			else
				send(inchar);
		}
	}
}

char *getm(line)	/* get memory for line, store it, return pointer */
char line[];
{
	int	strsiz;
	char	*p;

	strsiz = strlen(line) + 1;
	if((textbuf + textind + strsiz) < textend) {
		p = textbuf + textind;
		textind += strsiz;
		strcpy(p, line);
	} else
		p = 0;
	return(p);
}

iblock(rb, ib, cl)		/* insert block ib into rb at cl */
char *rb[], *ib[];
int cl;
{
	int i, j;

	j = 0;
	if (rb[cl]) {
		for (i = 0; ib[i]; i++)
			;
		j = (nlines - cl) * 2;
		movmem (&rb[cl], &rb[cl+i], j + 2);
	}
	for (i = 0; ib[i]; i++, cl++)
		rb[cl] = ib[i];
	if(!j) rb[cl] = NULL;
	nlines += i;
	return cl;	/* return new current line */
}

gets(str)	/* Get a string from the console */
char	*str; {

	lnmode();
	while((*str = getchar()) != '\n')
		str++;
	*str = 0;
	chmode();
}

fgets(str,fdes)	/* Get a string from a file */
char	*str;
int	fdes; {

	while((*str = getc(fdes)) != '\n' && *str != EOF)
		str++;
	if(*str == EOF)
		return(NULL);
	else {
		*str++ = '\n';
		*str = 0;
		return(str);
	}
}

sleep(seconds)
int	seconds; {
	int	i;

	while(seconds--)
		for(i = 0 ; i < SPS ; i++)
			;
}

tolower(c)	/* Convert c to lower case */
char	c; {

	if(c >= 'A' && c <= 'Z')
		c += 040;
	return(c);
}

isdigit(c)	/* Test if c is a digit */
char	c; {

	if(c >= '0' && c <= '9')
		return(1);
	else
		return(0);
}

max(a,b)	/* Return Maximum */
int	a,b; {

	return( (a > b) ? a : b);
}

min(a,b)	/* Return minimum */
int	a,b; {

	return( (a < b) ? a : b);

}

movmem(add1,add2,count)		/* Move memory */
char	*add1,*add2;
int	count; {

	while(count--)
		*add2++ = *add1++;
}

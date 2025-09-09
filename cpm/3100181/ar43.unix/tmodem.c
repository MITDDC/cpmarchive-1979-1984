/*
 * a version of Ward Christensen's MODEM program for
 * UNIX v7, 4.1bsd
 *
 * by Andrew Scott Beals
 * 9178 Centerway Rd.
 * Gaithersburg MD 20879
 * (301) 926-0911
 * last update->4 june 1982
 *
 */

#include <stdio.h>
#include <ctype.h>
#include <signal.h>
#include <sgtty.h>

#define uchar	unsigned char

#define	SLEEP	30

	/* Protocol characters used */

#define	SOH	1	/* Start Of Header */
#define	EOT	4	/* End Of Transmission */
#define	ACK	6	/* ACKnowlege */
#define	NAK	0x15	/* Negative AcKnowlege */

short		ttyhold;
struct sgttyb	ttymode;

main(argc,argv)
int	argc;
char	**argv;
{
	register uchar	checksum,index,blocknumber,errorcount,
			character;
	uchar		sector[128];
	int		foo,timeout();

	if(argc!=3)
	{
usage:		fprintf(stderr,"usage:\tmodem -<option> <file>\n");
		fprintf(stderr,"\twhere <option> is ``s'' for send, or ``r'' for recieve''\n");
		exit(1);
	}
	gtty(0,&ttymode);
	ttyhold=ttymode.sg_flags;
	ttymode.sg_flags|=RAW;
	ttymode.sg_flags&=~ECHO;

	if(argv[1][0]!='-')goto usage;
	if(argv[1][1]=='r')goto rec;
	if(argv[1][1]!='s')goto usage;

	/* send a file to the remote */

	stty(0,&ttymode);
	if((foo=open(argv[2],0))==-1)
	{
		fprintf(stderr,"can't open %s for send!\7\n",argv[2]);
		die(1);
	}
	fprintf(stderr,"file open, ready to send\r\n");
	fflush(stderr);
	fflush(stdout);
	errorcount=0;
	blocknumber=1;
	signal(SIGALRM,timeout);
	alarm(80);

	while((getchar()!=NAK)&&(errorcount<10))++errorcount;
	alarm(0);
#ifdef DEBUG
	fprintf(stderr,"transmission beginning\r\n");
	fflush(stderr);
#endif
	if(errorcount==10)
	{
error:		fprintf(stderr,"too many errors...aborting\7\7\7\r\n");
		die(1);
	}
	while(read(foo,sector,sizeof sector))
	{
		errorcount=0;
		while(errorcount<10)
		{
#ifdef DEBUG
			fprintf(stderr,"{%d} ",blocknumber);
			fflush(stderr);
#endif
			putchar(SOH); /* here is our header */
			putchar(blocknumber);	/* the block number */
			putchar(~blocknumber);	/* & its complement */
			checksum=0;
			for(index=0;index<128;index++)
			{
				putchar(sector[index]);
				checksum+=sector[index];
			}
			putchar(checksum); /* tell our checksum */
			fflush(stdout);
			if(getchar()!=ACK)++errorcount;
			else break;
		}
		if(errorcount==10)goto error;
		++blocknumber;
	}
	index=1;
	while(index)
	{
		putchar(EOT);
		fflush(stdout);
		index=getchar()==ACK;
	}
	fprintf(stderr,"Transmission complete.\r\n");
	fflush(stderr);
	die(0);

rec:	/* recieve a file */

	if((foo=open(argv[2],0))!=-1) {
		close(foo);
		fprintf(stderr,"%s exists; you have 10 seconds to abort\r\n",argv[2]);
		fflush(stderr);
		sleep(10);
		fprintf(stderr,"Too late!\r\n");
		fflush(stderr);
	}

	stty(0,&ttymode);

	if((foo=creat(argv[2],0666))==-1) {
		perror(argv[2]);
		die(1);
	}
	printf('you have 30 seconds...');
	fflush(stdout);
	sleep(SLEEP);	/* wait for the user to get his act together */
#ifdef DEBUG
	fprintf(stderr,"Starting...\r\n");
	fflush(stderr);
#endif
	putchar(NAK);
	fflush(stdout);
	errorcount=0;
	blocknumber=1;
	while((character=getchar())!=EOT)
	{
		register uchar not_ch;
		if(character!=SOH)
		{
#ifdef DEBUG
			fprintf(stderr,"Not SOH\r\n");
			fflush(stderr);
#endif
			if(++errorcount<10)goto nakit;
			else goto error;
		}
		character=getchar();
		not_ch=~getchar();
#ifdef DEBUG
		fprintf(stderr,"[%d] ",character);
		fflush(stderr);
#endif
		if(character!=not_ch)
		{
#ifdef DEBUG
			fprintf(stderr,"Blockcounts not ~\r\n");
			fflush(stderr);
#endif
			++errorcount;
			goto nakit;
		}
		if(character!=blocknumber)
		{
#ifdef DEBUG
			fprintf(stderr,"Wrong blocknumber\r\n");
			fflush(stderr);
#endif
			++errorcount;
			goto nakit;
		}
		checksum=0;
		for(index=0;index<128;index++)
		{
			sector[index]=getchar();
			checksum+=sector[index];
		}
		if(checksum!=getchar())
		{
#ifdef DEBUG
			fprintf(stderr,"Bad checksum\r\n");
			fflush(stderr);
#endif
			errorcount++;
			goto nakit;
		}
		putchar(ACK);
		fflush(stdout);
		blocknumber++;
		write(foo,sector,sizeof sector);
		if(!errorcount)continue;
nakit:
		putchar(NAK);
		fflush(stdout);
	}
	close(foo);

	putchar(ACK); /* tell the modem on the other end we accepted his EOT */
	putchar(ACK);
	putchar(ACK);
	fflush(stdout);

	fprintf(stderr,"Completed.\r\n");
	fflush(stderr);
	die(0);
}

timeout()
{
	fprintf(stderr,
	"Timed out waiting for NAK from remote system\7\7\7\r\n");
	die(1);
}

die(how)
register int how;
{
	ttymode.sg_flags=ttyhold;
	stty(0,&ttymode);
	exit(how);
}

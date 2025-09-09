/*
>>: yam.h
*/
#include "yamsys.h"		/* installation specific stuff */

#define VERSION "3.18 Rev 1-1-82"	/* (diff 10-25-81) */

#ifndef XMODEM
#define lprintf printf
#endif
/*
 * yam	-Yet Another Modem program
 *		Chuck Forsberg 10-18-81
 *
 *	Design goals: A general program performing the functions
 *	of MODEM and XMODEM, easily portable to non-timesharing
 *	computer systems.
 *
 *	Coding style is/was aimed at portability and clarity.
 *	File transfer routines are written without timing assumptions
 *   allowing error free high speed operation even if view selected
 *
 *	Comments to me at:
 *	Chuck Forsberg
 *		Computer Development Inc
 *		6700 S.W. 105th
 *		Beaverton OR 97005 503/646-1599
 *		Home 503/621-3406 Voice
 *		RBBS RCP/M 503/621-3193	(latest source code)
 *		  At 300, 450, or 1200 bps(212modem)	Random hours
 *		CBBS NW 503/284-5260
 *		Source TCE022
 *		RTTY Autostart 3627.5 "ZCZC WRU WA7KGX CR/LF msg... NNNN"
 *
 *	Files:
 *		yam.h		header and globals
 *		yamsys.h	Modem port adresses, installation specific data
 *		yam1.c		First time initialization
 *					Main command decoding
 *		yam2.c		Christensen protocol handler
 *		yam3.c		Conversation with data capture
 *					File xmsn w/o error checking.
 *
 *		yam5.c		Misc modem related functions, such as baudrate
 *		yam7.c		Disk i/o open,close, directory
 *					Wild card expansion, CP/M related stuff
 *		yam8.asm	CRCK calculation routine.
 *		yam9.asm	CRC calculation routine.
 *		yam10.c		USQ function (not used unless USQ defined)
 *
 *		compiled with -e 7000 for all files and -o for yam[2357]
 */

#ifdef CPM
char defdisk;		/* default disk */
char user;
#define PATHLEN 20	/* plenty long */
#endif

#ifdef BDSC
#define FLAG char
struct _buf fin,fout;
int logfd;		/* used by logfile */
#define stdin 0
#define stdout 1
#define stderr 1
char cfast;	/* BDS C fastest access is to extern's */
char checksum;	/* delcared here for speed */
unsigned oldcrc;	/* accumulates CRC checksum */
int wcj, firstch;
FLAG firstsec;		/* first sector, C instead of NAK for crc */
#endif

#ifndef IOTYPE		/* iotype may be unsigned for memory mapped i/o */
#define IOTYPE char
#endif

#define CMDLEN 132

#define ENQ 005
#define CAN ('X'&037)
#define XOFF ('s'&037)
#define XON ('q'&037)
#define SOH 01
#define EOT 4
#define ACK 6
#define WANTCRC 0103	/* send C not NAK to get crc not checksum */
#define NAK 025
#define TIMEOUT (-2)
#define ERRORMAX 5
#define RETRYMAX 5

/* declare all globally used functions not returning int */
char putcty(), *index(), *cisubstr();

FLAG Quiet;
char Ttycol, Lpcol;	/* column for tab expansion */
unsigned Numsecs;	/* Number of 128 byte sectors, used by compsec */
unsigned Numblks;	/* Number of CP/M blocks, used by compsec */
unsigned Numfiles;	/* Total number of files expanded */
unsigned Secpblk;	/* Number of sectors per block */
FLAG Rfile;		/* receiving into a file */
FLAG Tfile;		/* transmitting from a file */
FLAG Crcflg;		/* 1 if using crc, 0 otherwise */
FLAG Batch;		/* Batch (multi-file) xfer */
FLAG Creamfile;		/* true means o.k. to blast old file on rx */
FLAG Txgo;		/* file sending start/stop (XON/XOFF) */
FLAG Dumping;		/* not Squelched ^R */
FLAG Pflag;		/* printing the rx stuff */
FLAG Twxmode;		/* Respond to a/b requests */
FLAG Cis02;		/* Special functions for CIS02 access to Compuserve */
FLAG Ctlview;		/* Term function shows control chars as ^char */
FLAG View;	/* View data being transmitted/received if file xfer \
			also causes putcty to use putchar, allowing ^P, etc. */
FLAG Echo;	/* Echo modem data back to itself only in chat */
FLAG Hdx;	/* Half Duplex connection -no echo from far end */
FLAG Chat;	/* treat kbd \r as crlf when chatting */
FLAG Gototerm;	/* go to term after file xfer */
FLAG Exoneof;	/* exit from term() when finished with file */
/* Following flags affect data as it is written to file, not captured */
FLAG Image;	/* Tell it like it is. */
FLAG Zeof;	/* Terminate data capture & close file on ^Z */
FLAG Squelch;	/* Turn capture on after ^R, off before ^T */
char GOchar;	/* normally \n; resumes sending in EOL _ CRWAIT mode */
char *Txmoname;		/* asciz string corresponding to Txeoln mode */
FLAG Txeoln;	/* what to do at the end of a line */
#define EOL_NOTHING 0	/* send it all as is */
#define EOL_CR	1		/* send /r only */
#define EOL_NL	2		/* send \n only */
#define EOL_CRWAIT 3	/* send \r then wait for GOchar echo */
#define EOL_CRPROMPT 4	/* send \r then wait for silence. */
#define TX_BINARY 0200	/* don't stop on CPMEOF or whatever **/

/* For controls based on time since last RX char mostly */
unsigned Timeout;	/* measure of how long since last rx char */
unsigned Tpause;	/* when ++Timeout==Tpause, do something ... */
FLAG Xoffflg;		/* !=0 if we sent XOFF to stop the bubble machine */
FLAG Waitecho;		/* Wait for echo to stop when sending file */

/* If Waitbunch, Wait for Throttle loops each waitnum tx chars */
FLAG Waitbunch;
unsigned Waitnum;	/* do Waitecho each time chars_sent == Waitnum */
unsigned Throttle;
FLAG Txwait;		/* used with throttle */
unsigned Txtimeout;	/* counted down to 0, then Txwait becomes false */

unsigned T1pause;	/* for setting 0.1 second timeout for readline */
char Exitchar;		/* 0 or special character for exiting from term */
char Lastrx;		/* last char received, for detecting CAN CAN */

/*
 * start, end, input, output, printer-output pointers and marker
 * used with data capture
 */
char *bufst, *bufend, *bufcq, *bufcdq, *buffcdq, *bufpcdq, *bufmark;
char *abptr;		/* pointer to string to be sent, else 0 */
char *abend;		/* first character after string to be sent */
unsigned Free;		/* Number of characters free in capture buf */
unsigned Low;		/* when free==low, send the XOFF */
unsigned Bufsize;
FLAG Wrapped;		/* Buffer insertion pointer has wrapped around */
IOTYPE Dport,Sport;	/* data and status port addresses */
char Mstatus;		/* contents of modem error register if modem error */
unsigned Baudrate;  /* current baudrate */
FLAG Originate;	/* Originate mode requested */
FLAG Parity;
#define SEND8 0	/* RAW on Unix */
#define NORMAL 1	/* cooked o.k. on Unix */
	/* following would be CBREAK on Unix */
#define EVEN7 2
#define ODD7 3
#define EVEN8 4
#define ODD8 5

#ifndef KBMASK
#define KBMASK 0177	/* default strip parity bits from console kbd */
#endif

#ifdef USQ
#define RECOGNIZE 0xFF76	/* unlikely pattern */
/* External declarations for USQ feature */
#define NUMVALS 257	/* 256 data values plus SPEOF*/
/* Decoding tree */
struct {
	int children[2];	/* left, right */
} dnode[NUMVALS - 1];
int bpos;	/* last bit position read */
int curin;	/* last byte value read */
/* Variables associated with repetition decoding */
int repct;	/*Number of times to return value*/
int value;	/*current byte value or EOF */
#endif

char cmdbuf[CMDLEN+2], *cp;  /* for commands entered directly (not argv) */
char Rname[PATHLEN], Tname[PATHLEN];	/* saved file names */
char Phone[80];		/* phone number read in from file */

/*
 * Unix is a trademark of Western Electric
 * CP/M, Digital Research
 * Coherent, Mark Willams Co., Chicago IL
 * IDRIS, Whitesmiths Co.
 */

/*
Some #DEFINES you should know about:
	USERINIT this generates a call to userinit() from init()
	IOBYTE define this unsigned to point to memory mapped ports
	DEFBAUD if not defined, baudrate is read from the port
	USQ includes code to automatically type SQUEEZED files
	RESTRICTED disallows downloading of $SYS|TAG2 files, upload .com>.obj
	LOGTX log file name for completed file transmissions omit for no log
	LOGRX likewise, for files received omit for no log
	LOGFILE must be defined if logrx or logtx is defined.
	LOGUSER user number for log and lastcalr
	LASTCALR pathname for current caller (lastcalr with entbbs)
	TERMINIT string initializes terminal to default mode.
	TERMREPLOT string sets mode for replot; should disable line wrap.
	TERMRESET string sets terminal to mode for conversation with remote.
	PHONES file with phone numbers
*/

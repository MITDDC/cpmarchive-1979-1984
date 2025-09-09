/*
>>:yamsys.h 11-11-81
 *
 * Other modem specific stuff is in yam5.c
 *
 *	Features (and misfeatures) of YAM for the Apple with Micromodem II
 *
 *	Supports autodial of any entry in YAMPHONE.T.  Be warned that the
 * 	parsing is primitive -- every digit on the selected line is dialed.
 *	(Don't suppose you'd believe me if I said that's for compatability
 *	with MODEM7...)  Anyway, don't put any numbers in the location name.
 *	As a special case, put a line in YAMPHONE.T which just contains
 *	"askme".  Then typing "call askme" will cause a prompt for the
 *	telephone number to dial.
 *
 *	I've kludged the "b" (setbaud) command to provide an additional
 *	function. "b300" and "b110" do what you'd expect. "b1" (or
 *      b<anything else>) gets you into a menu to allow changing the
 *      byte format (character size, stop bits, parity).
 *
 *	Note that exiting YAM via "off" hangs up the phone.  If you want to
 *	exit and stay online, use ^C.  When re-entering YAM, the initialization
 *	routine tries to be smart about not bashing things if carrier is
 *	present.
 *
 *	The additional code in YAM5.C to support these functions requires that
 *	you add 500 (hex) to the external origin suggested by CAF.  E.g., if
 *	he suggests using "-e 6200" you should use "-e 6700".
 *
 *	NOTE WELL that use of inp() and outp() for memory mapped I/O
 *	requires changes to the BDS libraries.  One version of these changes
 *	is documented in APBDSC.DQC, to be found on finer RCPM systems.
 *
 *				-- Jeff Martin  11/13/81 --
 *
 */
/* STDIO file included here to simplify cross-compiles of cyams */
#include "a:bdscio.h"

/* files have single letter ext so pip yam?????.? gets all source but no crl */
#define HELPFILE "A:YAMHELP.T"
#define PHONES "A:YAMPHONE.T"
#define LOOPBACKNONO "\020\003\021\023\033"
#define ANSWERBACK ""
#define CPM
#define BDSC
#define INITBAUD
#define CLKMHZ 2
#define SECPBLK 2	/* 128 byte blocks on Apple controller 5" disk */
/* ********* following string must be in UPPER case ********* */
#define DISKS "AB"	/* legal disks for default selection */
#define MAXUSER 15	/* maximum user number */
#define FLAVOR "Apple/Micromodem II YAM"
#define STATLINE	/* do special status line information */
#define Z19				/* terminal type */
			/* 25th line on, cleared.  wrap at end of line*/
#define TERMRESET	"\033x1\033j\033Y8 \033K\033k\033v"
#define TERMINIT	"\033z"
#define DEFBAUD 300	/* Use this default baud rate -- MMII can't read */
#define MMII		/* type of modem port */
#define USERINIT	/* ours needs some initialization */

#define MMIICR2 0xE0A5	/* Modem (as opposed to ACIA) control/status port */
#define HOOKOFF 0x80	/* cr2 write functions */
#define MMSET 0x08
#define ORIGMODE 0x04
#define TXE 0x02
#define HISPEED 0x01

#define RESETACIA 0x03	/* cr1 write functions */
#define ACIAMODE 0x15	/* One start, 8 data, no parity, one stop */
#define SBREAK 0x60	/* Writing this to CR1 sends break */
#define IOTYPE unsigned	/* Port declaration for memory mapped I/O */

#define DPORT MDATA	/* Use the bdscio.h definition */
#define SPORT MSTAT	/* Use the bdscio.h definition */

char inp();	/* for fastest 8080 code */
char cr1;	/* Store last write to MMII cr1 */
char cr2;	/* Store last write to MMII cr2 */
#define MIREADY (inp(Sport)&MIMASK)	/* value != 0 if char available */
#define MIREADYERROR		/* rx data ready and error bits in smae reg */
#define CDO (inp(Sport)&0x04)	/* True if carrier dropped off */
#define MIREADYMASK MIMASK		/* rx character available */
#define MIERRORMASK 0x30		/* rx error (framing or overrun) */
#define MICHAR (inp(Dport))		/* get char assuming miready */

#define MOREADY (inp(Sport)&MOMASK)	/* modem ready to load next char */
/* It would be nice to have parameterized macros to do the following */
#define MODATA DPORT 		/* modem data output port */

#define CIREADY (inp(CSTAT)&CIMASK)
#define CICHAR (inp(CDATA))

#define COREADY (inp(CSTAT)&COMASK)

/*
 * It would be nice if Microsoft's BIOS for the Apple supported BIOS
 * function 15 (list device status) so the following wouldn't be needed
 */
#define PSTAT 0xE09E	/* Status port for CCS serial printer interface */
#define POMASK 0x02	/* CCS serial printer interface output ready mask */
#define POREADY (inp(PSTAT)&POMASK)

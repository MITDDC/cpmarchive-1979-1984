/*
PRINTER.C  a command to set the flags on an Espon MX series
printer.  I haven't bothered to type up a DOC on this one,
so you'll have to look at the source to see what's going on.

It was knocked out late one night, when I got tired of using
PIP to send the control codes.  Don't expect upgrades, and
feel free to stick in your own favorite functions.

Copyright (c) 1982 by Gary P. Novosielski
All rights reserved.
Permission is hereby granted for unrestricted non-commercial
use.  Any use for commercial advantage without prior written
consent of the author is prohibited.
*/

#include "bdscio.h"	

/*      Return code definitions   */
#define RESET	1
#define	PITCH	2
#define LPI 	3
#define	DRAFT	4
#define TEXT	5
#define	EJECT	6
#define	TINY	7
#define TABS	8
#define SKIP	9
#define NOSKIP	10
#define WIDTH	11
#define ITALIC	12
#define ROMAN	13

#define LST	5	/* Bdos function for list output */

main(argc, argv)
int  argc;
char **argv;
{
    int  value, oldvalue;
    char xlate();

    if (argc < 2)
    {
	puts("PRINTER  Ver:1.0    Copyright (c) 1982 Gary P. Novosielski\n");
	puts("Correct syntax is:\n");
	puts("PRINTER <opt> [<opt>...]\n");
	puts("\twhere <opt> may be:\n\n");
	puts("RESET\t\tPITCH n\t\tLPI n\t\tEJECT\n");
	puts("SKIP\t\tNOSKIP\t\tDRAFT\t\tTEXT\n");
	puts("TINY\t\tWIDTH n\t\tTABS n n n...\tITALIC\n");
	puts("ROMAN\n");
	puts("\nExample:\nPRINTER LPI 6 PITCH 10 DRAFT");
	exit();
    }

    while (--argc > 0)
    {
	switch (xlate(*++argv))
	{
	case RESET:
	    bdos(LST,ESC);
	    bdos(LST,'@');
	    bdos(LST,ESC);
	    bdos(LST,'C');
	    bdos(LST,0);
	    bdos(LST,11);
	    break;
	case PITCH:
	    value = atoi((--argc,*++argv));
	    if (value == 10)
		bdos(LST,18);
	    else if (value == 17)
		bdos(LST,15);
	    else
		abort ("%s--Invalid pitch.  Not 10 or 17.",*argv);
	    break;
	case LPI:
	    if (!(value = atoi((--argc,*++argv))) || value > 216)
		abort ("%s--Invalid Lines per Inch\nMust be 1 - 216.",*argv);
	    bdos(LST,ESC);
	    bdos(LST,'3');
	    bdos(LST,216/value);
	    break;
	case DRAFT:
	    bdos(LST,ESC);
	    bdos(LST,'H');
	    bdos(LST,ESC);
	    bdos(LST,'T');
	    break;
	case TEXT:
	    bdos(LST,ESC);
	    bdos(LST,'G');
	    bdos(LST,ESC);
	    bdos(LST,'U');
	    bdos(LST,1);
	    break;
	case EJECT:
	    bdos(LST,12);
	    break;
	case TINY:
	    bdos(LST,ESC);
	    bdos(LST,'S');
	    bdos(LST,0);
	    bdos(LST,ESC);
	    bdos(LST,'1');
	    break;
	case TABS:
	    oldvalue = 0;
	    bdos(LST,ESC);
	    bdos(LST,'D');
	    while(--argc)
	    {
		value = atoi(*++argv);
		if(value && value <= oldvalue)
		{
		    bdos(LST,0);
		    abort("Tabs not in increasing order");
		}
		if (!value)
		    --argv, ++argc;
		else
		    bdos(LST,(oldvalue = value));
	    }
	    bdos(LST,0);
	    break;
	case SKIP:
	    bdos(LST,ESC);
	    bdos(LST,'N');
	    bdos(LST,6);
	    break;
	case NOSKIP:
	    bdos(LST,ESC);
	    bdos(LST,'N');
	    bdos(LST,0);
	    break;
	case WIDTH:
	    if (!(--argc))
		break;
	    if (!(value = atoi(*++argv)))
		abort("%s--Invalid width.",*argv);
	    bdos(LST,ESC);
	    bdos(LST,'Q');
	    bdos(LST,value);
	    break;
	case ITALIC:
	    bdos(LST,ESC);
	    bdos(LST,'4');
	    break;
	case ROMAN:
	    bdos(LST,ESC);
	    bdos(LST,'5');
	    break;


	default:
	    abort("%s--Unknown keyword.",*argv);
	}
    }  
}

char xlate(string)
  char *string;
{
    if (!strcmp(string,"RESET"))
	return RESET;
    else if (!strcmp(string,"PITCH"))
	return PITCH;
    else if (!strcmp(string,"LPI"))
	return LPI;
    else if (!strcmp(string,"DRAFT"))
	return DRAFT;
    else if (!strcmp(string,"TEXT"))
	return TEXT;
    else if (!strcmp(string,"EJECT"))
	return EJECT;
    else if (!strcmp(string,"TINY"))
	return TINY;
    else if (!strcmp(string,"TABS"))
	return TABS;
    else if (!strcmp(string,"TAB"))
	return TABS;
    else if (!strcmp(string,"SKIP"))
	return SKIP;
    else if (!strcmp(string,"NOSKIP"))
	return NOSKIP;
    else if (!strcmp(string,"WIDTH"))
	return WIDTH;
    else if (!strcmp(string,"ITALIC"))
	return ITALIC;
    else if (!strcmp(string,"ROMAN"))
	return ROMAN;
    else
	return ERROR;
}

abort(p1,p2,p3,p4,p5,p6,p7,p8)
unsigned p1,p2,p3,p4,p5,p6,p7,p8;
{
    printf(p1,p2,p3,p4,p5,p6,p7,p8);
    unlink("A:$$$.SUB");
    puts("...ABORTED");
    exit();
}

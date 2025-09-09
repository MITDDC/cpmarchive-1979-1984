/*
 * SYSCOPY - a portable replacement for the CP/M SYSGEN utility
 * This program uses the disk parameter tables in CP/M 2.x if
 * possible, but can also be configured to prompt for CP/M 1.x
 * The input and output files are biased to 0900h so that they
 * can be loaded and debugged with DDT/SID ala the documentation
*/
#include "bdscio.h"
#define	INPUT	0
#define	OUTPUT	1
#define	UPDATE	2
#define	SELDSK	9
#define	SETTRK	10
#define	SETSEC	11
#define	SETDMA	12
#define	READS	13
#define	WRITES	14
#define	VERSION	12
#define	CURRENT	25
#define	READR	33
#define	WRITER	34
#define	COMFSZ	35
#define	dpb	struct DPB
struct	DPB	{
    int		dpb_spt;
    char	dpb_bsh;
    char	dpb_blm;
    char	dpb_exm;
    unsigned	dpb_dsm;
    unsigned	dpb_drm;
    char	dpb_al0;
    char	dpb_al1;
    int		dpb_cks;
    int		dpb_off;
    };
#define	dph	struct DPH
struct	DPH	{
    unsigned	dph_xlt;
    char	dph_res11[6];
    char	*dph_dirbuf;
    dpb		*dph_dpb;
    char	*dph_csv;
    char	*dph_alv;
    };
#define	DRIVES	"ABCDEFGHIJKLMNOP"
#define	MAXINT	32767
#define MAXSYS	64

main(argc,argv)
int argc;
char *argv[];
    {
    char source[32],destination[32],number[32],reply[32]; /* plenty big */
    int fromdisk,todisk; /* signal file or direct I/O */
    int version,inres,outres,inspt,outspt,indrive,outdrive;
    int i,count,infd,outfd,insec,outsec,intrk,outtrk,insize,outsize;
    dph *indph,*outdph;
    dpb *indpb,*outdpb;
    char current,buffer[SECSIZ],system[MAXSYS][SECSIZ];

/*
 * Output the signon message, init, and check for a help request
*/
    current = bdos(CURRENT,0); /* get current disk number */
    version = bdos(VERSION,0); /* get the CP/M version number */
    if ((argc > 1) && (argv[1][0] == '?'))
	{
	printf("Syscopy utility version 1.0 - by Stephen M. Kenton\n\n");
	printf("Syntax: syscpy [input [output [count]]]\n");
	printf("Input and output may be either a disk or a filename\n");
	printf("If specified, a colon ':' must be included with a disk\n");
	printf("name, or it will be considered to be a short file name\n");
	printf("Count is the number of sectors to be read and written\n");
	printf("It will normally be 1 for the boot block or '*' for all\n");
	printf("Count may be in decimal, or preceeded by a $ for hex\n");
	printf("Any argument(s) that are omitted will be prompted for\n");
	exit(0);
	}
    printf("Portable system copy utility. For help, enter 'syscopy ?'\n\n");

/*
 * Get the input arguments from the command line or the user
*/
    if (argc > 1)
	strcpy(source,argv[1]);
    else
	{
	printf("Enter source, or return for current drive: ");
	gets(source);
	}
    if (strlen(source) == 0)
	{
	source[0] = DRIVES[current]; /* fabricate a string */
	strcpy(source+1,":");
	}
    if ((strlen(source) == 2) && (source[1] == ':'))
	{
	fromdisk = TRUE;
	indrive = index(DRIVES,toupper(source[0]));
	}
    else
	fromdisk = FALSE;

    if (argc > 2)
	strcpy(destination,argv[2]);
    else
	{
	printf("Enter destination, or return for current drive: ");
	gets(destination);
	}
    if (strlen(destination) == 0)
	{
	destination[0] = DRIVES[current]; /* fabricate a string */
	strcpy(source+1,":");
	}
    if ((strlen(destination) == 2) && (destination[1] == ':'))
	{
	todisk = TRUE;
	outdrive = index(DRIVES,toupper(destination[0]));
	}
    else
	todisk = FALSE;

    if (argc > 3)
	strcpy(number,argv[3]);
    else
	{
	printf("Enter number of sectors, or return for all: ");
	gets(number);
	}
    if (strlen(number) == 0)
	{
	strcpy(number,"*"); /* asterisk means copy all sectors */
	}
    if (number[0] == '*') /* wild card */
	count = MAXINT; /* largest possible value */
    else if (number[0] == '$') /* hexidecimal */
	sscanf(number+1,"%x",&count);
    else /* decimal */
	sscanf(number,"%d",&count);

/*
 * Now determine the characteristics of the drives or files
*/
    if ((version == 0) || (version > 255)) /* CP/M 1.x or MP/M */
	{
	printf("MP/M does not allow access to some disk I/O calls,  and\n");
	printf("CP/M 1.x does not supply some needed information\n");
	printf("for this utility to run, use CP/M 2.x to run it\n");
	exit(1);
	}
    else
	{
	if (fromdisk) /* if reading from the system tracks */
	    {
	    indph = dphaddr(indrive); /* DPH address */
	    if (indph == 0)
		{
		printf("Invalid source drive %s selected\n",source);
		exit(1);
		}
	    indpb = indph->dph_dpb; /* DPB address */
	    inres = indpb->dpb_off; /* number of reserved tracks */
	    inspt = indpb->dpb_spt; /* number of sectors per track */
	    insize = inres * inspt; /* number of reserved sectors */
	    if (inres > 3)
		{
		printf("There are more than 3 reserved tracks on this drive\n");
		printf("This normally indicates that it is a logical disk\n");
		printf("rather than a bootable physical disk volume\n");
		printf("If this is the case, reading the reserved tracks\n");
		printf("will result in garbage being in the buffer\n");
		printf("Do you with to continue? (Y/N): ");
		scanf("%s",reply); /* get the response */
		if (toupper(reply[0]) != 'Y')
		    exit(1);
		}
	    }
	else /* if reading from a file */
	    {
	    if ((infd = open(source,INPUT)) == ERROR)
		{
		printf("Can not open source file %s\n",source);
		exit(1);
		}
	    insize = rcfsiz(infd) - 16; /* file size - bias */
	    for (i=0; i<16; i++)
		read(infd,buffer,1); /* dump the bias sectors */
	    }

	if (todisk) /* if writing to the system tracks */
	    {
	    outdph = dphaddr(outdrive); /* DPH address */
	    if (outdph == 0)
		{
		printf("Invalid destination drive %s selected\n",destination);
		exit(1);
		}
	    outdpb = outdph->dph_dpb; /* DPB address */
	    outres = outdpb->dpb_off;
	    outspt = outdpb->dpb_spt;
	    outsize = outres * outspt; /* number of reserved sectors */
	    if (inres > 3)
		{
		printf("There are more than 3 reserved tracks on this drive\n");
		printf("This normally indicates that it is a logical disk\n");
		printf("rather than a bootable physical disk volume\n");
		printf("If this is the case, writing on the reserved\n");
		printf("tracks will destroy another logical disk\n");
		printf("Do you with to continue? (Y/N): ");
		scanf("%s",reply); /* get the response */
		if (toupper(reply[0]) != 'Y')
		    exit(1);
		}
	    }
	else /* if writing to a file */
	    {
	    if ((outfd = creat(destination)) == ERROR)
		{
		printf("Can not open destination file %s\n",destination);
		exit(1);
		}
	    outsize = MAXINT; /* largest possible value */
	    setmem(buffer,SECSIZ,'\0'); /* clear the buffer */
	    for (i=0; i<16; i++)
		write(outfd,buffer,1); /* write the bias sectors */
	    }
	}
    insize = (count < insize) ? count : insize; /* choose  the smaller */
    if (insize > outsize)
	{
	printf("Source is longer than destination, truncate? (Y/N): ");
	scanf("%s",reply); /* check answer */
	if (toupper(reply[0]) == 'Y')
	    insize = outsize;
	else
	    exit(1);
	}
    if (insize > MAXSYS)
	{
	printf("System size exceeds memory buffer limit\n");
	exit(1);
	}

/*
 * Copy the source to the destination
*/
    outsize = insize; /* write only as much as was specified */
    if (fromdisk) /* read from the system tracks */
	{
	bios(SELDSK,indrive); /* select the input drive */
	for (intrk=0; intrk<inres; intrk++)
	    {
	    bios(SETTRK,intrk); /* select the track */
	    for (insec=1; insec<=inspt; insec++)
		{
		count = intrk*inspt+insec-1; /* number of sectors */
		if (count > insize)
		    goto stopin; /* we just hit the limit */
		bios(SETSEC,insec); /* set the sector number */
		bios(SETDMA,system[count]); /* set DMA address */
		bios(READS,0); /* read the sector in */
		}
	    }
	stopin:
	bios(SELDSK,current); /* select the origianal drive */
	}
    else /* read from a file */
	{
	if (read(infd,system,insize) < insize) /* read what you need */
	    {
	    printf("Error reading %s\n",source);
	    exit(1);
	    }
	}

    if (todisk) /* write to the system tracks */
	{
	bios(SELDSK,outdrive); /* select the output drive */
	for (outtrk=0; outtrk<outres; outtrk++)
	    {
	    bios(SETTRK,outtrk); /* select the track */
	    for (outsec=1; outsec<=outspt; outsec++)
		{
		count = outtrk*outspt+outsec-1; /* number of sectors */
		if (count > outsize)
		    goto stopout; /* we just hit the limit */
		bios(SETSEC,outsec); /* set the sector */
		bios(SETDMA,system[count]); /* set DMA address */
		bios(WRITES,0); /* write the sector */
		}
	    }
	stopout:
	bios(SELDSK,current); /* select the original drive */
	}
    else /* write to a file */
	{
	if (write(outfd,system,outsize) < outsize) /* write what you have */
	    {
	    printf("Error writing %s\n",destination);
	    exit(1);
	    }
	}

/*
 * Clean up and exit
*/
    if (!fromdisk) /* if reading from a file */
	close(infd);
    if (!todisk) /* if writing to a file */
	close(outfd);
    printf("%d sectors were copied from %s to %s\n",insize,source,destination);
    }

/*
 * Index - return the index of the first occurance of a char in a
 * string, or ERROR if it is not found
*/
index(str,c)
char *str,c;
    {
    int i;
    for (i=0; str[i]; i++)
	{
	if (str[i] == c)
	    return(i); /* found it */
	}
    return(ERROR); /* did not find it */
    }

/*
 * Dphaddr - return the address of a disk parameter header
 * This is performed by bios call 9, but the Bios() function
 * can not be used, because it returns a <A> not <HL>
*/
dphaddr(drive)
int drive;
    {
    unsigned *warmstart,seldsk,result;
    char current;

    current = bdos(CURRENT,0); /* save the current drive */
    warmstart = 1;
    seldsk = *warmstart + 24; /* address of SELDSK routine */
    result = call(seldsk,0,0,drive,0); /* call the bios seldsk routine */
    bios(SELDSK,current); /* restore the original disk */
    return(result);
    }

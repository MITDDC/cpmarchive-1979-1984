/*
	Program:  DEVICE
	Author:  Richard Conn
	Version:  1.0
	Date:  22 Aug 82
	Previous Versions:  None
*/
#define	ver	10		/* Version Number */
#define	defname	"DEVICE.COM"	/* Default File Name */

/*

	DEVICE -- a program for assigning mnemonic names to the
CP/M physical devices and allowing these devices to be selected
by the assigned names

	Command Forms:

		DEV CON: USERNAME	<-- Select Device
		    LST: USERNAME
		    RDR: USERNAME
		    PUN: USERNAME

		DEV //			<-- HELP

		DEV /DISPLAY		<-- Display USERNAMEs and
						current settings

		DEV /SET		<-- Define USERNAMEs and
						comments

	Concept and Examples:

		DEV CON: REMOTE		<-- Select Remote Console
		DEV LST: MODEM		<-- Select Modem Output
		DEV /D			<-- Display UNs and Settings
			CON: Mnemonic Devices --
				TTY	CRT	MODEM	CRT/MODEM
			LST: Mnemonic Devices --
				TTY	CRT	REMOTE	MODEM
			RDR: Mnemonic Devices --
				TTY	CRT	CLOCK	MODEM
			PUN: Mnemonic Devices --
				TTY	CRT	CLOCK	MODEM

			Current Settings --
				CON: = CRT
				LST: = MODEM
				RDR: = CLOCK
				PUN: = CLOCK

*/

/*  Global Definitions and Variables  */
char username[16][9];  /* 16 User Names of 8 Chars + Ending NULL Each */

/*  Main Program  */
main(argc,argv)
int argc;
char **argv;
{
	printf("DEVICE, Version %d.%d",ver/10,ver%10);
	switch (argc) {
		case 2 : if (*argv[1] == '/') option(argv[1]);
				else help();
			 break;
		case 3 : set(argv[1], argv[2]); break;
		default : help(); break;
		}
}

/*  Option Processor  */
option(ostr)
char *ostr;
{
	char *tstr;

	tstr = ostr;  /* assign temp ptr */
	printf("  -- Option: ");
	switch (*++tstr) {
		case 'D' : printf("Display Device Mnemonics and Status");
			   display(); break;
		case 'S' : printf("Setup of Device Mnemonics");
			   setup(); break;
		default  : printf("Help");
			   help(); break;
		}
}

/*  Help Message  */
help()
{
	printf("\n\tDEVICE Program Help Information\n");

	printf("\nDEVICE is a program used to assign mnemonic names to");
	printf("\nthe CP/M physical devices and allow these devices to");
	printf("\nbe selected by these names.");
	printf("\n");

	printf("\nThe forms of this command are --");

	printf("\n\tDEVICE ldev mnemonic\t<-- select device");
	printf("\n\t\tldev may be one of:");
		printf("\n\t\t\tCON  LST  PUN  RDR");
		printf("\n\t\t-- only first letter is required");

	printf("\n\tDEVICE /DISPLAY\t<-- display mnemonics and current ");
		printf("settings");

	printf("\n\tDEVICE /SET\t<-- define mnemonics");

	printf("\n\tDEVICE //\t<-- print HELP information\n");
}

/*  Display Mnemonics and Current Settings  */
display()
{
	int i,dev;

	printf("\nPhysical Device Mnemonics --");
	for (dev = 0; dev < 4; dev++) {
		prdev(dev);  /* Print Device Names */
		printf(" Mnemonic Names --\n\t");
		for (i = dev*4; i < (dev+1)*4; i++) {
			printf("\t");
			prun(i);  /* Print User Name */
			}
		}
	disp2();
}

/*  Display Current Device Assignments  */
disp2()
{
	int dev,i;

	printf("\n\nCurrent Device Assignments --");
	for (dev = 0; dev < 4; dev++) {
		prdev(dev); printf(" = ");
		i = dev*4 + binit(dev);  /* Get Number of User Name */
		prun(i);  /* Print User Name */
		}
	printf("\n");
}

/*  Print Names of Devices  */
prdev(dev)
int dev;
{
	printf("\n\t");
	switch (dev) {
		case 0 : printf("CON:"); break;
		case 1 : printf("RDR:"); break;
		case 2 : printf("PUN:"); break;
		case 3 : printf("LST:"); break;
		}
}

/*  Print User Name  */
prun(map)
int map;
{
	printf(username[map]);
}

/*  Extract Binit Number for Logical Device  */
binit(dev)
int dev;
{
	int stat,i;

	stat = bdos(7,0);  /* Get current I/O Byte */
	for (i = 0; i < dev; i++) stat = stat >> 2;
	stat &= 3;  /* 2 LSB only */
	return(stat);
}

/*  Set up Mnemonic Names  */
setup()
{
	char cmd, fname[40];
	int i,j,fd;
	unsigned cend,base;

	printf("\nDEVICE Setup Subsystem");
	do {
		printf("\nSetup Command (? for Help)? ");
		cmd = toupper(getchar());  /* Get Response */
		switch (cmd) {
			case 'C' : while(setdev(0) == 0); break;
			case 'R' : while(setdev(1) == 0); break;
			case 'P' : while(setdev(2) == 0); break;
			case 'L' : while(setdev(3) == 0); break;
			case 'I' : initdev(); break;
			case 'D' : display(); break;
			case 'Q' : printf("\tVerify Abort (Y/N)? ");
					if (toupper(getchar()) == 'Y')
						return(-1);
					break;
			case 'X' : break;
			default  : sethlp(); break;
			}
	} while (cmd != 'X');
	printf("\tWrite New File (Y/N)? ");
	if (toupper(getchar()) != 'Y') return(-1);
	printf("\nName of File (RETURN = %s)? ",defname);
	dots(12);
	scanf("%s",fname); strcap(fname);  /* Input and Capitalize File Name */
	if (strlen(fname) == 0) strcpy(fname,defname);  /* Set FN if none */
	if (strscan(fname) == 0) strcat(fname,".COM");  /* Make type COM */
	printf("\nWriting File %s to Disk ...",fname);
	fd = creat(fname);  /* Delete old file and open new one */
	if (fd == -1) {
		printf("\nError -- Can't Create File %s",fname);
		return(-1);
		}
	cend = codend()/128;  /* Determine last 128-byte block of code */
	write(fd,0x100,cend);  /* Write file to disk */
	close(fd);  /* Close file -- done */
	printf(" File %s Written to Disk\n",fname);
}

/*  Set Mnemonic String for Device Number Given; return -1 to abort  */
setdev(devno)
int devno;
{
	int i;
	char name[20];

	printf("\n\tPhysical Device Number (RETURN=Done or 0-3)? ");
	i = getchar() - '0';  /* Get response and convert to binary */
	if ((i < 0) || (i > 4))  /* i is out of range */
		return(-1);
	do {
		printf("\n\tDevice Name (RETURN = Clear Device Name)? ");
		dots(8);
		scanf("%s",name); strcap(name);  /* Get and Capitalize Name */
		if (strlen(name) > 8)
			printf("Device Name is too Long -- Reenter");
	} while (strlen(name) > 8);
	i = devno*4 + i; username[i][0]='\0'; /* Pt to name and clear it */
	if (strlen(name) == 0) {
		printf("\nName Cleared");
		return(-1);
		}
	strcat(username[i],name);  /* Make entry in array */
	return(0);  /* Continue Flag */
}

/*  Initialize all devices to clear  */
initdev()
{
	int i;
	char ans;

	printf("\tVerify Initialization (Y/N)? ");
	if (toupper(getchar()) != 'Y') {
		printf("\nInitialization Aborted");
		return(-1);
		}
	for (i=0; i<16; i++) username[i][0] = '\0';
	printf("\nAll Mnemonic Device Names Cleared");
}

/*  Set Binit in I/O Byte for Device (String 1) Mnemonic (String 2)  */
set(devs,user)
char *devs, *user;
{
	int dev,i,match,iobyte,mask;

	switch (*devs) {
		case 'C' : dev = 0; break;
		case 'R' : dev = 1; break;
		case 'P' : dev = 2; break;
		case 'L' : dev = 3; break;
		default : printf("\nError -- Invalid Logical Device Name\n");
			  help(); return(-1);
		}
	match = -1;
	for (i = dev*4; i < (dev+1)*4; i++)
		if (strcmp(username[i],user) == 0) match = i-dev*4;
	if (match == -1) {
		printf("\nError -- Invalid Device Mnemonic\n");
		help(); return(-1);
		}
	iobyte = bdos(7,0);  /* Get I/O Byte */
	mask = 3;  /* Set Mask */
	for (i = 0; i < dev; i++) {
		mask = mask << 2;  /* Set Mask on Target */
		match = match << 2;  /* Set Match on Target */
		}
	iobyte = iobyte & ~mask;  /* Complement Mask and Set Target to 0 */
	iobyte |= match;  /* Map In New Binit onto Target */
	bdos(8,iobyte);  /* Set New I/O Byte */
	disp2();  /* Display New Settings */
	return(0);  /* Return with Continuation Flag Set */
}

/*  Capitalize String  */
strcap(str)
char *str;
{
	char *tstr;

	tstr = str;
	while (*tstr != '\0') {
		*tstr = toupper(*tstr);
		tstr++;
		}
}

/*  Help File for Interactive Setup Commands  */
sethlp()
{
	printf("\nDEVICE Setup Subsystem Command Summary");
	printf("\n\tC, R, P, L -- Define Mnemonic for CON:, RDR:, PUN:, ");
	printf("or LST: Devices");
	printf("\n\tD -- Display Currently-Defined Device Mnemonics");
	printf("\n\tI -- Initialize and Clear All Device Mnemonics");
	printf("\n\tQ -- Quit without Changing Program on Disk");
	printf("\n\tX -- Exit and Update Program on Disk");
}

/*  Print num dots followed by num <BS> on screen  */
dots(num)
int num;
{
	int i;

	for (i=0; i<num; i++) putchar('.');
	for (i=0; i<num; i++) putchar('\010');
}

/*  Scan passed string for a decimal and return zero if not found  */
strscan(str)
char *str;
{
	char *tstr;

	tstr = str;  /* pt to first char */
	while (*tstr != '\0')
		if (*tstr++ == '.') return (-1);
	return(0);  /* Didn't find dot */
}
